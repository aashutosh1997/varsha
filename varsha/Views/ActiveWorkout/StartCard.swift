//
//  StartCard.swift
//  Varsha
//
//  Pre-start phase of the live workout: session summary, warm-up note,
//  and the start button.
//

import SwiftUI

struct StartCard: View {
    @ObservedObject var session: WorkoutSessionManager

    var body: some View {
        VStack(spacing: 16) {
            Text(session.workout.subtitle).font(.title2.bold())
            Text("\(session.totalSets) sets · \(session.workout.estimatedMinutes) min")
                .foregroundStyle(.secondary)
            if !session.workout.warmupNote.isEmpty {
                Label(session.workout.warmupNote, systemImage: "flame.fill")
                    .font(.callout)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Button {
                session.start()
            } label: {
                Label("Start workout", systemImage: "play.fill")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
        }
    }
}
