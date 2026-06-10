//
//  WorkoutData.swift
//  Varsha
//
//  Static data for the PCOS-tailored workout plan.
//  In production: move to a remote JSON / SwiftData store you can update OTA.
//

import Foundation

// MARK: - Helper builder

private func S(
    _ exId: String,
    reps: Int? = nil,
    duration: Int? = nil,
    weight: Double? = nil,
    perSide: Bool = false,
    rest: Int = 60,
    setLabel: String = "",
    block: String = "",
    notes: String? = nil
) -> PrescribedSet {
    PrescribedSet(
        exerciseId: exId, reps: reps, durationSeconds: duration,
        suggestedWeightKg: weight, perSide: perSide, restAfterSeconds: rest,
        setNumberLabel: setLabel, blockLabel: block, notes: notes
    )
}

/// Builds N sets of an exercise with auto-numbered labels (e.g. "Set 1 of 4").
private func straightSets(
    _ exId: String, count: Int, reps: Int? = nil, duration: Int? = nil,
    weight: Double? = nil, perSide: Bool = false, rest: Int = 60, block: String
) -> [PrescribedSet] {
    (1...count).map { i in
        S(exId, reps: reps, duration: duration, weight: weight, perSide: perSide,
          rest: i == count ? 90 : rest,    // longer rest after final set before moving on
          setLabel: "Set \(i) of \(count)", block: block)
    }
}

/// Builds a superset by interleaving exercises across rounds.
/// e.g. supersetSets(["bench", "row"], rounds: 4, ...) -> bench/row/bench/row/bench/row/bench/row
private func supersetSets(
    _ exIds: [String], rounds: Int, reps: Int, rest: Int = 60, block: String
) -> [PrescribedSet] {
    var out: [PrescribedSet] = []
    for round in 1...rounds {
        for (idx, exId) in exIds.enumerated() {
            let isLastInRound = (idx == exIds.count - 1)
            out.append(S(
                exId, reps: reps,
                rest: isLastInRound ? rest : 30,   // short between paired exercises, full between rounds
                setLabel: "Round \(round) of \(rounds)",
                block: block
            ))
        }
    }
    return out
}

// MARK: - Exercise Library

