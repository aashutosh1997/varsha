//
//  PlanLoader.swift
//  Varsha
//
//  Decodes the compact plan JSON in Resources/Plans/ and expands it into
//  the full model types. The compact schema keeps the JSON hand-editable:
//  blocks describe *patterns* (straight sets, supersets, rounds of items)
//  and the expansion below generates the individual PrescribedSets with
//  their labels and rest times.
//

import Foundation

enum PlanLoaderError: Error, CustomStringConvertible {
    case fileNotFound(String)
    case duplicateExerciseId(String)
    case unknownExerciseId(id: String, workout: String)
    case invalidBlock(label: String, reason: String)

    var description: String {
        switch self {
        case .fileNotFound(let name):
            return "Plan file '\(name).json' not found in bundle"
        case .duplicateExerciseId(let id):
            return "Duplicate exercise id '\(id)' in exercises.json"
        case .unknownExerciseId(let id, let workout):
            return "Unknown exercise id '\(id)' in workout '\(workout)'"
        case .invalidBlock(let label, let reason):
            return "Invalid block '\(label)': \(reason)"
        }
    }
}

enum PlanLoader {

    // MARK: - Public API

    static func loadLibrary(bundle: Bundle = .main) throws -> ExerciseLibrary {
        let file = try decode(ExercisesFileDTO.self, named: "exercises", bundle: bundle)
        var exercises: [String: Exercise] = [:]
        for dto in file.exercises {
            guard exercises[dto.id] == nil else { throw PlanLoaderError.duplicateExerciseId(dto.id) }
            exercises[dto.id] = Exercise(
                id: dto.id, name: dto.name, primaryMuscle: dto.primaryMuscle,
                formCues: dto.formCues,
                videoURLString: dto.videoURL,
                staticImageName: dto.staticImageName,
                alternativeIds: dto.alternativeIds ?? []
            )
        }
        return ExerciseLibrary(exercises: exercises)
    }

    static func loadPlan(named name: String, library: ExerciseLibrary, bundle: Bundle = .main) throws -> WorkoutPlan {
        try expand(try decode(PlanFileDTO.self, named: name, bundle: bundle), library: library)
    }

    /// Decodes a plan from raw JSON data — used by unit tests with inline fixtures.
    static func plan(from data: Data, library: ExerciseLibrary) throws -> WorkoutPlan {
        try expand(try JSONDecoder().decode(PlanFileDTO.self, from: data), library: library)
    }

    // MARK: - Bundle lookup

    private static func decode<T: Decodable>(_ type: T.Type, named name: String, bundle: Bundle) throws -> T {
        // The Xcode synchronized folder may bundle Plans/ as a subdirectory or
        // flatten it to the bundle root — try both (same as ExerciseFrameLocator).
        let url = bundle.url(forResource: name, withExtension: "json", subdirectory: "Plans")
            ?? bundle.url(forResource: name, withExtension: "json")
        guard let url else { throw PlanLoaderError.fileNotFound(name) }
        return try JSONDecoder().decode(T.self, from: try Data(contentsOf: url))
    }

    // MARK: - Expansion

    private static func expand(_ file: PlanFileDTO, library: ExerciseLibrary) throws -> WorkoutPlan {
        var workouts: [Weekday: Workout] = [:]
        for workoutDTO in file.workouts {
            let blocks = try workoutDTO.blocks.map { try expand($0, workout: workoutDTO.title, library: library) }
            workouts[workoutDTO.day] = Workout(
                day: workoutDTO.day,
                title: workoutDTO.title,
                subtitle: workoutDTO.subtitle,
                estimatedMinutes: workoutDTO.estimatedMinutes,
                warmupNote: workoutDTO.warmupNote,
                blocks: blocks,
                cooldownNote: workoutDTO.cooldownNote
            )
        }
        return WorkoutPlan(id: file.id, name: file.name, workouts: workouts, library: library)
    }

    private static func expand(_ block: BlockDTO, workout: String, library: ExerciseLibrary) throws -> WorkoutBlock {
        let forms: [Any?] = [block.straight, block.superset, block.groups, block.rounds, block.sets]
        guard forms.compactMap({ $0 }).count == 1 else {
            throw PlanLoaderError.invalidBlock(
                label: block.label,
                reason: "must have exactly one of straight/superset/groups/rounds/sets"
            )
        }

        let sets: [PrescribedSet]
        if let straight = block.straight {
            sets = expand(straight: straight, tag: block.tag)
        } else if let superset = block.superset {
            sets = expand(superset: superset, tag: block.tag)
        } else if let groups = block.groups {
            sets = groups.flatMap { expand(group: $0, tag: block.tag) }
        } else if let rounds = block.rounds {
            sets = expand(rounds: rounds, tag: block.tag)
        } else {
            sets = block.sets!.map { $0.prescribedSet(tag: block.tag) }
        }

        for set in sets where library.exercise(for: set.exerciseId) == nil {
            throw PlanLoaderError.unknownExerciseId(id: set.exerciseId, workout: workout)
        }

        return WorkoutBlock(label: block.label, kind: block.kind, prescribedSets: sets, notes: block.notes)
    }

    /// N sets of one exercise, "Set i of N" labels, final set always rests 90s
    /// before moving on to the next block.
    private static func expand(straight: StraightDTO, tag: String) -> [PrescribedSet] {
        (1...straight.sets).map { i in
            PrescribedSet(
                exerciseId: straight.exercise,
                reps: straight.reps,
                durationSeconds: straight.durationSeconds,
                suggestedWeightKg: straight.weightKg,
                perSide: straight.perSide ?? false,
                restAfterSeconds: i == straight.sets ? 90 : straight.rest,
                setNumberLabel: "Set \(i) of \(straight.sets)",
                blockLabel: tag,
                notes: nil
            )
        }
    }

