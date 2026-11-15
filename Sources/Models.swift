import Foundation
import SpriteKit

// MARK: - Visual & Audio Time-Machine Modes (1991 VGA/Amiga ↔ 2026 120Hz HD Cartoon)

enum VisualTheme: String, Codable, CaseIterable {
    case hdOverdrive
    case crtCabinet
    case retro1991

    var label: String {
        switch self {
        case .hdOverdrive: return "2026 HD CARTOON"
        case .crtCabinet:  return "CRT ARCADE"
        case .retro1991:   return "1991 VGA RETRO"
        }
    }

    var shortBadge: String {
        switch self {
        case .hdOverdrive: return "2026 HD"
        case .crtCabinet:  return "CRT"
        case .retro1991:   return "1991 VGA"
        }
    }

    func next() -> VisualTheme {
        let all = Self.allCases
        let idx = all.firstIndex(of: self) ?? 0
        return all[(idx + 1) % all.count]
    }
}

enum AudioChipMode: String, Codable, CaseIterable {
    case modernSynth
    case retroAdLib

    var label: String {
        switch self {
        case .modernSynth: return "TROPICAL MARIMBA"
        case .retroAdLib:  return "1991 ADLIB FM"
        }
    }

    var shortBadge: String {
        switch self {
        case .modernSynth: return "MARIMBA"
        case .retroAdLib:  return "ADLIB FM"
        }
    }

    func next() -> AudioChipMode {
        self == .modernSynth ? .retroAdLib : .modernSynth
    }
}

enum DifficultyRank: String, Codable, CaseIterable {
    case hungry
    case ravenous
    case stoneKing

    var label: String {
        switch self {
        case .hungry:    return "HUNGRY (CASUAL)"
        case .ravenous:  return "RAVENOUS (ARCADE)"
        case .stoneKing: return "STONE KING (PRO)"
        }
    }

    var startingHearts: Int {
        switch self {
        case .hungry:    return 5
        case .ravenous:  return 4
        case .stoneKing: return 3
        }
    }

    var enemySpeedMultiplier: CGFloat {
        switch self {
        case .hungry:    return 0.85
        case .ravenous:  return 1.00
        case .stoneKing: return 1.22
        }
    }
}

// MARK: - Boga's Club Upgrades, Giant Stone Age Food & Treasures

enum ClubTier: Int, Codable, CaseIterable {
    case oakClub = 0
    case stoneMallet = 1
    case boneHammer = 2

    var displayName: String {
        switch self {
        case .oakClub:     return "OAK CLUB"
        case .stoneMallet: return "STONE MALLET"
        case .boneHammer:  return "BONE HAMMER"
        }
    }

    var reach: CGFloat {
        switch self {
        case .oakClub:     return 70
        case .stoneMallet: return 84
        case .boneHammer:  return 98
        }
    }

    var power: Int {
        switch self {
        case .oakClub:     return 1
        case .stoneMallet: return 2
        case .boneHammer:  return 3
        }
    }
}

enum FoodKind: String, Codable, CaseIterable {
    case mammothDrumstick
    case stoneBurger
    case giantPineapple
    case honeycomb
    case goldenBanana
    case iceCreamSundae
    case megaCroissant

    var displayName: String {
        switch self {
        case .mammothDrumstick: return "MAMMOTH DRUMSTICK"
        case .stoneBurger:      return "STONE BURGER"
        case .giantPineapple:   return "GIANT PINEAPPLE"
        case .honeycomb:        return "HONEYCOMB"
        case .goldenBanana:     return "GOLDEN BANANAS"
        case .iceCreamSundae:   return "GLACIER SUNDAE"
        case .megaCroissant:    return "MEGA-CROISSANT!"
        }
    }

    var feastPercent: Int {
        switch self {
        case .mammothDrumstick: return 15
        case .stoneBurger:      return 18
        case .giantPineapple:   return 12
        case .honeycomb:        return 14
        case .goldenBanana:     return 10
        case .iceCreamSundae:   return 20
        case .megaCroissant:    return 28
        }
    }

    var points: Int {
        switch self {
        case .mammothDrumstick: return 400
        case .stoneBurger:      return 500
        case .giantPineapple:   return 250
        case .honeycomb:        return 350
        case .goldenBanana:     return 200
        case .iceCreamSundae:   return 600
        case .megaCroissant:    return 1000
        }
    }
}

enum TreasureKind: String, Codable, CaseIterable {
    case stoneWheel
    case amberGem
    case malletUpgrade
    case boneHammerUpgrade
    case vitalitySteak

    var points: Int {
        switch self {
        case .stoneWheel:        return 450
        case .amberGem:          return 850
        case .malletUpgrade:     return 600
        case .boneHammerUpgrade: return 900
        case .vitalitySteak:     return 500
        }
    }
}

enum PrehistoricWorldID: Int, Codable, CaseIterable {
    case palmJungle = 1
    case amberCavern = 2
    case magmaRidge = 3
    case glacierPeak = 4
    case volcanoRexArena = 5

