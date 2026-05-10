//
//  AnimatedGIFView.swift
//  Varsha
//
//  Native animated GIF player using ImageIO. No third-party dependencies.
//
//  Decodes a GIF file (from URL — bundled or remote), extracts frames and
//  per-frame delays via CGImageSource, and hands them to UIImageView's
//  built-in animated-images mechanism. UIImageView is hardware-accelerated
//  for this and uses far less memory than naively re-rendering frames.
//
//  Frames are decoded off the main thread; only the assignment back to the
//  view runs on main.
//

import SwiftUI
import UIKit
import ImageIO
import MobileCoreServices  // legacy const fallback

struct AnimatedGIFView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        return imageView
    }

    func updateUIView(_ imageView: UIImageView, context: Context) {
        // Avoid re-decoding the same GIF on every body update.
        if context.coordinator.loadedURL == url, imageView.animationImages != nil {
            return
        }
        context.coordinator.loadedURL = url
        loadGIF(into: imageView)
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var loadedURL: URL?
    }

    private func loadGIF(into imageView: UIImageView) {
        let url = self.url
        Task.detached(priority: .userInitiated) {
            guard let decoded = AnimatedGIFView.decode(url: url) else { return }
            await MainActor.run {
                imageView.animationImages = decoded.frames
                imageView.animationDuration = decoded.duration
                imageView.animationRepeatCount = 0   // 0 = infinite
                imageView.image = decoded.frames.first
                imageView.startAnimating()
            }
        }
    }

    // MARK: - Decoder

    private struct DecodedGIF {
        let frames: [UIImage]
        let duration: TimeInterval
    }

    private static func decode(url: URL) -> DecodedGIF? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let count = CGImageSourceGetCount(source)
        guard count > 0 else { return nil }

        var frames: [UIImage] = []
        frames.reserveCapacity(count)
        var totalDuration: TimeInterval = 0

        for i in 0..<count {
            guard let cg = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            frames.append(UIImage(cgImage: cg))
            totalDuration += frameDelay(source: source, index: i)
        }

        // Guard against zero-duration GIFs (shouldn't happen, but be safe).
        let duration = totalDuration > 0 ? totalDuration : Double(frames.count) * 0.1
        return DecodedGIF(frames: frames, duration: duration)
    }

    private static func frameDelay(source: CGImageSource, index: Int) -> TimeInterval {
        guard
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
            let gif = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        else { return 0.1 }

        // Prefer unclamped (true encoded delay); fall back to clamped (browser-safe).
        if let unclamped = gif[kCGImagePropertyGIFUnclampedDelayTime] as? TimeInterval, unclamped > 0 {
            return unclamped
        }
        if let clamped = gif[kCGImagePropertyGIFDelayTime] as? TimeInterval, clamped > 0 {
            return clamped
        }
        // Many GIFs use 100ms as the default frame delay.
        return 0.1
    }
}
