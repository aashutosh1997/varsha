//
//  VarshaApp.swift
//  Varsha
//
//  App entry point. Top-level navigation flow:
//    WeekScheduleView  →  WorkoutDetailView  →  ActiveWorkoutView
//

import SwiftUI

@main
struct VarshaApp: App {
    var body: some Scene {
        WindowGroup {
            WeekScheduleView()
        }
    }
}
