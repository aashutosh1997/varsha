//
//  WeekScheduleView.swift
//  Varsha
//
//  Root view: shows the seven days of the week with each day's workout
//  (or a rest-day indicator). Tapping a workout pushes WorkoutDetailView.
//

import SwiftUI

struct WeekScheduleView: View {
    private let library = exerciseLibrary
    private let plan = pcosPlan

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("This Week").font(.title2.bold())
                        Text("5 active days, 2 rest")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                Section("Workouts") {
                    ForEach(Weekday.allCases) { day in
                        if let workout = plan[day] {
                            NavigationLink {
                                WorkoutDetailView(workout: workout, library: library)
                            } label: {
                                WorkoutRow(day: day, workout: workout)
                            }
                        } else {
                            RestDayRow(day: day)
                        }
                    }
                }

                Section {
                    Text("Tap a workout to preview, then start the live session.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Varsha")
        }
    }
}

// MARK: - Row helpers (private to this file)

private struct WorkoutRow: View {
    let day: Weekday
    let workout: Workout

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(day.displayName.prefix(3).uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(.orange)
                Image(systemName: "dumbbell.fill")
                    .foregroundStyle(.orange)
            }
            .frame(width: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(workout.title).font(.headline)
                Text("\(workout.totalSets) sets · \(workout.estimatedMinutes) min")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

private struct RestDayRow: View {
    let day: Weekday

    var body: some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text(day.displayName.prefix(3).uppercased())
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Image(systemName: "leaf.fill")
                    .foregroundStyle(.green)
            }
            .frame(width: 44)
            Text("Rest / Active recovery").foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
