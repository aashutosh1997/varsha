//
//  ActiveWorkoutView.swift
//  Varsha
//
//  The live workout screen. Big timer, exercise demo, set info, controls.
//  Designed for at-arm's-length readability and thumb-zone controls.
//  Each session phase renders its own component (StartCard,
//  PerformingSection, RestingSection, CompletedCard).
//

import SwiftUI

struct ActiveWorkoutView: View {
    @StateObject private var session: WorkoutSessionManager
    @Environment(\.dismiss) private var dismiss
    @State private var showResetConfirm = false
    @State private var showAlternativesSheet = false

    init(workout: Workout, library: ExerciseLibrary) {
        _session = StateObject(wrappedValue: WorkoutSessionManager(workout: workout, library: library))
    }

    var body: some View {
        VStack(spacing: 0) {
            progressHeader
            ScrollView {
                VStack(spacing: 20) {
                    switch session.phase {
                    case .notStarted:
                        StartCard(session: session)
                    case .performing:
                        PerformingSection(session: session, showAlternativesSheet: $showAlternativesSheet)
                    case .resting:
                        RestingSection(session: session)
                    case .completed:
                        CompletedCard(session: session) { dismiss() }
                    }
                }
                .padding()
            }
            controlBar
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("Reset current set", systemImage: "arrow.counterclockwise") {
                        session.resetCurrentSet()
                    }
                    Button("Restart workout", systemImage: "backward.end", role: .destructive) {
                        showResetConfirm = true
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Restart workout?", isPresented: $showResetConfirm) {
            Button("Restart", role: .destructive) { session.resetWorkout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("All progress in this session will be lost.")
        }
        .sheet(isPresented: $showAlternativesSheet) {
            if let exercise = session.currentExercise {
                AlternativesSheet(exercise: exercise, library: session.library)
            }
        }
        .keepScreenAwake(true)   // <— the critical one
    }

    // MARK: - Progress header

    private var progressHeader: some View {
        VStack(spacing: 6) {
            HStack {
                Text(session.workout.title).font(.headline)
                Spacer()
                Text("\(session.currentSetIndex + 1)/\(session.totalSets)")
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: session.progress)
                .tint(.orange)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Bottom control bar

    @ViewBuilder
    private var controlBar: some View {
        switch session.phase {
        case .performing:
            HStack(spacing: 12) {
                Button {
                    session.resetCurrentSet()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.title3)
                        .frame(width: 56, height: 56)
                }
                .buttonStyle(.bordered)

                Button {
                    session.completeCurrentSet()
                } label: {
                    Label("Complete set", systemImage: "checkmark")
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
            .padding()
            .background(.ultraThinMaterial)
        default:
            EmptyView()
        }
    }
}
