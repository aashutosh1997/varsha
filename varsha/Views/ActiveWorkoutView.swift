//
//  ActiveWorkoutView.swift
//  Varsha
//
//  The live workout screen. Big timer, exercise demo, set info, controls.
//  Designed for at-arm's-length readability and thumb-zone controls.
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
                        startCard
                    case .performing:
                        performingSection
                    case .resting:
                        restingSection
                    case .completed:
                        completedCard
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

    // MARK: - Phase: not started

    private var startCard: some View {
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

    // MARK: - Phase: performing

    private var performingSection: some View {
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
                if let reps = set.reps {
                    statTile(label: "Reps", value: set.perSide ? "\(reps)/side" : "\(reps)")
                }
                if let dur = set.durationSeconds {
                    statTile(label: "Duration", value: "\(dur)s")
                }
                if let kg = set.suggestedWeightKg {
                    statTile(label: "Suggested", value: "\(kg.cleanString) kg")
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
            Text(timeString(session.displayedSeconds))
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

    // MARK: - Phase: resting

    private var restingSection: some View {
        VStack(spacing: 20) {
            Text("REST").font(.caption.bold()).foregroundStyle(.orange).tracking(2)

            Text(timeString(session.displayedSeconds))
                .font(.system(size: 96, weight: .bold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText())
                .animation(.snappy, value: session.displayedSeconds)

            if let next = session.nextSet, let nextEx = session.nextExercise {
                VStack(spacing: 0) {
                    ExerciseMediaView(exercise: nextEx, height: 140)

                    VStack(spacing: 4) {
                        Text("Up next").font(.caption.bold()).foregroundStyle(.secondary)
                        Text(nextEx.name).font(.title3.bold())
                        Text(nextSetSummary(next))
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

    private func nextSetSummary(_ set: PrescribedSet) -> String {
        var parts: [String] = []
        if let reps = set.reps {
            parts.append(set.perSide ? "\(reps)/side" : "\(reps) reps")
        }
        if let dur = set.durationSeconds {
            parts.append("\(dur)s")
        }
        if let kg = set.suggestedWeightKg {
            parts.append("\(kg.cleanString) kg")
        }
        parts.append(set.setNumberLabel)
        return parts.joined(separator: " · ")
    }

    // MARK: - Phase: completed

    private var completedCard: some View {
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
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
        }
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

    // MARK: - Helpers

    private func timeString(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - Alternatives sheet

struct AlternativesSheet: View {
    let exercise: Exercise
    let library: ExerciseLibrary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Alternatives for \(exercise.name)") {
                    ForEach(exercise.alternativeIds, id: \.self) { altId in
                        if let alt = library.exercise(for: altId) {
                            VStack(alignment: .leading) {
                                Text(alt.name).font(.headline)
                                Text(alt.primaryMuscle).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                Section("Form cues") {
                    ForEach(exercise.formCues, id: \.self) { cue in
                        Label(cue, systemImage: "checkmark.circle")
                    }
                }
            }
            .navigationTitle("Swap exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Helpers

private extension Double {
    var cleanString: String {
        truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", self)
            : String(format: "%.1f", self)
    }
}
