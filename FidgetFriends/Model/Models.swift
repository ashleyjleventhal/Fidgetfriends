import SwiftUI

enum CritterSpecies: String, Codable, CaseIterable, Identifiable {
    case blob, cat, bunny, bear, frog, axolotl, star, popIt, cube, spinner, otherSquishy, otherFidget

    var id: String { rawValue }

    var label: String {
        switch self {
        case .blob: return "Mochi blob"
        case .cat: return "Kitty"
        case .bunny: return "Bunny"
        case .bear: return "Bear"
        case .frog: return "Frog"
        case .axolotl: return "Axolotl"
        case .star: return "Star"
        case .popIt: return "Pop-it"
        case .cube: return "Fidget cube"
        case .spinner: return "Spinner"
        case .otherSquishy, .otherFidget: return "Other"
        }
    }

    var isFidget: Bool { Self.fidgetChoices.contains(self) }

    static let characterChoices: [CritterSpecies] = [.blob, .cat, .bunny, .bear, .frog, .axolotl, .star]
    static let squishyChoices: [CritterSpecies] = [.blob, .otherSquishy, .cat, .bunny, .bear, .frog, .axolotl, .star]
    static let fidgetChoices: [CritterSpecies] = [.popIt, .otherFidget, .cube, .spinner]
}

enum CritterColor: String, Codable, CaseIterable, Identifiable {
    case grape, bubblegum, tangerine, sunshine, mint, sky, coral, rainbow

    var id: String { rawValue }

    var label: String {
        switch self {
        case .grape: return "Grape"
        case .bubblegum: return "Bubblegum"
        case .tangerine: return "Tangerine"
        case .sunshine: return "Sunshine"
        case .mint: return "Mint"
        case .sky: return "Sky"
        case .coral: return "Coral"
        case .rainbow: return "Rainbow"
        }
    }

    var gradient: [Color] {
        switch self {
        case .grape: return [Color(hex: 0xE2D2FF), Color(hex: 0xB58CFF)]
        case .bubblegum: return [Color(hex: 0xFFD9EA), Color(hex: 0xFF9EC7)]
        case .tangerine: return [Color(hex: 0xFFDDB8), Color(hex: 0xFFA65A)]
        case .sunshine: return [Color(hex: 0xFFF3AE), Color(hex: 0xFFD84D)]
        case .mint: return [Color(hex: 0xD2F9EC), Color(hex: 0x6EE0BE)]
        case .sky: return [Color(hex: 0xD8F0FF), Color(hex: 0x7FCBFF)]
        case .coral: return [Color(hex: 0xFFD0C8), Color(hex: 0xFF8577)]
        case .rainbow: return [Color(hex: 0xFF9EC7), Color(hex: 0xFFD84D), Color(hex: 0x6EE0BE), Color(hex: 0x7FCBFF), Color(hex: 0xB58CFF)]
        }
    }

    var fill: Color { gradient[gradient.count - 1] }

    var pastel: Color {
        switch self {
        case .grape: return Palette.lilac
        case .bubblegum: return Color(hex: 0xFFE6F1)
        case .tangerine: return Palette.peachPastel
        case .sunshine: return Palette.sunshinePastel
        case .mint: return Palette.mintPastel
        case .sky: return Palette.skyPastel
        case .coral: return Color(hex: 0xFFE3DE)
        case .rainbow: return Color(hex: 0xFFF0F7)
        }
    }

    var shade: Color {
        switch self {
        case .grape: return Color(hex: 0x7B3FE4)
        case .bubblegum: return Color(hex: 0xE0558F)
        case .tangerine: return Color(hex: 0xE5731F)
        case .sunshine: return Color(hex: 0xD49E00)
        case .mint: return Color(hex: 0x1FA580)
        case .sky: return Color(hex: 0x2E8FD6)
        case .coral: return Color(hex: 0xE04E3E)
        case .rainbow: return Color(hex: 0x8A5CF0)
        }
    }
}

enum EyeStyle: String, Codable, CaseIterable, Identifiable {
    case dots, sparkle, happy, sleepy, wink
    var id: String { rawValue }
    var label: String {
        switch self {
        case .dots: return "Dots"
        case .sparkle: return "Sparkly"
        case .happy: return "Happy"
        case .sleepy: return "Sleepy"
        case .wink: return "Wink"
        }
    }
}

enum MouthStyle: String, Codable, CaseIterable, Identifiable {
    case smile, grin, tongue, oh, kitty
    var id: String { rawValue }
    var label: String {
        switch self {
        case .smile: return "Smile"
        case .grin: return "Big grin"
        case .tongue: return "Silly"
        case .oh: return "Ooh"
        case .kitty: return "Kitty"
        }
    }
}

enum Accessory: String, Codable, CaseIterable, Identifiable {
    case none, crown, bow, flower, star, glasses, headphones, partyHat
    var id: String { rawValue }
    var label: String {
        switch self {
        case .none: return "Nothing"
        case .crown: return "Crown"
        case .bow: return "Bow"
        case .flower: return "Flower"
        case .star: return "Star clip"
        case .glasses: return "Glasses"
        case .headphones: return "Headphones"
        case .partyHat: return "Party hat"
        }
    }
}