    /// Interleaves the exercises each round (A, B, A, B, ...): 30s rest between
    /// paired exercises, the full rest after the last exercise of each round.
    private static func expand(superset: SupersetDTO, tag: String) -> [PrescribedSet] {
        (1...superset.rounds).flatMap { round in
            superset.exercises.enumerated().map { index, exerciseId in
                PrescribedSet(
                    exerciseId: exerciseId,
                    reps: superset.reps,
                    durationSeconds: nil,
                    suggestedWeightKg: nil,
                    perSide: false,
                    restAfterSeconds: index == superset.exercises.count - 1 ? superset.rest : 30,
                    setNumberLabel: "Round \(round) of \(superset.rounds)",
                    blockLabel: tag,
                    notes: nil
                )
            }
        }
    }

    /// A homogeneous run of sets within a mixed block; `lastRest` overrides the
    /// rest after the final set (defaults to `rest`).
    private static func expand(group: GroupDTO, tag: String) -> [PrescribedSet] {
        (1...group.sets).map { i in
            PrescribedSet(
                exerciseId: group.exercise,
                reps: group.reps,
                durationSeconds: group.durationSeconds,
                suggestedWeightKg: group.weightKg,
                perSide: group.perSide ?? false,
                restAfterSeconds: i == group.sets ? (group.lastRest ?? group.rest) : group.rest,
                setNumberLabel: group.labelOverride ?? "Set \(i) of \(group.sets)",
                blockLabel: tag,
                notes: group.notes
            )
        }
    }

    /// `count` rounds of the item sequence (circuits, intervals); each item's
    /// `restFinalRound` overrides its rest on the last round only.
    private static func expand(rounds: RoundsDTO, tag: String) -> [PrescribedSet] {
        let labelWord = rounds.labelStyle == "set" ? "Set" : "Round"
        return (1...rounds.count).flatMap { round in
            rounds.items.map { item in
                let isFinalRound = round == rounds.count
                return PrescribedSet(
                    exerciseId: item.exercise,
                    reps: item.reps,
                    durationSeconds: item.durationSeconds,
                    suggestedWeightKg: item.weightKg,
                    perSide: item.perSide ?? false,
                    restAfterSeconds: isFinalRound ? (item.restFinalRound ?? item.rest) : item.rest,
                    setNumberLabel: "\(labelWord) \(round) of \(rounds.count)",
                    blockLabel: tag,
                    notes: item.notes
                )
            }
        }
    }
}

// MARK: - Compact-schema DTOs

private extension PlanLoader {

    struct ExercisesFileDTO: Decodable {
        let exercises: [ExerciseDTO]
    }

    struct ExerciseDTO: Decodable {
        let id: String
        let name: String
        let primaryMuscle: String
        let formCues: [String]
        let videoURL: String?
        let staticImageName: String?
        let alternativeIds: [String]?
    }

    struct PlanFileDTO: Decodable {
        let id: String
        let name: String
        let workouts: [WorkoutDTO]
    }

    struct WorkoutDTO: Decodable {
        let day: Weekday
        let title: String
        let subtitle: String
        let estimatedMinutes: Int
        let warmupNote: String
        let cooldownNote: String
        let blocks: [BlockDTO]
    }

    struct BlockDTO: Decodable {
        let label: String
        let kind: BlockKind
        let tag: String
        let notes: String?
        let straight: StraightDTO?
        let superset: SupersetDTO?
        let groups: [GroupDTO]?
        let rounds: RoundsDTO?
        let sets: [RawSetDTO]?
    }

    struct StraightDTO: Decodable {
        let exercise: String
        let sets: Int
        let reps: Int?
        let durationSeconds: Int?
        let weightKg: Double?
        let perSide: Bool?
        let rest: Int
    }

    struct SupersetDTO: Decodable {
        let exercises: [String]
        let rounds: Int
        let reps: Int
        let rest: Int
    }

    struct GroupDTO: Decodable {
        let exercise: String
        let sets: Int
        let reps: Int?
        let durationSeconds: Int?
        let weightKg: Double?
        let perSide: Bool?
        let notes: String?
        let rest: Int
        let lastRest: Int?
        let labelOverride: String?
    }

    struct RoundsDTO: Decodable {
        let count: Int
        let labelStyle: String?
        let items: [RoundItemDTO]
    }

    struct RoundItemDTO: Decodable {
        let exercise: String
        let reps: Int?
        let durationSeconds: Int?
        let weightKg: Double?
        let perSide: Bool?
        let notes: String?
        let rest: Int
        let restFinalRound: Int?
    }

    /// Raw escape hatch: one DTO per set, expanded 1:1.
    struct RawSetDTO: Decodable {
        let exercise: String
        let reps: Int?
        let durationSeconds: Int?
        let weightKg: Double?
        let perSide: Bool?
        let rest: Int
        let label: String
        let notes: String?

        func prescribedSet(tag: String) -> PrescribedSet {
            PrescribedSet(
                exerciseId: exercise, reps: reps, durationSeconds: durationSeconds,
                suggestedWeightKg: weightKg, perSide: perSide ?? false,
                restAfterSeconds: rest, setNumberLabel: label, blockLabel: tag, notes: notes
            )
        }
    }
}
