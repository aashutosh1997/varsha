//
//  Formatters.swift
//  Varsha
//
//  Shared display formatting used by the schedule, detail, and live
//  workout screens.
//

import Foundation

extension Int {
    /// 95 -> "1:35"
    var minutesSecondsString: String {
        String(format: "%d:%02d", self / 60, self % 60)
    }
}

extension Double {
    /// 40.0 -> "40", 12.5 -> "12.5"
    var cleanWeightString: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(format: "%.1f", self)
    }
}

extension PrescribedSet {
    /// "10" or "10/side" — compact form for stat tiles.
    var repsStatText: String? {
        reps.map { perSide ? "\($0)/side" : "\($0)" }
    }

    /// "10 reps" or "10/side" — spelled-out form for summaries.
    var repsSummaryText: String? {
        reps.map { perSide ? "\($0)/side" : "\($0) reps" }
    }

    /// "30s"
    var durationText: String? {
        durationSeconds.map { "\($0)s" }
    }

    /// "40 kg"
    var weightText: String? {
        suggestedWeightKg.map { "\($0.cleanWeightString) kg" }
    }

    /// "8 reps · 40 kg · Set 1 of 4"
    var summaryLine: String {
        ([repsSummaryText, durationText, weightText, setNumberLabel] as [String?])
            .compactMap { $0 }
            .joined(separator: " · ")
    }
}