    var title: String {
        switch self {
        case .palmJungle:      return "1 • PALM JUNGLE CANYON"
        case .amberCavern:     return "2 • AMBER CAVERN GROTTO"
        case .magmaRidge:      return "3 • MAGMA GEYSER RIDGE"
        case .glacierPeak:     return "4 • GLACIER MAMMOTH PEAK"
        case .volcanoRexArena: return "5 • VOLCANO REX ARENA"
        }
    }

    var shortName: String {
        switch self {
        case .palmJungle:      return "PALM JUNGLE"
        case .amberCavern:     return "AMBER CAVERN"
        case .magmaRidge:      return "MAGMA RIDGE"
        case .glacierPeak:     return "GLACIER PEAK"
        case .volcanoRexArena: return "VOLCANO REX"
        }
    }

    var subtitle: String {
        switch self {
        case .palmJungle:      return "Bouncy Palm Fronds, Grumpy Raptors & Tree-Canopy Secrets!"
        case .amberCavern:     return "Glowing Stalactites, Bouncy Mushrooms & Sleepy Cave Bears!"
        case .magmaRidge:      return "Lava Vents, Charging Triceratops & Stone-Wheel Zip Ledges!"
        case .glacierPeak:     return "Slippery Ice Slides, Snowball Yetis & Frozen Sundae Caches!"
        case .volcanoRexArena: return "Bonk Spicy Peppers & Outsmart Giant King Chomper T-Rex!"
        }
    }

    var nextWorld: PrehistoricWorldID? {
        PrehistoricWorldID(rawValue: self.rawValue + 1)
    }
}

enum DinoEnemyKind: String, Codable {
    case raptorScout
    case pterodactyl
    case caveBear
    case triceratops
    case snowYeti

    var points: Int {
        switch self {
        case .raptorScout: return 500
        case .pterodactyl: return 600
        case .caveBear:    return 750
        case .triceratops: return 850
        case .snowYeti:    return 800
        }
    }

    var maxStamina: Int {
        switch self {
        case .raptorScout: return 1
        case .pterodactyl: return 1
        case .caveBear:    return 2
        case .triceratops: return 2
        case .snowYeti:    return 2
        }
    }
}

// MARK: - Color Palettes (HD Painted Stone Age Cartoon + Authentic 1991 16-Color VGA/Amiga)

enum Palette {
    // Authentic 16-Color 1991 VGA / Amiga Palette
    static let vgaBlack        = SKColor.hex(0x000000)
    static let vgaBlue         = SKColor.hex(0x1D2B53)
    static let vgaGreen        = SKColor.hex(0x008751)
    static let vgaCyan         = SKColor.hex(0x29ADFF)
    static let vgaRed          = SKColor.hex(0xBE1250)
    static let vgaPurple       = SKColor.hex(0x7E2553)
    static let vgaBrown        = SKColor.hex(0xAB5236)
    static let vgaLightGrey    = SKColor.hex(0xC2C3C7)
    static let vgaDarkGrey     = SKColor.hex(0x5F574F)
    static let vgaBrightBlue   = SKColor.hex(0x3B78FF)
    static let vgaBrightGreen  = SKColor.hex(0x00E436)
    static let vgaBrightCyan   = SKColor.hex(0x83ECEF)
    static let vgaOrangeRed    = SKColor.hex(0xFF6C24)
    static let vgaMagenta      = SKColor.hex(0xFF77A8)
    static let vgaYellow       = SKColor.hex(0xFFEC27)
    static let vgaWhite        = SKColor.hex(0xFFF1E8)

    // 2026 HD Stone Age Cartoon Colors
    static let nightJungleBg   = SKColor.hex(0x121B28)
    static let cardWoodDark    = SKColor.hex(0x241710)
    static let cardStoneBg     = SKColor.hex(0x1A2436)
    static let amberGold       = SKColor.hex(0xFFD23F)
    static let volcanoOrange   = SKColor.hex(0xFF6B2B)
    static let clubCrimson     = SKColor.hex(0xF23838)
    static let jungleEmerald   = SKColor.hex(0x2EE573)
    static let tropicalSky     = SKColor.hex(0x36B5FF)
    static let leopardGold     = SKColor.hex(0xFFB627)
    static let boneCream       = SKColor.hex(0xFFF4D9)
    static let berryPurple     = SKColor.hex(0xA64DFF)
    static let glacierCyan     = SKColor.hex(0x64E9FF)
}

// MARK: - Trophy Cave Medals, High Scores & Persistent Save State

struct HighScoreEntry: Codable {
    var initials: String
    var score: Int
    var worldReached: Int
    var modeTag: String
}

struct PlayerSettings: Codable {
    var visualTheme: VisualTheme = .hdOverdrive
    var audioChip: AudioChipMode = .modernSynth
    var difficulty: DifficultyRank = .ravenous
    var screenShakeEnabled: Bool = true
    var musicVolume: Float = 0.80
    var sfxVolume: Float = 0.85
    var launchFullscreen: Bool = false
}

