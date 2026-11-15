import Foundation
import CoreGraphics
import SpriteKit

struct PlatformDef {
    let x: CGFloat       // Center X in world coordinates
    let topY: CGFloat    // Walkable top Y (ground baseline is 175)
    let width: CGFloat
    var isGround: Bool = false
    var isIce: Bool = false
    var moveAmpX: CGFloat = 0
    var moveSpeed: Double = 0
    var canopyFood: FoodKind? = nil // Dropped when Boga Ground-Pounds nearby!
}

struct SpringPadDef {
    let x: CGFloat
    let y: CGFloat
    let isMushroom: Bool
}

struct SecretBlockDef {
    let x: CGFloat
    let y: CGFloat
    let rewardFood: FoodKind?
    let rewardTreasure: TreasureKind?
}

struct GeyserVentDef {
    let x: CGFloat
    let baseY: CGFloat
    let maxHeight: CGFloat
    let phase: Double
}

struct EnemySpawnDef {
    let kind: DinoEnemyKind
    let x: CGFloat
    let y: CGFloat
    let minX: CGFloat
    let maxX: CGFloat
    let speed: CGFloat
}

struct FoodSpawnDef {
    let kind: FoodKind
    let x: CGFloat
    let y: CGFloat
}

struct TreasureSpawnDef {
    let kind: TreasureKind
    let x: CGFloat
    let y: CGFloat
}

struct StageBlueprint {
    let world: PrehistoricWorldID
    let worldWidth: CGFloat
    let timeLimit: Double
    let exitX: CGFloat
    let exitY: CGFloat
    let skyTopHex: UInt32
    let skyBotHex: UInt32
    let groundFillHex: UInt32
    let groundTurfHex: UInt32
    let platforms: [PlatformDef]
    let springs: [SpringPadDef]
    let secretBlocks: [SecretBlockDef]
    let geysers: [GeyserVentDef]
    let enemies: [EnemySpawnDef]
    let foods: [FoodSpawnDef]
    let treasures: [TreasureSpawnDef]
    let isBossArena: Bool
}

enum LevelCatalog {

    static func blueprint(for world: PrehistoricWorldID) -> StageBlueprint {
        switch world {
        case .palmJungle:
            return palmJungleStage()
        case .amberCavern:
            return amberCavernStage()
        case .magmaRidge:
            return magmaRidgeStage()
        case .glacierPeak:
            return glacierPeakStage()
        case .volcanoRexArena:
            return volcanoBossStage()
        }
    }

    // MARK: - World 1: Palm Jungle Canyon