struct CharacterLook: Codable, Equatable {
    var species: CritterSpecies = .blob
    var color: CritterColor = .grape
    var eyes: EyeStyle = .sparkle
    var mouth: MouthStyle = .smile
    var accessory: Accessory = .crown
    var cheeks: Bool = true

    static func random() -> CharacterLook {
        CharacterLook(
            species: CritterSpecies.characterChoices.randomElement() ?? .blob,
            color: CritterColor.allCases.randomElement() ?? .grape,
            eyes: EyeStyle.allCases.randomElement() ?? .dots,
            mouth: MouthStyle.allCases.randomElement() ?? .smile,
            accessory: Accessory.allCases.randomElement() ?? .none,
            cheeks: Bool.random()
        )
    }
}

struct Profile: Codable, Equatable {
    static let defaultBuddyName = "Pip"

    var nickname: String
    var buddyName: String
    var look: CharacterLook

    var shelfTitle: String { "My happy shelf" }

    static func resolvedBuddyName(_ input: String) -> String {
        let name = input.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? defaultBuddyName : name
    }

    static let sample = Profile(nickname: "Juniper", buddyName: defaultBuddyName, look: CharacterLook())
}

enum ItemKind: String, Codable, CaseIterable, Identifiable {
    case squishy, fidget
    var id: String { rawValue }
    var label: String { self == .squishy ? "Squishy" : "Fidget" }
}

enum FeelTag: String, Codable, CaseIterable, Identifiable {
    case soft, slowRise, squeezy, stretchy, clicky, poppy, sparkly, scented, glowy
    var id: String { rawValue }
    var label: String {
        switch self {
        case .soft: return "Soft"
        case .slowRise: return "Slow-rise"
        case .squeezy: return "Squeezy"
        case .stretchy: return "Stretchy"
        case .clicky: return "Clicky"
        case .poppy: return "Poppy"
        case .sparkly: return "Sparkly"
        case .scented: return "Smells yummy"
        case .glowy: return "Glows"
        }
    }
    var color: Color {
        switch self {
        case .soft, .scented: return Palette.bubblegum
        case .slowRise, .glowy: return Palette.mintPastel
        case .squeezy, .poppy: return Palette.sunshinePastel
        case .stretchy, .sparkly: return Palette.lilac
        case .clicky: return Palette.skyPastel
        }
    }
}

struct CollectionItem: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var kind: ItemKind
    var species: CritterSpecies
    var color: CritterColor
    var tags: [FeelTag] = []
    var notes: String = ""
    var isFavorite = false
    var photoFileName: String?
    /// Bundled illustration used instead of the drawn critter (sample toys only).
    var artName: String?
    var createdAt = Date()

    var subtitle: String { "\(kind.label) · \(species.label)" }

    static let samples: [CollectionItem] = [
        CollectionItem(name: "Peachy", kind: .squishy, species: .axolotl, color: .bubblegum, tags: [.soft, .slowRise], notes: "My favorite squishy! I got Peachy for my birthday.", isFavorite: true, artName: "ArtPeachy"),
        CollectionItem(name: "Rainbow Pop", kind: .fidget, species: .popIt, color: .rainbow, tags: [.poppy, .clicky], artName: "ArtRainbowPop"),
        CollectionItem(name: "Mochi", kind: .squishy, species: .cat, color: .tangerine, tags: [.squeezy], artName: "ArtMochi"),
        CollectionItem(name: "Pickles", kind: .squishy, species: .frog, color: .mint, tags: [.stretchy], isFavorite: true, artName: "ArtPickles"),
        CollectionItem(name: "Sunny", kind: .squishy, species: .star, color: .sunshine, tags: [.sparkly, .glowy], artName: "ArtSunny"),
        CollectionItem(name: "Blue Bean", kind: .squishy, species: .bunny, color: .sky, tags: [.soft, .scented]),
        CollectionItem(name: "Clicky Cube", kind: .fidget, species: .cube, color: .grape, tags: [.clicky]),
    ]
}

enum CollectionFilter: String, CaseIterable, Identifiable {
    case all, squishys, fidgets, faves
    var id: String { rawValue }
    var label: String {
        switch self {
        case .all: return "All"
        case .squishys: return "Squishies"
        case .fidgets: return "Fidgets"
        case .faves: return "Faves"
        }
    }
    var systemImage: String {
        switch self {
        case .all: return "sparkles"
        case .squishys: return "cloud.fill"
        case .fidgets: return "circle.grid.3x3.fill"
        case .faves: return "heart.fill"
        }
    }
}

extension Array where Element == CollectionItem {
    func filtered(_ filter: CollectionFilter, search: String = "") -> [CollectionItem] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return self.filter { item in
            switch filter {
            case .all: break
            case .squishys: if item.kind != .squishy { return false }
            case .fidgets: if item.kind != .fidget { return false }
            case .faves: if !item.isFavorite { return false }
            }
            guard !query.isEmpty else { return true }
            let haystack = [item.name, item.species.label, item.kind.label, item.notes] + item.tags.map(\.label)
            return haystack.contains { $0.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
        }
    }
}
