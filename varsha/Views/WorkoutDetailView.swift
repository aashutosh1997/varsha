//
//  WorkoutDetailView.swift
//  Varsha
//
//  Pre-workout preview screen. Lists every block of the workout with
//  exercises and prescribed sets, plus warm-up and cool-down notes.
//  Bottom button launches ActiveWorkoutView in a full-screen cover.
//

import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout
    let library: ExerciseLibrary
    @State private var showActive = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if !workout.warmupNote.isEmpty {
                    NoteCard(title: "Warm up", icon: "flame.fill", tint: .orange, text: workout.warmupNote)
                }

                ForEach(workout.blocks) { block in
                    BlockCard(block: block, library: library)
                }

                if !workout.cooldownNote.isEmpty {
                    NoteCard(title: "Cool down", icon: "leaf.fill", tint: .green, text: workout.cooldownNote)
                }
            }
            .padding()
        }
        .navigationTitle(workout.day.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                showActive = true
            } label: {
                Label("Start workout", systemImage: "play.fill")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(.orange)
            .padding()
            .background(.ultraThinMaterial)
        }
        .fullScreenCover(isPresented: $showActive) {
            NavigationStack {
                ActiveWorkoutView(workout: workout, library: library)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workout.title).font(.largeTitle.bold())
            Text(workout.subtitle).font(.title3).foregroundStyle(.secondary)
            HStack(spacing: 16) {
                Label("\(workout.totalSets) sets", systemImage: "list.number")
                Label("\(workout.estimatedMinutes) min", systemImage: "clock")
            }
            .font(.caption).foregroundStyle(.secondary)
            .padding(.top, 4)
        }
    }
}

// MARK: - Block preview card (private to this file)

private struct BlockCard: View {
    let block: WorkoutBlock
    let library: ExerciseLibrary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(block.label).font(.headline)

            // Group consecutive sets of the same exercise for a clean preview
            ForEach(uniqueExerciseSummaries(), id: \.self) { summary in
                HStack(alignment: .top) {
                    Image(systemName: "dot.circle.fill")
                        .foregroundStyle(.orange.opacity(0.7))
                        .padding(.top, 3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(summary.name).font(.subheadline.bold())
                        Text(summary.detail).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }

            if let notes = block.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private struct ExerciseSummary: Hashable {
        let name: String
        let detail: String
    }

    private func uniqueExerciseSummaries() -> [ExerciseSummary] {
        // Group sets by exerciseId, count them, build a summary like "4×8 reps".
        var seen: [String] = []
        var counts: [String: (set: PrescribedSet, count: Int)] = [:]
        for set in block.prescribedSets {
            if counts[set.exerciseId] == nil { seen.append(set.exerciseId) }
            counts[set.exerciseId, default: (set, 0)].count += 1
        }
        return seen.compactMap { id in
            guard let entry = counts[id], let exercise = library.exercise(for: id) else { return nil }
            let count = entry.count
            let set = entry.set
            var detail = "\(count) × "
            if let reps = set.reps {
                detail += set.perSide ? "\(reps)/side" : "\(reps) reps"
            } else if let dur = set.durationSeconds {
                detail += "\(dur)s"
            }
            return ExerciseSummary(name: exercise.name, detail: detail)
        }
    }
}

private struct NoteCard: View {
    let title: String
    let icon: String
    let tint: Color
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption.bold())
                .foregroundStyle(tint)
            Text(text).font(.callout)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
