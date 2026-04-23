import Foundation
import SwiftUI

public enum TimerDisplay {
    public static func format(remaining: TimeInterval, idle: Bool) -> String {
        if remaining >= 0 {
            let total = Int(ceil(remaining))
            let minutes = total / 60
            let seconds = total % 60
            return String(format: "%d:%02d", minutes, seconds)
        } else {
            let elapsed = Int(floor(-remaining))
            let minutes = elapsed / 60
            let seconds = elapsed % 60
            return String(format: "+%d:%02d", minutes, seconds)
        }
    }

    public static func backgroundColor(remaining: TimeInterval, idle: Bool, flashOn: Bool) -> Color {
        if idle {
            return Color(red: 0.04, green: 0.27, blue: 0.57) // idle same as 5:xx blue
        }
        if remaining <= 0 {
            return .black
        }
        if remaining <= 5 {
            return flashOn ? .white : .red
        }
        let minute = Int(ceil(remaining / 60.0))
        switch minute {
        case 5: return Color(red: 0.04, green: 0.27, blue: 0.57)   // blue
        case 4: return Color(red: 0.00, green: 0.55, blue: 0.55)   // teal
        case 3: return Color(red: 0.05, green: 0.55, blue: 0.15)   // green
        case 2: return Color(red: 0.82, green: 0.67, blue: 0.00)   // yellow
        case 1: return Color(red: 0.90, green: 0.45, blue: 0.00)   // orange
        default: return .red
        }
    }

    public static func textColor(remaining: TimeInterval, flashOn: Bool) -> Color {
        if remaining <= 5 && remaining > 0 {
            return flashOn ? .red : .white
        }
        return .white
    }

    /// 0 when nothing has elapsed (full duration remaining), 1 when remaining has reached 0 or gone past.
    public static func fillProgress(remaining: TimeInterval, duration: StartDuration, idle: Bool) -> CGFloat {
        if idle { return 0 }
        let total = TimeInterval(duration.rawValue)
        guard total > 0 else { return 0 }
        let raw = 1.0 - max(0, remaining) / total
        return CGFloat(min(max(raw, 0), 1))
    }

    /// Darker shade of the current per-minute color, drawn bottom-up to show countdown progress.
    public static func fillColor(remaining: TimeInterval, idle: Bool) -> Color {
        if idle {
            return Color(red: 0.015, green: 0.10, blue: 0.22) // dark blue to match idle bg
        }
        if remaining <= 0 {
            return Color(red: 0.25, green: 0.02, blue: 0.02) // dark red for count-up
        }
        let minute = Int(ceil(remaining / 60.0))
        switch minute {
        case 5: return Color(red: 0.015, green: 0.10, blue: 0.22)   // dark blue
        case 4: return Color(red: 0.00, green: 0.22, blue: 0.22)    // dark teal
        case 3: return Color(red: 0.02, green: 0.22, blue: 0.06)    // dark green
        case 2: return Color(red: 0.35, green: 0.28, blue: 0.00)    // dark olive
        case 1: return Color(red: 0.40, green: 0.20, blue: 0.00)    // dark amber
        default: return Color(red: 0.40, green: 0.03, blue: 0.03)   // dark red
        }
    }
}
