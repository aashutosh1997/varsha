//
//  CompletedCard.swift
//  Varsha
//
//  Completed phase of the live workout: celebration, cool-down note,
//  and the done button.
//

import SwiftUI

struct CompletedCard: View {
    @ObservedObject var session: WorkoutSessionManager
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
            Text("Workout complete").font(.title.bold())
            Text("\(session.totalSets) sets · \(session.workout.title)")
                .foregroundStyle(.secondary)
            if !session.workout.cooldownNote.isEmpty {
                Label(session.workout.cooldownNote, systemImage: "leaf.fill")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            Button("Done", action: onDone)
                .buttonStyle(.borderedProminent)
                .tint(.orange)
        }
    }
}