    private static func palmJungleStage() -> StageBlueprint {
        let plats: [PlatformDef] = [
            PlatformDef(x: 520,  topY: 175, width: 1080, isGround: true, canopyFood: .megaCroissant),
            PlatformDef(x: 1580, topY: 175, width: 880,  isGround: true, canopyFood: .stoneBurger),
            PlatformDef(x: 2440, topY: 175, width: 720,  isGround: true),

            PlatformDef(x: 470,  topY: 285, width: 210, canopyFood: .mammothDrumstick),
            PlatformDef(x: 780,  topY: 365, width: 220),
            PlatformDef(x: 1100, topY: 295, width: 210),
            PlatformDef(x: 1420, topY: 385, width: 230, canopyFood: .megaCroissant),
            PlatformDef(x: 1760, topY: 300, width: 210),
            PlatformDef(x: 2050, topY: 405, width: 220)
        ]

        let springs: [SpringPadDef] = [
            SpringPadDef(x: 635,  y: 192, isMushroom: false),
            SpringPadDef(x: 1265, y: 192, isMushroom: false),
            SpringPadDef(x: 1900, y: 192, isMushroom: false)
        ]

        let blocks: [SecretBlockDef] = [
            SecretBlockDef(x: 540,  y: 325, rewardFood: .stoneBurger, rewardTreasure: nil),
            SecretBlockDef(x: 840,  y: 405, rewardFood: nil, rewardTreasure: .malletUpgrade),
            SecretBlockDef(x: 1480, y: 425, rewardFood: .megaCroissant, rewardTreasure: .amberGem)
        ]

        let enemies: [EnemySpawnDef] = [
            EnemySpawnDef(kind: .raptorScout, x: 580,  y: 205, minX: 390,  maxX: 880,  speed: 105),
            EnemySpawnDef(kind: .raptorScout, x: 800,  y: 395, minX: 690,  maxX: 870,  speed: 90),
            EnemySpawnDef(kind: .pterodactyl, x: 1080, y: 445, minX: 920,  maxX: 1320, speed: 125),
            EnemySpawnDef(kind: .raptorScout, x: 1560, y: 205, minX: 1260, maxX: 1860, speed: 115),
            EnemySpawnDef(kind: .pterodactyl, x: 1920, y: 455, minX: 1720, maxX: 2180, speed: 130),
            EnemySpawnDef(kind: .raptorScout, x: 2260, y: 205, minX: 2120, maxX: 2450, speed: 110)
        ]

        let foods: [FoodSpawnDef] = [
            FoodSpawnDef(kind: .goldenBanana,     x: 360,  y: 225),
            FoodSpawnDef(kind: .giantPineapple,   x: 470,  y: 332),
            FoodSpawnDef(kind: .mammothDrumstick, x: 690,  y: 225),
            FoodSpawnDef(kind: .stoneBurger,      x: 780,  y: 415),
            FoodSpawnDef(kind: .honeycomb,        x: 1100, y: 345),
            FoodSpawnDef(kind: .giantPineapple,   x: 1320, y: 225),
            FoodSpawnDef(kind: .mammothDrumstick, x: 1420, y: 435),
            FoodSpawnDef(kind: .goldenBanana,     x: 1680, y: 225),
            FoodSpawnDef(kind: .stoneBurger,      x: 1760, y: 350),
            FoodSpawnDef(kind: .iceCreamSundae,   x: 2050, y: 455),
            FoodSpawnDef(kind: .mammothDrumstick, x: 2240, y: 225)
        ]

        let treasures: [TreasureSpawnDef] = [
            TreasureSpawnDef(kind: .stoneWheel, x: 635,  y: 360),
            TreasureSpawnDef(kind: .amberGem,   x: 1265, y: 380),
            TreasureSpawnDef(kind: .stoneWheel, x: 1900, y: 390),
            TreasureSpawnDef(kind: .amberGem,   x: 2360, y: 230)
        ]

        return StageBlueprint(
            world: .palmJungle,
            worldWidth: 2720,
            timeLimit: 120,
            exitX: 2540,
            exitY: 225,
            skyTopHex: 0x1B7BE0,
            skyBotHex: 0x7CE8FF,
            groundFillHex: 0x7A4421,
            groundTurfHex: 0x2FD663,
            platforms: plats,
            springs: springs,
            secretBlocks: blocks,
            geysers: [],
            enemies: enemies,
            foods: foods,
            treasures: treasures,
            isBossArena: false
        )
    }

    // MARK: - World 2: Amber Cavern Grotto

