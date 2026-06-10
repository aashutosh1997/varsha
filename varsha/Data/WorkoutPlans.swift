//
//  WorkoutPlans.swift
//  Varsha
//
//  Registry of the bundled plans. Each plan is decoded from
//  Resources/Plans/<id>.json exactly once (static let) so the generated
//  PrescribedSet UUIDs stay stable for the lifetime of the app run —
//  WorkoutSessionManager keys its in-session logs by those ids.
//

import Foundation

extension WorkoutPlan {
    // try! is deliberate: the JSON ships in the bundle, so a failure here is a
    // programmer error. PlanLoaderTests decode and validate every plan in CI.
    private static let sharedLibrary = try! PlanLoader.loadLibrary()

    static let varsha = try! PlanLoader.loadPlan(named: "varsha", library: sharedLibrary)
    static let aashutosh = try! PlanLoader.loadPlan(named: "aashutosh", library: sharedLibrary)

    /// All selectable plans, in display order.
    static let allPlans: [WorkoutPlan] = [.varsha, .aashutosh]

    static func plan(withId id: String) -> WorkoutPlan {
        allPlans.first { $0.id == id } ?? .varsha
    }
}
