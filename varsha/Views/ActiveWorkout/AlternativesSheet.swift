//
//  AlternativesSheet.swift
//  Varsha
//
//  Sheet listing substitute exercises and form cues for the current
//  exercise during a live workout.
//

import SwiftUI

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
