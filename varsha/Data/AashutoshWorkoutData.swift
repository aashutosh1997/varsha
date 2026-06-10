//
//  AashutoshWorkoutData.swift
//  Varsha
//
//  Static data for Aashutosh's lean-bulk plan: 4-day Upper/Lower split,
//  hypertrophy focus with a weekly conditioning finisher.
//  29M, 167cm, 60kg — goal: build muscle + overall fitness.
//

import Foundation

// MARK: - Exercises not in the shared library

private let aashutoshNewExercises: [Exercise] = [
    Exercise(
        id: "incline-db-press", name: "Incline Dumbbell Press", primaryMuscle: "Upper Chest / Shoulders",
        formCues: [
            "Bench at 30-45°",
            "Lower dumbbells to upper chest",
            "Press up and slightly together",
            "Keep shoulder blades pinned"
        ],
        videoURLString: nil,
        staticImageName: nil,
        alternativeIds: ["db-bench", "machine-press"]
    ),
    Exercise(
        id: "lateral-raise", name: "Dumbbell Lateral Raise", primaryMuscle: "Side Delts",
        formCues: ["Slight bend in elbows", "Raise to shoulder height, no higher", "Lead with elbows, not hands", "No swinging — go lighter if you must cheat"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["machine-shoulder-press"]
    ),
    Exercise(
        id: "face-pull", name: "Cable Face Pull", primaryMuscle: "Rear Delts / Upper Back",
        formCues: ["Rope at upper-chest height", "Pull towards your eyes", "Elbows high and wide", "Pause and squeeze shoulder blades"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["chest-supported-row"]
    ),
    Exercise(
        id: "pullup", name: "Pull-up", primaryMuscle: "Back / Lats",
        formCues: ["Full hang at the bottom", "Drive elbows down to lift", "Chin over bar without kipping", "Control the descent"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["assisted-pullup", "lat-pulldown"]
    ),
    Exercise(
        id: "leg-extension", name: "Leg Extension", primaryMuscle: "Quads",
        formCues: ["Pad on lower shin", "Extend fully and squeeze quads", "Lower with control, no slamming"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["hack-squat", "leg-press"]
    )
]

private let aashutoshLibrary = ExerciseLibrary(
    exercises: sharedExerciseLibrary.exercises.merging(
        Dictionary(uniqueKeysWithValues: aashutoshNewExercises.map { ($0.id, $0) }),
        uniquingKeysWith: { _, new in new }
    )
)

// MARK: - Sunday (Upper A — horizontal emphasis)

private let upperAWorkout = Workout(
    day: .sunday,
    title: "Upper A — Chest & Back",
    subtitle: "Hypertrophy",
    estimatedMinutes: 70,
    warmupNote: "5 min row machine + arm circles, band pull-aparts, scap push-ups, then 2 light feeder sets of bench.",
    blocks: [
        WorkoutBlock(
            label: "A — Bench Press",
            kind: .straight,
            prescribedSets: straightSets("bench-press", count: 4, reps: 6, weight: 40, rest: 120, block: "A"),
            notes: "Main strength lift. RPE 7-8 — add 2.5kg when all sets hit 6 clean reps."
        ),
        WorkoutBlock(
            label: "B — Barbell Row",
            kind: .straight,
            prescribedSets: straightSets("barbell-row", count: 4, reps: 8, weight: 40, rest: 90, block: "B"),
            notes: "Torso near parallel, no heaving."
        ),
        WorkoutBlock(
            label: "C — Incline DB Press",
            kind: .straight,
            prescribedSets: straightSets("incline-db-press", count: 3, reps: 10, rest: 90, block: "C"),
            notes: nil
        ),
        WorkoutBlock(
            label: "D — Lat Pulldown",
            kind: .straight,
            prescribedSets: straightSets("lat-pulldown", count: 3, reps: 10, rest: 75, block: "D"),
            notes: nil
        ),
        WorkoutBlock(
            label: "E — Lateral Raise / Face Pull",
            kind: .superset,
            prescribedSets: supersetSets(["lateral-raise", "face-pull"], rounds: 3, reps: 15, rest: 60, block: "E1/E2"),
            notes: "Light and strict — these build the 'look better' width."
        ),
        WorkoutBlock(
            label: "F — Curl / Pushdown",
            kind: .superset,
            prescribedSets: supersetSets(["db-curl", "tricep-pushdown"], rounds: 3, reps: 12, rest: 60, block: "F1/F2"),
            notes: nil
        ),
        WorkoutBlock(
            label: "Core",
            kind: .finisher,
            prescribedSets: straightSets("hanging-knee-raise", count: 3, reps: 10, rest: 45, block: "Core"),
            notes: nil
        )
    ],
    cooldownNote: "Stretch chest, lats, shoulders. Eat a solid meal within a couple of hours — you're bulking."
)

// MARK: - Monday (Lower A — squat emphasis)

private let lowerAWorkout = Workout(
    day: .monday,
    title: "Lower A — Squat Focus",
    subtitle: "Hypertrophy",
    estimatedMinutes: 65,
    warmupNote: "5 min easy bike + leg swings, hip openers, bodyweight squats, then 2 light feeder sets of squats.",
    blocks: [
        WorkoutBlock(
            label: "A — Back Squat",
            kind: .straight,
            prescribedSets: straightSets("back-squat", count: 4, reps: 6, weight: 50, rest: 150, block: "A"),
            notes: "Main strength lift. RPE 7-8 — add 2.5kg when all sets hit 6 clean reps."
        ),
        WorkoutBlock(
            label: "B — Romanian Deadlift",
            kind: .straight,
            prescribedSets: straightSets("rdl", count: 3, reps: 8, weight: 50, rest: 120, block: "B"),
            notes: "Feel the hamstrings load, keep the bar close."
        ),
        WorkoutBlock(
            label: "C — Leg Press",
            kind: .straight,
            prescribedSets: straightSets("leg-press", count: 3, reps: 10, rest: 90, block: "C"),
            notes: nil
        ),
        WorkoutBlock(
            label: "D — Seated Ham Curl",
            kind: .straight,
            prescribedSets: straightSets("ham-curl", count: 3, reps: 12, rest: 60, block: "D"),
            notes: nil
        ),
        WorkoutBlock(
            label: "E — Standing Calf Raise",
            kind: .straight,
            prescribedSets: straightSets("calf-raise", count: 4, reps: 12, rest: 45, block: "E"),
            notes: "Pause at the bottom stretch."
        ),
        WorkoutBlock(
            label: "Finisher",
            kind: .finisher,
            prescribedSets: [
                S("kb-swing", reps: 15, rest: 60, setLabel: "Set 1 of 3", block: "Finisher"),
                S("kb-swing", reps: 15, rest: 60, setLabel: "Set 2 of 3", block: "Finisher"),
                S("kb-swing", reps: 15, rest: 60, setLabel: "Set 3 of 3", block: "Finisher"),
                S("plank", duration: 45, rest: 30, setLabel: "Set 1 of 3", block: "Finisher"),
                S("plank", duration: 45, rest: 30, setLabel: "Set 2 of 3", block: "Finisher"),
                S("plank", duration: 45, rest: 0,  setLabel: "Set 3 of 3", block: "Finisher")
            ],
            notes: nil
        )
    ],
    cooldownNote: "5 min walk + stretch quads, hamstrings, hip flexors, calves."
)

// MARK: - Wednesday (Upper B — vertical / shoulder emphasis)

private let upperBWorkout = Workout(
    day: .wednesday,
    title: "Upper B — Shoulders & Pull",
    subtitle: "Hypertrophy",
    estimatedMinutes: 70,
    warmupNote: "5 min row machine + band pull-aparts, wall slides, then 2 light feeder sets of overhead press.",
    blocks: [
        WorkoutBlock(
            label: "A — Overhead Press",
            kind: .straight,
            prescribedSets: straightSets("ohp", count: 4, reps: 6, weight: 25, rest: 120, block: "A"),
            notes: "Squeeze glutes, don't lean back. Add 2.5kg when all sets hit 6."
        ),
        WorkoutBlock(
            label: "B — Pull-up",
            kind: .straight,
            prescribedSets: straightSets("pullup", count: 4, reps: 6, rest: 120, block: "B"),
            notes: "Use the assisted machine if you can't get 6 clean reps."
        ),
        WorkoutBlock(
            label: "C — Dumbbell Bench Press",
            kind: .straight,
            prescribedSets: straightSets("db-bench", count: 3, reps: 10, rest: 90, block: "C"),
            notes: nil
        ),
        WorkoutBlock(
            label: "D — Seated Cable Row",
            kind: .straight,
            prescribedSets: straightSets("cable-row", count: 3, reps: 10, rest: 75, block: "D"),
            notes: nil
        ),
        WorkoutBlock(
            label: "E — Lateral Raise / Face Pull",
            kind: .superset,
            prescribedSets: supersetSets(["lateral-raise", "face-pull"], rounds: 3, reps: 15, rest: 60, block: "E1/E2"),
            notes: "Second weekly hit for delts and rear delts."
        ),
        WorkoutBlock(
            label: "F — Cable Curl / Overhead Extension",
            kind: .superset,
            prescribedSets: supersetSets(["cable-curl", "overhead-tri-extension"], rounds: 3, reps: 12, rest: 60, block: "F1/F2"),
            notes: nil
        ),
        WorkoutBlock(
            label: "Core",
            kind: .finisher,
            prescribedSets: straightSets("lying-leg-raise", count: 3, reps: 12, rest: 45, block: "Core"),
            notes: nil
        )
    ],
    cooldownNote: "Stretch lats, chest, forearms."
)

// MARK: - Thursday (Lower B — hinge emphasis + conditioning)

private let lowerBWorkout = Workout(
    day: .thursday,
    title: "Lower B — Hinge & Conditioning",
    subtitle: "Hypertrophy + intervals",
    estimatedMinutes: 65,
    warmupNote: "5 min incline treadmill walk + hip hinges with a dowel, glute bridges 2×12, then 2 light feeder sets of RDL.",
    blocks: [
        WorkoutBlock(
            label: "A — Romanian Deadlift (heavy)",
            kind: .straight,
            prescribedSets: straightSets("rdl", count: 4, reps: 6, weight: 55, rest: 150, block: "A"),
            notes: "Heavier than Monday's RDL — RPE 7-8."
        ),
        WorkoutBlock(
            label: "B — Hack Squat",
            kind: .straight,
            prescribedSets: straightSets("hack-squat", count: 3, reps: 8, rest: 120, block: "B"),
            notes: nil
        ),
        WorkoutBlock(
            label: "C — Bulgarian Split Squat",
            kind: .straight,
            prescribedSets: straightSets("bulgarian-split-squat", count: 3, reps: 10, perSide: true, rest: 90, block: "C"),
            notes: "10/leg."
        ),
        WorkoutBlock(
            label: "D — Leg Extension / Lying Ham Curl",
            kind: .superset,
            prescribedSets: supersetSets(["leg-extension", "lying-ham-curl"], rounds: 3, reps: 12, rest: 60, block: "D1/D2"),
            notes: nil
        ),
        WorkoutBlock(
            label: "E — Seated Calf Raise",
            kind: .straight,
            prescribedSets: straightSets("seated-calf-raise", count: 4, reps: 15, rest: 45, block: "E"),
            notes: nil
        ),
        WorkoutBlock(
            label: "Bike intervals (6 rounds)",
            kind: .interval,
            prescribedSets: (1...6).map { round in
                S("bike-sprint", duration: 20, rest: round == 6 ? 0 : 70,
                  setLabel: "Round \(round) of 6", block: "Intervals",
                  notes: "Easy spin during the rest")
            },
            notes: "Sprint at RPE 8 — conditioning without eating into recovery."
        )
    ],
    cooldownNote: "5 min easy spin + full-body stretch. Hit your calorie surplus today."
)

// MARK: - Plan registry

extension WorkoutPlan {
    static let aashutosh = WorkoutPlan(
        id: "aashutosh",
        name: "Aashutosh",
        workouts: [
            .sunday:    upperAWorkout,
            .monday:    lowerAWorkout,
            .wednesday: upperBWorkout,
            .thursday:  lowerBWorkout
            // Tuesday, Friday & Saturday are rest / active recovery
        ],
        library: aashutoshLibrary
    )

    /// All selectable plans, in display order.
    static let allPlans: [WorkoutPlan] = [.varsha, .aashutosh]

    static func plan(withId id: String) -> WorkoutPlan {
        allPlans.first { $0.id == id } ?? .varsha
    }
}
