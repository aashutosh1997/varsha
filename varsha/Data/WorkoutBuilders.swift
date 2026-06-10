//
//  WorkoutBuilders.swift
//  Varsha
//
//  Shared helpers for authoring workout plan data.
//

import Foundation

func S(
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
func straightSets(
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
func supersetSets(
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
