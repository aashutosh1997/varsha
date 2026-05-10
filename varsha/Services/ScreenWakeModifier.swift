//
//  ScreenWakeModifier.swift
//  Varsha
//
//  Keep the iOS screen on while a view is visible. Apply to any root view
//  of an active workout session. Auto-restores when view leaves.
//

import SwiftUI
import UIKit

private struct ScreenWakeModifier: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        content
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = enabled
            }
            .onDisappear {
                // Critical: re-enable idle timer or you'll murder the user's battery.
                UIApplication.shared.isIdleTimerDisabled = false
            }
            .onChange(of: enabled) { _, newValue in
                UIApplication.shared.isIdleTimerDisabled = newValue
            }
    }
}

extension View {
    /// Prevents the screen from auto-locking while this view is on screen.
    /// Use only on workout-active views — never globally.
    func keepScreenAwake(_ enabled: Bool = true) -> some View {
        modifier(ScreenWakeModifier(enabled: enabled))
    }
}