    private static func amberCavernStage() -> StageBlueprint {
        let plats: [PlatformDef] = [
            PlatformDef(x: 490,  topY: 175, width: 1020, isGround: true),
            PlatformDef(x: 1520, topY: 175, width: 820,  isGround: true, canopyFood: .honeycomb),
            PlatformDef(x: 2420, topY: 175, width: 760,  isGround: true),

            PlatformDef(x: 460,  topY: 295, width: 210),
            PlatformDef(x: 790,  topY: 385, width: 230, canopyFood: .megaCroissant),
            PlatformDef(x: 1055, topY: 280, width: 190),
            PlatformDef(x: 1380, topY: 375, width: 220),
            PlatformDef(x: 1710, topY: 440, width: 220, canopyFood: .stoneBurger),
            PlatformDef(x: 2040, topY: 320, width: 220)
        ]

        let springs: [SpringPadDef] = [
            SpringPadDef(x: 615,  y: 192, isMushroom: true),
            SpringPadDef(x: 1210, y: 192, isMushroom: true),
            SpringPadDef(x: 1555, y: 192, isMushroom: true),
            SpringPadDef(x: 2180, y: 192, isMushroom: true)
        ]

        let blocks: [SecretBlockDef] = [
            SecretBlockDef(x: 460,  y: 335, rewardFood: .honeycomb, rewardTreasure: .amberGem),
            SecretBlockDef(x: 1380, y: 415, rewardFood: .megaCroissant, rewardTreasure: .malletUpgrade),
            SecretBlockDef(x: 2040, y: 360, rewardFood: .iceCreamSundae, rewardTreasure: .vitalitySteak)
        ]

        let enemies: [EnemySpawnDef] = [
            EnemySpawnDef(kind: .caveBear,    x: 620,  y: 205, minX: 410,  maxX: 860,  speed: 88),
            EnemySpawnDef(kind: .pterodactyl, x: 960,  y: 440, minX: 760,  maxX: 1180, speed: 120),
            EnemySpawnDef(kind: .caveBear,    x: 1480, y: 205, minX: 1220, maxX: 1780, speed: 95),
            EnemySpawnDef(kind: .raptorScout, x: 1710, y: 470, minX: 1620, maxX: 1800, speed: 95),
            EnemySpawnDef(kind: .caveBear,    x: 2260, y: 205, minX: 2100, maxX: 2440, speed: 98)
        ]

        let foods: [FoodSpawnDef] = [
            FoodSpawnDef(kind: .honeycomb,        x: 350,  y: 225),
            FoodSpawnDef(kind: .mammothDrumstick, x: 790,  y: 435),
            FoodSpawnDef(kind: .giantPineapple,   x: 1055, y: 330),
            FoodSpawnDef(kind: .stoneBurger,      x: 1290, y: 225),
            FoodSpawnDef(kind: .honeycomb,        x: 1555, y: 380),
            FoodSpawnDef(kind: .megaCroissant,    x: 1710, y: 490),
            FoodSpawnDef(kind: .mammothDrumstick, x: 1920, y: 225),
            FoodSpawnDef(kind: .stoneBurger,      x: 2220, y: 225)
        ]

        let treasures: [TreasureSpawnDef] = [
            TreasureSpawnDef(kind: .amberGem,   x: 615,  y: 370),
            TreasureSpawnDef(kind: .amberGem,   x: 1210, y: 370),
            TreasureSpawnDef(kind: .stoneWheel, x: 1840, y: 230),
            TreasureSpawnDef(kind: .amberGem,   x: 2180, y: 385)
        ]

        return StageBlueprint(
            world: .amberCavern,
            worldWidth: 2720,
            timeLimit: 125,
            exitX: 2540,
            exitY: 225,
            skyTopHex: 0x1A1033,
            skyBotHex: 0x3D235E,
            groundFillHex: 0x3B2B4A,
            groundTurfHex: 0xFFA62B,
            platforms: plats,
            springs: springs,
            secretBlocks: blocks,
            geysers: [],
            enemies: enemies,
            foods: foods,
            treasures: treasures,
            isBossArena: false
        )
    }

    // MARK: - World 3: Magma Geyser Ridge

