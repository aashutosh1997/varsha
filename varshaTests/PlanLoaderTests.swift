//
//  PlanLoaderTests.swift
//  varshaTests
//
//  Pins the exact expansion output of the compact plan JSON so that edits to
//  the JSON or the PlanLoader expansion logic fail loudly. The expected
//  numbers were captured from the original Swift-defined plans before the
//  JSON migration.
//

import Foundation
import Testing
@testable import varsha

@MainActor
struct PlanLoaderTests {

    // MARK: - Registry

    @Test func registryContainsBothPlans() {
        #expect(WorkoutPlan.allPlans.map(\.id) == ["varsha", "aashutosh"])
        #expect(WorkoutPlan.allPlans.map(\.name) == ["Varsha", "Aashutosh"])
    }

    @Test func planLookupFallsBackToVarsha() {
        #expect(WorkoutPlan.plan(withId: "aashutosh").id == "aashutosh")
        #expect(WorkoutPlan.plan(withId: "nope").id == "varsha")
    }

    @Test func plansAreDecodedOnce() {
        // Static lets must cache the decoded plan; re-decoding would
        // regenerate the PrescribedSet UUIDs that session logs key on.
        let first = WorkoutPlan.varsha.workouts[.sunday]!.setSequence.map(\.id)
        let second = WorkoutPlan.varsha.workouts[.sunday]!.setSequence.map(\.id)
        #expect(first == second)
    }

    // MARK: - Library

    @Test func libraryHasAllExercises() {
        #expect(WorkoutPlan.varsha.library.exercises.count == 62)
        #expect(WorkoutPlan.aashutosh.library.exercises.count == 62)
    }

