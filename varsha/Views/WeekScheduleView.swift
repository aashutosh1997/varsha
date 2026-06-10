//
//  WeekScheduleView.swift
//  Varsha
//
//  Root view: shows the seven days of the week with each day's workout
//  (or a rest-day indicator). Tapping a workout pushes WorkoutDetailView.
//

import SwiftUI

struct WeekScheduleView: View {
    @AppStorage("selectedPlanId") private var selectedPlanId = WorkoutPlan.varsha.id

    private var plan: WorkoutPlan { .plan(withId: selectedPlanId) }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("This Week").font(.title2.bold())
                        Text("\(plan.workouts.count) active days, \(7 - plan.workouts.count) rest")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                Section("Workouts") {
                    ForEach(Weekday.allCases) { day in
                        if let workout = plan.workouts[day] {
                            NavigationLink {
                                WorkoutDetailView(workout: workout, library: plan.library)
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
            .navigationTitle(plan.name)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Plan", selection: $selectedPlanId) {
                            ForEach(WorkoutPlan.allPlans) { plan in
                                Text(plan.name).tag(plan.id)
                            }
                        }
                    } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
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
