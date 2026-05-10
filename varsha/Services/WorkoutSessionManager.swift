//
//  WorkoutSessionManager.swift
//  Varsha
//
//  The brain of an active workout: walks through the flattened set sequence,
//  drives countdowns for time-based sets and rest periods, supports reset/skip,
//  and emits state via @Published for the UI to react to.
//

import Foundation
import Combine
import UIKit       // for haptics
import AudioToolbox // for system sounds

@MainActor
final class WorkoutSessionManager: ObservableObject {

    // MARK: - State

    enum Phase: Equatable {
        case notStarted
        case performing(setIndex: Int)   // user is actively doing a set
        case resting(setIndex: Int)      // between sets
        case completed
    }

    let workout: Workout
    let library: ExerciseLibrary

    @Published private(set) var phase: Phase = .notStarted
    @Published private(set) var currentSetIndex: Int = 0

    /// For rep-based sets: how long the user has been on this set (seconds).
    /// For time-based sets: how many seconds remain on the countdown.
    @Published private(set) var displayedSeconds: Int = 0

    /// Logged actuals — you'd persist these to SwiftData.
    @Published var loggedWeights: [UUID: Double] = [:]
    @Published var loggedReps: [UUID: Int] = [:]

    // MARK: - Private

    private var timer: Timer?
    private var countdownEnd: Date?         // for time-based sets and rest periods
    private let setSequence: [PrescribedSet]

    // MARK: - Init

    init(workout: Workout, library: ExerciseLibrary) {
        self.workout = workout
        self.library = library
        self.setSequence = workout.setSequence
    }

    // MARK: - Computed

    var currentSet: PrescribedSet? {
        guard currentSetIndex < setSequence.count else { return nil }
        return setSequence[currentSetIndex]
    }

    var currentExercise: Exercise? {
        guard let id = currentSet?.exerciseId else { return nil }
        return library.exercise(for: id)
    }

    var nextSet: PrescribedSet? {
        let nextIdx = currentSetIndex + 1
        guard nextIdx < setSequence.count else { return nil }
        return setSequence[nextIdx]
    }

    var nextExercise: Exercise? {
        guard let id = nextSet?.exerciseId else { return nil }
        return library.exercise(for: id)
    }

    var totalSets: Int { setSequence.count }
    var progress: Double {
        guard totalSets > 0 else { return 0 }
        return Double(currentSetIndex) / Double(totalSets)
    }

    // MARK: - Public commands

    func start() {
        guard case .notStarted = phase else { return }
        beginCurrentSet()
    }

    /// Mark current set as done. Triggers rest period (or finishes workout).
    func completeCurrentSet(loggedReps: Int? = nil, loggedWeight: Double? = nil) {
        guard case .performing = phase, let set = currentSet else { return }
        if let r = loggedReps { self.loggedReps[set.id] = r }
        if let w = loggedWeight { self.loggedWeights[set.id] = w }

        stopTimer()
        successHaptic()

        if set.restAfterSeconds > 0 && currentSetIndex < setSequence.count - 1 {
            beginRest(seconds: set.restAfterSeconds)
        } else {
            advanceToNextSet()
        }
    }

    /// Skip the rest period and go straight to the next set.
    func skipRest() {
        guard case .resting = phase else { return }
        stopTimer()
        advanceToNextSet()
    }

    /// Add 15 seconds to current rest (common UX pattern).
    func addRestTime(seconds: Int = 15) {
        guard case .resting = phase, let end = countdownEnd else { return }
        countdownEnd = end.addingTimeInterval(TimeInterval(seconds))
        tick()
    }

    /// Reset the *current set's* timer back to zero. Workout state preserved.
    func resetCurrentSet() {
        guard case .performing = phase else { return }
        stopTimer()
        beginCurrentSet()
    }

    /// Hard reset: back to set zero, not started. Used for "Restart workout".
    func resetWorkout() {
        stopTimer()
        currentSetIndex = 0
        displayedSeconds = 0
        phase = .notStarted
    }

    /// Manual jump (debug / power user).
    func jump(toSetIndex idx: Int) {
        guard idx >= 0 && idx < setSequence.count else { return }
        stopTimer()
        currentSetIndex = idx
        beginCurrentSet()
    }

    // MARK: - Internal flow

    private func beginCurrentSet() {
        guard let set = currentSet else {
            phase = .completed
            return
        }
        phase = .performing(setIndex: currentSetIndex)

        if let duration = set.durationSeconds {
            // Time-based: countdown, auto-complete at 0
            startCountdown(seconds: duration) { [weak self] in
                self?.completeCurrentSet()
            }
        } else {
            // Rep-based: count *up* so user sees how long they've been on this set
            startStopwatch()
        }
    }

    private func beginRest(seconds: Int) {
        phase = .resting(setIndex: currentSetIndex)
        startCountdown(seconds: seconds) { [weak self] in
            self?.advanceToNextSet()
        }
    }

    private func advanceToNextSet() {
        currentSetIndex += 1
        if currentSetIndex >= setSequence.count {
            phase = .completed
            stopTimer()
            successHaptic()
        } else {
            beginCurrentSet()
        }
    }

    // MARK: - Timer machinery

    private func startStopwatch() {
        displayedSeconds = 0
        countdownEnd = nil
        let started = Date()
        scheduleTimer { [weak self] in
            guard let self = self else { return }
            self.displayedSeconds = Int(Date().timeIntervalSince(started))
        }
    }

    private func startCountdown(seconds: Int, onComplete: @escaping () -> Void) {
        let end = Date().addingTimeInterval(TimeInterval(seconds))
        displayedSeconds = seconds
        scheduleTimer { [weak self] in
            guard let self = self, let end = self.countdownEnd else { return }
            let remaining = max(0, Int(ceil(end.timeIntervalSinceNow)))
            self.displayedSeconds = remaining
            // Tick haptic for last 3 seconds — works during rest *and* time-based sets
            if remaining > 0 && remaining <= 3 {
                self.tickHaptic()
            }
            if remaining <= 0 {
                self.stopTimer()
                onComplete()
            }
        }
        // Set after scheduleTimer because scheduleTimer calls stopTimer() which clears countdownEnd
        countdownEnd = end
    }

    /// Re-emit current state without changing it. Used after addRestTime to refresh UI.
    private func tick() {
        if let end = countdownEnd {
            displayedSeconds = max(0, Int(ceil(end.timeIntervalSinceNow)))
        }
    }

    private func scheduleTimer(_ tick: @escaping () -> Void) {
        stopTimer()
        let t = Timer(timeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in tick() }
        }
        // .common runloop mode — keeps firing during scrolling, animations, etc.
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        countdownEnd = nil
    }

    // MARK: - Feedback

    private func tickHaptic() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    private func successHaptic() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    deinit {
        timer?.invalidate()
    }
}