    @Test func everyPrescribedExerciseResolves() {
        for plan in WorkoutPlan.allPlans {
            for workout in plan.workouts.values {
                for set in workout.setSequence {
                    #expect(plan.library.exercise(for: set.exerciseId) != nil,
                            "\(plan.id)/\(workout.title) references unknown '\(set.exerciseId)'")
                }
            }
        }
    }

    @Test func onlyKnownDanglingAlternativesExist() {
        // Two alternative ids reference exercises that were never added to the
        // library (carried over verbatim from the original Swift data).
        let library = WorkoutPlan.varsha.library
        let dangling = Set(library.exercises.values.flatMap(\.alternativeIds)
            .filter { library.exercise(for: $0) == nil })
        #expect(dangling == ["banded-rotation", "bird-dog"])
    }

    // MARK: - Plan shape

    @Test func workoutDaysMatch() {
        #expect(Set(WorkoutPlan.varsha.workouts.keys) ==
                [.sunday, .monday, .tuesday, .wednesday, .thursday])
        #expect(Set(WorkoutPlan.aashutosh.workouts.keys) ==
                [.sunday, .monday, .wednesday, .thursday])
    }

    @Test(arguments: [
        ("varsha", Weekday.sunday, 26, 5),
        ("varsha", Weekday.monday, 28, 5),
        ("varsha", Weekday.tuesday, 23, 4),
        ("varsha", Weekday.wednesday, 32, 3),
        ("varsha", Weekday.thursday, 23, 2),
        ("aashutosh", Weekday.sunday, 29, 7),
        ("aashutosh", Weekday.monday, 23, 6),
        ("aashutosh", Weekday.wednesday, 29, 7),
        ("aashutosh", Weekday.thursday, 26, 6),
    ])
    func setAndBlockCounts(planId: String, day: Weekday, sets: Int, blocks: Int) {
        let workout = WorkoutPlan.plan(withId: planId).workouts[day]!
        #expect(workout.setSequence.count == sets)
        #expect(workout.blocks.count == blocks)
    }

    @Test func metadataSpotChecks() {
        let varshaSunday = WorkoutPlan.varsha.workouts[.sunday]!
        #expect(varshaSunday.title == "Lower Body Strength")
        #expect(varshaSunday.estimatedMinutes == 60)
        #expect(!varshaSunday.warmupNote.isEmpty)
        #expect(!varshaSunday.cooldownNote.isEmpty)
        #expect(WorkoutPlan.aashutosh.workouts[.thursday]!.title == "Lower B — Hinge & Conditioning")
    }

    // MARK: - Expansion conventions

    @Test func supersetInterleavesWithPairRest() {
        let block = WorkoutPlan.varsha.workouts[.tuesday]!.blocks[0]
        let sets = block.prescribedSets
        #expect(sets.map(\.exerciseId) ==
                ["bench-press", "barbell-row", "bench-press", "barbell-row",
                 "bench-press", "barbell-row", "bench-press", "barbell-row"])
        #expect(sets.map(\.restAfterSeconds) == [30, 90, 30, 90, 30, 90, 30, 90])
        #expect(sets.map(\.setNumberLabel) ==
                ["Round 1 of 4", "Round 1 of 4", "Round 2 of 4", "Round 2 of 4",
                 "Round 3 of 4", "Round 3 of 4", "Round 4 of 4", "Round 4 of 4"])
        #expect(sets.allSatisfy { $0.blockLabel == "A1/A2" })
    }

    @Test func straightSetsAlwaysRest90AfterFinalSet() {
        // Final-set rest is 90 even when the base rest is higher...
        let bench = WorkoutPlan.aashutosh.workouts[.sunday]!.blocks[0].prescribedSets
        #expect(bench.map(\.restAfterSeconds) == [120, 120, 120, 90])
        #expect(bench.map(\.suggestedWeightKg) == [40, 40, 40, 40])
        #expect(bench.map(\.setNumberLabel) == (1...4).map { "Set \($0) of 4" })
        // ...or lower.
        let calf = WorkoutPlan.varsha.workouts[.sunday]!.blocks[3].prescribedSets
        #expect(calf.map(\.restAfterSeconds) == [45, 45, 90])
    }

    @Test func circuitAppliesFinalRoundRest() {
        // Last round drops the side-plank rest to 0.
        let core = WorkoutPlan.varsha.workouts[.monday]!.blocks[4].prescribedSets
        #expect(core.count == 12)
        let sidePlanks = core.filter { $0.exerciseId == "side-plank" }
        #expect(sidePlanks.allSatisfy { $0.durationSeconds == 30 && $0.perSide })
        #expect(sidePlanks.map(\.restAfterSeconds) == [60, 60, 0])
        #expect(core.filter { $0.exerciseId == "dead-bug" }.allSatisfy { $0.restAfterSeconds == 0 })

        // Last round can also raise the rest (90 after the final circuit lap).
        let circuitA = WorkoutPlan.varsha.workouts[.wednesday]!.blocks[0].prescribedSets
        #expect(circuitA.count == 20)
        #expect(circuitA.allSatisfy { $0.durationSeconds == 40 })
        #expect(circuitA.filter { $0.exerciseId == "plank-to-pushup" }.map(\.restAfterSeconds) == [60, 60, 60, 90])
        #expect(circuitA.filter { $0.exerciseId != "plank-to-pushup" }.allSatisfy { $0.restAfterSeconds == 20 })
    }

    @Test func roundsCanUseSetLabels() {
        let finisher = WorkoutPlan.varsha.workouts[.sunday]!.blocks[4].prescribedSets
        #expect(finisher.map(\.exerciseId) ==
                ["dead-bug", "side-plank", "dead-bug", "side-plank", "dead-bug", "side-plank"])
        #expect(finisher.map(\.setNumberLabel) ==
                ["Set 1 of 3", "Set 1 of 3", "Set 2 of 3", "Set 2 of 3", "Set 3 of 3", "Set 3 of 3"])
        #expect(finisher.last!.restAfterSeconds == 0)
    }

    @Test func intervalRepeatsPerItemNotes() {
        let bike = WorkoutPlan.aashutosh.workouts[.thursday]!.blocks[5].prescribedSets
        #expect(bike.count == 6)
        #expect(bike.allSatisfy { $0.durationSeconds == 20 })
        #expect(bike.map(\.restAfterSeconds) == [70, 70, 70, 70, 70, 0])
        #expect(bike.allSatisfy { $0.notes == "Easy spin during the rest" })
        #expect(bike.map(\.setNumberLabel) == (1...6).map { "Round \($0) of 6" })
    }

    @Test func groupsKeepNotesAndLabelOverrides() {
        let finishers = WorkoutPlan.varsha.workouts[.thursday]!.blocks[1].prescribedSets
        #expect(finishers.count == 7)
        #expect(finishers[0].exerciseId == "farmer-carry")
        #expect(finishers[0].durationSeconds == 45)
        #expect(finishers[0].notes == "30m carry")
        let last = finishers.last!
        #expect(last.setNumberLabel == "Hollow rocks")
        #expect(last.reps == 20)
        #expect(last.restAfterSeconds == 0)
    }

    // MARK: - Error paths

    private static let fixtureLibrary = ExerciseLibrary(exercises: [
        "real-exercise": Exercise(
            id: "real-exercise", name: "Real", primaryMuscle: "Test",
            formCues: [], videoURLString: nil, staticImageName: nil, alternativeIds: []
        )
    ])

    private func fixturePlan(blocks: String) -> Data {
        Data("""
        {
          "id": "fixture", "name": "Fixture",
          "workouts": [{
            "day": "monday", "title": "T", "subtitle": "S", "estimatedMinutes": 10,
            "warmupNote": "w", "cooldownNote": "c",
            "blocks": [\(blocks)]
          }]
        }
        """.utf8)
    }

    @Test func unknownExerciseIdThrows() {
        let json = fixturePlan(blocks: """
            { "label": "A", "kind": "straight", "tag": "A",
              "straight": { "exercise": "nonexistent-exercise", "sets": 2, "reps": 5, "rest": 60 } }
            """)
        #expect(throws: PlanLoaderError.self) {
            try PlanLoader.plan(from: json, library: Self.fixtureLibrary)
        }
    }

    @Test func blockWithTwoFormsThrows() {
        let json = fixturePlan(blocks: """
            { "label": "A", "kind": "straight", "tag": "A",
              "straight": { "exercise": "real-exercise", "sets": 2, "reps": 5, "rest": 60 },
              "superset": { "exercises": ["real-exercise"], "rounds": 2, "reps": 5, "rest": 60 } }
            """)
        #expect(throws: PlanLoaderError.self) {
            try PlanLoader.plan(from: json, library: Self.fixtureLibrary)
        }
    }

    @Test func rawSetsEscapeHatchWorks() {
        let json = fixturePlan(blocks: """
            { "label": "A", "kind": "finisher", "tag": "X",
              "sets": [
                { "exercise": "real-exercise", "reps": 5, "rest": 10, "label": "Only set", "notes": "n" }
              ] }
            """)
        let plan = try! PlanLoader.plan(from: json, library: Self.fixtureLibrary)
        let set = plan.workouts[.monday]!.setSequence[0]
        #expect(set.exerciseId == "real-exercise")
        #expect(set.setNumberLabel == "Only set")
        #expect(set.blockLabel == "X")
        #expect(set.notes == "n")
    }
}
