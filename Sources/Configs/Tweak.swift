import Foundation
import Combine
import Tweaks

struct TweakConfigProvider<Value: Tweakable, Renderer: ViewRenderer> where Renderer.Value == Value {
    let category: String
    let section: String
    let definition: TweakDefinition<Value, Renderer>
    let repository: TweakRepository
}

extension TweakConfigProvider: ValueProvider {
    var objectWillChange: AnyPublisher<Void, Never> {
        repository.objectWillChange.eraseToAnyPublisher()
    }
    func value() -> ValueOverride<Value>? {
        if let value = repository[definition] {
            return .override(value)
        }
        return .noOverride
    }
}

public extension ConfigDefinition where Value: Tweakable {
    func tweak<Renderer: ViewRenderer>(category: String, section: String, name: String, configRepository: ConfigRepository? = .shared, renderer: Renderer) -> ConfigDefinition where Renderer.Value == Value {
        let value = configRepository?[self] ?? defaultValue
        let definition = TweakDefinition(id: "\(category) \(section) \(name)", name: name, initialValue: value, valueRenderer: renderer)
        return tweak(category: category, section: section, definition: definition)
    }
    
    func tweak<Renderer: ViewRenderer>(category: String, section: String, definition: TweakDefinition<Value, Renderer>, configRepository: ConfigRepository? = .shared) -> ConfigDefinition where Renderer.Value == Value {
        let tweakProvider = TweakConfigProvider(category: category, section: section, definition: definition, repository: .shared)
        TweakRepository.shared.add(tweak: definition, category: category, section: section)
        return ConfigDefinition(id: id, defaultValue: defaultValue, providers: providers + [AnyProvider(tweakProvider)])
    }
}

public extension ConfigDefinition where Value == Bool {
    func tweak(category: String, section: String, name: String, configRepository: ConfigRepository? = .shared) -> ConfigDefinition {
        tweak(category: category, section: section, name: name, configRepository: configRepository, renderer: ToggleBoolRenderer())
    }
}

public extension ConfigDefinition where Value == Int {
    func tweak(category: String, section: String, name: String, configRepository: ConfigRepository? = .shared) -> ConfigDefinition {
        tweak(category: category, section: section, name: name, configRepository: configRepository, renderer: InputAndStepperRenderer())
    }
}

public extension ConfigDefinition where Value == Double {
    func tweak(category: String, section: String, name: String, configRepository: ConfigRepository? = .shared, range: ClosedRange<Double> = 0 ... 1) -> ConfigDefinition {
        tweak(category: category, section: section, name: name, configRepository: configRepository, renderer: SliderRenderer(range: range))
    }
}

public extension ConfigDefinition where Value == String {
    func tweak(category: String, section: String, name: String, configRepository: ConfigRepository? = .shared) -> ConfigDefinition {
        tweak(category: category, section: section, name: name, configRepository: configRepository, renderer: StringTextfieldRenderer())
    }
}

public extension ConfigDefinition {
    func tweak<Wrapped: Tweakable, Renderer: ViewRenderer>(category: String, section: String, name: String, configRepository: ConfigRepository? = .shared, renderer: Renderer, defaultValueForNew: Wrapped) -> ConfigDefinition where Value == Wrapped?, Renderer.Value == Wrapped {
        tweak(category: category, section: section, name: name, configRepository: configRepository, renderer: OptionalToggleRenderer(renderer: renderer, defaultValueForNew: defaultValueForNew))
    }
    
    func tweak<Element: Tweakable, Renderer: ViewRenderer>(category: String, section: String, name: String, configRepository: ConfigRepository? = .shared, renderer: Renderer, defaultValueForNewElement: Element) -> ConfigDefinition where Value == [Element], Renderer.Value == Element {
        tweak(category: category, section: section, name: name, configRepository: configRepository, renderer: ArrayRenderer(renderer: renderer, defaultValueForNewElement: defaultValueForNewElement))
    }
}

public extension ConfigDefinition where Value == [Int] {
    func tweak(category: String, section: String, name: String, configRepository: ConfigRepository? = .shared, defaultValueForNewElement: Int = 0) -> ConfigDefinition {
        tweak(category: category, section: section, name: name, configRepository: configRepository, renderer: ArrayRenderer(renderer: InputAndStepperRenderer(), defaultValueForNewElement: defaultValueForNewElement))
    }
}

public extension ConfigDefinition where Value: Tweakable & CaseIterable & RawRepresentable, Value.RawValue: CustomStringConvertible & Hashable {
    func tweak(category: String, section: String, name: String, configRepository: ConfigRepository? = .shared) -> ConfigDefinition {
        tweak(category: category, section: section, name: name, configRepository: configRepository, renderer: OptionPickerRenderer())
    }
}
