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
        .tweak(category: "Product Settings", section: "Essentials", name: "Backend Url", renderer: PickerRendererWithCustomValue(options: ["Debug": "https://debug", "Production": "https://production", "Test": "https://preprod"], renderer: StringTextfieldRenderer()))
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
    static let color = ConfigDefinition(defaultValue: .red)
        .when(.deviceType(is: .iPhone), return: .purple)
        .tweak(category: "Product Settings", section: "Chart", name: "Test values", renderer: ColorPickerRenderer())
}

extension ConfigDefinition where Value == Double? {
    static let chartOffset = ConfigDefinition(defaultValue: nil)
        .when(.deviceType(is: [.iPad, .tv]), return: 20)
        .when(.deviceType(is: .iPhone), return: 0)
        .userDefaults(key: "chart_offset")
        .tweak(category: "Product Settings", section: "Chart", name: "Offset", renderer: SliderRenderer(range: 0 ... 100), defaultValueForNew: 0)
}

extension ConfigDefinition where Value == ABValues {
    static let myExperiment = ConfigDefinition(defaultValue: .b)
        .when(.userIsInternal(), return: .a)
        .experimentManager("my_experiment")
        .tweak(category: "Feature Flags", section: "Experiments", name: "My experiment")
}

extension TweakAction {
    static let resetAction = TweakAction(category: "Product Settings", section: "Actions", name: "Reset onboarding") {
        print("reset")
    }
    static let restartAction = TweakAction(category: "Product Settings", section: "Actions", name: "Restart app") {
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

extension Color: Configurable, Tweakable {
    public static var valueTransformer: Tweaks.ValueTransformer<Color, String> {
        Tweaks.ValueTransformer(transform: \.hexValue, retrieve: Color.init(hex:))
    }
    
    init(hex string: String) {
        var string: String = string.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if string.hasPrefix("#") {
            _ = string.removeFirst()
        }

        let scanner = Scanner(string: string)

        var color: UInt64 = 0
        scanner.scanHexInt64(&color)

        let mask = 0x000000FF
        let r = Int(color >> 24) & mask
        let g = Int(color >> 16) & mask
        let b = Int(color >> 8) & mask
        let a = Int(color) & mask

        let red = Double(r) / 255.0
        let green = Double(g) / 255.0
        let blue = Double(b) / 255.0
        let alpha = Double(a) / 255.0

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
    
    var hexValue: String {
        guard let values = cgColor?.components else { return "#00000000" }
        let outputR = Int(values[0] * 255)
        let outputG = Int(values[1] * 255)
        let outputB = Int(values[2] * 255)
        let outputA = Int(values[3] * 255)
        return "#"
            + String(format:"%02X", outputR)
            + String(format:"%02X", outputG)
            + String(format:"%02X", outputB)
            + String(format:"%02X", outputA)
    }
}

public struct ColorPickerRenderer: ViewRenderer {
    public typealias Value = Color
    public init() {}
    public func previewView(value: Value) -> some View {
        value.frame(width: 30, height: 30).cornerRadius(8)
    }
    
    public func tweakView(value: Binding<Value>) -> some View {
        Group {
            if #available(iOS 14.0, *) {
                ColorPicker("Pick a color", selection: value)
            } else {
                previewView(value: value.wrappedValue)
            }
        }
    }
}
