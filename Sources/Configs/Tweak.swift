import Foundation
import Combine
import Tweaks
import SwiftUI

struct TweakConfigProvider<Renderer: ViewRenderer, Store: Tweaks.StorageMechanism> where Renderer.Value: Tweakable, Store.Key == String, Store.Value == Renderer.Value {
    let category: String
    let section: String
    let definition: TweakDefinition<Renderer, Store>
    let repository: TweakRepository
}

extension TweakConfigProvider: ValueProvider {
    var objectWillChange: AnyPublisher<Void, Never> {
        repository.objectWillChange.eraseToAnyPublisher()
    }
    func value() -> ValueOverride<Renderer.Value>? {
        if let value = repository[definition] {
            return .override(value)
        }
        return .noOverride
    }
}

public extension ConfigDefinition where Value: Tweakable {
    func tweak<Renderer: ViewRenderer>(category: String,
                                       section: String,
                                       name: String,
                                       configRepository: ConfigRepository? = .shared,
                                       renderer: Renderer,
                                       converter: SymmetricConverting<Value, String>) -> ConfigDefinition where Renderer.Value == Value {
        let value = configRepository?[self] ?? defaultValue
        let definition = TweakDefinition(id: "\(category) \(section) \(name)",
                                         name: name,
                                         initialValue: value,
                                         renderer: renderer,
                                         store: UserDefaultsStore(converter: converter))
        return tweak(category: category, section: section, definition: definition, configRepository: configRepository)
    }
    
    func tweak<Renderer: ViewRenderer, Store: Tweaks.StorageMechanism>(category: String,
                                                                       section: String,
                                                                       definition: TweakDefinition<Renderer, Store>,
                                                                       configRepository: ConfigRepository? = .shared) -> ConfigDefinition where Renderer.Value == Value {
        let tweakRepository = TweakRepository.shared
        let tweakProvider = TweakConfigProvider(category: category,
                                                section: section,
                                                definition: definition,
                                                repository: tweakRepository)
        tweakRepository.add(tweak: definition, category: category, section: section)
        return ConfigDefinition(id: id, defaultValue: defaultValue, providers: providers + [AnyProvider(tweakProvider)])
    }
}

public extension ConfigDefinition where Value == Bool {
    func tweak(category: String, section: String, name: String, configRepository: ConfigRepository? = .shared) -> ConfigDefinition {
        tweak(category: category,
              section: section,
              name: name,
              configRepository: configRepository,
              renderer: ToggleBoolRenderer(),
              converter: .description)
    }
}

public extension ConfigDefinition where Value == Int {
    func tweak(category: String,
               section: String,
               name: String,
               configRepository: ConfigRepository? = .shared) -> ConfigDefinition {
        tweak(category: category,
              section: section,
              name: name,
              configRepository: configRepository,
              renderer: InputAndStepperRenderer(),
              converter: .description)
    }
}

public extension ConfigDefinition where Value == Double {
    func tweak(category: String,
               section: String,
               name: String,
               configRepository: ConfigRepository? = .shared,
               range: ClosedRange<Double> = 0 ... 1) -> ConfigDefinition {
        tweak(category: category,
              section: section,
              name: name,
              configRepository: configRepository,
              renderer: SliderRenderer(range: range),
              converter: .description)
    }
}

public extension ConfigDefinition where Value == String {
    func tweak(category: String,
               section: String,
               name: String,
               configRepository: ConfigRepository? = .shared) -> ConfigDefinition {
        tweak(category: category,
              section: section,
              name: name,
              configRepository: configRepository,
              renderer: StringTextfieldRenderer(),
              converter: .identity)
    }
}

public extension ConfigDefinition {
    func tweak<Wrapped: Tweakable, Renderer: ViewRenderer>(category: String,
                                                           section: String,
                                                           name: String,
                                                           configRepository: ConfigRepository? = .shared,
                                                           renderer: Renderer,
                                                           defaultValueForNewElement: Wrapped,
                                                           converter: SymmetricConverting<Wrapped, String>) -> ConfigDefinition where Value == Wrapped?, Renderer.Value == Wrapped {
        tweak(category: category,
              section: section,
              name: name,
              configRepository: configRepository,
              renderer: OptionalToggleRenderer(renderer: renderer,
                                               defaultValueForNewElement: defaultValueForNewElement),
              converter: .optional(converter: converter))
    }

    func tweak<Element: Tweakable, Renderer: ViewRenderer>(category: String,
                                                           section: String,
                                                           name: String,
                                                           configRepository: ConfigRepository? = .shared,
                                                           renderer: Renderer,
                                                           defaultValueForNewElement: Element,
                                                           converter: SymmetricConverting<Element, String>) -> ConfigDefinition where Value == [Element], Renderer.Value == Element {
        tweak(category: category,
              section: section,
              name: name,
              configRepository: configRepository,
              renderer: ArrayRenderer(renderer: renderer,
                                      converter: converter.encoding,
                                      defaultValueForNewElement: defaultValueForNewElement),
              converter: .array(converter: converter))
    }
}

public extension ConfigDefinition where Value == [Int] {
    func tweak(category: String,
               section: String,
               name: String,
               configRepository: ConfigRepository? = .shared,
               defaultValueForNewElement: Int = 0) -> ConfigDefinition {
        tweak(category: category,
              section: section,
              name: name,
              configRepository: configRepository,
              renderer: ArrayRenderer(renderer: InputAndStepperRenderer(),
                                      converter: .description,
                                      defaultValueForNewElement: defaultValueForNewElement),
              converter: .array(converter: .description))
    }
}

public extension ConfigDefinition where Value == Color {
    @available(iOS 14.0, *)
    func tweak(category: String,
               section: String,
               name: String,
               configRepository: ConfigRepository? = .shared) -> ConfigDefinition {
        tweak(category: category,
              section: section,
              name: name,
              configRepository: configRepository,
              renderer: ColorPickerRenderer(),
              converter: .hex)
    }
}

public extension ConfigDefinition where Value: CaseIterable & Tweakable {
    func tweak(category: String,
               section: String,
               name: String,
               configRepository: ConfigRepository? = .shared,
               converter: SymmetricConverting<Value, String>) -> ConfigDefinition {
        tweak(category: category,
              section: section,
              name: name,
              configRepository: configRepository,
              renderer: OptionPickerRenderer(converter: converter.encoding),
              converter: converter)
    }
}
