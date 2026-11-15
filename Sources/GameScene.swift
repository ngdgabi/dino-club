import Foundation
import SpriteKit
#if canImport(GameController)
import GameController
#endif

enum ActiveGameMode {
    case titleMenu
    case worldSelect
    case trophyCaveOverlay
    case howToPlayOverlay
    case settingsOverlay
    case platformStage
    case gliderBonus
    case stageVictory
}

@MainActor
final class GameScene: SKScene {

    // Scene Graph Layers
    private let bgLayer = SKNode()
    private let worldLayer = SKNode()
    private let fxLayer = SKNode()
    private let hudLayer = SKNode()
    private let overlayLayer = SKNode()
    private let crtLayer = SKNode()

    // Scrolling World Container inside worldLayer
    private let cameraStrip = SKNode()
    private let parallaxFar = SKNode()
    private let parallaxMid = SKNode()

    // Active Mode & Progression
    private(set) var mode: ActiveGameMode = .titleMenu
    var isActionArcadePhase: Bool {
        mode == .platformStage || mode == .gliderBonus
    }

    private var currentWorld: PrehistoricWorldID = .palmJungle
    private var isAdventureRun: Bool = true
    private var isQuickDinoBash: Bool = false

    // Menu Navigation
    private var menuIndex: Int = 0
    private let titleMenuItems = [
        "START ADVENTURE",
        "QUICK DINO BASH",
        "GLIDER FEAST BONUS",
        "BOSS ARENA",
        "TROPHY CAVE / MEDALS",
        "HOW TO PLAY",
        "SETTINGS"
    ]
    private var selectedSetupWorld: PrehistoricWorldID = .palmJungle

    // Timing & Controls
    private var keysHeld: Set<UInt16> = []
    private var keyJustPressedClub: Bool = false
    private var keyJustPressedJump: Bool = false
    private var lastUpdateTime: TimeInterval = 0
    private var sceneClock: Double = 0
    private var isUserPaused: Bool = false
    var isAutopilotActive: Bool = false

    // Title Screen Interactive Props
    private var spitRoastNode: SKSpriteNode?
    private var spitRoastFlipped: Bool = false
    private var titleBogaNode: SKSpriteNode?
    private var titlePteroNode: SKSpriteNode?

    // Hero ("Boga the Hungry Caveman") State
    private var heroPos: CGPoint = CGPoint(x: 240, y: 209)
    private var heroVel: CGVector = .zero
    private var heroFacingRight: Bool = true
    private var heroGrounded: Bool = true
    private var heroOnIce: Bool = false
    private var coyoteTimer: Double = 0
    private var heroClub: ClubTier = .oakClub
    private var heroHearts: Int = 4
    private var heroMaxHearts: Int = 4
    private var swingTimer: Double = 0
    private var groundPoundActive: Bool = false
    private var heroInvulnTimer: Double = 0
    private var heroHurtTimer: Double = 0
    private var heroAnimClock: Double = 0
    private var heroNode: SKSpriteNode?

    // Stage State & Iconic Feast Meter
    private var activeBlueprint: StageBlueprint?
    private var camX: CGFloat = 0
    private var feastPercent: Int = 0
    private var feastFullAnnounced: Bool = false
    private var score: Int = 0
    private var comboCount: Int = 0
    private var comboTimer: Double = 0
    private var stageTimer: Double = 120
    private var stageFinishTimer: Double = 0
    private var stageWonFlag: Bool = false
    private var exitCaveNode: SKSpriteNode?

    // Stage Entities
    private struct LivePlatform {
        var def: PlatformDef
        var currentX: CGFloat
        var prevX: CGFloat
        var canopyShaken: Bool = false
        var node: SKNode
        var canopyBadge: SKNode?
    }

    private struct LiveSpring {
        var def: SpringPadDef
        var node: SKSpriteNode
    }

    private struct LiveSecretBlock {
        var def: SecretBlockDef
        var broken: Bool = false
        var node: SKSpriteNode
    }

    private struct LiveGeyser {
        var def: GeyserVentDef
        var currentHeight: CGFloat = 20
        var plumeNode: SKShapeNode
    }

    private struct LiveEnemy {
        var id: Int
        var kind: DinoEnemyKind
        var pos: CGPoint
        var vx: CGFloat
        var minX: CGFloat
        var maxX: CGFloat
        var baseY: CGFloat
        var stamina: Int
        var dizzyTimer: Double = 0
        var throwCooldown: Double = 1.8
        var animClock: Double = 0
        var knockedOut: Bool = false
        var node: SKSpriteNode
    }

    private struct LiveFood {
        var kind: FoodKind
        var basePos: CGPoint
        var pos: CGPoint
        var bobPhase: Double
        var vx: CGFloat = 0
        var vy: CGFloat = 0
        var airborneDrop: Bool = false
        var collected: Bool = false
        var node: SKSpriteNode
    }

    private struct LiveTreasure {
        var kind: TreasureKind
        var pos: CGPoint
        var collected: Bool = false
        var node: SKSpriteNode
    }

    private struct LiveHazardBall {
        var kind: HazardBallKind
        var pos: CGPoint
        var vx: CGFloat
        var vy: CGFloat
        var life: Double
        var node: SKSpriteNode
    }

    private struct LiveSpicyPepper {
        var pos: CGPoint
        var vx: CGFloat
        var vy: CGFloat
        var batted: Bool
        var node: SKSpriteNode
    }

    private var livePlatforms: [LivePlatform] = []
    private var liveSprings: [LiveSpring] = []
    private var liveBlocks: [LiveSecretBlock] = []
    private var liveGeysers: [LiveGeyser] = []
    private var liveEnemies: [LiveEnemy] = []
    private var liveFoods: [LiveFood] = []
    private var liveTreasures: [LiveTreasure] = []
    private var liveHazards: [LiveHazardBall] = []
    private var livePeppers: [LiveSpicyPepper] = []

    // Boss ("King Chomper T-Rex") State
    private var bossActive: Bool = false
    private var bossPos: CGPoint = CGPoint(x: 910, y: 245)
    private var bossVX: CGFloat = -95
    private var bossHP: Int = 5
    private var bossMaxHP: Int = 5
    private var bossDizzyTimer: Double = 0
    private var bossActionTimer: Double = 2.2
    private var bossLungeTimer: Double = 0
    private var bossNode: SKSpriteNode?

    // Glider Bonus State
    private var gliderDistance: CGFloat = 0
    private var gliderGoalDistance: CGFloat = 3200
    private var gliderSpawnClock: Double = 0

    // Victory Summary
    private var victoryTitle: String = ""
    private var victorySubtitle: String = ""
    private var canAdvanceNextWorld: Bool = false
    private var medalToastNode: SKNode?

    var isRetro1991: Bool {
        PersistenceManager.shared.data.settings.visualTheme == .retro1991
    }

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        size = CGSize(width: 1280, height: 800)
        scaleMode = .aspectFill
        backgroundColor = Palette.nightJungleBg

        if bgLayer.parent == nil {
            bgLayer.zPosition = 0
            worldLayer.zPosition = 10
            fxLayer.zPosition = 30
            hudLayer.zPosition = 50
            overlayLayer.zPosition = 70
            crtLayer.zPosition = 95

            addChild(bgLayer)
            addChild(worldLayer)
            addChild(fxLayer)
            addChild(hudLayer)
            addChild(overlayLayer)
            addChild(crtLayer)
        }

