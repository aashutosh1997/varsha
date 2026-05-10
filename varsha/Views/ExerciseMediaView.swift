//
//  ExerciseMediaView.swift
//  Varsha
//
//  Progressive media fallback for exercise demonstration. Picks the first
//  available source in this priority order:
//
//    1. Looped MP4 video                            (self-recorded clips)
//    2. Bundled GIF                                 (ExerciseDB v1, AGPL-3.0)
//    3. Two-frame animation from bundled JPGs       (free-exercise-db, public domain)
//    4. Static image                                (rare fallback)
//    5. Icon + form cues                            (always works)
//
//  GIFs are preferred over the two-frame animator because they show real
//  motion. Two-frame is the universal fallback when no GIF match exists.
//
//  Bundled assets live under Resources/ExerciseMedia/ and are looked up by
//  convention from the exercise's id:
//      ExerciseMedia/{id}.gif        ← preferred
//      ExerciseMedia/{id}-0.jpg      ← start frame (fallback)
//      ExerciseMedia/{id}-1.jpg      ← end frame (fallback)
//
//  Run Scripts/fetch_exercise_media.py to populate the folder, then drag
//  Resources/ExerciseMedia/ into Xcode and choose "Create folder references".
//

import SwiftUI
import AVKit
import AVFoundation
import UIKit
import Combine

// MARK: - Top-level view

struct ExerciseMediaView: View {
    let exercise: Exercise
    var height: CGFloat = 280

    var body: some View {
        Group {
            if let videoURL = exercise.videoURL {
                LoopingVideoPlayer(url: videoURL)
            } else if let gifURL = ExerciseFrameLocator.gif(for: exercise.id) {
                AnimatedGIFView(url: gifURL)
            } else if let frames = ExerciseFrameLocator.frames(for: exercise.id) {
                TwoFrameAnimator(frame0URL: frames.start, frame1URL: frames.end)
            } else if let imageName = exercise.staticImageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
            } else {
                fallbackPlaceholder
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var fallbackPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text(exercise.name)
                .font(.headline)
            if !exercise.formCues.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(exercise.formCues.prefix(3), id: \.self) { cue in
                        Label(cue, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
    }
}

// MARK: - Frame locator

/// Looks up bundled exercise media by convention.
///
/// Tries two layouts to be robust across Xcode versions and folder-add styles:
///   1. Inside an `ExerciseMedia/` subdirectory (true folder reference / blue
///      synchronized folder, where the directory structure survives into the bundle).
///   2. Flat at the bundle root (yellow group, individually-added files, or
///      Xcode 16 synchronized folder that flattens its children).
///
/// Expected file naming:
///   - `{id}.gif`         → animated GIF (preferred)
///   - `{id}-0.jpg`/`-1.jpg` → start/end frames for two-frame fallback
enum ExerciseFrameLocator {
    private static let mediaSubdir = "ExerciseMedia"

    static func gif(for exerciseId: String) -> URL? {
        bundleURL(name: exerciseId, ext: "gif")
    }

    static func frames(for exerciseId: String) -> (start: URL, end: URL)? {
        guard
            let start = bundleURL(name: "\(exerciseId)-0", ext: "jpg"),
            let end = bundleURL(name: "\(exerciseId)-1", ext: "jpg")
        else { return nil }
        return (start, end)
    }

    /// Tries the subdirectory first, then falls back to the bundle root.
    private static func bundleURL(name: String, ext: String) -> URL? {
        if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: mediaSubdir) {
            return url
        }
        return Bundle.main.url(forResource: name, withExtension: ext)
    }
}

// MARK: - Two-frame animator

/// Crossfades between two still images on a fixed interval to simulate motion.
/// Used as the default exercise demo when no Lottie or video is available.
struct TwoFrameAnimator: View {
    let frame0URL: URL
    let frame1URL: URL
    let interval: TimeInterval

    @State private var showingSecond = false
    @State private var images: LoadedImages?

    private let timer: Publishers.Autoconnect<Timer.TimerPublisher>

    init(frame0URL: URL, frame1URL: URL, interval: TimeInterval = 0.7) {
        self.frame0URL = frame0URL
        self.frame1URL = frame1URL
        self.interval = interval
        self.timer = Timer.publish(every: interval, on: .main, in: .common).autoconnect()
    }

    var body: some View {
        ZStack {
            if let images {
                Image(uiImage: images.start)
                    .resizable()
                    .scaledToFit()
                    .opacity(showingSecond ? 0 : 1)
                Image(uiImage: images.end)
                    .resizable()
                    .scaledToFit()
                    .opacity(showingSecond ? 1 : 0)
            } else {
                ProgressView()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showingSecond)
        .task {
            // Load both images off the main thread; assign on main.
            let loaded = await Self.loadImages(start: frame0URL, end: frame1URL)
            await MainActor.run { self.images = loaded }
        }
        .onReceive(timer) { _ in
            showingSecond.toggle()
        }
    }

    private struct LoadedImages {
        let start: UIImage
        let end: UIImage
    }

    private static func loadImages(start: URL, end: URL) async -> LoadedImages? {
        await Task.detached(priority: .userInitiated) {
            guard
                let s = UIImage(contentsOfFile: start.path),
                let e = UIImage(contentsOfFile: end.path)
            else { return nil }
            return LoadedImages(start: s, end: e)
        }.value
    }
}

// MARK: - Looping muted video player

/// Plays a video URL on loop, muted, no controls. Used for self-recorded MP4 clips.
///
/// On load failure (bad URL, unreachable host, unsupported format) the inner
/// AVPlayerViewController stays empty rather than crashing the app — but the
/// caller (ExerciseMediaView) won't know and won't fall through to the next
/// media tier. Always set `videoURLString` only for URLs you've verified work.
struct LoopingVideoPlayer: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        player.isMuted = true
        player.actionAtItemEnd = .none

        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = false
        vc.videoGravity = .resizeAspectFill
        vc.view.backgroundColor = .clear

        // Loop forever
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }

        // Surface load failures in the console so they're easy to spot.
        // (AVPlayer doesn't crash on bad URLs — it just silently fails — which
        // is why the symptom shows up downstream as "the animation didn't play".)
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: item,
            queue: .main
        ) { note in
            if let error = note.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                print("⚠️ LoopingVideoPlayer failed for \(url): \(error.localizedDescription)")
            }
        }

        player.play()
        return vc
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if let currentURL = (uiViewController.player?.currentItem?.asset as? AVURLAsset)?.url,
           currentURL != url {
            let item = AVPlayerItem(url: url)
            uiViewController.player?.replaceCurrentItem(with: item)
            uiViewController.player?.play()
        }
    }
}