private let exerciseLibrary = ExerciseLibrary(exercises: Dictionary(uniqueKeysWithValues: [
    Exercise(
        id: "back-squat", name: "Barbell Back Squat", primaryMuscle: "Quads / Glutes",
        formCues: [
            "Brace core before each rep",
            "Knees track over toes",
            "Hip crease below knee at depth",
            "Drive through mid-foot"
        ],
        videoURLString: nil,
        staticImageName: nil,
        alternativeIds: ["goblet-squat", "leg-press", "hack-squat"]
    ),
    Exercise(
        id: "goblet-squat", name: "Goblet Squat", primaryMuscle: "Quads / Glutes",
        formCues: ["Hold dumbbell at chest", "Elbows inside knees at bottom", "Chest tall"],
        videoURLString: nil,
        staticImageName: nil,
        alternativeIds: ["back-squat", "leg-press"]
    ),
    Exercise(
        id: "leg-press", name: "Leg Press", primaryMuscle: "Quads / Glutes",
        formCues: ["Feet shoulder-width on platform", "Lower until thighs ~90°", "Don't lock knees at top"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["back-squat", "goblet-squat"]
    ),
    Exercise(
        id: "hack-squat", name: "Hack Squat", primaryMuscle: "Quads",
        formCues: ["Back flat against pad", "Feet shoulder-width", "Controlled descent"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["back-squat", "leg-press"]
    ),
    Exercise(
        id: "rdl", name: "Romanian Deadlift", primaryMuscle: "Hamstrings / Glutes",
        formCues: [
            "Hinge at hips, slight knee bend",
            "Bar stays close to legs",
            "Stop when you feel hamstring stretch",
            "Drive hips forward to stand"
        ],
        videoURLString: nil,
        staticImageName: nil,
        alternativeIds: ["db-rdl", "cable-pull-through"]
    ),
    Exercise(
        id: "db-rdl", name: "Dumbbell RDL", primaryMuscle: "Hamstrings / Glutes",
        formCues: ["DBs in front of thighs", "Hinge, don't squat", "Soft knees"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["rdl", "cable-pull-through"]
    ),
    Exercise(
        id: "cable-pull-through", name: "Cable Pull-through", primaryMuscle: "Glutes / Hamstrings",
        formCues: ["Hinge at hips", "Squeeze glutes at top", "Don't overextend lower back"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["rdl", "kb-swing"]
    ),
    Exercise(
        id: "bulgarian-split-squat", name: "Bulgarian Split Squat", primaryMuscle: "Quads / Glutes",
        formCues: [
            "Front foot far enough that front shin stays vertical",
            "Lower straight down, not forward",
            "Front heel stays planted"
        ],
        videoURLString: nil,
        staticImageName: nil,
        alternativeIds: ["reverse-lunge", "step-up"]
    ),
    Exercise(
        id: "reverse-lunge", name: "Reverse Lunge", primaryMuscle: "Quads / Glutes",
        formCues: ["Step back, drop straight down", "Front knee 90°", "Drive through front heel"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["bulgarian-split-squat", "walking-lunge"]
    ),
    Exercise(
        id: "walking-lunge", name: "Walking Lunge", primaryMuscle: "Quads / Glutes",
        formCues: ["Long stride", "Knee tracks over toe, doesn't pass it", "Torso upright"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["reverse-lunge", "step-up"]
    ),
    Exercise(
        id: "step-up", name: "Step-up", primaryMuscle: "Quads / Glutes",
        formCues: ["Whole foot on box", "Drive through heel", "Don't push off back foot"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["reverse-lunge"]
    ),
    Exercise(
        id: "ham-curl", name: "Seated Hamstring Curl", primaryMuscle: "Hamstrings",
        formCues: ["Pad just above ankles", "Full ROM", "Squeeze at bottom"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["lying-ham-curl", "nordic-curl"]
    ),
    Exercise(
        id: "lying-ham-curl", name: "Lying Hamstring Curl", primaryMuscle: "Hamstrings",
        formCues: ["Hips stay on pad", "Controlled tempo"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["ham-curl", "nordic-curl"]
    ),
    Exercise(
        id: "nordic-curl", name: "Nordic Curl", primaryMuscle: "Hamstrings",
        formCues: ["Anchor feet", "Lower under control", "Use hands to push back up"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["ham-curl"]
    ),
    Exercise(
        id: "hip-thrust", name: "Barbell Hip Thrust", primaryMuscle: "Glutes",
        formCues: [
            "Shoulder blades on bench",
            "Chin tucked, ribs down",
            "Drive through heels, not toes",
            "Squeeze glutes hard at top"
        ],
        videoURLString: nil,
        staticImageName: nil,
        alternativeIds: ["glute-bridge", "single-leg-hip-thrust"]
    ),
    Exercise(
        id: "glute-bridge", name: "Glute Bridge", primaryMuscle: "Glutes",
        formCues: ["Feet flat", "Drive hips up, squeeze glutes", "Don't arch lower back"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["hip-thrust"]
    ),
    Exercise(
        id: "single-leg-hip-thrust", name: "Single-Leg Hip Thrust", primaryMuscle: "Glutes",
        formCues: ["One foot up", "Drive through planted heel", "Stay level"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["hip-thrust"]
    ),
    Exercise(
        id: "calf-raise", name: "Standing Calf Raise", primaryMuscle: "Calves",
        formCues: ["Full stretch at bottom", "Pause at top", "Slow eccentric"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["seated-calf-raise"]
    ),
    Exercise(
        id: "seated-calf-raise", name: "Seated Calf Raise", primaryMuscle: "Calves",
        formCues: ["Knees bent 90°", "Full ROM"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["calf-raise"]
    ),
    Exercise(
        id: "dead-bug", name: "Dead Bug", primaryMuscle: "Core",
        formCues: ["Lower back glued to floor", "Opposite arm/leg extend", "Slow + controlled"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["bird-dog"]
    ),
    Exercise(
        id: "side-plank", name: "Side Plank", primaryMuscle: "Obliques / Core",
        formCues: ["Stack hips and shoulders", "Push the floor away", "Don't sag"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["plank"]
    ),
    Exercise(
        id: "plank", name: "Plank", primaryMuscle: "Core",
        formCues: ["Squeeze glutes", "Ribs down", "Neutral neck"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["side-plank"]
    ),
    Exercise(
        id: "pallof-press", name: "Pallof Press", primaryMuscle: "Core / Anti-rotation",
        formCues: ["Cable at chest height", "Press straight out", "Resist rotation"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["banded-rotation"]
    ),
    Exercise(
        id: "hanging-knee-raise", name: "Hanging Knee Raise", primaryMuscle: "Core",
        formCues: ["No swinging", "Curl pelvis up, don't just lift legs", "Slow descent"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["lying-leg-raise"]
    ),
    Exercise(
        id: "lying-leg-raise", name: "Lying Leg Raise", primaryMuscle: "Core",
        formCues: ["Lower back pressed down", "Don't let feet touch the floor"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["hanging-knee-raise"]
    ),
    Exercise(
        id: "curtsy-lunge", name: "Curtsy Lunge", primaryMuscle: "Glutes / Adductors",
        formCues: ["Step behind and across", "Drop straight down", "Front foot stays planted"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["lateral-lunge"]
    ),
    Exercise(
        id: "lateral-lunge", name: "Lateral Lunge", primaryMuscle: "Glutes / Adductors",
        formCues: ["Sit into the working leg", "Keep other leg straight", "Chest up"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["curtsy-lunge"]
    ),
    Exercise(
        id: "glute-kickback", name: "Cable Glute Kickback", primaryMuscle: "Glutes",
        formCues: ["Cable on ankle", "Drive heel back, squeeze glute", "Don't arch low back"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["banded-kickback"]
    ),
    Exercise(
        id: "banded-kickback", name: "Banded Donkey Kick", primaryMuscle: "Glutes",
        formCues: ["On all fours", "Drive heel toward ceiling", "Slow + controlled"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["glute-kickback"]
    ),
    Exercise(
        id: "kb-swing", name: "Kettlebell Swing", primaryMuscle: "Posterior Chain",
        formCues: ["Hinge, don't squat", "Power from hips", "Bell to chest height (Russian)"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["cable-pull-through"]
    ),
    // Upper body
    Exercise(
        id: "bench-press", name: "Barbell Bench Press", primaryMuscle: "Chest / Triceps",
        formCues: ["Shoulder blades retracted, down", "Bar to lower chest", "Drive feet into floor"],
        videoURLString: nil,
        staticImageName: nil,
        alternativeIds: ["db-bench", "machine-press"]
    ),
    Exercise(
        id: "db-bench", name: "Dumbbell Bench Press", primaryMuscle: "Chest / Triceps",
        formCues: ["Slight arch", "DBs press in slight arc", "Don't clang"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["bench-press", "machine-press"]
    ),
    Exercise(
        id: "machine-press", name: "Machine Chest Press", primaryMuscle: "Chest",
        formCues: ["Adjust seat so handles align with chest", "Don't shrug"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["bench-press", "db-bench"]
    ),
    Exercise(
        id: "barbell-row", name: "Bent-over Barbell Row", primaryMuscle: "Back",
        formCues: ["Hinge ~45°", "Pull to lower ribs", "Squeeze shoulder blades"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["chest-supported-row", "cable-row"]
    ),
    Exercise(
        id: "chest-supported-row", name: "Chest-supported DB Row", primaryMuscle: "Back",
        formCues: ["Chest stays on pad", "Lead with elbows", "Squeeze at top"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["barbell-row", "cable-row"]
    ),
    Exercise(
        id: "cable-row", name: "Seated Cable Row", primaryMuscle: "Back",
        formCues: ["Tall chest", "Pull to lower abs", "Don't lean back excessively"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["barbell-row", "chest-supported-row"]
    ),
    Exercise(
        id: "ohp", name: "Overhead Press", primaryMuscle: "Shoulders / Triceps",
        formCues: ["Brace core, glutes tight", "Bar over mid-foot at lockout", "Don't flare ribs"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["db-shoulder-press", "machine-shoulder-press"]
    ),
    Exercise(
        id: "db-shoulder-press", name: "DB Shoulder Press", primaryMuscle: "Shoulders",
        formCues: ["Seated with back support", "DBs press up and slightly in"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["ohp", "machine-shoulder-press"]
    ),
    Exercise(
        id: "machine-shoulder-press", name: "Machine Shoulder Press", primaryMuscle: "Shoulders",
        formCues: ["Adjust seat so handles at shoulder", "Smooth tempo"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["ohp", "db-shoulder-press"]
    ),
    Exercise(
        id: "lat-pulldown", name: "Lat Pulldown", primaryMuscle: "Back / Lats",
        formCues: ["Slight lean back", "Pull to upper chest", "Lead with elbows down"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["assisted-pullup"]
    ),
    Exercise(
        id: "assisted-pullup", name: "Assisted Pull-up", primaryMuscle: "Back / Lats",
        formCues: ["Full hang at bottom", "Chin over bar", "Don't kip"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["lat-pulldown"]
    ),
    Exercise(
        id: "db-curl", name: "DB Bicep Curl", primaryMuscle: "Biceps",
        formCues: ["Elbows pinned to sides", "Don't swing", "Full range of motion"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["cable-curl"]
    ),
    Exercise(
        id: "cable-curl", name: "Cable Curl", primaryMuscle: "Biceps",
        formCues: ["Constant tension", "Slow eccentric"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["db-curl"]
    ),
    Exercise(
        id: "tricep-pushdown", name: "Tricep Rope Pushdown", primaryMuscle: "Triceps",
        formCues: ["Elbows pinned", "Pull rope apart at bottom", "Don't lean over"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["overhead-tri-extension"]
    ),
    Exercise(
        id: "overhead-tri-extension", name: "Overhead Tricep Extension", primaryMuscle: "Triceps",
        formCues: ["Elbows close to head", "Stretch at bottom"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["tricep-pushdown"]
    ),
    // Calisthenics / circuit
    Exercise(
        id: "pushup", name: "Push-up", primaryMuscle: "Chest / Triceps",
        formCues: ["Body straight, glutes tight", "Elbows ~45° from body", "Full ROM"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["incline-pushup", "knee-pushup"]
    ),
    Exercise(
        id: "incline-pushup", name: "Incline Push-up", primaryMuscle: "Chest",
        formCues: ["Hands on bench", "Body straight"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["pushup", "knee-pushup"]
    ),
    Exercise(
        id: "knee-pushup", name: "Knee Push-up", primaryMuscle: "Chest",
        formCues: ["Knees + hands on floor", "Body straight from knees to head"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["incline-pushup", "pushup"]
    ),
    Exercise(
        id: "inverted-row", name: "Inverted Row", primaryMuscle: "Back",
        formCues: ["Body straight", "Pull chest to bar", "Squeeze shoulder blades"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["chest-supported-row"]
    ),
    Exercise(
        id: "plank-to-pushup", name: "Plank to Push-up", primaryMuscle: "Core / Chest",
        formCues: ["Minimize hip rotation", "Switch lead arm each round"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["plank"]
    ),
    Exercise(
        id: "bench-dip", name: "Bench Dip", primaryMuscle: "Triceps",
        formCues: ["Hands on bench", "Lower until elbows ~90°", "Don't shrug"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["tricep-pushdown"]
    ),
    Exercise(
        id: "hollow-hold", name: "Hollow Body Hold", primaryMuscle: "Core",
        formCues: ["Lower back glued to floor", "Arms by ears", "Legs locked"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["dead-bug"]
    ),
    Exercise(
        id: "russian-twist", name: "Russian Twist", primaryMuscle: "Obliques",
        formCues: ["Feet up if possible", "Rotate from torso, not arms"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["pallof-press"]
    ),
    // HIIT
    Exercise(
        id: "treadmill-sprint", name: "Treadmill Sprint", primaryMuscle: "Cardio",
        formCues: ["RPE 8-9 — hard but sustainable for 30s", "Mid-foot strike", "Arms drive"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["bike-sprint"]
    ),
    Exercise(
        id: "treadmill-walk", name: "Treadmill Walk Recovery", primaryMuscle: "Cardio",
        formCues: ["Easy pace", "Recover breathing"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: []
    ),
    Exercise(
        id: "bike-sprint", name: "Bike Sprint", primaryMuscle: "Cardio",
        formCues: ["RPE 8-9", "Resistance high enough you can't spin out"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: ["treadmill-sprint"]
    ),
    Exercise(
        id: "farmer-carry", name: "Farmer's Carry", primaryMuscle: "Grip / Core / Posterior",
        formCues: ["Stand tall, shoulders back", "Walk with purpose", "Don't lean to one side"],
        videoURLString: nil, staticImageName: nil,
        alternativeIds: []
    ),
].map { ($0.id, $0) }))

// MARK: - The PCOS Plan — Sunday (Lower Body, Self-led)

private let sundayWorkout = Workout(
    day: .sunday,
    title: "Lower Body Strength",
    subtitle: "Self-led",
    estimatedMinutes: 60,
    warmupNote: "5 min easy bike + dynamic mobility (leg swings, hip openers, world's greatest stretch).",
    blocks: [
        WorkoutBlock(
            label: "A — Squat / RDL Superset",
            kind: .superset,
            prescribedSets: supersetSets(["back-squat", "rdl"], rounds: 4, reps: 8, rest: 90, block: "A1/A2"),
            notes: "Compound focus. Build to a working weight at RPE 7-8."
        ),
        WorkoutBlock(
            label: "B — Bulgarian / Ham Curl Superset",
            kind: .superset,
            prescribedSets: supersetSets(["bulgarian-split-squat", "ham-curl"], rounds: 3, reps: 10, rest: 75, block: "B1/B2"),
            notes: "10/leg for the split squat."
        ),
        WorkoutBlock(
            label: "C — Hip Thrust",
            kind: .straight,
            prescribedSets: straightSets("hip-thrust", count: 3, reps: 10, rest: 75, block: "C"),
            notes: nil
        ),
        WorkoutBlock(
            label: "D — Calf Raise",
            kind: .straight,
            prescribedSets: straightSets("calf-raise", count: 3, reps: 15, rest: 45, block: "D"),
            notes: nil
        ),
        WorkoutBlock(
            label: "Core Finisher",
            kind: .finisher,
            prescribedSets: [
                S("dead-bug", reps: 10, rest: 30, setLabel: "Set 1 of 3", block: "Core"),
                S("side-plank", duration: 30, perSide: true, rest: 30, setLabel: "Set 1 of 3", block: "Core"),
                S("dead-bug", reps: 10, rest: 30, setLabel: "Set 2 of 3", block: "Core"),
                S("side-plank", duration: 30, perSide: true, rest: 30, setLabel: "Set 2 of 3", block: "Core"),
                S("dead-bug", reps: 10, rest: 30, setLabel: "Set 3 of 3", block: "Core"),
                S("side-plank", duration: 30, perSide: true, rest: 0,  setLabel: "Set 3 of 3", block: "Core")
            ],
            notes: nil
        )
    ],
    cooldownNote: "5 min walk + stretch quads, hams, hip flexors, calves."
)

// MARK: - Monday (Glutes & Core)

private let mondayWorkout = Workout(
    day: .monday,
    title: "Glutes & Core",
    subtitle: "Self-led",
    estimatedMinutes: 55,
    warmupNote: "Glute activation: banded clamshells 2×15/side, banded glute bridge 2×15, lateral walks 2×10/side.",
    blocks: [
        WorkoutBlock(
            label: "A — Hip Thrust",
            kind: .straight,
            prescribedSets: straightSets("hip-thrust", count: 4, reps: 10, rest: 90, block: "A"),
            notes: nil
        ),
        WorkoutBlock(
            label: "B — Cable Pull-through",
            kind: .straight,
            prescribedSets: straightSets("cable-pull-through", count: 3, reps: 12, rest: 60, block: "B"),
            notes: nil
        ),
        WorkoutBlock(
            label: "C — Walking Lunge / Glute Kickback",
            kind: .superset,
            prescribedSets: supersetSets(["walking-lunge", "glute-kickback"], rounds: 3, reps: 10, rest: 75, block: "C1/C2"),
            notes: "10/leg both."
        ),
        WorkoutBlock(
            label: "D — Curtsy Lunge",
            kind: .straight,
            prescribedSets: straightSets("curtsy-lunge", count: 3, reps: 10, perSide: true, rest: 60, block: "D"),
            notes: nil
        ),
        WorkoutBlock(
            label: "Core Circuit (3 rounds)",
            kind: .circuit,
            prescribedSets: (1...3).flatMap { round in
                [
                    S("dead-bug", reps: 12, rest: 0, setLabel: "Round \(round) of 3", block: "Core Circuit"),
                    S("pallof-press", reps: 10, perSide: true, rest: 0, setLabel: "Round \(round) of 3", block: "Core Circuit"),
                    S("hanging-knee-raise", reps: 10, rest: 0, setLabel: "Round \(round) of 3", block: "Core Circuit"),
                    S("side-plank", duration: 30, perSide: true, rest: round == 3 ? 0 : 60, setLabel: "Round \(round) of 3", block: "Core Circuit")
                ]
            },
            notes: nil
        )
    ],
    cooldownNote: "Stretch hip flexors, glutes, hamstrings."
)

// MARK: - Tuesday (Upper Body)

private let tuesdayWorkout = Workout(
    day: .tuesday,
    title: "Upper Body / Lifting Technique",
    subtitle: "Self-led",
    estimatedMinutes: 60,
    warmupNote: "5 min row machine + arm circles, scap pulls, band pull-aparts.",
    blocks: [
        WorkoutBlock(
            label: "A — Bench / Row Superset",
            kind: .superset,
            prescribedSets: supersetSets(["bench-press", "barbell-row"], rounds: 4, reps: 8, rest: 90, block: "A1/A2"),
            notes: "Heavy compound work. Form > weight."
        ),
        WorkoutBlock(
            label: "B — OHP / Lat Pulldown Superset",
            kind: .superset,
            prescribedSets: supersetSets(["ohp", "lat-pulldown"], rounds: 3, reps: 10, rest: 75, block: "B1/B2"),
            notes: nil
        ),
        WorkoutBlock(
            label: "C — Curl / Pushdown Superset",
            kind: .superset,
            prescribedSets: supersetSets(["db-curl", "tricep-pushdown"], rounds: 3, reps: 12, rest: 60, block: "C1/C2"),
            notes: nil
        ),
        WorkoutBlock(
            label: "Core",
            kind: .finisher,
            prescribedSets: straightSets("hanging-knee-raise", count: 3, reps: 10, rest: 45, block: "Core"),
            notes: nil
        )
    ],
    cooldownNote: "Stretch chest, lats, shoulders."
)

// MARK: - Wednesday (Full Body Calisthenics)

private let wednesdayWorkout = Workout(
    day: .wednesday,
    title: "Full Body Conditioning",
    subtitle: "Calisthenics-style",
    estimatedMinutes: 50,
    warmupNote: "5 min easy cardio + dynamic mobility.",
    blocks: [
        WorkoutBlock(
            label: "Circuit A (4 rounds, 40s work / 20s rest)",
            kind: .circuit,
            prescribedSets: (1...4).flatMap { round in
                [
                    S("goblet-squat", duration: 40, rest: 20, setLabel: "Round \(round) of 4", block: "Circuit A"),
                    S("pushup", duration: 40, rest: 20, setLabel: "Round \(round) of 4", block: "Circuit A"),
                    S("inverted-row", duration: 40, rest: 20, setLabel: "Round \(round) of 4", block: "Circuit A"),
                    S("reverse-lunge", duration: 40, rest: 20, setLabel: "Round \(round) of 4", block: "Circuit A"),
                    S("plank-to-pushup", duration: 40, rest: round == 4 ? 90 : 60, setLabel: "Round \(round) of 4", block: "Circuit A")
                ]
            },
            notes: nil
        ),
        WorkoutBlock(
            label: "Strength finishers",
            kind: .straight,
            prescribedSets: straightSets("assisted-pullup", count: 3, reps: 6, rest: 60, block: "Strength")
                + straightSets("bench-dip", count: 3, reps: 10, rest: 60, block: "Strength"),
            notes: nil
        ),
        WorkoutBlock(
            label: "Core",
            kind: .finisher,
            prescribedSets: [
                S("hollow-hold", duration: 20, rest: 40, setLabel: "Set 1 of 3", block: "Core"),
                S("hollow-hold", duration: 20, rest: 40, setLabel: "Set 2 of 3", block: "Core"),
                S("hollow-hold", duration: 20, rest: 60, setLabel: "Set 3 of 3", block: "Core"),
                S("russian-twist", reps: 20, rest: 30, setLabel: "Set 1 of 3", block: "Core"),
                S("russian-twist", reps: 20, rest: 30, setLabel: "Set 2 of 3", block: "Core"),
                S("russian-twist", reps: 20, rest: 0,  setLabel: "Set 3 of 3", block: "Core")
            ],
            notes: nil
        )
    ],
    cooldownNote: "Full-body stretch, foam roll quads + IT band."
)

// MARK: - Thursday (HIIT)

private let thursdayWorkout = Workout(
    day: .thursday,
    title: "HIIT + Conditioning",
    subtitle: "Treadmill intervals + finishers",
    estimatedMinutes: 40,
    warmupNote: "5 min easy walk warm-up before sprints.",
    blocks: [
        WorkoutBlock(
            label: "Treadmill intervals (8 rounds)",
            kind: .interval,
            prescribedSets: (1...8).flatMap { round -> [PrescribedSet] in
                [
                    S("treadmill-sprint", duration: 30, rest: 0, setLabel: "Round \(round) of 8", block: "HIIT"),
                    S("treadmill-walk", duration: 90, rest: 0, setLabel: "Round \(round) of 8", block: "HIIT")
                ]
            },
            notes: "Sprint at RPE 8-9 (hard but controlled). Walk fully easy."
        ),
        WorkoutBlock(
            label: "Finishers",
            kind: .finisher,
            prescribedSets: [
                S("farmer-carry", duration: 45, rest: 60, setLabel: "Set 1 of 3", block: "Finisher", notes: "30m carry"),
                S("farmer-carry", duration: 45, rest: 60, setLabel: "Set 2 of 3", block: "Finisher", notes: "30m carry"),
                S("farmer-carry", duration: 45, rest: 60, setLabel: "Set 3 of 3", block: "Finisher", notes: "30m carry"),
                S("plank", duration: 45, rest: 30, setLabel: "Set 1 of 3", block: "Finisher"),
                S("plank", duration: 45, rest: 30, setLabel: "Set 2 of 3", block: "Finisher"),
                S("plank", duration: 45, rest: 30, setLabel: "Set 3 of 3", block: "Finisher"),
                S("hollow-hold", reps: 20, rest: 0, setLabel: "Hollow rocks", block: "Finisher")
            ],
            notes: nil
        )
    ],
    cooldownNote: "5 min walk + full-body stretch. Hydrate."
)

// MARK: - Plan registry

extension WorkoutPlan {
    static let varsha = WorkoutPlan(
        id: "varsha",
        name: "Varsha",
        workouts: [
            .sunday:    sundayWorkout,
            .monday:    mondayWorkout,
            .tuesday:   tuesdayWorkout,
            .wednesday: wednesdayWorkout,
            .thursday:  thursdayWorkout
            // Friday & Saturday are rest / active recovery — no structured session
        ],
        library: exerciseLibrary
    )
}