    private static func magmaRidgeStage() -> StageBlueprint {
        let plats: [PlatformDef] = [
            PlatformDef(x: 460,  topY: 175, width: 960, isGround: true),
            PlatformDef(x: 1480, topY: 175, width: 760, isGround: true),
            PlatformDef(x: 2420, topY: 175, width: 760, isGround: true),

            // Moving Obsidian & Stone-Wheel Zip Platforms!
            PlatformDef(x: 720,  topY: 300, width: 200, moveAmpX: 85,  moveSpeed: 1.5),
            PlatformDef(x: 1030, topY: 365, width: 210, moveAmpX: 95,  moveSpeed: 1.7),
            PlatformDef(x: 1440, topY: 320, width: 220, canopyFood: .stoneBurger),
            PlatformDef(x: 1760, topY: 410, width: 200, moveAmpX: 90,  moveSpeed: 1.6),
            PlatformDef(x: 2040, topY: 310, width: 210, moveAmpX: 80,  moveSpeed: 1.8)
        ]

        let springs: [SpringPadDef] = [
            SpringPadDef(x: 520,  y: 192, isMushroom: false),
            SpringPadDef(x: 1620, y: 192, isMushroom: false)
        ]

        let blocks: [SecretBlockDef] = [
            SecretBlockDef(x: 1440, y: 360, rewardFood: .megaCroissant, rewardTreasure: .boneHammerUpgrade),
            SecretBlockDef(x: 2240, y: 215, rewardFood: .stoneBurger, rewardTreasure: .amberGem)
        ]

        let geysers: [GeyserVentDef] = [
            GeyserVentDef(x: 980,  baseY: 165, maxHeight: 155, phase: 0.0),
            GeyserVentDef(x: 1920, baseY: 165, maxHeight: 165, phase: 1.6)
        ]

        let enemies: [EnemySpawnDef] = [
            EnemySpawnDef(kind: .triceratops, x: 640,  y: 205, minX: 360,  maxX: 860,  speed: 120),
            EnemySpawnDef(kind: .pterodactyl, x: 1120, y: 455, minX: 900,  maxX: 1360, speed: 135),
            EnemySpawnDef(kind: .triceratops, x: 1520, y: 205, minX: 1200, maxX: 1780, speed: 128),
            EnemySpawnDef(kind: .raptorScout, x: 2220, y: 205, minX: 2080, maxX: 2440, speed: 118),
            EnemySpawnDef(kind: .triceratops, x: 2380, y: 205, minX: 2120, maxX: 2480, speed: 122)
        ]

        let foods: [FoodSpawnDef] = [
            FoodSpawnDef(kind: .mammothDrumstick, x: 360,  y: 225),
            FoodSpawnDef(kind: .stoneBurger,      x: 720,  y: 355),
            FoodSpawnDef(kind: .giantPineapple,   x: 1030, y: 420),
            FoodSpawnDef(kind: .mammothDrumstick, x: 1280, y: 225),
            FoodSpawnDef(kind: .honeycomb,        x: 1620, y: 375),
            FoodSpawnDef(kind: .stoneBurger,      x: 1760, y: 465),
            FoodSpawnDef(kind: .megaCroissant,    x: 2040, y: 365),
            FoodSpawnDef(kind: .mammothDrumstick, x: 2320, y: 225)
        ]

        let treasures: [TreasureSpawnDef] = [
            TreasureSpawnDef(kind: .stoneWheel, x: 520,  y: 360),
            TreasureSpawnDef(kind: .amberGem,   x: 1180, y: 240),
            TreasureSpawnDef(kind: .stoneWheel, x: 1860, y: 245),
            TreasureSpawnDef(kind: .amberGem,   x: 2420, y: 240)
        ]

        return StageBlueprint(
            world: .magmaRidge,
            worldWidth: 2720,
            timeLimit: 125,
            exitX: 2540,
            exitY: 225,
            skyTopHex: 0x381217,
            skyBotHex: 0xA8381E,
            groundFillHex: 0x2B1E22,
            groundTurfHex: 0xFF6B2B,
            platforms: plats,
            springs: springs,
            secretBlocks: blocks,
            geysers: geysers,
            enemies: enemies,
            foods: foods,
            treasures: treasures,
            isBossArena: false
        )
    }

    // MARK: - World 4: Glacier Mammoth Peak

