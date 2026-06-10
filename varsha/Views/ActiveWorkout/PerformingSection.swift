//
//  PerformingSection.swift
//  Varsha
//
//  Performing phase of the live workout: exercise demo, set prescription,
//  the big timer, and form cues.
//

import SwiftUI

struct PerformingSection: View {
    @ObservedObject var session: WorkoutSessionManager
    @Binding var showAlternativesSheet: Bool

    var body: some View {
        VStack(spacing: 16) {
            if let exercise = session.currentExercise {
                ExerciseMediaView(exercise: exercise)
                exerciseHeader(exercise)
            }
            setPrescription
            timerDisplay
            formCues
        }
    }

    private func exerciseHeader(_ exercise: Exercise) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(exercise.name).font(.title2.bold())
                Spacer()
                if !exercise.alternativeIds.isEmpty {
                    Button {
                        showAlternativesSheet = true
                    } label: {
                        Label("Swap", systemImage: "arrow.triangle.2.circlepath")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                }
            }
            if let block = session.currentSet?.blockLabel {
                Text(block).font(.caption).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    private var setPrescription: some View {
        if let set = session.currentSet {
            HStack(spacing: 24) {
                if let reps = set.repsStatText {
                    statTile(label: "Reps", value: reps)
                }
                if let duration = set.durationText {
                    statTile(label: "Duration", value: duration)
                }
                if let weight = set.weightText {
                    statTile(label: "Suggested", value: weight)
                }
                statTile(label: "Set", value: set.setNumberLabel)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func statTile(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold().monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var timerDisplay: some View {
        VStack(spacing: 4) {
            Text(session.displayedSeconds.minutesSecondsString)
                .font(.system(size: 64, weight: .semibold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText())
                .animation(.snappy, value: session.displayedSeconds)
            if let set = session.currentSet, set.isTimeBased {
                Text("Time remaining").font(.caption).foregroundStyle(.secondary)
            } else {
                Text("Elapsed").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private var formCues: some View {
        if let exercise = session.currentExercise, !exercise.formCues.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Form").font(.caption.bold()).foregroundStyle(.secondary)
                ForEach(exercise.formCues, id: \.self) { cue in
                    Label(cue, systemImage: "checkmark.circle")
                        .font(.callout)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.tertiarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
