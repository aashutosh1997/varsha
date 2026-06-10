//
//  RestingSection.swift
//  Varsha
//
//  Rest phase of the live workout: countdown, up-next preview, and
//  rest adjustment controls.
//

import SwiftUI

struct RestingSection: View {
    @ObservedObject var session: WorkoutSessionManager

    var body: some View {
        VStack(spacing: 20) {
            Text("REST").font(.caption.bold()).foregroundStyle(.orange).tracking(2)

            Text(session.displayedSeconds.minutesSecondsString)
                .font(.system(size: 96, weight: .bold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText())
                .animation(.snappy, value: session.displayedSeconds)

            if let next = session.nextSet, let nextEx = session.nextExercise {
                VStack(spacing: 0) {
                    ExerciseMediaView(exercise: nextEx, height: 140)

                    VStack(spacing: 4) {
                        Text("Up next").font(.caption.bold()).foregroundStyle(.secondary)
                        Text(nextEx.name).font(.title3.bold())
                        Text(next.summaryLine)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .background(Color(.tertiarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(spacing: 12) {
                Button("+15s") { session.addRestTime(seconds: 15) }
                    .buttonStyle(.bordered)
                Button("Skip rest") { session.skipRest() }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
            }
        }
        .padding(.top, 24)
    }
}
