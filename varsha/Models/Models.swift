//
//  Models.swift
//  Varsha
//
//  Core data structures for workouts, blocks, exercises, and prescribed sets.
//

import Foundation

// MARK: - Day of week

enum Weekday: String, Codable, CaseIterable, Identifiable {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

// MARK: - Exercise

/// An exercise in the catalog. Identified by stable `id` (not name).
struct Exercise: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let primaryMuscle: String
    let formCues: [String]              // Always present — ultimate fallback
    let videoURLString: String?         // Remote MP4 URL or bundle:// scheme
    let staticImageName: String?        // Asset catalog image name
    let alternativeIds: [String]        // Other exercises that hit the same pattern

    var videoURL: URL? {
        guard let s = videoURLString else { return nil }
        return URL(string: s)
    }
}

// MARK: - Prescribed set

/// One scheduled set. Either rep-based (manual completion) or time-based (auto-completion).
struct PrescribedSet: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    let exerciseId: String
    let reps: Int?                      // nil for time-based sets
    let durationSeconds: Int?           // nil for rep-based sets
    let suggestedWeightKg: Double?      // nil if bodyweight or user-decides
    let perSide: Bool                   // e.g. "10 reps per leg"
    let restAfterSeconds: Int           // 0 = no rest
    let setNumberLabel: String          // e.g. "Set 2 of 4", "Round 3"
    let blockLabel: String              // e.g. "A1", "Circuit", "Finisher"
    let notes: String?

    /// True if the set should auto-complete on a countdown.
    var isTimeBased: Bool { durationSeconds != nil }
}

// MARK: - Workout block

enum BlockKind: String, Codable {
    case straight       // N sets of one exercise, then move on
    case superset       // Alternate between exercises, N rounds
    case circuit        // Round of all exercises, then repeat N times
    case interval       // HIIT-style timed work/rest cycles
    case finisher       // Bonus / closer
}

/// Authoring shape — the human-readable workout structure. The session manager flattens this.
struct WorkoutBlock: Identifiable, Codable {
    var id: UUID = UUID()
    let label: String
    let kind: BlockKind
    let prescribedSets: [PrescribedSet]
    let notes: String?
}

// MARK: - Workout

struct Workout: Identifiable, Codable {
    var id: UUID = UUID()
    let day: Weekday
    let title: String
    let subtitle: String                // e.g. "Lower Body Strength"
    let estimatedMinutes: Int
    let warmupNote: String
    let blocks: [WorkoutBlock]
    let cooldownNote: String

    /// Flattened ordered set sequence — what the runner walks through.
    var setSequence: [PrescribedSet] {
        blocks.flatMap { $0.prescribedSets }
    }

    var totalSets: Int { setSequence.count }
}

// MARK: - Exercise library

/// Lookup wrapper. In production, back this with SwiftData or a remote API.
struct ExerciseLibrary {
    let exercises: [String: Exercise]

    func exercise(for id: String) -> Exercise? {
        exercises[id]
    }
}
