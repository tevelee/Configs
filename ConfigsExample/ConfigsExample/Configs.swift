import Foundation
import Configs
import Tweaks
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Definitions

extension ConfigDefinition where Value == Bool {
    static let secretNewInProgressFeatureFlag = ConfigDefinition(id: "secret_new_feature", defaultValue: false)
        .when(.deviceType(is: .iPad), return: false)
        .userDefaults(key: "secret_new_feature")
        .firebaseRemoteConfig(key: "secret_new_feature")
        .tweak(category: "Feature Flags", section: "In progress features", name: "Secret New Feature Enabled")
}

extension ConfigDefinition where Value == String {
    static let backendBaseUrl = ConfigDefinition(defaultValue: "https://production")
        .firebaseRemoteConfig(key: "server_url")
        .tweak(category: "Product Settings", section: "Essentials", name: "Backend Url", renderer: PickerRendererWithCustomValue(options: ["Debug": "https://debug", "Production": "https://production", "Test": "https://preprod"], renderer: StringTextfieldRenderer()), converter: .identity)
}

extension ConfigDefinition where Value == Int {
    static let numberOfFreeItems = ConfigDefinition(defaultValue: 1)
        .when(.userIsInternal(), return: 100)
        .firebaseRemoteConfig(key: "free_items")
        .tweak(category: "Product Settings", section: "Monetisation", name: "Free items")
}

extension ConfigDefinition where Value == [Int] {
    static let valuesForChart = ConfigDefinition(defaultValue: [1, 2, 3])
        .tweak(category: "Product Settings", section: "Chart", name: "Test values")
}

extension ConfigDefinition where Value == Color {
    @available(iOS 14.0, *)
    static let color = ConfigDefinition(defaultValue: .red)
        .when(.deviceType(is: .iPhone), return: .purple)
        .tweak(category: "Product Settings", section: "Chart", name: "Test values", renderer: ColorPickerRenderer(), converter: .hex)
}

extension ConfigDefinition where Value == Double? {
    static let chartOffset = ConfigDefinition(defaultValue: nil)
        .when(.deviceType(is: [.iPad, .tv]), return: 20)
        .when(.deviceType(is: .iPhone), return: 0)
        .userDefaults(key: "chart_offset")
        .tweak(category: "Product Settings", section: "Chart", name: "Offset", renderer: SliderRenderer(range: 0 ... 100), defaultValueForNewElement: 0, converter: .description)
}

extension ConfigDefinition where Value == ABValues {
    static let myExperiment = ConfigDefinition(defaultValue: .b)
        .when(.userIsInternal(), return: .a)
        .experimentManager("my_experiment")
        .tweak(category: "Feature Flags", section: "Experiments", name: "My experiment", converter: .rawValue)
}

extension TweakAction {
    static let reset = TweakAction(name: "Reset onboarding") {
        print("reset")
    }
    static let restart = TweakAction(name: "Restart app") {
        print("restart")
    }
}

// MARK: - Helpers

enum ABValues: String, CaseIterable, Configurable, Tweakable, StorableInUserDefaults {
    case a, b
}

public extension ConfigCondition {
    static func userEmail(hasSuffix value: String) -> ConfigCondition {
        ConfigCondition {
            true // userManager.currentUser?.email.hasSuffix(value) ?? false
        }
    }
    static func userIsInternal() -> ConfigCondition {
        userEmail(hasSuffix: "mycompany.com")
    }
    enum BuildType { case debug, `internal`, production }
    static func buildType() -> BuildType {
        .debug // buildEnvironment.current.buildType
    }
}

public extension ConfigDefinition {
    func experimentManager(_ key: String) -> ConfigDefinition {
        self //ConfigDefinition(id: id, defaultValue: defaultValue, providers: providers + [AnyProvider(experimentManager.currentSession[key])])
    }
}