struct SavePayload: Codable {
    var settings: PlayerSettings = PlayerSettings()
    var highestUnlockedWorld: Int = 5 // All quick worlds accessible while tracking full Adventure mastery
    var highScores: [HighScoreEntry] = [
        HighScoreEntry(initials: "BOG", score: 28500, worldReached: 5, modeTag: "ADVENTURE"),
        HighScoreEntry(initials: "NGD", score: 22400, worldReached: 5, modeTag: "BOSS REX"),
        HighScoreEntry(initials: "OAK", score: 17800, worldReached: 4, modeTag: "GLIDER"),
        HighScoreEntry(initials: "YUM", score: 13200, worldReached: 3, modeTag: "RUSH"),
        HighScoreEntry(initials: "VGA", score: 9600,  worldReached: 2, modeTag: "1991 MODE")
    ]
    var unlockedMedals: Set<String> = []
    var totalBonks: Int = 0
    var totalFoodsGobbled: Int = 0
    var bossesDefeated: Int = 0
    var stagesCleared: Int = 0
}

struct MedalDefinition {
    let id: String
    let title: String
    let subtitle: String
}

enum AchievementCatalog {
    static let all: [MedalDefinition] = [
        MedalDefinition(id: "first_bonk",       title: "FIRST DINO BONK!",     subtitle: "Knock an angry prehistoric critter dizzy with your club"),
        MedalDefinition(id: "full_belly",       title: "100% FULL BELLY!",     subtitle: "Fill the Stone Age Feast Meter to 100% on any stage"),
        MedalDefinition(id: "canopy_shaker",    title: "CANOPY SHAKER",        subtitle: "Shake hidden giant food from a tree with Ground-Pound"),
        MedalDefinition(id: "secret_cracker",   title: "STONE BLOCK BUSTER",   subtitle: "Smash open a secret cracked stone cache"),
        MedalDefinition(id: "bone_hammer_pro",  title: "MEGA BONE HAMMER",     subtitle: "Upgrade Boga's weapon all the way to the Bone Hammer"),
        MedalDefinition(id: "sky_glider_ace",   title: "BAMBOO SKY GLIDER",    subtitle: "Complete the Hang-Glider Sky Feast Bonus stage"),
        MedalDefinition(id: "glacier_surfer",   title: "GLACIER MAMMOTH ACE",  subtitle: "Conquer the slippery Glacier Mammoth Peak"),
        MedalDefinition(id: "rex_tamer",        title: "KING CHOMPER TAMED!",  subtitle: "Defeat the giant comical King Chomper T-Rex Boss"),
        MedalDefinition(id: "spit_roast_chef",  title: "CAMPFIRE PITMASTER",   subtitle: "Flip the sizzling Mammoth Spit-Roast on the Title Screen"),
        MedalDefinition(id: "time_caveman_91",  title: "1991 TIME CAVEMAN",    subtitle: "Play in live 1991 16-Color VGA + AdLib FM Chiptune mode"),
        MedalDefinition(id: "gourmet_combo",    title: "MEGA FEAST GOURMET",   subtitle: "Overfill the Feast Meter past 130% in a single stage"),
        MedalDefinition(id: "stone_king_champ", title: "STONE AGE CHAMPION",   subtitle: "Clear all 5 Prehistoric Worlds in Adventure Mode")
    ]
}

@MainActor
final class PersistenceManager {
    static let shared = PersistenceManager()
    private let key = "com.ngd.dinoclub.save.v1"
    private(set) var data: SavePayload

    private init() {
        if let raw = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(SavePayload.self, from: raw) {
            self.data = decoded
        } else {
            self.data = SavePayload()
        }
    }

    private func save() {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }

    func updateSettings(_ block: (inout PlayerSettings) -> Void) {
        block(&data.settings)
        save()
    }

    @discardableResult
    func unlockMedal(_ id: String) -> MedalDefinition? {
        guard !data.unlockedMedals.contains(id) else { return nil }
        data.unlockedMedals.insert(id)
        save()
        return AchievementCatalog.all.first { $0.id == id }
    }

    func recordBonk() {
        data.totalBonks += 1
        save()
    }

    func recordFoodGobbled() {
        data.totalFoodsGobbled += 1
        save()
    }

    func recordStageCleared(world: Int) {
        data.stagesCleared += 1
        data.highestUnlockedWorld = max(data.highestUnlockedWorld, min(5, world + 1))
        save()
    }

    func recordBossDefeated() {
        data.bossesDefeated += 1
        save()
    }

    func recordHighScore(initials: String, score: Int, worldReached: Int, modeTag: String) {
        guard score > 0 else { return }
        data.highScores.append(HighScoreEntry(initials: initials, score: score, worldReached: worldReached, modeTag: modeTag))
        data.highScores.sort { $0.score > $1.score }
        if data.highScores.count > 8 {
            data.highScores = Array(data.highScores.prefix(8))
        }
        save()
    }
}
