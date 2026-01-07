//
//  HapticsManager.swift
//  BlockBlast
//

import UIKit

/// Manages haptic feedback throughout the game
class HapticsManager {
    static let shared = HapticsManager()

    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()

    private var isEnabled: Bool = true

    private init() {
        prepareGenerators()
    }

    /// Prepare all generators for immediate use
    func prepareGenerators() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }

    /// Enable or disable haptics
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    /// Trigger impact feedback
    func impact(style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
        guard isEnabled else { return }

        let generator: UIImpactFeedbackGenerator
        switch style {
        case .light:
            generator = impactLight
        case .medium:
            generator = impactMedium
        case .heavy:
            generator = impactHeavy
        case .soft:
            generator = impactSoft
        case .rigid:
            generator = impactRigid
        @unknown default:
            generator = impactMedium
        }

        generator.impactOccurred(intensity: intensity)
        generator.prepare()
    }

    /// Trigger selection feedback
    func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }

    /// Trigger notification feedback
    func notification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(type)
        notificationGenerator.prepare()
    }

    // MARK: - Game-specific haptics

    /// Block tap haptic
    func blockTap() {
        impact(style: .light)
    }

    /// Blocks cleared haptic
    func blocksClear(count: Int) {
        if count > 10 {
            impact(style: .heavy)
        } else if count > 5 {
            impact(style: .medium)
        } else {
            impact(style: .light)
        }
    }

    /// Combo haptic
    func combo(level: Int) {
        let intensity = min(1.0, CGFloat(level) * 0.2)
        impact(style: .rigid, intensity: intensity)
    }

    /// Power-up activated haptic
    func powerUp() {
        notification(type: .success)
    }

    /// Game over haptic
    func gameOver() {
        notification(type: .error)
    }

    /// Victory haptic
    func victory() {
        // Triple success notification
        notification(type: .success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.notification(type: .success)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) { [weak self] in
            self?.notification(type: .success)
        }
    }

    /// Freeze effect haptic
    func freeze() {
        notification(type: .warning)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.impact(style: .heavy)
        }
    }
}