    private static func glacierPeakStage() -> StageBlueprint {
        let plats: [PlatformDef] = [
            PlatformDef(x: 500,  topY: 175, width: 1040, isGround: true, isIce: true, canopyFood: .iceCreamSundae),
            PlatformDef(x: 1520, topY: 175, width: 840,  isGround: true, isIce: true),
            PlatformDef(x: 2420, topY: 175, width: 760,  isGround: true, isIce: true),

            PlatformDef(x: 480,  topY: 290, width: 230, isIce: true),
            PlatformDef(x: 820,  topY: 380, width: 230, isIce: true, canopyFood: .megaCroissant),
            PlatformDef(x: 1140, topY: 300, width: 210, isIce: true),
            PlatformDef(x: 1480, topY: 400, width: 240, isIce: true),
            PlatformDef(x: 1820, topY: 315, width: 220, isIce: true),
            PlatformDef(x: 2120, topY: 410, width: 220, isIce: true)
        ]

        let springs: [SpringPadDef] = [
            SpringPadDef(x: 650,  y: 192, isMushroom: true),
            SpringPadDef(x: 1320, y: 192, isMushroom: true),
            SpringPadDef(x: 1960, y: 192, isMushroom: true)
        ]

        let blocks: [SecretBlockDef] = [
            SecretBlockDef(x: 820,  y: 420, rewardFood: .iceCreamSundae, rewardTreasure: .boneHammerUpgrade),
            SecretBlockDef(x: 1480, y: 440, rewardFood: .megaCroissant, rewardTreasure: .vitalitySteak)
        ]

        let enemies: [EnemySpawnDef] = [
            EnemySpawnDef(kind: .snowYeti,    x: 610,  y: 205, minX: 400,  maxX: 880,  speed: 92),
            EnemySpawnDef(kind: .caveBear,    x: 820,  y: 410, minX: 730,  maxX: 910,  speed: 85),
            EnemySpawnDef(kind: .snowYeti,    x: 1460, y: 205, minX: 1200, maxX: 1760, speed: 98),
            EnemySpawnDef(kind: .pterodactyl, x: 1760, y: 465, minX: 1540, maxX: 1980, speed: 128),
            EnemySpawnDef(kind: .snowYeti,    x: 2260, y: 205, minX: 2100, maxX: 2450, speed: 100)
        ]

        let foods: [FoodSpawnDef] = [
            FoodSpawnDef(kind: .iceCreamSundae,   x: 380,  y: 225),
            FoodSpawnDef(kind: .goldenBanana,     x: 480,  y: 340),
            FoodSpawnDef(kind: .iceCreamSundae,   x: 720,  y: 225),
            FoodSpawnDef(kind: .stoneBurger,      x: 1140, y: 350),
            FoodSpawnDef(kind: .iceCreamSundae,   x: 1380, y: 225),
            FoodSpawnDef(kind: .mammothDrumstick, x: 1820, y: 365),
            FoodSpawnDef(kind: .megaCroissant,    x: 2120, y: 460),
            FoodSpawnDef(kind: .iceCreamSundae,   x: 2340, y: 225)
        ]

        let treasures: [TreasureSpawnDef] = [
            TreasureSpawnDef(kind: .amberGem,   x: 650,  y: 375),
            TreasureSpawnDef(kind: .stoneWheel, x: 1320, y: 375),
            TreasureSpawnDef(kind: .amberGem,   x: 1960, y: 385)
        ]

        return StageBlueprint(
            world: .glacierPeak,
            worldWidth: 2720,
            timeLimit: 125,
            exitX: 2540,
            exitY: 225,
            skyTopHex: 0x164E87,
            skyBotHex: 0xA8F2FF,
            groundFillHex: 0x2F5E85,
            groundTurfHex: 0xDCF8FF,
            platforms: plats,
            springs: springs,
            secretBlocks: blocks,
            geysers: [],
            enemies: enemies,
            foods: foods,
            treasures: treasures,
            isBossArena: false
        )
    }

    // MARK: - World 5: Volcano Rex Arena (King Chomper T-Rex Boss Showdown!)

    private static func volcanoBossStage() -> StageBlueprint {
        // Single-screen 1280px arena framed strictly inside Universal Safe Box x: 155..1125!
        let plats: [PlatformDef] = [
            PlatformDef(x: 640, topY: 175, width: 1120, isGround: true),
            PlatformDef(x: 315, topY: 305, width: 175),
            PlatformDef(x: 640, topY: 385, width: 185),
            PlatformDef(x: 965, topY: 305, width: 175)
        ]

        let springs: [SpringPadDef] = [
            SpringPadDef(x: 205, y: 192, isMushroom: false),
            SpringPadDef(x: 1075, y: 192, isMushroom: false)
        ]

        let foods: [FoodSpawnDef] = [
            FoodSpawnDef(kind: .mammothDrumstick, x: 315, y: 355),
            FoodSpawnDef(kind: .stoneBurger,      x: 640, y: 435),
            FoodSpawnDef(kind: .megaCroissant,    x: 965, y: 355)
        ]

        let treasures: [TreasureSpawnDef] = [
            TreasureSpawnDef(kind: .boneHammerUpgrade, x: 465, y: 225)
        ]

        return StageBlueprint(
            world: .volcanoRexArena,
            worldWidth: 1280,
            timeLimit: 150,
            exitX: 640,
            exitY: 225,
            skyTopHex: 0x290B14,
            skyBotHex: 0x9E2A1C,
            groundFillHex: 0x2B191C,
            groundTurfHex: 0xFF7B29,
            platforms: plats,
            springs: springs,
            secretBlocks: [],
            geysers: [],
            enemies: [],
            foods: foods,
            treasures: treasures,
            isBossArena: true
        )
    }
}