        AudioSynth.shared.syncSettings(PersistenceManager.shared.data.settings)
        rebuildCRTOverlay()
        enterTitleMenu()
    }

    private func clearSceneLayers() {
        isUserPaused = false
        AudioSynth.shared.setPaused(false)
        bgLayer.removeAllChildren()
        worldLayer.removeAllChildren()
        cameraStrip.removeAllChildren()
        cameraStrip.removeFromParent()
        parallaxFar.removeAllChildren()
        parallaxFar.removeFromParent()
        parallaxMid.removeAllChildren()
        parallaxMid.removeFromParent()
        fxLayer.removeAllChildren()
        hudLayer.removeAllChildren()
        overlayLayer.removeAllChildren()

        livePlatforms.removeAll()
        liveSprings.removeAll()
        liveBlocks.removeAll()
        liveGeysers.removeAll()
        liveEnemies.removeAll()
        liveFoods.removeAll()
        liveTreasures.removeAll()
        liveHazards.removeAll()
        livePeppers.removeAll()
        bossNode = nil
        heroNode = nil
        exitCaveNode = nil
        TouchInputState.shared.reset()
    }

    // MARK: - Live 1991 ↔ 2026 Time-Machine Toggles

    func cycleVisualTheme() {
        PersistenceManager.shared.updateSettings {
            $0.visualTheme = $0.visualTheme.next()
        }
        AudioSynth.shared.trigger(.menuSelect)
        check1991Medal()
        rebuildCRTOverlay()
        refreshCurrentModeVisuals()
        let lbl = PersistenceManager.shared.data.settings.visualTheme.label
        showFloatingBanner("VISUAL ERA: \(lbl)", color: Palette.amberGold)
    }

    func cycleAudioChip() {
        PersistenceManager.shared.updateSettings {
            $0.audioChip = $0.audioChip.next()
        }
        let s = PersistenceManager.shared.data.settings
        AudioSynth.shared.syncSettings(s)
        AudioSynth.shared.trigger(.gemChime)
        check1991Medal()
        refreshCurrentModeVisuals()
        showFloatingBanner("AUDIO SYNTH: \(s.audioChip.label)", color: Palette.jungleEmerald)
    }

    private func check1991Medal() {
        let s = PersistenceManager.shared.data.settings
        if s.visualTheme == .retro1991 && s.audioChip == .retroAdLib {
            if let m = PersistenceManager.shared.unlockMedal("time_caveman_91") {
                presentMedalToast(m)
            }
        }
    }

    private func rebuildCRTOverlay() {
        crtLayer.removeAllChildren()
        let theme = PersistenceManager.shared.data.settings.visualTheme
        guard theme == .crtCabinet || theme == .retro1991 else { return }

        let alpha: CGFloat = (theme == .crtCabinet) ? 0.16 : 0.08
        for y in stride(from: 0, through: 800, by: 4) {
            let line = SKSpriteNode(color: SKColor.rgba(0, 0, 0, alpha), size: CGSize(width: 1280, height: 1.5))
            line.position = CGPoint(x: 640, y: CGFloat(y))
            crtLayer.addChild(line)
        }
        if theme == .crtCabinet {
            let bezel = SKShapeNode(rectOf: CGSize(width: 1268, height: 788), cornerRadius: 24)
            bezel.position = CGPoint(x: 640, y: 400)
            bezel.fillColor = .clear
            bezel.strokeColor = SKColor.rgba(0, 0, 0, 0.45)
            bezel.lineWidth = 14
            crtLayer.addChild(bezel)
        }
    }

    private func refreshCurrentModeVisuals() {
        switch mode {
        case .titleMenu:
            enterTitleMenu()
        case .worldSelect:
            showWorldSelectOverlay()
        case .trophyCaveOverlay:
            showTrophyCaveOverlay()
        case .howToPlayOverlay:
            showHowToPlayOverlay()
        case .settingsOverlay:
            showSettingsOverlay()
        case .platformStage:
            refreshLivePlatformStageTextures()
            rebuildGameplayHUD()
        case .gliderBonus:
            refreshLiveGliderTextures()
            rebuildGameplayHUD()
        case .stageVictory:
            renderVictoryScreen()
        }
    }

    // MARK: - 1. Interactive Stone Age Campfire Title Menu (Safe Box x: 145..1135, y: 135..665)

    func enterTitleMenu() {
        mode = .titleMenu
        clearSceneLayers()
        AudioSynth.shared.setTrack(.campfireTitle)

        let retro = isRetro1991
        drawPrehistoricBackdrop(skyTop: 0x132242, skyBot: 0x5E2C4D, world: .palmJungle, includeVolcano: true)

        // Full-bleed jungle ground floor
        let floor = SKSpriteNode(color: retro ? Palette.vgaBrown : SKColor.hex(0x4A2B16), size: CGSize(width: 1320, height: 185))
        floor.position = CGPoint(x: 640, y: 92)
        bgLayer.addChild(floor)
        let turf = SKSpriteNode(color: retro ? Palette.vgaGreen : SKColor.hex(0x28B856), size: CGSize(width: 1320, height: 18))
        turf.position = CGPoint(x: 640, y: 178)
        bgLayer.addChild(turf)

        // Top Title Header Banner (x: 165..1115, y: 585..655 — strictly inside Safe Box!)
        let titleCard = SKShapeNode(rectOf: CGSize(width: 950, height: 74), cornerRadius: retro ? 2 : 16)
        titleCard.position = CGPoint(x: 640, y: 622)
        titleCard.fillColor = (retro ? Palette.vgaBlue : Palette.cardWoodDark).withAlphaComponent(0.92)
        titleCard.strokeColor = retro ? Palette.vgaYellow : Palette.amberGold
        titleCard.lineWidth = 3.0
        hudLayer.addChild(titleCard)

        let mainTitle = CoreTextLabelRenderer.makeLabelNode(
            "DINO CLUB: STONE AGE FEAST",
            fontSize: 28,
            color: retro ? Palette.vgaYellow : Palette.amberGold,
            retroMono: retro
        )
        mainTitle.position = CGPoint(x: 505, y: 632)
        hudLayer.addChild(mainTitle)

        let subTitle = CoreTextLabelRenderer.makeLabelNode(
            "SLAPSTICK CAVEMAN PLATFORMER  •  1991 ↔ 2026 LIVE TIME-MACHINE",
            fontSize: 11.5,
            color: .white,
            bold: false,
            retroMono: retro
        )
        subTitle.position = CGPoint(x: 505, y: 604)
        hudLayer.addChild(subTitle)

        // Top-Right Quick Era & Audio Pills inside Title Header
        let s = PersistenceManager.shared.data.settings
        hudLayer.addChild(makePillButton(name: "btn_era", text: "ERA: \(s.visualTheme.shortBadge)", width: 132, pos: CGPoint(x: 912, y: 622), accent: Palette.amberGold, height: 36, fontSize: 11))
        hudLayer.addChild(makePillButton(name: "btn_chip", text: "CHIP: \(s.audioChip.shortBadge)", width: 132, pos: CGPoint(x: 1048, y: 622), accent: Palette.jungleEmerald, height: 36, fontSize: 11))

        // Left Campfire Diorama & Clickable Spit-Roast Gag (x: 185..545, y: 180..540)
        let dioramaCard = SKShapeNode(rectOf: CGSize(width: 365, height: 365), cornerRadius: retro ? 2 : 18)
        dioramaCard.position = CGPoint(x: 362, y: 365)
        dioramaCard.fillColor = SKColor.hex(0x0D1420).withAlphaComponent(0.55)
        dioramaCard.strokeColor = Palette.volcanoOrange.withAlphaComponent(0.65)
        dioramaCard.lineWidth = 2.0
        worldLayer.addChild(dioramaCard)

        let boga = SKSpriteNode(texture: SpriteFactory.shared.bogaTexture(pose: .cheer, club: .boneHammer, retro: retro), size: CGSize(width: 96, height: 86))
        boga.position = CGPoint(x: 250, y: 256)
        worldLayer.addChild(boga)
        titleBogaNode = boga

        let roast = SKSpriteNode(texture: SpriteFactory.shared.campfireSpitRoastTexture(flipped: spitRoastFlipped, retro: retro), size: CGSize(width: 146, height: 102))
        roast.position = CGPoint(x: 392, y: 248)
        roast.name = "gag_spitroast"
        worldLayer.addChild(roast)
        spitRoastNode = roast

        let gagHint = makePillButton(name: "gag_spitroast", text: "🔥 TAP SPIT-ROAST TO FLIP!", width: 250, pos: CGPoint(x: 362, y: 196), accent: Palette.volcanoOrange, height: 28, fontSize: 11)
        worldLayer.addChild(gagHint)

        // Grumpy Raptor eyeing the roast + floating Giant Delicacies showcase!
        let raptor = SKSpriteNode(texture: SpriteFactory.shared.dinoEnemyTexture(kind: .raptorScout, frame: 0, dizzy: false, retro: retro), size: CGSize(width: 78, height: 68))
        raptor.xScale = -1
        raptor.position = CGPoint(x: 498, y: 242)
        worldLayer.addChild(raptor)

        let showcaseFoods: [(FoodKind, CGPoint)] = [
            (.mammothDrumstick, CGPoint(x: 245, y: 468)),
            (.stoneBurger,      CGPoint(x: 325, y: 492)),
            (.megaCroissant,    CGPoint(x: 405, y: 492)),
            (.iceCreamSundae,   CGPoint(x: 482, y: 468))
        ]
        for (i, item) in showcaseFoods.enumerated() {
            let fn = SKSpriteNode(texture: SpriteFactory.shared.foodTexture(kind: item.0, retro: retro), size: CGSize(width: 50, height: 50))
            fn.position = item.1
            fn.run(.repeatForever(.sequence([
                .moveBy(x: 0, y: i % 2 == 0 ? 8 : -8, duration: 0.9),
                .moveBy(x: 0, y: i % 2 == 0 ? -8 : 8, duration: 0.9)
            ])))
            worldLayer.addChild(fn)
        }

        let badge = CoreTextLabelRenderer.makeLabelNode("GOBBLE GIANT FOOD TO FILL THE FEAST METER!", fontSize: 11.5, color: Palette.amberGold, retroMono: retro)
        badge.position = CGPoint(x: 362, y: 412)
        worldLayer.addChild(badge)

        let ptero = SKSpriteNode(texture: SpriteFactory.shared.dinoEnemyTexture(kind: .pterodactyl, frame: 0, dizzy: false, retro: retro), size: CGSize(width: 68, height: 58))
        ptero.position = CGPoint(x: 260, y: 538)
        worldLayer.addChild(ptero)
        titlePteroNode = ptero

        // Right 7-Button Chiseled Menu Column (x: 565..1110, y: 185..545)
        rebuildTitleMenuButtons()

        // Bottom Controls Strip inside Safe Box (y = 148)
        let foot = CoreTextLabelRenderer.makeLabelNode(
            "MOVE: ARROWS / WASD / STICK  •  CLUB: SPACE / Z  •  JUMP: UP / X  •  GROUND-POUND: JUMP + DOWN + CLUB",
            fontSize: 10.5,
            color: SKColor.rgba(0.90, 0.94, 1.0, 0.88),
            bold: false,
            retroMono: retro
        )
        foot.position = CGPoint(x: 640, y: 148)
        hudLayer.addChild(foot)
    }

    private func rebuildTitleMenuButtons() {
        hudLayer.children.filter { ($0.name ?? "").hasPrefix("menu_row_") }.forEach { $0.removeFromParent() }
        for (i, title) in titleMenuItems.enumerated() {
            let selected = (i == menuIndex)
            let yPos: CGFloat = 524 - CGFloat(i) * 52
            let accent: SKColor = selected ? Palette.amberGold : SKColor.hex(0x6C82A6)
            let fill: SKColor = selected
                ? (isRetro1991 ? Palette.vgaRed : SKColor.hex(0x4A2214))
                : (isRetro1991 ? Palette.vgaBlue : SKColor.hex(0x162236))
            let prefix = selected ? "▶ " : ""
            let btn = makePillButton(
                name: "menu_row_\(i)",
                text: "\(prefix)\(title)",
                width: 520,
                pos: CGPoint(x: 845, y: yPos),
                accent: accent,
                fill: fill,
                height: 43,
                fontSize: 15
            )
            hudLayer.addChild(btn)
        }
    }

    private func triggerCampfireSpitRoastGag() {
        spitRoastFlipped.toggle()
        AudioSynth.shared.trigger(.spitRoastSizzle)
        HapticsManager.mediumImpact()
        spitRoastNode?.texture = SpriteFactory.shared.campfireSpitRoastTexture(flipped: spitRoastFlipped, retro: isRetro1991)
        spitRoastNode?.run(.sequence([
            .scale(to: 1.18, duration: 0.08),
            .scale(to: 1.0, duration: 0.12)
        ]))
        titleBogaNode?.run(.sequence([
            .moveBy(x: 0, y: 24, duration: 0.12),
            .moveBy(x: 0, y: -24, duration: 0.14)
        ]))
        spawnComicStarburst(text: "SIZZLE! YUM!", at: CGPoint(x: 392, y: 318), color: Palette.amberGold, inWorld: false)
        if let m = PersistenceManager.shared.unlockMedal("spit_roast_chef") {
            presentMedalToast(m)
        }
    }

    private func activateTitleMenuSelection() {
        AudioSynth.shared.trigger(.menuSelect)
        switch menuIndex {
        case 0:
            showWorldSelectOverlay()
        case 1:
            startQuickDinoBash()
        case 2:
            startGliderBonusStage(fromAdventure: false)
        case 3:
            startPlatformWorld(.volcanoRexArena, adventureMode: false, resetStats: true)
        case 4:
            showTrophyCaveOverlay()
        case 5:
            showHowToPlayOverlay()
        default:
            showSettingsOverlay()
        }
    }

    // MARK: - 2. Adventure Setup, Trophy Cave, How To Play & Settings Modals (Safe Box)

    private func showWorldSelectOverlay() {
        mode = .worldSelect
        overlayLayer.removeAllChildren()
        hudLayer.removeAllChildren()
        let diff = PersistenceManager.shared.data.settings.difficulty

        let card = makeModalCard(title: "STONE AGE FEAST ADVENTURE", subtitle: selectedSetupWorld.subtitle)
        card.addChild(makePillButton(name: "opt_world", text: "STARTING WORLD: \(selectedSetupWorld.title)", width: 580, pos: CGPoint(x: 640, y: 455), accent: Palette.amberGold, height: 46))
        card.addChild(makePillButton(name: "opt_diff", text: "APPETITE RANK: \(diff.label)", width: 580, pos: CGPoint(x: 640, y: 392), accent: Palette.tropicalSky, height: 44))
        card.addChild(makePillButton(name: "btn_launch_adventure", text: "▶ LAUNCH STONE AGE EXPEDITION!", width: 460, pos: CGPoint(x: 640, y: 312), accent: Palette.jungleEmerald, fill: SKColor.hex(0x143D29), height: 50, fontSize: 16))
        card.addChild(makePillButton(name: "btn_modal_back", text: "BACK TO CAMPFIRE", width: 280, pos: CGPoint(x: 640, y: 225), accent: Palette.amberGold, height: 40))
        overlayLayer.addChild(card)
    }

    private func showTrophyCaveOverlay() {
        mode = .trophyCaveOverlay
        overlayLayer.removeAllChildren()
        hudLayer.removeAllChildren()
        let unlocked = PersistenceManager.shared.data.unlockedMedals
        let scores = PersistenceManager.shared.data.highScores

        let card = makeModalCard(
            title: "TROPHY CAVE & STONE TABLETS",
            subtitle: "Medals Unlocked: \(unlocked.count)/\(AchievementCatalog.all.count)  •  Bonks: \(PersistenceManager.shared.data.totalBonks)  •  Food Gobbled: \(PersistenceManager.shared.data.totalFoodsGobbled)"
        )

        // Left 2x6 Medal Grid (x: 195..765)
        for (i, m) in AchievementCatalog.all.enumerated() {
            let col = i % 2
            let row = i / 2
            let cx: CGFloat = 335 + CGFloat(col) * 265
            let cy: CGFloat = 482 - CGFloat(row) * 43
            let has = unlocked.contains(m.id)
            let pill = SKShapeNode(rectOf: CGSize(width: 252, height: 36), cornerRadius: 8)
            pill.position = CGPoint(x: cx, y: cy)
            pill.fillColor = has ? SKColor.hex(0x1B3E2B) : SKColor.hex(0x151E2E)
            pill.strokeColor = has ? Palette.amberGold : SKColor.hex(0x3B4B66)
            pill.lineWidth = 1.5
            let t = CoreTextLabelRenderer.makeLabelNode("\(has ? "★" : "○") \(m.title)", fontSize: 10.5, color: has ? Palette.amberGold : SKColor.hex(0x8A9BB8), retroMono: isRetro1991)
            t.position = CGPoint(x: 0, y: 6)
            let sub = CoreTextLabelRenderer.makeLabelNode(m.subtitle, fontSize: 8.2, color: .white, bold: false, retroMono: isRetro1991)
            sub.position = CGPoint(x: 0, y: -7)
            pill.addChild(t)
            pill.addChild(sub)
            card.addChild(pill)
        }

        // Right High Score Stone Tablet (x: 965)
        let hdr = CoreTextLabelRenderer.makeLabelNode("TOP CAVEMEN", fontSize: 13, color: Palette.amberGold, retroMono: isRetro1991)
        hdr.position = CGPoint(x: 968, y: 486)
        card.addChild(hdr)
        for (idx, hs) in scores.prefix(5).enumerated() {
            let rowLbl = CoreTextLabelRenderer.makeLabelNode(
                "\(idx + 1). \(hs.initials)  \(hs.score)  (\(hs.modeTag))",
                fontSize: 11,
                color: idx == 0 ? Palette.jungleEmerald : .white,
                retroMono: true
            )
            rowLbl.position = CGPoint(x: 968, y: 448 - CGFloat(idx) * 34)
            card.addChild(rowLbl)
        }

        card.addChild(makePillButton(name: "btn_modal_back", text: "BACK TO CAMPFIRE", width: 290, pos: CGPoint(x: 640, y: 205), accent: Palette.amberGold, height: 40))
        overlayLayer.addChild(card)
    }

    private func showHowToPlayOverlay() {
        mode = .howToPlayOverlay
        overlayLayer.removeAllChildren()
        hudLayer.removeAllChildren()

        let card = makeModalCard(title: "HOW TO BONK & FEAST!", subtitle: "Inspired by Classic 1991/1993 Prehistoric Slapstick Platformers")
        let lines = [
            "1. CLUB BASH (SPACE / Z / CLUB): Swing Boga's Oak Club, Stone Mallet, or Bone Hammer to bonk grumpy dinos dizzy!",
            "2. GROUND-POUND (JUMP + DOWN + CLUB): Slam the earth to shake giant Mega-Croissants from palm trees & crack stone blocks!",
            "3. FILL THE FEAST METER (0% -> 100%): Gobble Mammoth Drumsticks, Burgers, Pineapples & Sundaes to unlock the Exit Cave!",
            "4. HANG-GLIDER SKY BONUS: Steer Boga's bamboo glider through floating fruit rings & amber gems over smoking volcanoes!",
            "5. KING CHOMPER T-REX BOSS: Bat fiery Volcano Peppers into his chomping jaws, then bonk his dizzy snout 5 times!",
            "6. LIVE 1991 ↔ 2026 TIME-MACHINE: Press V & B (or tap ERA & CHIP) anytime for 16-Color VGA Pixel Art & AdLib FM Chiptunes!"
        ]
        for (i, line) in lines.enumerated() {
            let lbl = CoreTextLabelRenderer.makeLabelNode(line, fontSize: 11.6, color: i % 2 == 0 ? Palette.boneCream : Palette.amberGold, bold: false, retroMono: isRetro1991)
            lbl.position = CGPoint(x: 640, y: 472 - CGFloat(i) * 38)
            card.addChild(lbl)
        }
        card.addChild(makePillButton(name: "btn_modal_back", text: "READY TO FEAST!", width: 290, pos: CGPoint(x: 640, y: 215), accent: Palette.jungleEmerald, height: 42))
        overlayLayer.addChild(card)
    }

    private func showSettingsOverlay() {
        mode = .settingsOverlay
        overlayLayer.removeAllChildren()
        hudLayer.removeAllChildren()
        let s = PersistenceManager.shared.data.settings

        let card = makeModalCard(title: "ERA, SYNTH & GAMEPLAY SETTINGS", subtitle: "Instant Universal Switching Across Mac, iPhone & iPad")
        card.addChild(makePillButton(name: "set_theme", text: "VISUAL ERA [V]: \(s.visualTheme.label)", width: 540, pos: CGPoint(x: 640, y: 476), accent: Palette.amberGold, height: 40))
        card.addChild(makePillButton(name: "set_chip", text: "AUDIO SYNTH [B]: \(s.audioChip.label)", width: 540, pos: CGPoint(x: 640, y: 424), accent: Palette.jungleEmerald, height: 40))
        card.addChild(makePillButton(name: "set_shake", text: "CARTOON SCREEN SHAKE: \(s.screenShakeEnabled ? "ON" : "OFF")", width: 540, pos: CGPoint(x: 640, y: 372), accent: Palette.tropicalSky, height: 40))
        card.addChild(makePillButton(name: "set_music", text: "MUSIC VOLUME: \(Int(round(s.musicVolume * 100)))%", width: 260, pos: CGPoint(x: 500, y: 316), accent: Palette.volcanoOrange, height: 40))
        card.addChild(makePillButton(name: "set_sfx", text: "SFX VOLUME: \(Int(round(s.sfxVolume * 100)))%", width: 260, pos: CGPoint(x: 780, y: 316), accent: Palette.volcanoOrange, height: 40))
        card.addChild(makePillButton(name: "btn_modal_back", text: "SAVE & RETURN", width: 290, pos: CGPoint(x: 640, y: 225), accent: Palette.amberGold, height: 42))
        overlayLayer.addChild(card)
    }

    // MARK: - 3. Prehistoric Platformer World Builder & Gameplay Engine

    func startQuickDinoBash() {
        isQuickDinoBash = true
        let pick: [PrehistoricWorldID] = [.palmJungle, .amberCavern, .magmaRidge, .glacierPeak]
        let chosen = pick[Int(sceneClock * 10) % pick.count]
        startPlatformWorld(chosen, adventureMode: false, resetStats: true)
        stageTimer = 75
        heroClub = .stoneMallet
        refreshHeroSprite()
        showFloatingBanner("QUICK DINO BASH! FILL THE FEAST METER FAST!", color: Palette.amberGold)
    }

    func startPlatformWorld(_ world: PrehistoricWorldID, adventureMode: Bool, resetStats: Bool) {
        mode = .platformStage
        currentWorld = world
        isAdventureRun = adventureMode
        if adventureMode { isQuickDinoBash = false }
        clearSceneLayers()

        let bp = LevelCatalog.blueprint(for: world)
        activeBlueprint = bp

        let diff = PersistenceManager.shared.data.settings.difficulty
        if resetStats {
            score = 0
            heroClub = (world == .volcanoRexArena) ? .stoneMallet : .oakClub
            heroMaxHearts = diff.startingHearts
            heroHearts = heroMaxHearts
        } else {
            heroHearts = min(heroMaxHearts, heroHearts + 1)
        }

        feastPercent = 0
        feastFullAnnounced = false
        comboCount = 0
        comboTimer = 0
        stageTimer = bp.timeLimit
        stageFinishTimer = 0
        stageWonFlag = false

        heroPos = CGPoint(x: 245, y: 209)
        heroVel = .zero
        heroFacingRight = true
        heroGrounded = true
        heroOnIce = (world == .glacierPeak)
        swingTimer = 0
        groundPoundActive = false
        heroInvulnTimer = 0
        heroHurtTimer = 0
        camX = 0

        // Select matching world soundtrack
        let track: MusicTrack = {
            switch world {
            case .palmJungle:      return .palmJungle
            case .amberCavern:     return .amberCavern
            case .magmaRidge:      return .magmaRidge
            case .glacierPeak:     return .glacierPeak
            case .volcanoRexArena: return .bossRex
            }
        }()
        AudioSynth.shared.setTrack(track)

        drawPrehistoricBackdrop(skyTop: bp.skyTopHex, skyBot: bp.skyBotHex, world: world, includeVolcano: world == .magmaRidge || world == .volcanoRexArena || world == .palmJungle)

        worldLayer.addChild(parallaxFar)
        worldLayer.addChild(parallaxMid)
        worldLayer.addChild(cameraStrip)

        buildStageGeometryAndActors(from: bp)
        rebuildGameplayHUD()
        updateCameraScroll()
    }

    private func buildStageGeometryAndActors(from bp: StageBlueprint) {
        let retro = isRetro1991
        let diffMul = PersistenceManager.shared.data.settings.difficulty.enemySpeedMultiplier

        // Decorative Parallax Mountains / Stalactites / Palms in camera-relative layers
        for i in 0..<8 {
            let mx = CGFloat(i) * 380 + 140
            let peak = SKShapeNode()
            let p = CGMutablePath()
            p.move(to: CGPoint(x: mx - 190, y: 165))
            p.addLine(to: CGPoint(x: mx, y: 390 + CGFloat((i % 3) * 45)))
            p.addLine(to: CGPoint(x: mx + 190, y: 165))
            p.closeSubpath()
            peak.path = p
            peak.fillColor = SKColor.hex(bp.groundFillHex).withAlphaComponent(0.50)
            peak.strokeColor = .clear
            parallaxMid.addChild(peak)

            if bp.world == .amberCavern {
                // Glowing ceiling stalactites above y=665
                let stal = SKShapeNode()
                let sp = CGMutablePath()
                sp.move(to: CGPoint(x: mx - 36, y: 800))
                sp.addLine(to: CGPoint(x: mx, y: 672))
                sp.addLine(to: CGPoint(x: mx + 36, y: 800))
                sp.closeSubpath()
                stal.path = sp
                stal.fillColor = retro ? Palette.vgaYellow : Palette.amberGold.withAlphaComponent(0.65)
                stal.strokeColor = .clear
                parallaxMid.addChild(stal)
            }
        }

        // Lava / Chasm Base under gaps (full bleed y: 0..155)
        let hazardSea = SKSpriteNode(
            color: bp.world == .glacierPeak ? SKColor.hex(0x1B85B8) : SKColor.hex(0xD9381E),
            size: CGSize(width: bp.worldWidth + 800, height: 155)
        )
        hazardSea.position = CGPoint(x: bp.worldWidth * 0.5, y: 77)
        hazardSea.zPosition = 1
        cameraStrip.addChild(hazardSea)

        // Platforms + Overhead Secret Canopy Trees
        for pDef in bp.platforms {
            let container = SKNode()
            let h: CGFloat = pDef.isGround ? 185 : 28
            let centerOffsetY: CGFloat = pDef.isGround ? (-h * 0.5) : (-14)
            let body = SKShapeNode(rectOf: CGSize(width: pDef.width, height: h), cornerRadius: retro ? 0 : 10)
            body.position = CGPoint(x: 0, y: centerOffsetY)
            body.fillColor = retro
                ? (pDef.isIce ? Palette.vgaCyan : Palette.vgaBrown)
                : SKColor.hex(bp.groundFillHex)
            body.strokeColor = retro ? Palette.vgaBlack : SKColor.hex(0x120E0B)
            body.lineWidth = 2.2
            container.addChild(body)

            let turf = SKShapeNode(rectOf: CGSize(width: pDef.width + 4, height: 11), cornerRadius: retro ? 0 : 5)
            turf.position = CGPoint(x: 0, y: -5)
            turf.fillColor = retro
                ? (pDef.isIce ? Palette.vgaWhite : Palette.vgaBrightGreen)
                : SKColor.hex(bp.groundTurfHex)
            turf.strokeColor = .clear
            container.addChild(turf)

            if pDef.moveAmpX > 0 {
                // Stone wheels on zip-platforms!
                for wx in [-pDef.width * 0.34, pDef.width * 0.34] {
                    let wSpr = SKSpriteNode(texture: SpriteFactory.shared.treasureTexture(kind: .stoneWheel, retro: retro), size: CGSize(width: 26, height: 26))
                    wSpr.position = CGPoint(x: wx, y: -16)
                    container.addChild(wSpr)
                }
            }

            var badgeNode: SKNode? = nil
            if pDef.canopyFood != nil {
                // Lush Prehistorik Palm/Pine Tree whose canopy hides a giant delicacy!
                let trunk = SKSpriteNode(color: SKColor.hex(0x7D461F), size: CGSize(width: 18, height: 118))
                trunk.position = CGPoint(x: 0, y: 59)
                trunk.zPosition = -2
                container.addChild(trunk)

                let crown = SKShapeNode(ellipseOf: CGSize(width: 132, height: 54))
                crown.position = CGPoint(x: 0, y: 122)
                crown.fillColor = bp.world == .glacierPeak ? Palette.glacierCyan : Palette.jungleEmerald
                crown.strokeColor = SKColor.hex(0x132618)
                crown.lineWidth = 2.0
                crown.zPosition = -1
                container.addChild(crown)

                let glint = CoreTextLabelRenderer.makeLabelNode("★ SLAM!", fontSize: 10, color: Palette.amberGold, retroMono: retro)
                glint.position = CGPoint(x: 0, y: 122)
                container.addChild(glint)
                badgeNode = glint
            }

            container.position = CGPoint(x: pDef.x, y: pDef.topY)
            container.zPosition = 5
            cameraStrip.addChild(container)
            livePlatforms.append(LivePlatform(def: pDef, currentX: pDef.x, prevX: pDef.x, node: container, canopyBadge: badgeNode))
        }

        // Bouncy Palm / Mushroom Springs
        for sp in bp.springs {
            let spr = SKSpriteNode(texture: SpriteFactory.shared.springPadTexture(isMushroom: sp.isMushroom, retro: retro), size: CGSize(width: 64, height: 38))
            spr.position = CGPoint(x: sp.x, y: sp.y)
            spr.zPosition = 8
            cameraStrip.addChild(spr)
            liveSprings.append(LiveSpring(def: sp, node: spr))
        }

        // Secret Cracked Stone Blocks
        for blk in bp.secretBlocks {
            let bNode = SKSpriteNode(texture: SpriteFactory.shared.crackedStoneBlockTexture(retro: retro), size: CGSize(width: 52, height: 52))
            bNode.position = CGPoint(x: blk.x, y: blk.y)
            bNode.zPosition = 9
            cameraStrip.addChild(bNode)
            liveBlocks.append(LiveSecretBlock(def: blk, node: bNode))
        }

        // Magma Geyser Vents
        for g in bp.geysers {
            let plume = SKShapeNode(rectOf: CGSize(width: 34, height: 40), cornerRadius: 12)
            plume.fillColor = Palette.volcanoOrange
            plume.strokeColor = Palette.amberGold
            plume.lineWidth = 2.0
            plume.position = CGPoint(x: g.x, y: g.baseY + 20)
            plume.zPosition = 7
            cameraStrip.addChild(plume)
            liveGeysers.append(LiveGeyser(def: g, plumeNode: plume))
        }

        // Exit Cave Archway (non-boss worlds)
        if !bp.isBossArena {
            let cave = SKSpriteNode(texture: SpriteFactory.shared.exitCaveTexture(isOpen: false, retro: retro), size: CGSize(width: 112, height: 108))
            cave.position = CGPoint(x: bp.exitX, y: bp.exitY)
            cave.zPosition = 6
            cameraStrip.addChild(cave)
            exitCaveNode = cave
        }

        // Collectible Giant Foods
        for (idx, fDef) in bp.foods.enumerated() {
            spawnFoodItem(kind: fDef.kind, at: CGPoint(x: fDef.x, y: fDef.y), phase: Double(idx) * 0.7, airborne: false)
        }

        // Collectible Treasures & Club Upgrades
        for tDef in bp.treasures {
            spawnTreasureItem(kind: tDef.kind, at: CGPoint(x: tDef.x, y: tDef.y))
        }

        // Grumpy Dinosaur & Yeti Patrols
        for (idx, eDef) in bp.enemies.enumerated() {
            let eNode = SKSpriteNode(texture: SpriteFactory.shared.dinoEnemyTexture(kind: eDef.kind, frame: 0, dizzy: false, retro: retro), size: CGSize(width: 68, height: 60))
            eNode.position = CGPoint(x: eDef.x, y: eDef.y)
            eNode.zPosition = 16
            cameraStrip.addChild(eNode)
            liveEnemies.append(LiveEnemy(
                id: idx + 1,
                kind: eDef.kind,
                pos: CGPoint(x: eDef.x, y: eDef.y),
                vx: eDef.speed * diffMul,
                minX: eDef.minX,
                maxX: eDef.maxX,
                baseY: eDef.y,
                stamina: eDef.kind.maxStamina,
                node: eNode
            ))
        }

        // Boss Arena: Spawn Giant King Chomper T-Rex + Spicy Volcano Peppers!
        bossActive = bp.isBossArena
        if bp.isBossArena {
            bossMaxHP = 5
            bossHP = 5
            bossPos = CGPoint(x: 925, y: 248)
            bossVX = -105
            bossDizzyTimer = 0
            bossActionTimer = 2.0
            bossLungeTimer = 0
            let rex = SKSpriteNode(texture: SpriteFactory.shared.bossRexTexture(pose: .idle, retro: retro), size: CGSize(width: 184, height: 154))
            rex.position = bossPos
            rex.zPosition = 18
            cameraStrip.addChild(rex)
            bossNode = rex

            spawnSpicyPepper(at: CGPoint(x: 520, y: 206))
            spawnSpicyPepper(at: CGPoint(x: 760, y: 206))
        }

        // Spawn Boga the Hungry Caveman!
        let bNode = SKSpriteNode(texture: SpriteFactory.shared.bogaTexture(pose: .idle, club: heroClub, retro: retro), size: CGSize(width: 76, height: 68))
        bNode.position = heroPos
        bNode.zPosition = 20
        cameraStrip.addChild(bNode)
        heroNode = bNode
    }

    private func spawnFoodItem(kind: FoodKind, at pt: CGPoint, phase: Double = 0, airborne: Bool = false, vx: CGFloat = 0, vy: CGFloat = 0) {
        let spr = SKSpriteNode(texture: SpriteFactory.shared.foodTexture(kind: kind, retro: isRetro1991), size: CGSize(width: 48, height: 48))
        spr.position = pt
        spr.zPosition = 14
        cameraStrip.addChild(spr)
        liveFoods.append(LiveFood(kind: kind, basePos: pt, pos: pt, bobPhase: phase, vx: vx, vy: vy, airborneDrop: airborne, node: spr))
    }

    private func spawnTreasureItem(kind: TreasureKind, at pt: CGPoint) {
        let spr = SKSpriteNode(texture: SpriteFactory.shared.treasureTexture(kind: kind, retro: isRetro1991), size: CGSize(width: 44, height: 44))
        spr.position = pt
        spr.zPosition = 14
        cameraStrip.addChild(spr)
        liveTreasures.append(LiveTreasure(kind: kind, pos: pt, node: spr))
    }

    private func spawnSpicyPepper(at pt: CGPoint) {
        guard livePeppers.count < 3 else { return }
        let spr = SKSpriteNode(texture: SpriteFactory.shared.spicyPepperTexture(retro: isRetro1991), size: CGSize(width: 44, height: 44))
        spr.position = pt
        spr.zPosition = 15
        cameraStrip.addChild(spr)
        livePeppers.append(LiveSpicyPepper(pos: pt, vx: 0, vy: 0, batted: false, node: spr))
    }

    private func refreshLivePlatformStageTextures() {
        let retro = isRetro1991
        refreshHeroSprite()
        for i in liveSprings.indices {
            liveSprings[i].node.texture = SpriteFactory.shared.springPadTexture(isMushroom: liveSprings[i].def.isMushroom, retro: retro)
        }
        for i in liveBlocks.indices where !liveBlocks[i].broken {
            liveBlocks[i].node.texture = SpriteFactory.shared.crackedStoneBlockTexture(retro: retro)
        }
        for i in liveFoods.indices where !liveFoods[i].collected {
            liveFoods[i].node.texture = SpriteFactory.shared.foodTexture(kind: liveFoods[i].kind, retro: retro)
        }
        for i in liveTreasures.indices where !liveTreasures[i].collected {
            liveTreasures[i].node.texture = SpriteFactory.shared.treasureTexture(kind: liveTreasures[i].kind, retro: retro)
        }
        for i in liveEnemies.indices where !liveEnemies[i].knockedOut {
            liveEnemies[i].node.texture = SpriteFactory.shared.dinoEnemyTexture(kind: liveEnemies[i].kind, frame: 0, dizzy: liveEnemies[i].dizzyTimer > 0, retro: retro)
        }
        exitCaveNode?.texture = SpriteFactory.shared.exitCaveTexture(isOpen: feastPercent >= 100, retro: retro)
        bossNode?.texture = SpriteFactory.shared.bossRexTexture(pose: bossDizzyTimer > 0 ? .dizzy : .idle, retro: retro)
    }

    // MARK: - 4. Bamboo Hang-Glider Sky Feast Bonus Stage

    func startGliderBonusStage(fromAdventure: Bool) {
        mode = .gliderBonus
        isAdventureRun = fromAdventure
        clearSceneLayers()
        AudioSynth.shared.setTrack(.gliderSkyBonus)

        score = fromAdventure ? score : 0
        feastPercent = 0
        feastFullAnnounced = false
        stageTimer = 45
        stageFinishTimer = 0
        stageWonFlag = false
        gliderDistance = 0
        gliderGoalDistance = 3000
        gliderSpawnClock = 0

        heroPos = CGPoint(x: 310, y: 410)
        heroVel = .zero
        heroMaxHearts = 4
        heroHearts = 4

        drawPrehistoricBackdrop(skyTop: 0x0E6BD6, skyBot: 0x8EF3FF, world: .palmJungle, includeVolcano: true)

        // Sparkling Turquoise Lagoon along bottom (full bleed y: 0..162)
        let sea = SKSpriteNode(color: isRetro1991 ? Palette.vgaCyan : SKColor.hex(0x18B6E8), size: CGSize(width: 1320, height: 162))
        sea.position = CGPoint(x: 640, y: 81)
        bgLayer.addChild(sea)

        worldLayer.addChild(cameraStrip)

        let boga = SKSpriteNode(texture: SpriteFactory.shared.bogaTexture(pose: .glider, club: heroClub, retro: isRetro1991), size: CGSize(width: 96, height: 82))
        boga.position = heroPos
        boga.zPosition = 20
        cameraStrip.addChild(boga)
        heroNode = boga

        // Pre-populate tasty sky arcs right away!
        let foodCycle: [FoodKind] = [.giantPineapple, .stoneBurger, .mammothDrumstick, .iceCreamSundae, .megaCroissant, .goldenBanana]
        for i in 0..<8 {
            let fx: CGFloat = 520 + CGFloat(i) * 115
            let fy: CGFloat = 385 + sin(CGFloat(i) * 0.75) * 115
            spawnFoodItem(kind: foodCycle[i % foodCycle.count], at: CGPoint(x: fx, y: fy), phase: Double(i) * 0.5)
            if i % 3 == 2 {
                spawnTreasureItem(kind: .amberGem, at: CGPoint(x: fx, y: min(555, fy + 62)))
            }
        }

        rebuildGameplayHUD()
        showFloatingBanner("BAMBOO HANG-GLIDER BONUS! SWOOP FOR SKY FRUITS!", color: Palette.amberGold)
    }

    private func refreshLiveGliderTextures() {
        let retro = isRetro1991
        heroNode?.texture = SpriteFactory.shared.bogaTexture(pose: .glider, club: heroClub, retro: retro)
        for i in liveFoods.indices where !liveFoods[i].collected {
            liveFoods[i].node.texture = SpriteFactory.shared.foodTexture(kind: liveFoods[i].kind, retro: retro)
        }
        for i in liveTreasures.indices where !liveTreasures[i].collected {
            liveTreasures[i].node.texture = SpriteFactory.shared.treasureTexture(kind: liveTreasures[i].kind, retro: retro)
        }
        for i in liveEnemies.indices {
            liveEnemies[i].node.texture = SpriteFactory.shared.dinoEnemyTexture(kind: .pterodactyl, frame: 0, dizzy: liveEnemies[i].dizzyTimer > 0, retro: retro)
        }
    }

    // MARK: - 5. Universal Safe-Box HUD (`x: 160..1120, y: 636`)

    private func rebuildGameplayHUD() {
        hudLayer.removeAllChildren()
        let retro = isRetro1991

        // Main Status Bar inside Universal Safe Box (x: 160..1120, y: 614..658)
        let bar = SKShapeNode(rectOf: CGSize(width: 960, height: 44), cornerRadius: retro ? 0 : 12)
        bar.position = CGPoint(x: 640, y: 636)
        bar.fillColor = retro ? Palette.vgaDarkGrey : SKColor.hex(0x18120F).withAlphaComponent(0.92)
        bar.strokeColor = retro ? Palette.vgaWhite : Palette.amberGold
        bar.lineWidth = retro ? 3.0 : 2.2
        hudLayer.addChild(bar)

        // 1. Vitality Hearts & Club Tier (Left: x=285)
        let heartsStr = String(repeating: "♥", count: max(0, heroHearts)) + String(repeating: "♡", count: max(0, heroMaxHearts - heroHearts))
        let hpLbl = CoreTextLabelRenderer.makeLabelNode(
            "\(heartsStr) • \(heroClub.displayName)",
            fontSize: 12.5,
            color: Palette.clubCrimson,
            retroMono: true
        )
        hpLbl.position = CGPoint(x: 292, y: 636)
        hpLbl.name = "hud_hp"
        hudLayer.addChild(hpLbl)

        // 2. Iconic Prehistorik FEAST METER (Center: x=625, width=290)
        let meterBg = SKShapeNode(rectOf: CGSize(width: 286, height: 24), cornerRadius: retro ? 0 : 8)
        meterBg.position = CGPoint(x: 625, y: 636)
        meterBg.fillColor = SKColor.hex(0x0B0F17)
        meterBg.strokeColor = feastPercent >= 100 ? Palette.jungleEmerald : Palette.amberGold
        meterBg.lineWidth = 2.0
        meterBg.name = "hud_feast_bg"
        hudLayer.addChild(meterBg)

        let ratio = min(1.0, CGFloat(feastPercent) / 100.0)
        let fillW = max(4, 280 * ratio)
        let meterFill = SKShapeNode(rectOf: CGSize(width: fillW, height: 18), cornerRadius: retro ? 0 : 6)
        meterFill.position = CGPoint(x: 625 - 140 + fillW * 0.5, y: 636)
        meterFill.fillColor = feastPercent >= 100 ? Palette.jungleEmerald : Palette.volcanoOrange
        meterFill.strokeColor = .clear
        meterFill.name = "hud_feast_fill"
        hudLayer.addChild(meterFill)

        let feastText = feastPercent >= 100 ? "FEAST \(feastPercent)% • EXIT OPEN!" : "FEAST METER: \(feastPercent)%"
        let feastLbl = CoreTextLabelRenderer.makeLabelNode(feastText, fontSize: 11.5, color: .white, retroMono: retro)
        feastLbl.position = CGPoint(x: 625, y: 636)
        feastLbl.name = "hud_feast_lbl"
        hudLayer.addChild(feastLbl)

        // 3. Score & Stage Clock (Right: x=958)
        let rightLbl = CoreTextLabelRenderer.makeLabelNode(
            String(format: "SCORE %06d  •  %02dS", score, max(0, Int(ceil(stageTimer)))),
            fontSize: 12.5,
            color: Palette.amberGold,
            retroMono: true
        )
        rightLbl.position = CGPoint(x: 960, y: 636)
        rightLbl.name = "hud_score"
        hudLayer.addChild(rightLbl)

        // Optional Boss Health Bar (Volcano Rex Arena: y=592)
        if bossActive && mode == .platformStage {
            let bCard = SKShapeNode(rectOf: CGSize(width: 450, height: 28), cornerRadius: retro ? 0 : 8)
            bCard.position = CGPoint(x: 640, y: 592)
            bCard.fillColor = SKColor.hex(0x260E12).withAlphaComponent(0.92)
            bCard.strokeColor = Palette.clubCrimson
            bCard.lineWidth = 2.0
            bCard.name = "hud_boss_card"
            let pips = String(repeating: "█ ", count: max(0, bossHP)) + String(repeating: "░ ", count: max(0, bossMaxHP - bossHP))
            let bLbl = CoreTextLabelRenderer.makeLabelNode("KING CHOMPER T-REX: \(pips)", fontSize: 12, color: Palette.amberGold, retroMono: true)
            bLbl.name = "hud_boss_lbl"
            bCard.addChild(bLbl)
            hudLayer.addChild(bCard)
        }
    }

    private func syncHUDValues() {
        let heartsStr = String(repeating: "♥", count: max(0, heroHearts)) + String(repeating: "♡", count: max(0, heroMaxHearts - heroHearts))
        (hudLayer.childNode(withName: "hud_hp") as? SKLabelNode)?.text = "\(heartsStr) • \(heroClub.displayName)"
        (hudLayer.childNode(withName: "hud_score") as? SKLabelNode)?.text = String(format: "SCORE %06d  •  %02dS", score, max(0, Int(ceil(stageTimer))))

        if let fLbl = hudLayer.childNode(withName: "hud_feast_lbl") as? SKLabelNode {
            fLbl.text = feastPercent >= 100
                ? (mode == .gliderBonus ? "SKY FEAST \(feastPercent)% ★" : "FEAST \(feastPercent)% • EXIT OPEN!")
                : "FEAST METER: \(feastPercent)%"
        }
        if let oldFill = hudLayer.childNode(withName: "hud_feast_fill") as? SKShapeNode {
            oldFill.removeFromParent()
            let ratio = min(1.0, CGFloat(feastPercent) / 100.0)
            let fillW = max(4, 280 * ratio)
            let meterFill = SKShapeNode(rectOf: CGSize(width: fillW, height: 18), cornerRadius: isRetro1991 ? 0 : 6)
            meterFill.position = CGPoint(x: 625 - 140 + fillW * 0.5, y: 636)
            meterFill.fillColor = feastPercent >= 100 ? Palette.jungleEmerald : Palette.volcanoOrange
            meterFill.strokeColor = .clear
            meterFill.name = "hud_feast_fill"
            hudLayer.insertChild(meterFill, at: 2)
        }
        if bossActive, let bCard = hudLayer.childNode(withName: "hud_boss_card"), let bLbl = bCard.childNode(withName: "hud_boss_lbl") as? SKLabelNode {
            let pips = String(repeating: "█ ", count: max(0, bossHP)) + String(repeating: "░ ", count: max(0, bossMaxHP - bossHP))
            bLbl.text = "KING CHOMPER T-REX: \(pips)"
        }
    }

    // MARK: - 6. 120Hz Gameplay Frame Simulation

    override func update(_ currentTime: TimeInterval) {
        let rawDt = lastUpdateTime == 0 ? (1.0 / 60.0) : (currentTime - lastUpdateTime)
        lastUpdateTime = currentTime
        let dt = min(1.0 / 24.0, max(1.0 / 240.0, rawDt))
        guard !isUserPaused else { return }

        sceneClock += dt
        pollHardwareGamepads()

        switch mode {
        case .titleMenu:
            if let pt = titlePteroNode {
                pt.position.x += CGFloat(68.0 * dt)
                pt.position.y = 538 + sin(CGFloat(sceneClock * 4.0)) * 10
                if pt.position.x > 525 { pt.position.x = 205 }
                let fr = Int(sceneClock * 6) % 2
                pt.texture = SpriteFactory.shared.dinoEnemyTexture(kind: .pterodactyl, frame: fr, dizzy: false, retro: isRetro1991)
            }

        case .platformStage:
            updatePlatformStage(dt: dt)

        case .gliderBonus:
            updateGliderBonus(dt: dt)

        default:
            break
        }

        keyJustPressedClub = false
        keyJustPressedJump = false
        TouchInputState.shared.primaryJustPressed = false
        TouchInputState.shared.secondaryJustPressed = false
    }

    private func updatePlatformStage(dt: Double) {
        if stageFinishTimer > 0 {
            stageFinishTimer -= dt
            if stageFinishTimer <= 0 {
                concludeStage(won: stageWonFlag)
            }
            return
        }

        guard let bp = activeBlueprint else { return }

        stageTimer -= dt
        if comboTimer > 0 {
            comboTimer -= dt
            if comboTimer <= 0 { comboCount = 0 }
        }
        if stageTimer <= 0 {
            if isQuickDinoBash && feastPercent >= 60 {
                triggerStageClear()
            } else {
                triggerStageGameOver(reason: "TIME UP! BOGA'S BELLY IS STILL RUMBLING!")
            }
            return
        }

        // 1. Update Moving Platforms
        for i in livePlatforms.indices where livePlatforms[i].def.moveAmpX > 0 {
            livePlatforms[i].prevX = livePlatforms[i].currentX
            let nx = livePlatforms[i].def.x + sin(CGFloat(sceneClock * livePlatforms[i].def.moveSpeed)) * livePlatforms[i].def.moveAmpX
            livePlatforms[i].currentX = nx
            livePlatforms[i].node.position.x = nx
        }

        // 2. Read Player Controls
        let (dx, dy, clubJust, jumpJust) = readCombinedControls()
        heroInvulnTimer = max(0, heroInvulnTimer - dt)
        heroHurtTimer = max(0, heroHurtTimer - dt)
        swingTimer = max(0, swingTimer - dt)

        if dx > 0.12 { heroFacingRight = true }
        else if dx < -0.12 { heroFacingRight = false }

        // Horizontal velocity (crisp arcade control vs slippery Glacier ice!)
        let maxRunSpeed: CGFloat = 295
        if heroHurtTimer <= 0 {
            if heroOnIce && heroGrounded {
                let targetVX = dx * (maxRunSpeed * 1.12)
                heroVel.dx += (targetVX - heroVel.dx) * min(1.0, CGFloat(dt * 4.2))
            } else {
                let targetVX = dx * maxRunSpeed
                heroVel.dx += (targetVX - heroVel.dx) * min(1.0, CGFloat(dt * 16.0))
            }
        }

        // Jump & Coyote Time
        if heroGrounded {
            coyoteTimer = 0.11
        } else {
            coyoteTimer = max(0, coyoteTimer - dt)
        }
        if jumpJust && coyoteTimer > 0 && !groundPoundActive {
            heroVel.dy = 575
            heroGrounded = false
            coyoteTimer = 0
            AudioSynth.shared.trigger(.jumpSlideWhistle)
            HapticsManager.tap()
        }

        // Club Bash vs Prehistorik Ground-Pound!
        if clubJust && heroHurtTimer <= 0 {
            if !heroGrounded && dy < -0.32 && !groundPoundActive {
                // Prehistorik Ground-Pound Slam!
                groundPoundActive = true
                heroVel.dx *= 0.25
                heroVel.dy = -780
                AudioSynth.shared.trigger(.clubSwing)
            } else if !groundPoundActive {
                performClubSwing()
            }
        }

        // Gravity & Position Integration
        let gravity: CGFloat = groundPoundActive ? -1950 : -1320
        heroVel.dy = max(-860, heroVel.dy + gravity * CGFloat(dt))

        let prevY = heroPos.y
        var nextX = heroPos.x + heroVel.dx * CGFloat(dt)
        var nextY = heroPos.y + heroVel.dy * CGFloat(dt)

        let minWorldX: CGFloat = bp.isBossArena ? 175 : 175
        let maxWorldX: CGFloat = bp.isBossArena ? 1105 : (bp.worldWidth - 150)
        nextX = max(minWorldX, min(maxWorldX, nextX))

        // Platform Landing Resolution (foot offset = 30 below heroPos.y)
        let footHalf: CGFloat = 18
        let prevFootY = prevY - 30
        let nextFootY = nextY - 30
        var landedPlatformIdx: Int? = nil

        if heroVel.dy <= 0 {
            for (idx, plat) in livePlatforms.enumerated() {
                let halfW = plat.def.width * 0.5 + footHalf
                if abs(nextX - plat.currentX) <= halfW {
                    if prevFootY >= plat.def.topY - 12 && nextFootY <= plat.def.topY + 6 {
                        nextY = plat.def.topY + 30
                        heroVel.dy = 0
                        landedPlatformIdx = idx
                        break
                    }
                }
            }
        }

        if let pIdx = landedPlatformIdx {
            let wasPound = groundPoundActive
            heroGrounded = true
            groundPoundActive = false
            heroOnIce = livePlatforms[pIdx].def.isIce
            nextX += (livePlatforms[pIdx].currentX - livePlatforms[pIdx].prevX)
            if wasPound {
                executeGroundPoundImpact(at: CGPoint(x: nextX, y: nextY - 22))
            }
        } else {
            heroGrounded = false
        }

        // Fall into Lava / Glacier Chasm Recovery
        if nextY < 95 {
            hurtHero(at: CGPoint(x: nextX, y: 180))
            nextX = max(220, nextX - 140)
            nextY = 340
            heroVel = CGVector(dx: 0, dy: 120)
        }

        heroPos = CGPoint(x: nextX, y: nextY)

        // 3. Bouncy Palm & Mushroom Springs
        for sp in liveSprings {
            if heroVel.dy <= 40 && abs(heroPos.x - sp.def.x) < 40 && abs((heroPos.y - 28) - sp.def.y) < 26 {
                heroVel.dy = 735
                heroGrounded = false
                groundPoundActive = false
                AudioSynth.shared.trigger(.springBounce)
                HapticsManager.mediumImpact()
                sp.node.run(.sequence([.scaleY(to: 0.65, duration: 0.06), .scaleY(to: 1.15, duration: 0.09), .scaleY(to: 1.0, duration: 0.08)]))
                spawnComicStarburst(text: "BOING!", at: CGPoint(x: sp.def.x, y: sp.def.y + 34), color: Palette.jungleEmerald, inWorld: true)
            }
        }

        // 4. Magma Geyser Vents
        for i in liveGeysers.indices {
            let cyc = (sin(sceneClock * 2.3 + liveGeysers[i].def.phase) + 1.0) * 0.5
            let gh = 22 + CGFloat(cyc) * liveGeysers[i].def.maxHeight
            liveGeysers[i].currentHeight = gh
            liveGeysers[i].plumeNode.path = CGPath(roundedRect: CGRect(x: -17, y: 0, width: 34, height: gh), cornerWidth: 12, cornerHeight: 12, transform: nil)
            liveGeysers[i].plumeNode.position = CGPoint(x: liveGeysers[i].def.x, y: liveGeysers[i].def.baseY)
            if gh > 70 && abs(heroPos.x - liveGeysers[i].def.x) < 28 && (heroPos.y - 24) < (liveGeysers[i].def.baseY + gh) {
                hurtHero(at: heroPos)
            }
        }

        // 5. Collect Giant Foods & Treasures
        updateCollectibles(dt: dt, isGlider: false)

        // 6. Update Prehistoric Enemies & Projectiles
        updateEnemiesAndHazards(dt: dt)

        // 7. Update Boss King Chomper T-Rex (World 5)
        if bossActive {
            updateKingChomperBoss(dt: dt)
        }

        // 8. Check Stage Exit Cave!
        if !bp.isBossArena {
            if abs(heroPos.x - bp.exitX) < 54 && abs(heroPos.y - bp.exitY) < 64 {
                if feastPercent >= 100 || isAutopilotActive {
                    triggerStageClear()
                    return
                } else if Int(sceneClock * 2) % 2 == 0 {
                    showFloatingBanner("GOBBLE MORE FOOD TO REACH 100% FEAST!", color: Palette.amberGold)
                }
            }
            if isQuickDinoBash && feastPercent >= 100 {
                triggerStageClear()
                return
            }
        }

        // 9. Animate Boga & Scroll Camera
        heroAnimClock += dt * (abs(heroVel.dx) > 35 ? 10.5 : 3.0)
        refreshHeroSprite()
        updateCameraScroll()
        syncHUDValues()
    }

    private func performClubSwing() {
        swingTimer = 0.22
        AudioSynth.shared.trigger(.clubSwing)
        HapticsManager.lightImpact()

        let dir: CGFloat = heroFacingRight ? 1.0 : -1.0
        let hitCenter = CGPoint(x: heroPos.x + dir * (heroClub.reach * 0.62), y: heroPos.y + 4)
        let hitRadius = heroClub.reach * 0.72

        // Smash Secret Cracked Stone Blocks!
        for i in liveBlocks.indices where !liveBlocks[i].broken {
            if hypot(liveBlocks[i].def.x - hitCenter.x, liveBlocks[i].def.y - hitCenter.y) < hitRadius + 16 {
                crackSecretBlock(at: i)
            }
        }

        // Bat Spicy Volcano Peppers toward King Chomper!
        for i in livePeppers.indices where !livePeppers[i].batted {
            if hypot(livePeppers[i].pos.x - hitCenter.x, livePeppers[i].pos.y - hitCenter.y) < hitRadius + 18 {
                livePeppers[i].batted = true
                let toBoss: CGFloat = (bossPos.x >= livePeppers[i].pos.x) ? 1.0 : -1.0
                livePeppers[i].vx = toBoss * 480
                livePeppers[i].vy = 210
                AudioSynth.shared.trigger(.clubBonk)
                spawnComicStarburst(text: "PEPPER SHOT!", at: livePeppers[i].pos, color: Palette.volcanoOrange, inWorld: true)
            }
        }

        // Deflect Snowballs / Boulders!
        for i in liveHazards.indices.reversed() {
            if hypot(liveHazards[i].pos.x - hitCenter.x, liveHazards[i].pos.y - hitCenter.y) < hitRadius + 12 {
                AudioSynth.shared.trigger(.clubBonk)
                spawnComicStarburst(text: "SMASH! +200", at: liveHazards[i].pos, color: Palette.amberGold, inWorld: true)
                score += 200
                liveHazards[i].node.removeFromParent()
                liveHazards.remove(at: i)
            }
        }

        // Bonk Grumpy Dinosaurs!
        for i in liveEnemies.indices where !liveEnemies[i].knockedOut {
            if hypot(liveEnemies[i].pos.x - hitCenter.x, liveEnemies[i].pos.y - hitCenter.y) < hitRadius + 18 {
                bonkEnemy(index: i, isGroundSlam: false)
            }
        }

        // Bonk King Chomper T-Rex Boss!
        if bossActive, hypot(bossPos.x - hitCenter.x, bossPos.y - hitCenter.y) < hitRadius + 68 {
            if bossDizzyTimer > 0 {
                bossDizzyTimer = 0
                damageKingChomper()
            } else {
                // Direct bravery bonk nudges him & stuns briefly if he just lunged!
                AudioSynth.shared.trigger(.clubBonk)
                bossDizzyTimer = 1.6
                bossNode?.texture = SpriteFactory.shared.bossRexTexture(pose: .dizzy, retro: isRetro1991)
                spawnComicStarburst(text: "DIZZY SNOUT!", at: CGPoint(x: bossPos.x - 45, y: bossPos.y + 42), color: Palette.amberGold, inWorld: true)
            }
        }
    }

    private func executeGroundPoundImpact(at pt: CGPoint) {
        AudioSynth.shared.trigger(.groundPound)
        HapticsManager.heavyImpact()
        triggerScreenShake(intensity: 9.0)
        spawnComicStarburst(text: "SLAM!", at: CGPoint(x: pt.x, y: pt.y + 28), color: Palette.volcanoOrange, inWorld: true)

        // Shockwave Ring
        let ring = SKShapeNode(ellipseOf: CGSize(width: 44, height: 18))
        ring.position = pt
        ring.strokeColor = Palette.amberGold
        ring.lineWidth = 3.5
        ring.fillColor = .clear
        ring.zPosition = 25
        cameraStrip.addChild(ring)
        ring.run(.sequence([
            .group([.scaleX(to: 4.5, duration: 0.24), .scaleY(to: 2.2, duration: 0.24), .fadeOut(withDuration: 0.24)]),
            .removeFromParent()
        ]))

        // Crack nearby Secret Stone Blocks
        for i in liveBlocks.indices where !liveBlocks[i].broken {
            if hypot(liveBlocks[i].def.x - pt.x, liveBlocks[i].def.y - pt.y) < 165 {
                crackSecretBlock(at: i)
            }
        }

        // Shake Hidden Giant Delicacies out of Tree Canopies!
        for i in livePlatforms.indices {
            if let hidden = livePlatforms[i].def.canopyFood, !livePlatforms[i].canopyShaken {
                if abs(livePlatforms[i].currentX - pt.x) < 260 {
                    livePlatforms[i].canopyShaken = true
                    livePlatforms[i].canopyBadge?.removeFromParent()
                    let dropOrigin = CGPoint(x: livePlatforms[i].currentX + 24, y: livePlatforms[i].def.topY + 125)
                    spawnFoodItem(kind: hidden, at: dropOrigin, airborne: true, vx: 45, vy: 210)
                    AudioSynth.shared.trigger(.gemChime)
                    showFloatingBanner("TREE SECRET SHAKEN LOOSE: \(hidden.displayName)!", color: Palette.jungleEmerald)
                    if let m = PersistenceManager.shared.unlockMedal("canopy_shaker") {
                        presentMedalToast(m)
                    }
                }
            }
        }

        // Stun nearby Dinosaurs!
        for i in liveEnemies.indices where !liveEnemies[i].knockedOut {
            if hypot(liveEnemies[i].pos.x - pt.x, liveEnemies[i].pos.y - pt.y) < 195 {
                bonkEnemy(index: i, isGroundSlam: true)
            }
        }

        // Shake loose a Spicy Volcano Pepper in Boss Arena!
        if bossActive {
            spawnSpicyPepper(at: CGPoint(x: max(220, min(980, pt.x + 85)), y: 215))
        }
    }

    private func crackSecretBlock(at idx: Int) {
        guard !liveBlocks[idx].broken else { return }
        liveBlocks[idx].broken = true
        let pos = liveBlocks[idx].node.position
        liveBlocks[idx].node.removeFromParent()
        AudioSynth.shared.trigger(.stoneCrack)
        triggerScreenShake(intensity: 6.0)
        spawnComicStarburst(text: "SECRET!", at: CGPoint(x: pos.x, y: pos.y + 24), color: Palette.amberGold, inWorld: true)

        if let food = liveBlocks[idx].def.rewardFood {
            spawnFoodItem(kind: food, at: CGPoint(x: pos.x - 16, y: pos.y + 18), airborne: true, vx: -35, vy: 220)
        }
        if let tr = liveBlocks[idx].def.rewardTreasure {
            spawnTreasureItem(kind: tr, at: CGPoint(x: pos.x + 18, y: pos.y + 16))
        }
        if let m = PersistenceManager.shared.unlockMedal("secret_cracker") {
            presentMedalToast(m)
        }
    }

    private func bonkEnemy(index i: Int, isGroundSlam: Bool) {
        AudioSynth.shared.trigger(.clubBonk)
        AudioSynth.shared.trigger(.dizzyStars)
        HapticsManager.mediumImpact()
        triggerScreenShake(intensity: 6.5)
        PersistenceManager.shared.recordBonk()
        if let m = PersistenceManager.shared.unlockMedal("first_bonk") {
            presentMedalToast(m)
        }

        comboCount += 1
        comboTimer = 3.2
        let mult = min(4, max(1, comboCount))
        let pts = liveEnemies[i].kind.points * mult
        score += pts

        let alreadyDizzy = liveEnemies[i].dizzyTimer > 0
        liveEnemies[i].stamina -= heroClub.power

        if alreadyDizzy || liveEnemies[i].stamina <= 0 {
            // Slapstick cartoon home-run launch (100% family-friendly, zero gore!) + bonus food pop!
            liveEnemies[i].knockedOut = true
            let ep = liveEnemies[i].pos
            let words = ["BONK!", "POW!", "WHACK!", "KAPOW!"]
            spawnComicStarburst(text: "\(words[i % words.count]) +\(pts)", at: CGPoint(x: ep.x, y: ep.y + 36), color: Palette.amberGold, inWorld: true)

            let dropFoods: [FoodKind] = [.mammothDrumstick, .stoneBurger, .giantPineapple, .goldenBanana, .honeycomb]
            spawnFoodItem(kind: dropFoods[i % dropFoods.count], at: CGPoint(x: ep.x, y: ep.y + 20), airborne: true, vx: 0, vy: 230)

            let dir: CGFloat = heroFacingRight ? 110 : -110
            liveEnemies[i].node.texture = SpriteFactory.shared.dinoEnemyTexture(kind: liveEnemies[i].kind, frame: 0, dizzy: true, retro: isRetro1991)
            liveEnemies[i].node.run(.sequence([
                .group([
                    .moveBy(x: dir, y: 155, duration: 0.38),
                    .rotate(byAngle: 4.2, duration: 0.38),
                    .fadeOut(withDuration: 0.38)
                ]),
                .removeFromParent()
            ]))
        } else {
            liveEnemies[i].dizzyTimer = 4.0
            liveEnemies[i].node.texture = SpriteFactory.shared.dinoEnemyTexture(kind: liveEnemies[i].kind, frame: 0, dizzy: true, retro: isRetro1991)
            spawnComicStarburst(text: "DIZZY! +\(pts / 2)", at: CGPoint(x: liveEnemies[i].pos.x, y: liveEnemies[i].pos.y + 34), color: Palette.tropicalSky, inWorld: true)
        }
    }

    private func updateCollectibles(dt: Double, isGlider: Bool) {
        let pickupRadius: CGFloat = isGlider ? 56 : 46

        for i in liveFoods.indices where !liveFoods[i].collected {
            if liveFoods[i].airborneDrop {
                liveFoods[i].vy -= 720 * CGFloat(dt)
                liveFoods[i].pos.x += liveFoods[i].vx * CGFloat(dt)
                liveFoods[i].pos.y += liveFoods[i].vy * CGFloat(dt)
                if liveFoods[i].pos.y <= 212 {
                    liveFoods[i].pos.y = 212
                    liveFoods[i].basePos = liveFoods[i].pos
                    liveFoods[i].airborneDrop = false
                }
                liveFoods[i].node.position = liveFoods[i].pos
            } else {
                let bob = sin(CGFloat(sceneClock * 3.6 + liveFoods[i].bobPhase)) * 6.5
                liveFoods[i].pos = CGPoint(x: liveFoods[i].basePos.x, y: liveFoods[i].basePos.y + bob)
                liveFoods[i].node.position = liveFoods[i].pos
            }

            if hypot(liveFoods[i].pos.x - heroPos.x, liveFoods[i].pos.y - heroPos.y) < pickupRadius {
                liveFoods[i].collected = true
                let f = liveFoods[i].kind
                let fp = liveFoods[i].pos
                liveFoods[i].node.run(.sequence([
                    .group([.scale(to: 1.55, duration: 0.14), .fadeOut(withDuration: 0.14)]),
                    .removeFromParent()
                ]))
                AudioSynth.shared.trigger(.foodGobble)
                HapticsManager.tap()
                PersistenceManager.shared.recordFoodGobbled()

                let bonusMul = feastPercent >= 100 ? 2 : 1
                let gainedPts = f.points * bonusMul
                score += gainedPts
                feastPercent = min(199, feastPercent + f.feastPercent)
                spawnComicStarburst(text: "YUM! +\(gainedPts)", at: CGPoint(x: fp.x, y: fp.y + 26), color: Palette.jungleEmerald, inWorld: true)

                if feastPercent >= 100 && !feastFullAnnounced {
                    feastFullAnnounced = true
                    AudioSynth.shared.trigger(.megaFeastFull)
                    HapticsManager.success()
                    exitCaveNode?.texture = SpriteFactory.shared.exitCaveTexture(isOpen: true, retro: isRetro1991)
                    showFloatingBanner("100% FULL BELLY! EXIT CAVE IS NOW OPEN!", color: Palette.jungleEmerald)
                    if let m = PersistenceManager.shared.unlockMedal("full_belly") {
                        presentMedalToast(m)
                    }
                }
                if feastPercent >= 130, let m = PersistenceManager.shared.unlockMedal("gourmet_combo") {
                    presentMedalToast(m)
                }
            }
        }

        for i in liveTreasures.indices where !liveTreasures[i].collected {
            if hypot(liveTreasures[i].pos.x - heroPos.x, liveTreasures[i].pos.y - heroPos.y) < pickupRadius {
                liveTreasures[i].collected = true
                let tr = liveTreasures[i].kind
                let tp = liveTreasures[i].pos
                liveTreasures[i].node.removeFromParent()
                AudioSynth.shared.trigger(.gemChime)
                HapticsManager.mediumImpact()
                score += tr.points

                switch tr {
                case .stoneWheel:
                    spawnComicStarburst(text: "WHEEL +\(tr.points)", at: tp, color: Palette.boneCream, inWorld: true)
                case .amberGem:
                    spawnComicStarburst(text: "AMBER +\(tr.points)", at: tp, color: Palette.amberGold, inWorld: true)
                case .malletUpgrade:
                    if heroClub.rawValue < ClubTier.stoneMallet.rawValue { heroClub = .stoneMallet }
                    showFloatingBanner("CLUB UPGRADED: GRANITE STONE MALLET!", color: Palette.tropicalSky)
                case .boneHammerUpgrade:
                    heroClub = .boneHammer
                    showFloatingBanner("MEGA UPGRADE: MAMMOTH BONE HAMMER!", color: Palette.berryPurple)
                    if let m = PersistenceManager.shared.unlockMedal("bone_hammer_pro") {
                        presentMedalToast(m)
                    }
                case .vitalitySteak:
                    heroHearts = min(heroMaxHearts, heroHearts + 1)
                    showFloatingBanner("+1 VITALITY HEART RESTORED!", color: Palette.clubCrimson)
                }
            }
        }
    }

    private func updateEnemiesAndHazards(dt: Double) {
        let retro = isRetro1991
        for i in liveEnemies.indices where !liveEnemies[i].knockedOut {
            if liveEnemies[i].dizzyTimer > 0 {
                liveEnemies[i].dizzyTimer = max(0, liveEnemies[i].dizzyTimer - dt)
                if liveEnemies[i].dizzyTimer <= 0 {
                    liveEnemies[i].node.texture = SpriteFactory.shared.dinoEnemyTexture(kind: liveEnemies[i].kind, frame: 0, dizzy: false, retro: retro)
                }
                continue
            }

            liveEnemies[i].animClock += dt * 7.0
            liveEnemies[i].pos.x += liveEnemies[i].vx * CGFloat(dt)
            if liveEnemies[i].pos.x < liveEnemies[i].minX {
                liveEnemies[i].pos.x = liveEnemies[i].minX
                liveEnemies[i].vx = abs(liveEnemies[i].vx)
            } else if liveEnemies[i].pos.x > liveEnemies[i].maxX {
                liveEnemies[i].pos.x = liveEnemies[i].maxX
                liveEnemies[i].vx = -abs(liveEnemies[i].vx)
            }

            if liveEnemies[i].kind == .pterodactyl {
                liveEnemies[i].pos.y = liveEnemies[i].baseY + sin(CGFloat(sceneClock * 3.4 + Double(i))) * 26
            }

            liveEnemies[i].node.position = liveEnemies[i].pos
            liveEnemies[i].node.xScale = liveEnemies[i].vx >= 0 ? 1 : -1
            let frame = Int(liveEnemies[i].animClock) % 2
            liveEnemies[i].node.texture = SpriteFactory.shared.dinoEnemyTexture(kind: liveEnemies[i].kind, frame: frame, dizzy: false, retro: retro)

            // Snow Yeti tosses comical snowballs when Boga is nearby!
            if liveEnemies[i].kind == .snowYeti && abs(liveEnemies[i].pos.x - heroPos.x) < 420 {
                liveEnemies[i].throwCooldown -= dt
                if liveEnemies[i].throwCooldown <= 0 {
                    liveEnemies[i].throwCooldown = 2.4
                    let dir: CGFloat = (heroPos.x >= liveEnemies[i].pos.x) ? 1 : -1
                    spawnHazardBall(kind: .snowball, at: CGPoint(x: liveEnemies[i].pos.x + dir * 24, y: liveEnemies[i].pos.y + 14), vx: dir * 235, vy: 160)
                }
            }

            // Player vs Enemy Collision (Jump stomp or Ground-Pound bonks them; side bump hurts Boga!)
            if hypot(liveEnemies[i].pos.x - heroPos.x, liveEnemies[i].pos.y - heroPos.y) < 44 {
                if heroVel.dy < -60 && heroPos.y > liveEnemies[i].pos.y + 14 {
                    heroVel.dy = 460
                    bonkEnemy(index: i, isGroundSlam: false)
                } else if swingTimer <= 0 {
                    hurtHero(at: heroPos)
                }
            }
        }

        // Update Rolling Boulders / Snowballs / Magma Meteors
        for idx in liveHazards.indices.reversed() {
            liveHazards[idx].life -= dt
            liveHazards[idx].vy -= 520 * CGFloat(dt)
            liveHazards[idx].pos.x += liveHazards[idx].vx * CGFloat(dt)
            liveHazards[idx].pos.y += liveHazards[idx].vy * CGFloat(dt)
            if liveHazards[idx].pos.y < 194 && liveHazards[idx].kind != .magmaMeteor {
                liveHazards[idx].pos.y = 194
                liveHazards[idx].vy = abs(liveHazards[idx].vy) * 0.45
            }
            liveHazards[idx].node.position = liveHazards[idx].pos
            liveHazards[idx].node.zRotation -= 0.12

            if hypot(liveHazards[idx].pos.x - heroPos.x, liveHazards[idx].pos.y - heroPos.y) < 34 {
                liveHazards[idx].node.removeFromParent()
                liveHazards.remove(at: idx)
                hurtHero(at: heroPos)
                continue
            }
            if liveHazards[idx].life <= 0 || liveHazards[idx].pos.y < 80 {
                liveHazards[idx].node.removeFromParent()
                liveHazards.remove(at: idx)
            }
        }
    }

    private func spawnHazardBall(kind: HazardBallKind, at pt: CGPoint, vx: CGFloat, vy: CGFloat) {
        let spr = SKSpriteNode(texture: SpriteFactory.shared.hazardBallTexture(kind: kind, retro: isRetro1991), size: CGSize(width: 36, height: 36))
        spr.position = pt
        spr.zPosition = 17
        cameraStrip.addChild(spr)
        liveHazards.append(LiveHazardBall(kind: kind, pos: pt, vx: vx, vy: vy, life: 4.5, node: spr))
    }

    // MARK: - 7. Boss Encounter: Giant Comical King Chomper T-Rex

    private func updateKingChomperBoss(dt: Double) {
        // Update Spicy Volcano Peppers
        for idx in livePeppers.indices.reversed() {
            if livePeppers[idx].batted {
                livePeppers[idx].vy -= 540 * CGFloat(dt)
                livePeppers[idx].pos.x += livePeppers[idx].vx * CGFloat(dt)
                livePeppers[idx].pos.y = max(204, livePeppers[idx].pos.y + livePeppers[idx].vy * CGFloat(dt))
                livePeppers[idx].node.position = livePeppers[idx].pos
                livePeppers[idx].node.zRotation += 0.22
            }
            if hypot(livePeppers[idx].pos.x - bossPos.x, livePeppers[idx].pos.y - bossPos.y) < 76 {
                livePeppers[idx].node.removeFromParent()
                livePeppers.remove(at: idx)
                bossDizzyTimer = 4.2
                AudioSynth.shared.trigger(.rexRoar)
                AudioSynth.shared.trigger(.dizzyStars)
                bossNode?.texture = SpriteFactory.shared.bossRexTexture(pose: .dizzy, retro: isRetro1991)
                spawnComicStarburst(text: "TOO SPICY!!", at: CGPoint(x: bossPos.x - 40, y: bossPos.y + 62), color: Palette.clubCrimson, inWorld: true)
                showFloatingBanner("KING CHOMPER IS DIZZY! BONK HIS SNOUT NOW!", color: Palette.amberGold)
            }
        }

        if bossDizzyTimer > 0 {
            bossDizzyTimer = max(0, bossDizzyTimer - dt)
            if bossDizzyTimer <= 0 {
                bossNode?.texture = SpriteFactory.shared.bossRexTexture(pose: .idle, retro: isRetro1991)
            }
            return
        }

        bossActionTimer -= dt
        if bossActionTimer <= 0 {
            bossActionTimer = 2.6
            bossLungeTimer = 0.65
            AudioSynth.shared.trigger(.rexRoar)
            triggerScreenShake(intensity: 6.0)
            bossNode?.texture = SpriteFactory.shared.bossRexTexture(pose: .roar, retro: isRetro1991)
            // Drop 2 magma pebbles from volcano sky + ensure a Spicy Pepper is available!
            spawnHazardBall(kind: .magmaMeteor, at: CGPoint(x: CGFloat.random(in: 260...860), y: 580), vx: CGFloat.random(in: -45...45), vy: -40)
            spawnSpicyPepper(at: CGPoint(x: CGFloat.random(in: 340...740), y: 206))
        }

        let speedMul: CGFloat = bossLungeTimer > 0 ? 2.1 : 1.0
        if bossLungeTimer > 0 {
            bossLungeTimer = max(0, bossLungeTimer - dt)
            if bossLungeTimer <= 0 {
                bossNode?.texture = SpriteFactory.shared.bossRexTexture(pose: .idle, retro: isRetro1991)
            }
        }

        bossPos.x += bossVX * speedMul * CGFloat(dt)
        if bossPos.x < 430 {
            bossPos.x = 430
            bossVX = abs(bossVX)
        } else if bossPos.x > 1015 {
            bossPos.x = 1015
            bossVX = -abs(bossVX)
        }
        bossNode?.position = bossPos
        bossNode?.xScale = bossVX <= 0 ? 1 : -1 // bossRexTexture faces LEFT by default

        if hypot(bossPos.x - heroPos.x, (bossPos.y - 12) - heroPos.y) < 64 && swingTimer <= 0 {
            hurtHero(at: heroPos)
        }
    }

    private func damageKingChomper() {
        bossHP = max(0, bossHP - 1)
        AudioSynth.shared.trigger(.clubBonk)
        AudioSynth.shared.trigger(.rexRoar)
        HapticsManager.heavyImpact()
        triggerScreenShake(intensity: 11.0)
        score += 1500
        feastPercent = min(199, feastPercent + 24)

        spawnComicStarburst(text: "MEGA BONK! +1500", at: CGPoint(x: bossPos.x - 20, y: bossPos.y + 68), color: Palette.amberGold, inWorld: true)
        spawnFoodItem(kind: .mammothDrumstick, at: CGPoint(x: bossPos.x - 65, y: bossPos.y + 40), airborne: true, vx: -95, vy: 250)

        if bossHP <= 0 {
            PersistenceManager.shared.recordBossDefeated()
            if let m = PersistenceManager.shared.unlockMedal("rex_tamer") {
                presentMedalToast(m)
            }
            if isAdventureRun, let m = PersistenceManager.shared.unlockMedal("stone_king_champ") {
                presentMedalToast(m)
            }
            bossNode?.texture = SpriteFactory.shared.bossRexTexture(pose: .dizzy, retro: isRetro1991)
            bossNode?.run(.sequence([
                .moveBy(x: 40, y: -22, duration: 0.35)
            ]))
            triggerStageClear()
        } else {
            bossNode?.texture = SpriteFactory.shared.bossRexTexture(pose: .idle, retro: isRetro1991)
            spawnSpicyPepper(at: CGPoint(x: 480, y: 206))
        }
    }

    // MARK: - 8. Hang-Glider Bonus Update Loop

    private func updateGliderBonus(dt: Double) {
        if stageFinishTimer > 0 {
            stageFinishTimer -= dt
            if stageFinishTimer <= 0 {
                concludeStage(won: true)
            }
            return
        }

        stageTimer -= dt
        let scrollSpeed: CGFloat = 245
        gliderDistance += scrollSpeed * CGFloat(dt)

        let (dx, dy, clubJust, jumpJust) = readCombinedControls()
        if clubJust || jumpJust {
            heroVel.dy = 250
            AudioSynth.shared.trigger(.gliderWhoosh)
            HapticsManager.tap()
        } else {
            heroVel.dy += (-280 + dy * 540) * CGFloat(dt)
            heroVel.dy = max(-240, min(260, heroVel.dy))
        }

        heroPos.x = max(210, min(680, heroPos.x + dx * 240 * CGFloat(dt)))
        heroPos.y = max(205, min(565, heroPos.y + heroVel.dy * CGFloat(dt)))
        heroNode?.position = heroPos
        heroNode?.zRotation = max(-0.26, min(0.28, heroVel.dy * 0.0009))

        // Scroll fruits, gems, and Pterodactyls leftward across screen
        for i in liveFoods.indices where !liveFoods[i].collected {
            liveFoods[i].basePos.x -= scrollSpeed * CGFloat(dt)
        }
        for i in liveTreasures.indices where !liveTreasures[i].collected {
            liveTreasures[i].pos.x -= scrollSpeed * CGFloat(dt)
            liveTreasures[i].node.position = liveTreasures[i].pos
        }
        for i in liveEnemies.indices {
            liveEnemies[i].pos.x -= (scrollSpeed + 95) * CGFloat(dt)
            liveEnemies[i].pos.y = liveEnemies[i].baseY + sin(CGFloat(sceneClock * 4.0 + Double(i))) * 34
            liveEnemies[i].node.position = liveEnemies[i].pos
            liveEnemies[i].node.xScale = -1
            let fr = Int(sceneClock * 7.0) % 2
            liveEnemies[i].node.texture = SpriteFactory.shared.dinoEnemyTexture(kind: .pterodactyl, frame: fr, dizzy: false, retro: isRetro1991)
            if heroInvulnTimer <= 0 && hypot(liveEnemies[i].pos.x - heroPos.x, liveEnemies[i].pos.y - heroPos.y) < 42 {
                heroInvulnTimer = 1.0
                AudioSynth.shared.trigger(.clubBonk)
                spawnComicStarburst(text: "BUMP!", at: heroPos, color: Palette.volcanoOrange, inWorld: true)
            }
        }
        heroInvulnTimer = max(0, heroInvulnTimer - dt)

        // Spawn fresh floating fruit arcs & gems!
        gliderSpawnClock += dt
        if gliderSpawnClock >= 0.95 {
            gliderSpawnClock = 0
            let kinds: [FoodKind] = [.giantPineapple, .stoneBurger, .mammothDrumstick, .iceCreamSundae, .megaCroissant, .honeycomb]
            let baseY = CGFloat.random(in: 255...515)
            for k in 0..<3 {
                let kind = kinds[(Int(gliderDistance) + k) % kinds.count]
                spawnFoodItem(kind: kind, at: CGPoint(x: 1280 + CGFloat(k) * 76, y: baseY + CGFloat(k - 1) * 28), phase: Double(k))
            }
            spawnTreasureItem(kind: .amberGem, at: CGPoint(x: 1356, y: min(555, baseY + 66)))

            if Int(gliderDistance) % 2 == 0 {
                let pY = CGFloat.random(in: 250...520)
                let pNode = SKSpriteNode(texture: SpriteFactory.shared.dinoEnemyTexture(kind: .pterodactyl, frame: 0, dizzy: false, retro: isRetro1991), size: CGSize(width: 66, height: 56))
                pNode.position = CGPoint(x: 1360, y: pY)
                pNode.xScale = -1
                pNode.zPosition = 16
                cameraStrip.addChild(pNode)
                liveEnemies.append(LiveEnemy(id: 99, kind: .pterodactyl, pos: pNode.position, vx: -95, minX: -200, maxX: 2000, baseY: pY, stamina: 1, node: pNode))
            }
        }

        updateCollectibles(dt: dt, isGlider: true)
        syncHUDValues()

        if gliderDistance >= gliderGoalDistance || stageTimer <= 0 {
            if let m = PersistenceManager.shared.unlockMedal("sky_glider_ace") {
                presentMedalToast(m)
            }
            triggerStageClear()
        }
    }

    // MARK: - 9. Damage, Camera Framing, Stage Completion & Victory Modal

    private func hurtHero(at pt: CGPoint) {
        guard heroInvulnTimer <= 0 && !isAutopilotActive else { return }
        heroHearts = max(0, heroHearts - 1)
        heroInvulnTimer = 1.35
        heroHurtTimer = 0.28
        heroVel = CGVector(dx: heroFacingRight ? -180 : 180, dy: 280)
        AudioSynth.shared.trigger(.hurtOof)
        HapticsManager.heavyImpact()
        triggerScreenShake(intensity: 8.0)
        spawnComicStarburst(text: "OOF!", at: CGPoint(x: pt.x, y: pt.y + 30), color: Palette.clubCrimson, inWorld: true)

        if heroHearts <= 0 {
            triggerStageGameOver(reason: "DIZZY CAVEMAN! REST BY THE CAMPFIRE & TRY AGAIN!")
        }
    }

    private func refreshHeroSprite() {
        guard let node = heroNode, mode == .platformStage else { return }
        let pose: BogaPose = {
            if heroHurtTimer > 0 { return .dizzy }
            if groundPoundActive { return .groundPound }
            if swingTimer > 0 { return .swing }
            if !heroGrounded { return .jump }
            if abs(heroVel.dx) > 32 {
                return (Int(heroAnimClock) % 2 == 0) ? .runA : .runB
            }
            return .idle
        }()
        node.texture = SpriteFactory.shared.bogaTexture(pose: pose, club: heroClub, retro: isRetro1991)
        node.position = heroPos
        node.xScale = heroFacingRight ? 1 : -1
        node.alpha = (heroInvulnTimer > 0 && Int(sceneClock * 16) % 2 == 0) ? 0.55 : 1.0
    }

    private func updateCameraScroll() {
        guard let bp = activeBlueprint else { return }
        if bp.isBossArena {
            camX = 0
        } else {
            let desired = heroPos.x - 480
            camX = max(0, min(bp.worldWidth - 1280, desired))
        }
        cameraStrip.position.x = -camX
        parallaxMid.position.x = -camX * 0.42
        parallaxFar.position.x = -camX * 0.18
    }

    private func triggerStageClear() {
        guard stageFinishTimer <= 0 else { return }
        stageWonFlag = true
        stageFinishTimer = 1.05
        let timeBonus = max(0, Int(stageTimer)) * 25
        score += timeBonus + 1000
        AudioSynth.shared.trigger(.megaFeastFull)
        HapticsManager.success()
        showFloatingBanner("STAGE FEAST COMPLETE! TIME BONUS +\(timeBonus)!", color: Palette.jungleEmerald)
    }

    private func triggerStageGameOver(reason: String) {
        guard stageFinishTimer <= 0 else { return }
        stageWonFlag = false
        victorySubtitle = reason
        stageFinishTimer = 1.05
        AudioSynth.shared.trigger(.hurtOof)
    }

    private func concludeStage(won: Bool) {
        let tag = mode == .gliderBonus ? "GLIDER" : (isQuickDinoBash ? "RUSH" : (currentWorld == .volcanoRexArena ? "BOSS REX" : "ADVENTURE"))
        PersistenceManager.shared.recordHighScore(initials: "BOG", score: score, worldReached: currentWorld.rawValue, modeTag: tag)

        if won {
            if mode == .platformStage {
                PersistenceManager.shared.recordStageCleared(world: currentWorld.rawValue)
                if currentWorld == .glacierPeak, let m = PersistenceManager.shared.unlockMedal("glacier_surfer") {
                    presentMedalToast(m)
                }
            }
            canAdvanceNextWorld = (mode == .platformStage && isAdventureRun && currentWorld.nextWorld != nil)
            victoryTitle = (currentWorld == .volcanoRexArena && mode == .platformStage)
                ? "KING CHOMPER DEFEATED! GRAND FEAST!"
                : "BELLY FULL! STAGE CLEARED!"
            victorySubtitle = "Feast Meter: \(feastPercent)%  •  Total Score: \(score)  •  Weapon: \(heroClub.displayName)"
        } else {
            canAdvanceNextWorld = false
            victoryTitle = "STILL HUNGRY! TRY AGAIN!"
        }
        enterVictoryScreen()
    }

    private func enterVictoryScreen() {
        mode = .stageVictory
        clearSceneLayers()
        AudioSynth.shared.setTrack(.feastVictory)
        renderVictoryScreen()
    }

    private func renderVictoryScreen() {
        bgLayer.removeAllChildren()
        overlayLayer.removeAllChildren()
        drawPrehistoricBackdrop(skyTop: 0x16294A, skyBot: 0x3D6A4E, world: currentWorld, includeVolcano: false)

        let card = makeModalCard(title: victoryTitle, subtitle: victorySubtitle)
        let boga = SKSpriteNode(
            texture: SpriteFactory.shared.bogaTexture(pose: stageWonFlag ? .cheer : .dizzy, club: heroClub, retro: isRetro1991),
            size: CGSize(width: 112, height: 100)
        )
        boga.position = CGPoint(x: 640, y: 425)
        card.addChild(boga)

        if canAdvanceNextWorld, let nxt = currentWorld.nextWorld {
            card.addChild(makePillButton(name: "btn_next_world", text: "▶ ONWARD TO \(nxt.shortName)!", width: 390, pos: CGPoint(x: 640, y: 300), accent: Palette.jungleEmerald, fill: SKColor.hex(0x143D29), height: 48, fontSize: 15))
            card.addChild(makePillButton(name: "btn_modal_back", text: "RETURN TO CAMPFIRE", width: 280, pos: CGPoint(x: 640, y: 228), accent: Palette.amberGold, height: 40))
        } else if !stageWonFlag {
            card.addChild(makePillButton(name: "btn_retry_stage", text: "▶ RETRY STAGE", width: 320, pos: CGPoint(x: 640, y: 300), accent: Palette.jungleEmerald, height: 46))
            card.addChild(makePillButton(name: "btn_modal_back", text: "RETURN TO CAMPFIRE", width: 280, pos: CGPoint(x: 640, y: 228), accent: Palette.amberGold, height: 40))
        } else {
            card.addChild(makePillButton(name: "btn_modal_back", text: "▶ RETURN TO CAMPFIRE", width: 340, pos: CGPoint(x: 640, y: 255), accent: Palette.jungleEmerald, height: 48))
        }

        overlayLayer.addChild(card)
    }

    // MARK: - 10. Unified Controls (Keyboard + Touch + PS5/Xbox/MFi Gamepad)

    private var padDX: CGFloat = 0
    private var padDY: CGFloat = 0
    private var padClubPrev: Bool = false
    private var padJumpPrev: Bool = false
    private var padClubJust: Bool = false
    private var padJumpJust: Bool = false

    private func pollHardwareGamepads() {
        #if canImport(GameController)
        guard let gp = GCController.controllers().first?.extendedGamepad else {
            padDX = 0; padDY = 0; return
        }
        let lx = CGFloat(gp.leftThumbstick.xAxis.value)
        let ly = CGFloat(gp.leftThumbstick.yAxis.value)
        padDX = abs(lx) > 0.15 ? lx : CGFloat((gp.dpad.right.isPressed ? 1 : 0) - (gp.dpad.left.isPressed ? 1 : 0))
        padDY = abs(ly) > 0.15 ? ly : CGFloat((gp.dpad.up.isPressed ? 1 : 0) - (gp.dpad.down.isPressed ? 1 : 0))

        let clubNow = gp.buttonX.isPressed || gp.buttonB.isPressed || gp.rightTrigger.isPressed
        let jumpNow = gp.buttonA.isPressed || gp.leftShoulder.isPressed
        if clubNow && !padClubPrev { padClubJust = true }
        if jumpNow && !padJumpPrev { padJumpJust = true }
        padClubPrev = clubNow
        padJumpPrev = jumpNow
        #endif
    }

    private func readCombinedControls() -> (dx: CGFloat, dy: CGFloat, clubJust: Bool, jumpJust: Bool) {
        var dx = TouchInputState.shared.moveDX + padDX
        var dy = TouchInputState.shared.moveDY + padDY

        // macOS KeyCodes: Left=123, Right=124, Down=125, Up=126, A=0, D=2, S=1, W=13
        if keysHeld.contains(123) || keysHeld.contains(0)  { dx -= 1 }
        if keysHeld.contains(124) || keysHeld.contains(2)  { dx += 1 }
        if keysHeld.contains(125) || keysHeld.contains(1)  { dy -= 1 }
        if keysHeld.contains(126) || keysHeld.contains(13) { dy += 1 }

        dx = max(-1, min(1, dx))
        dy = max(-1, min(1, dy))

        let club = keyJustPressedClub || TouchInputState.shared.primaryJustPressed || padClubJust
        let jump = keyJustPressedJump || TouchInputState.shared.secondaryJustPressed || padJumpJust
        padClubJust = false
        padJumpJust = false
        return (dx, dy, club, jump)
    }

    func togglePauseFromUI() {
        guard isActionArcadePhase else { return }
        isUserPaused.toggle()
        AudioSynth.shared.setPaused(isUserPaused)
        AudioSynth.shared.trigger(.menuMove)
        rebuildPauseOverlay()
    }

    private func rebuildPauseOverlay() {
        overlayLayer.removeAllChildren()
        guard isUserPaused else { return }
        let card = makeModalCard(title: "FEAST PAUSED", subtitle: "Press P / ESC or Tap Resume to Keep Bonking!")
        card.addChild(makePillButton(name: "pause_resume", text: "▶ RESUME ADVENTURE", width: 330, pos: CGPoint(x: 640, y: 390), accent: Palette.jungleEmerald, height: 46))
        card.addChild(makePillButton(name: "pause_quit", text: "RETURN TO CAMPFIRE", width: 330, pos: CGPoint(x: 640, y: 315), accent: Palette.amberGold, height: 42))
        overlayLayer.addChild(card)
    }

    // MARK: - Pointer & Keyboard Event Routing

    func handlePointerDown(at pt: CGPoint) {
        if isUserPaused {
            let hit = nodes(at: pt)
            if hit.contains(where: { $0.name == "pause_resume" }) {
                togglePauseFromUI()
            } else if hit.contains(where: { $0.name == "pause_quit" }) {
                enterTitleMenu()
            }
            return
        }

        for n in nodes(at: pt) {
            guard let nm = n.name else { continue }
            if nm == "btn_era" || nm == "set_theme" {
                cycleVisualTheme()
                return
            }
            if nm == "btn_chip" || nm == "set_chip" {
                cycleAudioChip()
                return
            }
            if nm == "gag_spitroast" {
                triggerCampfireSpitRoastGag()
                return
            }
            if nm.hasPrefix("menu_row_"), let idx = Int(nm.replacingOccurrences(of: "menu_row_", with: "")) {
                menuIndex = idx
                rebuildTitleMenuButtons()
                activateTitleMenuSelection()
                return
            }
            if nm == "btn_modal_back" {
                AudioSynth.shared.trigger(.menuSelect)
                enterTitleMenu()
                return
            }
            if nm == "opt_world" {
                let all = PrehistoricWorldID.allCases
                selectedSetupWorld = all[((all.firstIndex(of: selectedSetupWorld) ?? 0) + 1) % all.count]
                AudioSynth.shared.trigger(.menuMove)
                showWorldSelectOverlay()
                return
            }
            if nm == "opt_diff" {
                PersistenceManager.shared.updateSettings {
                    let all = DifficultyRank.allCases
                    $0.difficulty = all[((all.firstIndex(of: $0.difficulty) ?? 0) + 1) % all.count]
                }
                AudioSynth.shared.trigger(.menuMove)
                showWorldSelectOverlay()
                return
            }
            if nm == "btn_launch_adventure" {
                AudioSynth.shared.trigger(.megaFeastFull)
                startPlatformWorld(selectedSetupWorld, adventureMode: true, resetStats: true)
                return
            }
            if nm == "btn_next_world", let nxt = currentWorld.nextWorld {
                startPlatformWorld(nxt, adventureMode: true, resetStats: false)
                return
            }
            if nm == "btn_retry_stage" {
                startPlatformWorld(currentWorld, adventureMode: isAdventureRun, resetStats: true)
                return
            }
            if nm == "set_shake" {
                PersistenceManager.shared.updateSettings { $0.screenShakeEnabled.toggle() }
                AudioSynth.shared.trigger(.menuMove)
                showSettingsOverlay()
                return
            }
            if nm == "set_music" {
                PersistenceManager.shared.updateSettings {
                    let v = $0.musicVolume - 0.25
                    $0.musicVolume = v < -0.05 ? 1.0 : max(0.0, v)
                }
                AudioSynth.shared.syncSettings(PersistenceManager.shared.data.settings)
                showSettingsOverlay()
                return
            }
            if nm == "set_sfx" {
                PersistenceManager.shared.updateSettings {
                    let v = $0.sfxVolume - 0.25
                    $0.sfxVolume = v < -0.05 ? 1.0 : max(0.0, v)
                }
                AudioSynth.shared.syncSettings(PersistenceManager.shared.data.settings)
                AudioSynth.shared.trigger(.clubBonk)
                showSettingsOverlay()
                return
            }
        }
    }

    #if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        handlePointerDown(at: t.location(in: self))
    }
    #else
    override func mouseDown(with event: NSEvent) {
        handlePointerDown(at: event.location(in: self))
    }

    override func rightMouseDown(with event: NSEvent) {
        keyJustPressedJump = true
    }

    override func keyDown(with event: NSEvent) {
        guard !event.isARepeat else { return }
        let code = event.keyCode
        keysHeld.insert(code)

        // V = 9 (Visual Era), B = 11 (Audio Chip), P = 35, Esc = 53
        if code == 9  { cycleVisualTheme(); return }
        if code == 11 { cycleAudioChip(); return }
        if code == 35 || code == 53 {
            if mode == .titleMenu { return }
            if !isActionArcadePhase { enterTitleMenu(); return }
            togglePauseFromUI()
            return
        }

        if mode == .titleMenu {
            if code == 126 || code == 13 { // Up / W
                menuIndex = (menuIndex - 1 + titleMenuItems.count) % titleMenuItems.count
                AudioSynth.shared.trigger(.menuMove)
                rebuildTitleMenuButtons()
            } else if code == 125 || code == 1 { // Down / S
                menuIndex = (menuIndex + 1) % titleMenuItems.count
                AudioSynth.shared.trigger(.menuMove)
                rebuildTitleMenuButtons()
            } else if code == 36 || code == 49 || code == 6 { // Return / Space / Z
                activateTitleMenuSelection()
            }
            return
        }

        // Club Swing: Space (49), Z (6), Return (36)
        if code == 49 || code == 6 || code == 36 {
            keyJustPressedClub = true
        }
        // Jump: Up (126), W (13), X (7), Shift (56)
        if code == 126 || code == 13 || code == 7 || code == 56 {
            keyJustPressedJump = true
        }
    }

    override func keyUp(with event: NSEvent) {
        keysHeld.remove(event.keyCode)
    }
    #endif

    // MARK: - Shared UI Builders, Painted Backdrops & Comic Starburst FX

    private func drawPrehistoricBackdrop(skyTop: UInt32, skyBot: UInt32, world: PrehistoricWorldID, includeVolcano: Bool) {
        let retro = isRetro1991
        let bands = retro ? 4 : 10
        let cTop = SKColor.hex(skyTop)
        let cBot = SKColor.hex(skyBot)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        #if os(iOS)
        cTop.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        cBot.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        #else
        (cTop.usingColorSpace(.deviceRGB) ?? cTop).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        (cBot.usingColorSpace(.deviceRGB) ?? cBot).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        #endif

        let bandH = 800.0 / CGFloat(bands)
        for i in 0..<bands {
            let t = CGFloat(i) / CGFloat(max(1, bands - 1))
            let col = SKColor.rgba(r2 + (r1 - r2) * t, g2 + (g1 - g2) * t, b2 + (b1 - b2) * t, 1.0)
            let strip = SKSpriteNode(color: col, size: CGSize(width: 1300, height: bandH + 2))
            strip.position = CGPoint(x: 640, y: CGFloat(i) * bandH + bandH * 0.5)
            bgLayer.addChild(strip)
        }

        // Prehistoric Sun / Twin Moons
        let sun = SKShapeNode(circleOfRadius: 46)
        sun.position = CGPoint(x: 980, y: 545)
        sun.fillColor = (world == .glacierPeak ? Palette.boneCream : Palette.amberGold).withAlphaComponent(0.85)
        sun.strokeColor = .clear
        bgLayer.addChild(sun)

        if includeVolcano {
            // Smoking Prehistoric Volcano Silhouette!
            let vol = SKShapeNode()
            let vp = CGMutablePath()
            vp.move(to: CGPoint(x: 420, y: 155))
            vp.addLine(to: CGPoint(x: 590, y: 455))
            vp.addLine(to: CGPoint(x: 665, y: 455))
            vp.addLine(to: CGPoint(x: 845, y: 155))
            vp.closeSubpath()
            vol.path = vp
            vol.fillColor = retro ? Palette.vgaDarkGrey : SKColor.hex(0x2A1D2B)
            vol.strokeColor = Palette.volcanoOrange.withAlphaComponent(0.55)
            vol.lineWidth = 2.0
            bgLayer.addChild(vol)

            let craterGlow = SKShapeNode(ellipseOf: CGSize(width: 78, height: 22))
            craterGlow.position = CGPoint(x: 628, y: 455)
            craterGlow.fillColor = Palette.volcanoOrange
            craterGlow.strokeColor = Palette.amberGold
            bgLayer.addChild(craterGlow)
        }
    }

    private func makeModalCard(title: String, subtitle: String) -> SKNode {
        let root = SKNode()
        let dim = SKSpriteNode(color: SKColor.rgba(0, 0, 0, 0.58), size: CGSize(width: 1280, height: 800))
        dim.position = CGPoint(x: 640, y: 400)
        root.addChild(dim)

        // Strictly inside Universal Safe Box x: 165..1115, y: 165..635!
        let card = SKShapeNode(rectOf: CGSize(width: 940, height: 460), cornerRadius: isRetro1991 ? 0 : 20)
        card.position = CGPoint(x: 640, y: 400)
        card.fillColor = isRetro1991 ? Palette.vgaBlue : Palette.cardStoneBg
        card.strokeColor = Palette.amberGold
        card.lineWidth = 3.0
        root.addChild(card)

        let tLbl = CoreTextLabelRenderer.makeLabelNode(title, fontSize: 24, color: Palette.amberGold, retroMono: isRetro1991)
        tLbl.position = CGPoint(x: 640, y: 582)
        root.addChild(tLbl)

        let sLbl = CoreTextLabelRenderer.makeLabelNode(subtitle, fontSize: 12.5, color: .white, bold: false, retroMono: isRetro1991)
        sLbl.position = CGPoint(x: 640, y: 546)
        root.addChild(sLbl)

        return root
    }

    private func makePillButton(
        name: String,
        text: String,
        width: CGFloat,
        pos: CGPoint,
        accent: SKColor,
        fill: SKColor = SKColor.hex(0x162236),
        height: CGFloat = 42,
        fontSize: CGFloat = 13.5
    ) -> SKNode {
        let box = SKShapeNode(rectOf: CGSize(width: width, height: height), cornerRadius: isRetro1991 ? 0 : (height * 0.34))
        box.position = pos
        box.fillColor = fill
        box.strokeColor = accent
        box.lineWidth = 2.2
        box.name = name

        let lbl = CoreTextLabelRenderer.makeLabelNode(text, fontSize: fontSize, color: .white, retroMono: isRetro1991)
        lbl.name = name
        box.addChild(lbl)
        return box
    }

    func spawnComicStarburst(text: String, at pt: CGPoint, color: SKColor, inWorld: Bool) {
        let burst = SKShapeNode()
        let path = CGMutablePath()
        let points = 12
        for i in 0..<points {
            let ang = CGFloat(i) * (.pi * 2.0 / CGFloat(points))
            let rad: CGFloat = (i % 2 == 0) ? 54 : 30
            let px = cos(ang) * rad * 1.45
            let py = sin(ang) * rad * 0.78
            if i == 0 { path.move(to: CGPoint(x: px, y: py)) }
            else { path.addLine(to: CGPoint(x: px, y: py)) }
        }
        path.closeSubpath()
        burst.path = path
        burst.fillColor = color
        burst.strokeColor = SKColor.hex(0x140E0A)
        burst.lineWidth = 2.4
        burst.position = pt
        burst.zPosition = 42

        let lbl = CoreTextLabelRenderer.makeLabelNode(text, fontSize: 13.5, color: SKColor.hex(0x140E0A), retroMono: isRetro1991)
        burst.addChild(lbl)

        let parentNode = inWorld ? cameraStrip : fxLayer
        parentNode.addChild(burst)
        burst.setScale(0.45)
        burst.run(.sequence([
            .scale(to: 1.08, duration: 0.10),
            .wait(forDuration: 0.38),
            .group([.moveBy(x: 0, y: 24, duration: 0.24), .fadeOut(withDuration: 0.24)]),
            .removeFromParent()
        ]))
    }

    private func triggerScreenShake(intensity: CGFloat) {
        guard PersistenceManager.shared.data.settings.screenShakeEnabled, !isAutopilotActive else { return }
        worldLayer.removeAction(forKey: "shake")
        worldLayer.position = .zero
        worldLayer.run(.sequence([
            .moveBy(x: intensity, y: -intensity * 0.6, duration: 0.035),
            .moveBy(x: -intensity * 1.8, y: intensity * 1.1, duration: 0.04),
            .moveBy(x: intensity * 0.8, y: -intensity * 0.5, duration: 0.04),
            .move(to: .zero, duration: 0.03)
        ]), withKey: "shake")
    }

    private func showFloatingBanner(_ text: String, color: SKColor) {
        hudLayer.childNode(withName: "float_banner")?.removeFromParent()
        let b = SKShapeNode(rectOf: CGSize(width: 650, height: 34), cornerRadius: isRetro1991 ? 0 : 10)
        b.position = CGPoint(x: 640, y: bossActive ? 550 : 582)
        b.fillColor = SKColor.hex(0x14100E).withAlphaComponent(0.94)
        b.strokeColor = color
        b.lineWidth = 2.0
        b.name = "float_banner"
        let l = CoreTextLabelRenderer.makeLabelNode(text, fontSize: 13, color: color, retroMono: isRetro1991)
        b.addChild(l)
        hudLayer.addChild(b)
        b.run(.sequence([.wait(forDuration: 1.9), .fadeOut(withDuration: 0.35), .removeFromParent()]))
    }

    private func presentMedalToast(_ medal: MedalDefinition) {
        medalToastNode?.removeFromParent()
        let toast = SKShapeNode(rectOf: CGSize(width: 450, height: 52), cornerRadius: 12)
        toast.position = CGPoint(x: 640, y: 162)
        toast.fillColor = SKColor.hex(0x18392B)
        toast.strokeColor = Palette.amberGold
        toast.lineWidth = 2.5
        let t = CoreTextLabelRenderer.makeLabelNode("★ MEDAL UNLOCKED: \(medal.title)", fontSize: 13, color: Palette.amberGold, retroMono: isRetro1991)
        t.position = CGPoint(x: 0, y: 8)
        let s = CoreTextLabelRenderer.makeLabelNode(medal.subtitle, fontSize: 10.5, color: .white, bold: false, retroMono: isRetro1991)
        s.position = CGPoint(x: 0, y: -10)
        toast.addChild(t)
        toast.addChild(s)
        overlayLayer.addChild(toast)
        medalToastNode = toast
        toast.run(.sequence([.wait(forDuration: 2.6), .fadeOut(withDuration: 0.35), .removeFromParent()]))
    }

    // MARK: - 11. Deterministic App Store Screenshot Staging (6 Scenes) & 60fps Trailer Autopilot

    func stageAppStoreScreenshot(index: Int, isMobile: Bool) {
        PersistenceManager.shared.updateSettings {
            $0.visualTheme = (index == 5) ? .retro1991 : .hdOverdrive
            $0.audioChip = (index == 5) ? .retroAdLib : .modernSynth
        }
        rebuildCRTOverlay()

        switch index {
        case 1:
            // 01_jungle_club_bonk_feast: Palm Jungle mid-club-bonk on Raptors with flying drumsticks, burger, "BONK! +500" & 75% Feast Meter!
            startPlatformWorld(.palmJungle, adventureMode: true, resetStats: true)
            heroClub = .stoneMallet
            feastPercent = 75
            score = 14850
            stageTimer = 96
            heroPos = CGPoint(x: 515, y: 209)
            heroFacingRight = true
            swingTimer = 0.20
            refreshHeroSprite()

            if liveEnemies.count >= 2 {
                liveEnemies[0].pos = CGPoint(x: 595, y: 209)
                liveEnemies[0].dizzyTimer = 3.5
                liveEnemies[0].node.position = liveEnemies[0].pos
                liveEnemies[0].node.texture = SpriteFactory.shared.dinoEnemyTexture(kind: .raptorScout, frame: 0, dizzy: true, retro: false)

                liveEnemies[1].pos = CGPoint(x: 785, y: 398)
                liveEnemies[1].node.position = liveEnemies[1].pos
            }
            let ptero = SKSpriteNode(texture: SpriteFactory.shared.dinoEnemyTexture(kind: .pterodactyl, frame: 0, dizzy: false, retro: false), size: CGSize(width: 72, height: 62))
            ptero.position = CGPoint(x: 880, y: 485)
            ptero.xScale = -1
            ptero.zPosition = 16
            cameraStrip.addChild(ptero)

            spawnFoodItem(kind: .mammothDrumstick, at: CGPoint(x: 635, y: 295))
            spawnFoodItem(kind: .stoneBurger, at: CGPoint(x: 430, y: 332))
            spawnFoodItem(kind: .megaCroissant, at: CGPoint(x: 720, y: 245))
            spawnComicStarburst(text: "BONK! +500", at: CGPoint(x: 600, y: 278), color: Palette.amberGold, inWorld: true)
            updateCameraScroll()
            syncHUDValues()
            showFloatingBanner("BONK GRUMPY DINOS & GOBBLE GIANT STONE AGE FOOD!", color: Palette.amberGold)

        case 2:
            // 02_volcano_rex_boss_duel: Volcano Rex Arena boss fight vs giant comical King Chomper T-Rex!
            startPlatformWorld(.volcanoRexArena, adventureMode: true, resetStats: false)
            heroClub = .boneHammer
            feastPercent = 85
            score = 26400
            stageTimer = 112
            bossHP = 3
            heroPos = CGPoint(x: 595, y: 338)
            heroGrounded = false
            swingTimer = 0.20
            refreshHeroSprite()

            bossPos = CGPoint(x: 845, y: 248)
            bossDizzyTimer = 3.0
            bossNode?.position = bossPos
            bossNode?.texture = SpriteFactory.shared.bossRexTexture(pose: .dizzy, retro: false)

            spawnHazardBall(kind: .magmaMeteor, at: CGPoint(x: 420, y: 485), vx: 20, vy: -80)
            spawnHazardBall(kind: .magmaMeteor, at: CGPoint(x: 985, y: 465), vx: -20, vy: -80)
            spawnComicStarburst(text: "SPICY BONK! +1500", at: CGPoint(x: 755, y: 342), color: Palette.amberGold, inWorld: true)
            syncHUDValues()
            showFloatingBanner("VOLCANO REX ARENA: BONK KING CHOMPER'S DIZZY SNOUT!", color: Palette.clubCrimson)

        case 3:
            // 03_glider_sky_feast_bonus: Bamboo Hang-Glider sky bonus catching floating giant fruits & amber gems over smoking volcano!
            startGliderBonusStage(fromAdventure: false)
            feastPercent = 80
            score = 19200
            stageTimer = 34
            heroPos = CGPoint(x: 365, y: 425)
            heroNode?.position = heroPos

            let ptero = SKSpriteNode(texture: SpriteFactory.shared.dinoEnemyTexture(kind: .pterodactyl, frame: 0, dizzy: false, retro: false), size: CGSize(width: 72, height: 62))
            ptero.position = CGPoint(x: 935, y: 470)
            ptero.xScale = -1
            ptero.zPosition = 16
            cameraStrip.addChild(ptero)

            spawnComicStarburst(text: "SKY FEAST +1000", at: CGPoint(x: 495, y: 478), color: Palette.jungleEmerald, inWorld: true)
            syncHUDValues()
            showFloatingBanner("BAMBOO HANG-GLIDER SKY FEAST OVER VOLCANO RIDGE!", color: Palette.jungleEmerald)

        case 4:
            // 04_glacier_mammoth_peak: Glacier Mammoth Peak ice-platforming vs snowball Yeti & Cave Bear!
            startPlatformWorld(.glacierPeak, adventureMode: true, resetStats: false)
            heroClub = .boneHammer
            feastPercent = 90
            score = 21900
            stageTimer = 88
            heroPos = CGPoint(x: 525, y: 295)
            heroGrounded = false
            swingTimer = 0.18
            refreshHeroSprite()

            if !liveEnemies.isEmpty {
                liveEnemies[0].pos = CGPoint(x: 660, y: 209)
                liveEnemies[0].node.position = liveEnemies[0].pos
                liveEnemies[0].node.xScale = -1
            }
            spawnHazardBall(kind: .snowball, at: CGPoint(x: 595, y: 265), vx: -180, vy: 60)
            spawnComicStarburst(text: "ICE BONK! +800", at: CGPoint(x: 615, y: 332), color: Palette.glacierCyan, inWorld: true)
            updateCameraScroll()
            syncHUDValues()
            showFloatingBanner("GLACIER MAMMOTH PEAK: SLIDE, BOUNCE & DODGE SNOWBALL YETIS!", color: Palette.glacierCyan)

        case 5:
            // 05_retro_1991_adlib_mode: Live 1991 16-Color Pixel & FM Chiptune Retro Mode in Amber Cavern!
            startPlatformWorld(.amberCavern, adventureMode: true, resetStats: false)
            heroClub = .stoneMallet
            feastPercent = 100
            feastFullAnnounced = true
            score = 18400
            stageTimer = 94
            heroPos = CGPoint(x: 525, y: 209)
            swingTimer = 0.20
            refreshHeroSprite()

            if !liveEnemies.isEmpty {
                liveEnemies[0].pos = CGPoint(x: 615, y: 209)
                liveEnemies[0].dizzyTimer = 3.0
                liveEnemies[0].node.position = liveEnemies[0].pos
                liveEnemies[0].node.texture = SpriteFactory.shared.dinoEnemyTexture(kind: .caveBear, frame: 0, dizzy: true, retro: true)
            }
            spawnComicStarburst(text: "1991 POW!", at: CGPoint(x: 605, y: 278), color: Palette.vgaYellow, inWorld: true)
            updateCameraScroll()
            rebuildGameplayHUD()
            showFloatingBanner("LIVE 1991 16-COLOR VGA PIXEL & ADLIB FM RETRO MODE!", color: Palette.vgaYellow)

        default:
            // 06_campfire_title_screen: Interactive Stone Age Campfire Title Screen!
            enterTitleMenu()
            titlePteroNode?.position = CGPoint(x: 365, y: 542)
        }
    }

    // Drives 60fps Launch Trailers (15s = 900f) & Uncut macOS App Review Walkthrough (18s = 1080f)
    func applyTrailerAutopilot(frame: Int, includeTitleIntro: Bool = false) {
        isAutopilotActive = true
        let f = includeTitleIntro ? frame : (frame + 180)

        if f == 0 {
            PersistenceManager.shared.updateSettings {
                $0.visualTheme = .hdOverdrive
                $0.audioChip = .modernSynth
            }
            rebuildCRTOverlay()
            enterTitleMenu()
        } else if f == 75 && includeTitleIntro {
            triggerCampfireSpitRoastGag()
        } else if f == 135 && includeTitleIntro {
            menuIndex = 1
            rebuildTitleMenuButtons()
        } else if f == 180 {
            TouchInputState.shared.reset()
            startPlatformWorld(.palmJungle, adventureMode: true, resetStats: true)
            heroClub = .stoneMallet
            refreshHeroSprite()
        } else if f > 180 && f < 450 {
            TouchInputState.shared.moveDX = 0.92
            if f == 245 {
                // Demonstrate Jump -> Ground-Pound Canopy Shake!
                TouchInputState.shared.secondaryJustPressed = true
            } else if f == 265 {
                TouchInputState.shared.moveDY = -1.0
                TouchInputState.shared.primaryJustPressed = true
            } else {
                TouchInputState.shared.moveDY = 0
                if f % 34 == 0 { TouchInputState.shared.primaryJustPressed = true }
                if f % 52 == 0 { TouchInputState.shared.secondaryJustPressed = true }
            }
        } else if f == 450 {
            TouchInputState.shared.reset()
            startGliderBonusStage(fromAdventure: true)
        } else if f > 450 && f < 680 {
            TouchInputState.shared.moveDX = 0.35
            TouchInputState.shared.moveDY = CGFloat(sin(Double(f) * 0.08)) * 0.75
            if f % 28 == 0 { TouchInputState.shared.secondaryJustPressed = true }
        } else if f == 680 {
            TouchInputState.shared.reset()
            startPlatformWorld(.volcanoRexArena, adventureMode: true, resetStats: false)
            heroClub = .boneHammer
            refreshHeroSprite()
        } else if f > 680 && f < 920 {
            let targetX: CGFloat = bossDizzyTimer > 0 ? (bossPos.x - 55) : 520
            TouchInputState.shared.moveDX = heroPos.x < targetX - 18 ? 0.9 : (heroPos.x > targetX + 18 ? -0.9 : 0)
            if f % 24 == 0 { TouchInputState.shared.primaryJustPressed = true }
            if f % 58 == 0 { TouchInputState.shared.secondaryJustPressed = true }
        } else if f == 920 {
            TouchInputState.shared.reset()
            startPlatformWorld(.amberCavern, adventureMode: true, resetStats: false)
        } else if f > 920 && f < 1080 {
            TouchInputState.shared.moveDX = 0.88
            if f == 955 {
                // Live morph into 1991 16-Color VGA + AdLib FM Retro Mode!
                PersistenceManager.shared.updateSettings {
                    $0.visualTheme = .retro1991
                    $0.audioChip = .retroAdLib
                }
                AudioSynth.shared.syncSettings(PersistenceManager.shared.data.settings)
                rebuildCRTOverlay()
                refreshCurrentModeVisuals()
                showFloatingBanner("LIVE 1991 16-COLOR VGA & ADLIB FM RETRO MODE!", color: Palette.vgaYellow)
            }
            if f % 30 == 0 { TouchInputState.shared.primaryJustPressed = true }
            if f % 46 == 0 { TouchInputState.shared.secondaryJustPressed = true }
        }

        let simTime = TimeInterval(frame) / 60.0 + 1.0
        update(simTime)
    }
}
