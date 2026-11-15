import Foundation
import SpriteKit
import CoreGraphics

enum BogaPose: Int {
    case idle = 0
    case runA = 1
    case runB = 2
    case jump = 3
    case swing = 4
    case groundPound = 5
    case dizzy = 6
    case cheer = 7
    case glider = 8
}

enum BossRexPose: Int {
    case idle = 0
    case roar = 1
    case lunge = 2
    case dizzy = 3
}

enum HazardBallKind: Int {
    case boulder = 0
    case snowball = 1
    case magmaMeteor = 2
}

@MainActor
final class SpriteFactory {
    static let shared = SpriteFactory()
    private var cache: [String: SKTexture] = [:]

    private init() {}

    func clearCache() {
        cache.removeAll()
    }

    private func cached(_ key: String, width: Int, height: Int, pixelArt: Bool, draw: (CGContext, CGFloat, CGFloat) -> Void) -> SKTexture {
        let fullKey = "\(key)_\(pixelArt ? "vga91" : "hd26")"
        if let existing = cache[fullKey] {
            return existing
        }
        let scale = pixelArt ? 1 : 2
        let pw = max(4, width * scale)
        let ph = max(4, height * scale)
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: nil,
            width: pw,
            height: ph,
            bitsPerComponent: 8,
            bytesPerRow: pw * 4,
            space: cs,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return SKTexture()
        }
        ctx.clear(CGRect(x: 0, y: 0, width: pw, height: ph))
        ctx.scaleBy(x: CGFloat(scale), y: CGFloat(scale))
        if pixelArt {
            ctx.setShouldAntialias(false)
            ctx.interpolationQuality = .none
        } else {
            ctx.setShouldAntialias(true)
            ctx.interpolationQuality = .high
        }
        draw(ctx, CGFloat(width), CGFloat(height))
        guard let cg = ctx.makeImage() else { return SKTexture() }
        let tex = SKTexture(cgImage: cg)
        tex.filteringMode = pixelArt ? .nearest : .linear
        cache[fullKey] = tex
        return tex
    }

    private func drawPill(_ ctx: CGContext, _ r: CGRect, fill: SKColor, ink: SKColor, retro: Bool, strokeW: CGFloat = 1.8) {
        ctx.setFillColor(fill.cgColor)
        if retro {
            ctx.fill(r.integral)
            if strokeW > 0 {
                ctx.setStrokeColor(ink.cgColor)
                ctx.setLineWidth(1.0)
                ctx.stroke(r.integral.insetBy(dx: 0.5, dy: 0.5))
            }
        } else {
            let rad = min(r.width, r.height) * 0.34
            let p = CGPath(roundedRect: r, cornerWidth: rad, cornerHeight: rad, transform: nil)
            ctx.addPath(p)
            ctx.fillPath()
            if strokeW > 0 {
                ctx.setStrokeColor(ink.cgColor)
                ctx.setLineWidth(strokeW)
                ctx.addPath(p)
                ctx.strokePath()
            }
        }
    }

    private func drawEllipse(_ ctx: CGContext, _ r: CGRect, fill: SKColor, ink: SKColor, retro: Bool, strokeW: CGFloat = 1.8) {
        ctx.setFillColor(fill.cgColor)
        if retro {
            ctx.fillEllipse(in: r.integral)
        } else {
            ctx.fillEllipse(in: r)
            if strokeW > 0 {
                ctx.setStrokeColor(ink.cgColor)
                ctx.setLineWidth(strokeW)
                ctx.strokeEllipse(in: r)
            }
        }
    }

    // MARK: - 1. Boga the Hungry Caveman (+ Club Tiers & Bamboo Hang-Glider)

    func bogaTexture(pose: BogaPose, club: ClubTier, retro: Bool) -> SKTexture {
        let w = (pose == .glider) ? 92 : 76
        let h = (pose == .glider) ? 78 : 68
        return cached("boga_\(pose.rawValue)_\(club.rawValue)", width: w, height: h, pixelArt: retro) { ctx, cw, ch in
            let ink     = retro ? Palette.vgaBlack : SKColor.hex(0x14100D)
            let skin    = retro ? Palette.vgaMagenta : SKColor.hex(0xFFBE88)
            let tunic   = retro ? Palette.vgaOrangeRed : Palette.leopardGold
            let spots   = retro ? Palette.vgaBrown : SKColor.hex(0x5E2C0B)
            let hair    = retro ? Palette.vgaBlack : SKColor.hex(0x1E1612)
            let bone    = retro ? Palette.vgaWhite : Palette.boneCream
            let oakWood = retro ? Palette.vgaBrown : SKColor.hex(0x9E5524)
            let stoneC  = retro ? Palette.vgaLightGrey : SKColor.hex(0x9DAAB8)
            let leafG   = retro ? Palette.vgaBrightGreen : Palette.jungleEmerald

            let baseX: CGFloat = (pose == .glider) ? 26 : 14
            let baseY: CGFloat = (pose == .glider) ? 6 : 4

            // Optional Bamboo & Jungle-Leaf Hang Glider Canopy above Boga!
            if pose == .glider {
                // Wing sail
                ctx.saveGState()
                ctx.beginPath()
                ctx.move(to: CGPoint(x: 6, y: 50))
                ctx.addLine(to: CGPoint(x: 52, y: 73))
                ctx.addLine(to: CGPoint(x: 88, y: 52))
                ctx.addLine(to: CGPoint(x: 46, y: 46))
                ctx.closePath()
                ctx.setFillColor(leafG.cgColor)
                ctx.fillPath()
                ctx.setStrokeColor(ink.cgColor)
                ctx.setLineWidth(retro ? 1.0 : 2.2)
                ctx.beginPath()
                ctx.move(to: CGPoint(x: 6, y: 50))
                ctx.addLine(to: CGPoint(x: 52, y: 73))
                ctx.addLine(to: CGPoint(x: 88, y: 52))
                ctx.closePath()
                ctx.strokePath()
                // Bamboo crossbar & grip struts
                drawPill(ctx, CGRect(x: 10, y: 48, width: 76, height: 5), fill: Palette.amberGold, ink: ink, retro: retro, strokeW: 1.4)
                ctx.setStrokeColor(oakWood.cgColor)
                ctx.setLineWidth(2.4)
                ctx.move(to: CGPoint(x: 34, y: 49)); ctx.addLine(to: CGPoint(x: 42, y: 31))
                ctx.move(to: CGPoint(x: 58, y: 49)); ctx.addLine(to: CGPoint(x: 50, y: 31))
                ctx.strokePath()
                ctx.restoreGState()
            }

            // Feet & Bare Caveman Legs
            let stride: CGFloat = (pose == .runA) ? -5 : ((pose == .runB) ? 5 : 0)
            let legLift: CGFloat = (pose == .jump || pose == .groundPound || pose == .glider) ? 4 : 0
            drawPill(ctx, CGRect(x: baseX + 8 + stride, y: baseY + legLift, width: 10, height: 12), fill: skin, ink: ink, retro: retro)
            drawPill(ctx, CGRect(x: baseX + 20 - stride, y: baseY + legLift, width: 10, height: 12), fill: skin, ink: ink, retro: retro)

            // Spotted Leopard Tunic Body
            let bodyY = baseY + 10 + legLift * 0.5
            drawPill(ctx, CGRect(x: baseX + 6, y: bodyY, width: 25, height: 21), fill: tunic, ink: ink, retro: retro)
            ctx.setFillColor(spots.cgColor)
            ctx.fillEllipse(in: CGRect(x: baseX + 10, y: bodyY + 5, width: 4, height: 4))
            ctx.fillEllipse(in: CGRect(x: baseX + 19, y: bodyY + 11, width: 4.5, height: 4.5))
            ctx.fillEllipse(in: CGRect(x: baseX + 13, y: bodyY + 14, width: 3.5, height: 3.5))

            // Big Cartoon Caveman Head & Nose
            let headY = bodyY + 17
            drawEllipse(ctx, CGRect(x: baseX + 6, y: headY, width: 26, height: 22), fill: skin, ink: ink, retro: retro)
            // Big comical bulbous caveman nose facing right
            drawEllipse(ctx, CGRect(x: baseX + 26, y: headY + 6, width: 10, height: 8), fill: skin, ink: ink, retro: retro, strokeW: 1.5)

            // Unruly Spiky Black Hair + White Topknot Bone!
            drawPill(ctx, CGRect(x: baseX + 4, y: headY + 13, width: 23, height: 11), fill: hair, ink: ink, retro: retro)
            drawPill(ctx, CGRect(x: baseX + 3, y: headY + 6, width: 8, height: 12), fill: hair, ink: ink, retro: retro)
            // Bone hairpin
            drawPill(ctx, CGRect(x: baseX + 10, y: headY + 22, width: 13, height: 4.5), fill: bone, ink: ink, retro: retro, strokeW: 1.3)
            drawEllipse(ctx, CGRect(x: baseX + 7, y: headY + 21, width: 5.5, height: 6.5), fill: bone, ink: ink, retro: retro, strokeW: 1.2)
            drawEllipse(ctx, CGRect(x: baseX + 21, y: headY + 21, width: 5.5, height: 6.5), fill: bone, ink: ink, retro: retro, strokeW: 1.2)

            // Expressive Cartoon Eyes & Grin
            if pose == .dizzy {
                ctx.setStrokeColor(ink.cgColor)
                ctx.setLineWidth(2.0)
                ctx.move(to: CGPoint(x: baseX + 19, y: headY + 11)); ctx.addLine(to: CGPoint(x: baseX + 25, y: headY + 16))
                ctx.move(to: CGPoint(x: baseX + 25, y: headY + 11)); ctx.addLine(to: CGPoint(x: baseX + 19, y: headY + 16))
                ctx.strokePath()
                ctx.setFillColor(Palette.amberGold.cgColor)
                ctx.fillEllipse(in: CGRect(x: baseX + 2, y: headY + 26, width: 6, height: 6))
                ctx.fillEllipse(in: CGRect(x: baseX + 28, y: headY + 25, width: 6, height: 6))
            } else {
                drawEllipse(ctx, CGRect(x: baseX + 18, y: headY + 10, width: 8, height: 9), fill: .white, ink: ink, retro: retro, strokeW: 1.3)
                ctx.setFillColor(ink.cgColor)
                ctx.fillEllipse(in: CGRect(x: baseX + 22, y: headY + 12, width: 3.5, height: 4.5))
                // Happy open caveman grin
                drawPill(ctx, CGRect(x: baseX + 18, y: headY + 2, width: 9, height: 4.5), fill: bone, ink: ink, retro: retro, strokeW: 1.2)
            }

            // Boga's Giant Club / Stone Mallet / Bone Hammer!
            guard pose != .glider else { return }
            ctx.saveGState()
            let pivotX = baseX + 25
            let pivotY = bodyY + 11
            ctx.translateBy(x: pivotX, y: pivotY)
            let angle: CGFloat = {
                switch pose {
                case .swing:       return -0.25 // Smashing forward horizontally!
                case .groundPound: return -0.95 // Slamming straight down!
                case .cheer:       return 1.25  // Raised high in triumph!
                case .jump:        return 0.75
                default:           return 0.55  // Resting over shoulder/ready
                }
            }()
            ctx.rotate(by: angle)

            // Arm
            drawPill(ctx, CGRect(x: -3, y: -4, width: 12, height: 8), fill: skin, ink: ink, retro: retro, strokeW: 1.4)

            switch club {
            case .oakClub:
                // Giant knobby Oak Club
                drawPill(ctx, CGRect(x: 6, y: -3.5, width: 12, height: 7), fill: oakWood, ink: ink, retro: retro, strokeW: 1.5)
                drawEllipse(ctx, CGRect(x: 14, y: -9, width: 25, height: 18), fill: oakWood, ink: ink, retro: retro, strokeW: 1.8)
                ctx.setFillColor((retro ? Palette.vgaYellow : SKColor.hex(0xCA7B42)).cgColor)
                ctx.fillEllipse(in: CGRect(x: 22, y: 1, width: 10, height: 5))
                // Knobby bumps
                drawEllipse(ctx, CGRect(x: 24, y: 6, width: 6, height: 5), fill: oakWood, ink: ink, retro: retro, strokeW: 1.2)
                drawEllipse(ctx, CGRect(x: 31, y: -9, width: 6, height: 5), fill: oakWood, ink: ink, retro: retro, strokeW: 1.2)

            case .stoneMallet:
                // Chiseled Granite Stone Mallet
                drawPill(ctx, CGRect(x: 6, y: -3, width: 20, height: 6), fill: oakWood, ink: ink, retro: retro, strokeW: 1.5)
                drawPill(ctx, CGRect(x: 21, y: -13, width: 18, height: 26), fill: stoneC, ink: ink, retro: retro, strokeW: 1.8)
                drawPill(ctx, CGRect(x: 26, y: -13, width: 6, height: 26), fill: Palette.amberGold, ink: ink, retro: retro, strokeW: 1.0)

            case .boneHammer:
                // Gleaming Giant Mammoth Bone Hammer
                drawPill(ctx, CGRect(x: 6, y: -3, width: 22, height: 6), fill: Palette.clubCrimson, ink: ink, retro: retro, strokeW: 1.5)
                drawPill(ctx, CGRect(x: 22, y: -14, width: 18, height: 28), fill: bone, ink: ink, retro: retro, strokeW: 1.8)
                drawEllipse(ctx, CGRect(x: 19, y: 8, width: 10, height: 9), fill: bone, ink: ink, retro: retro, strokeW: 1.4)
                drawEllipse(ctx, CGRect(x: 33, y: 8, width: 10, height: 9), fill: bone, ink: ink, retro: retro, strokeW: 1.4)
                drawEllipse(ctx, CGRect(x: 19, y: -17, width: 10, height: 9), fill: bone, ink: ink, retro: retro, strokeW: 1.4)
                drawEllipse(ctx, CGRect(x: 33, y: -17, width: 10, height: 9), fill: bone, ink: ink, retro: retro, strokeW: 1.4)
            }
            ctx.restoreGState()
        }
    }

    // MARK: - 2. Prehistoric Critters & Grumpy Dinosaurs (Facing Right by Default)

    func dinoEnemyTexture(kind: DinoEnemyKind, frame: Int, dizzy: Bool, retro: Bool) -> SKTexture {
        cached("enemy_\(kind.rawValue)_\(frame)_\(dizzy ? 1 : 0)", width: 68, height: 60, pixelArt: retro) { ctx, w, h in
            let ink = retro ? Palette.vgaBlack : SKColor.hex(0x12151C)
            let step: CGFloat = (frame % 2 == 0) ? -3.5 : 3.5

            switch kind {
            case .raptorScout:
                let scaleG = retro ? Palette.vgaBrightGreen : SKColor.hex(0x35D461)
                let bellyY = retro ? Palette.vgaYellow : SKColor.hex(0xFFE066)
                let crestR = retro ? Palette.vgaRed : Palette.volcanoOrange
                // Tail
                drawPill(ctx, CGRect(x: 4, y: 16, width: 22, height: 10), fill: scaleG, ink: ink, retro: retro)
                // Legs
                drawPill(ctx, CGRect(x: 22 + step, y: 4, width: 9, height: 15), fill: scaleG, ink: ink, retro: retro)
                drawPill(ctx, CGRect(x: 33 - step, y: 4, width: 9, height: 15), fill: scaleG, ink: ink, retro: retro)
                // Body & Belly
                drawEllipse(ctx, CGRect(x: 18, y: 14, width: 28, height: 24), fill: scaleG, ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 28, y: 16, width: 16, height: 16), fill: bellyY, ink: ink, retro: retro, strokeW: 0)
                // Dorsal spikes
                drawEllipse(ctx, CGRect(x: 18, y: 34, width: 7, height: 7), fill: crestR, ink: ink, retro: retro, strokeW: 1.2)
                drawEllipse(ctx, CGRect(x: 24, y: 42, width: 7, height: 7), fill: crestR, ink: ink, retro: retro, strokeW: 1.2)
                // Big Snout & Goofy Eye
                drawPill(ctx, CGRect(x: 28, y: 32, width: 32, height: 18), fill: scaleG, ink: ink, retro: retro)
                // Teeth
                drawPill(ctx, CGRect(x: 42, y: 30, width: 15, height: 4), fill: .white, ink: ink, retro: retro, strokeW: 1.0)
                drawEnemyEyeAndDizzy(ctx: ctx, eyePt: CGPoint(x: 40, y: 42), dizzy: dizzy, retro: retro, ink: ink)

            case .pterodactyl:
                let wingP  = retro ? Palette.vgaPurple : SKColor.hex(0x9D4BFF)
                let beakO  = retro ? Palette.vgaYellow : Palette.amberGold
                let wingY: CGFloat = (frame % 2 == 0) ? 38 : 18
                // Flapping Wings
                drawPill(ctx, CGRect(x: 8, y: wingY, width: 28, height: 12), fill: wingP, ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 20, y: 22, width: 26, height: 18), fill: wingP, ink: ink, retro: retro)
                // Crest & Long Beak
                drawPill(ctx, CGRect(x: 26, y: 38, width: 14, height: 8), fill: Palette.clubCrimson, ink: ink, retro: retro)
                drawPill(ctx, CGRect(x: 42, y: 26, width: 22, height: 10), fill: beakO, ink: ink, retro: retro)
                drawEnemyEyeAndDizzy(ctx: ctx, eyePt: CGPoint(x: 40, y: 33), dizzy: dizzy, retro: retro, ink: ink)

            case .caveBear:
                let fur    = retro ? Palette.vgaBrown : SKColor.hex(0x8C4E27)
                let muzzle = retro ? Palette.vgaWhite : SKColor.hex(0xF5D5B0)
                drawPill(ctx, CGRect(x: 16 + step, y: 4, width: 12, height: 14), fill: fur, ink: ink, retro: retro)
                drawPill(ctx, CGRect(x: 34 - step, y: 4, width: 12, height: 14), fill: fur, ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 10, y: 12, width: 42, height: 32), fill: fur, ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 26, y: 42, width: 10, height: 10), fill: fur, ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 28, y: 28, width: 28, height: 22), fill: fur, ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 44, y: 30, width: 16, height: 13), fill: muzzle, ink: ink, retro: retro)
                ctx.setFillColor(ink.cgColor)
                ctx.fillEllipse(in: CGRect(x: 55, y: 37, width: 5, height: 4))
                drawEnemyEyeAndDizzy(ctx: ctx, eyePt: CGPoint(x: 42, y: 40), dizzy: dizzy, retro: retro, ink: ink)

            case .triceratops:
                let hide   = retro ? Palette.vgaOrangeRed : SKColor.hex(0xEB7328)
                let horn   = retro ? Palette.vgaWhite : Palette.boneCream
                drawPill(ctx, CGRect(x: 14 + step, y: 4, width: 11, height: 14), fill: hide, ink: ink, retro: retro)
                drawPill(ctx, CGRect(x: 36 - step, y: 4, width: 11, height: 14), fill: hide, ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 8, y: 13, width: 42, height: 28), fill: hide, ink: ink, retro: retro)
                // Shield Frill
                drawEllipse(ctx, CGRect(x: 28, y: 20, width: 20, height: 30), fill: Palette.amberGold, ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 34, y: 16, width: 24, height: 22), fill: hide, ink: ink, retro: retro)
                // Three Horns
                drawPill(ctx, CGRect(x: 52, y: 32, width: 13, height: 6), fill: horn, ink: ink, retro: retro, strokeW: 1.3)
                drawPill(ctx, CGRect(x: 55, y: 23, width: 10, height: 5), fill: horn, ink: ink, retro: retro, strokeW: 1.3)
                drawEnemyEyeAndDizzy(ctx: ctx, eyePt: CGPoint(x: 45, y: 30), dizzy: dizzy, retro: retro, ink: ink)

            case .snowYeti:
                let yetiFur = retro ? Palette.vgaWhite : SKColor.hex(0xE8F7FF)
                let iceFace = retro ? Palette.vgaBrightCyan : SKColor.hex(0x70D6FF)
                drawPill(ctx, CGRect(x: 16 + step, y: 4, width: 13, height: 15), fill: yetiFur, ink: ink, retro: retro)
                drawPill(ctx, CGRect(x: 35 - step, y: 4, width: 13, height: 15), fill: yetiFur, ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 12, y: 14, width: 42, height: 34), fill: yetiFur, ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 20, y: 34, width: 32, height: 22), fill: yetiFur, ink: ink, retro: retro)
                drawPill(ctx, CGRect(x: 30, y: 37, width: 20, height: 13), fill: iceFace, ink: ink, retro: retro, strokeW: 1.2)
                drawPill(ctx, CGRect(x: 44, y: 24, width: 16, height: 10), fill: yetiFur, ink: ink, retro: retro)
                drawEnemyEyeAndDizzy(ctx: ctx, eyePt: CGPoint(x: 41, y: 44), dizzy: dizzy, retro: retro, ink: ink)
            }
        }
    }

    private func drawEnemyEyeAndDizzy(ctx: CGContext, eyePt: CGPoint, dizzy: Bool, retro: Bool, ink: SKColor) {
        if dizzy {
            // Pink slapstick tongue + golden orbiting stars!
            drawPill(ctx, CGRect(x: eyePt.x + 8, y: eyePt.y - 16, width: 9, height: 7), fill: SKColor.hex(0xFF6B9E), ink: ink, retro: retro, strokeW: 1.0)
            ctx.setStrokeColor(ink.cgColor)
            ctx.setLineWidth(2.0)
            ctx.move(to: CGPoint(x: eyePt.x - 3, y: eyePt.y - 3)); ctx.addLine(to: CGPoint(x: eyePt.x + 4, y: eyePt.y + 4))
            ctx.move(to: CGPoint(x: eyePt.x + 4, y: eyePt.y - 3)); ctx.addLine(to: CGPoint(x: eyePt.x - 3, y: eyePt.y + 4))
            ctx.strokePath()
            ctx.setFillColor(Palette.amberGold.cgColor)
            ctx.fillEllipse(in: CGRect(x: eyePt.x - 14, y: eyePt.y + 10, width: 7, height: 7))
            ctx.fillEllipse(in: CGRect(x: eyePt.x + 2,  y: eyePt.y + 12, width: 6, height: 6))
            ctx.fillEllipse(in: CGRect(x: eyePt.x - 5,  y: eyePt.y + 14, width: 5, height: 5))
        } else {
            drawEllipse(ctx, CGRect(x: eyePt.x - 4, y: eyePt.y - 4, width: 9, height: 9), fill: Palette.amberGold, ink: ink, retro: retro, strokeW: 1.3)
            ctx.setFillColor(ink.cgColor)
            ctx.fillEllipse(in: CGRect(x: eyePt.x, y: eyePt.y - 2, width: 4, height: 4.5))
        }
    }

    // MARK: - 3. Giant Boss: King Chomper T-Rex (Facing Left toward Player by Default!)

    func bossRexTexture(pose: BossRexPose, retro: Bool) -> SKTexture {
        cached("boss_rex_\(pose.rawValue)", width: 176, height: 148, pixelArt: retro) { ctx, w, h in
            let ink    = retro ? Palette.vgaBlack : SKColor.hex(0x140E0E)
            let scales = (pose == .dizzy)
                ? (retro ? Palette.vgaMagenta : SKColor.hex(0xFF5277))
                : (retro ? Palette.vgaRed : SKColor.hex(0xE03A2E))
            let belly  = retro ? Palette.vgaYellow : Palette.amberGold
            let teeth  = retro ? Palette.vgaWhite : Palette.boneCream

            // Massive Tail (Right side)
            drawPill(ctx, CGRect(x: 112, y: 24, width: 56, height: 26), fill: scales, ink: ink, retro: retro, strokeW: 2.4)
            // Giant Stomping Legs
            let stompLift: CGFloat = (pose == .lunge) ? 10 : 0
            drawPill(ctx, CGRect(x: 68, y: 6 + stompLift, width: 26, height: 34), fill: scales, ink: ink, retro: retro, strokeW: 2.4)
            drawPill(ctx, CGRect(x: 98, y: 6, width: 26, height: 34), fill: scales, ink: ink, retro: retro, strokeW: 2.4)

            // Huge Chubby T-Rex Torso & Golden Belly
            drawEllipse(ctx, CGRect(x: 54, y: 26, width: 82, height: 74), fill: scales, ink: ink, retro: retro, strokeW: 2.6)
            drawEllipse(ctx, CGRect(x: 58, y: 32, width: 44, height: 54), fill: belly, ink: ink, retro: retro, strokeW: 0)

            // Tiny Hilarious Stubby T-Rex Arms
            drawPill(ctx, CGRect(x: 42, y: 58, width: 22, height: 11), fill: scales, ink: ink, retro: retro, strokeW: 2.0)

            // Massive Comical Jaw & Snout (Facing Left)
            let jawOpen: CGFloat = (pose == .roar || pose == .lunge) ? 16 : (pose == .dizzy ? 10 : 4)
            // Lower Jaw
            drawPill(ctx, CGRect(x: 14, y: 66 - jawOpen, width: 62, height: 20), fill: scales, ink: ink, retro: retro, strokeW: 2.4)
            // Upper Snout & Head
            drawPill(ctx, CGRect(x: 10, y: 82, width: 78, height: 42), fill: scales, ink: ink, retro: retro, strokeW: 2.6)

            // Chunky Cartoon Teeth
            for tx in stride(from: 18, through: 54, by: 12) {
                drawPill(ctx, CGRect(x: CGFloat(tx), y: 75, width: 8, height: 9), fill: teeth, ink: ink, retro: retro, strokeW: 1.4)
            }

            // Crooked Golden Stone Age Crown!
            ctx.saveGState()
            ctx.translateBy(x: 64, y: 124)
            ctx.rotate(by: pose == .dizzy ? -0.35 : 0.12)
            drawPill(ctx, CGRect(x: -18, y: 0, width: 36, height: 16), fill: Palette.amberGold, ink: ink, retro: retro, strokeW: 2.0)
            drawEllipse(ctx, CGRect(x: -5, y: 4, width: 10, height: 8), fill: Palette.jungleEmerald, ink: ink, retro: retro, strokeW: 1.2)
            ctx.restoreGState()

            // Eyes & Dizzy Stars
            if pose == .dizzy {
                drawPill(ctx, CGRect(x: 14, y: 56, width: 18, height: 12), fill: SKColor.hex(0xFF7EB3), ink: ink, retro: retro, strokeW: 1.5)
                ctx.setStrokeColor(ink.cgColor)
                ctx.setLineWidth(3.0)
                ctx.move(to: CGPoint(x: 42, y: 98)); ctx.addLine(to: CGPoint(x: 54, y: 110))
                ctx.move(to: CGPoint(x: 54, y: 98)); ctx.addLine(to: CGPoint(x: 42, y: 110))
                ctx.strokePath()
                for sx in [22, 48, 82] {
                    drawEllipse(ctx, CGRect(x: CGFloat(sx), y: 132, width: 12, height: 12), fill: Palette.amberGold, ink: ink, retro: retro, strokeW: 1.4)
                }
            } else {
                drawEllipse(ctx, CGRect(x: 40, y: 96, width: 18, height: 18), fill: .white, ink: ink, retro: retro, strokeW: 2.0)
                ctx.setFillColor(ink.cgColor)
                ctx.fillEllipse(in: CGRect(x: 43, y: 100, width: 8, height: 9))
            }
        }
    }

    // MARK: - 4. Oversized Prehistorik Collectible Delicacies & Treasures

    func foodTexture(kind: FoodKind, retro: Bool) -> SKTexture {
        cached("food_\(kind.rawValue)", width: 48, height: 48, pixelArt: retro) { ctx, w, h in
            let ink = retro ? Palette.vgaBlack : SKColor.hex(0x18120E)

            switch kind {
            case .mammothDrumstick:
                // White bone handle + juicy glazed roast leg!
                drawPill(ctx, CGRect(x: 5, y: 18, width: 18, height: 9), fill: Palette.boneCream, ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 3, y: 22, width: 8, height: 8), fill: Palette.boneCream, ink: ink, retro: retro, strokeW: 1.3)
                drawEllipse(ctx, CGRect(x: 3, y: 14, width: 8, height: 8), fill: Palette.boneCream, ink: ink, retro: retro, strokeW: 1.3)
                drawEllipse(ctx, CGRect(x: 16, y: 9, width: 29, height: 28), fill: SKColor.hex(0xC9521E), ink: ink, retro: retro, strokeW: 2.0)
                ctx.setFillColor(Palette.amberGold.withAlphaComponent(0.65).cgColor)
                ctx.fillEllipse(in: CGRect(x: 24, y: 24, width: 12, height: 7))

            case .stoneBurger:
                // Bottom bun, patty, cheese, lettuce, tomato, sesame top bun!
                drawPill(ctx, CGRect(x: 7, y: 7, width: 34, height: 9), fill: SKColor.hex(0xE89B3C), ink: ink, retro: retro)
                drawPill(ctx, CGRect(x: 5, y: 14, width: 38, height: 8), fill: SKColor.hex(0x6E3319), ink: ink, retro: retro)
                drawPill(ctx, CGRect(x: 6, y: 21, width: 36, height: 5), fill: Palette.amberGold, ink: ink, retro: retro, strokeW: 1.0)
                drawPill(ctx, CGRect(x: 4, y: 25, width: 40, height: 5), fill: Palette.jungleEmerald, ink: ink, retro: retro, strokeW: 1.0)
                drawEllipse(ctx, CGRect(x: 7, y: 27, width: 34, height: 15), fill: SKColor.hex(0xF2A644), ink: ink, retro: retro)
                ctx.setFillColor(Palette.boneCream.cgColor)
                for sx in [15, 23, 31] { ctx.fillEllipse(in: CGRect(x: CGFloat(sx), y: 35, width: 3.5, height: 2.2)) }

            case .giantPineapple:
                // Leafy crown + golden pineapple body
                drawPill(ctx, CGRect(x: 18, y: 31, width: 12, height: 13), fill: Palette.jungleEmerald, ink: ink, retro: retro)
                drawPill(ctx, CGRect(x: 12, y: 30, width: 24, height: 8), fill: SKColor.hex(0x20B857), ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 10, y: 6, width: 28, height: 27), fill: Palette.amberGold, ink: ink, retro: retro, strokeW: 2.0)
                ctx.setStrokeColor(SKColor.hex(0xBA7214).cgColor)
                ctx.setLineWidth(1.4)
                ctx.move(to: CGPoint(x: 15, y: 12)); ctx.addLine(to: CGPoint(x: 33, y: 26))
                ctx.move(to: CGPoint(x: 33, y: 12)); ctx.addLine(to: CGPoint(x: 15, y: 26))
                ctx.strokePath()

            case .honeycomb:
                drawPill(ctx, CGRect(x: 8, y: 8, width: 32, height: 30), fill: Palette.amberGold, ink: ink, retro: retro, strokeW: 2.0)
                drawPill(ctx, CGRect(x: 13, y: 14, width: 22, height: 18), fill: SKColor.hex(0xE08E1B), ink: ink, retro: retro, strokeW: 1.2)
                drawEllipse(ctx, CGRect(x: 19, y: 20, width: 10, height: 8), fill: Palette.amberGold, ink: ink, retro: retro, strokeW: 1.0)

            case .goldenBanana:
                ctx.saveGState()
                ctx.translateBy(x: 24, y: 22)
                ctx.rotate(by: -0.35)
                drawEllipse(ctx, CGRect(x: -16, y: -9, width: 32, height: 14), fill: Palette.amberGold, ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: -13, y: -2, width: 28, height: 13), fill: SKColor.hex(0xFFE94D), ink: ink, retro: retro)
                ctx.restoreGState()

            case .iceCreamSundae:
                // Waffle cup + 3 scoops + cherry!
                drawPill(ctx, CGRect(x: 13, y: 6, width: 22, height: 14), fill: SKColor.hex(0xD98B38), ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 9, y: 17, width: 16, height: 15), fill: Palette.glacierCyan, ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 23, y: 17, width: 16, height: 15), fill: SKColor.hex(0xFF85B3), ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 15, y: 25, width: 18, height: 15), fill: Palette.boneCream, ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 20, y: 37, width: 8, height: 8), fill: Palette.clubCrimson, ink: ink, retro: retro, strokeW: 1.3)

            case .megaCroissant:
                drawEllipse(ctx, CGRect(x: 4, y: 11, width: 40, height: 24), fill: SKColor.hex(0xF59F2A), ink: ink, retro: retro, strokeW: 2.2)
                drawEllipse(ctx, CGRect(x: 12, y: 16, width: 24, height: 18), fill: Palette.amberGold, ink: ink, retro: retro, strokeW: 1.6)
                drawEllipse(ctx, CGRect(x: 18, y: 7, width: 12, height: 9), fill: Palette.nightJungleBg.withAlphaComponent(0.01), ink: ink, retro: retro, strokeW: 0)
            }
        }
    }

    func treasureTexture(kind: TreasureKind, retro: Bool) -> SKTexture {
        cached("treasure_\(kind.rawValue)", width: 44, height: 44, pixelArt: retro) { ctx, w, h in
            let ink = retro ? Palette.vgaBlack : SKColor.hex(0x141820)
            switch kind {
            case .stoneWheel:
                drawEllipse(ctx, CGRect(x: 5, y: 5, width: 34, height: 34), fill: SKColor.hex(0xB8C4D4), ink: ink, retro: retro, strokeW: 2.2)
                drawPill(ctx, CGRect(x: 17, y: 17, width: 10, height: 10), fill: SKColor.hex(0x3B4659), ink: ink, retro: retro, strokeW: 1.5)
            case .amberGem:
                drawEllipse(ctx, CGRect(x: 7, y: 5, width: 30, height: 34), fill: Palette.amberGold, ink: ink, retro: retro, strokeW: 2.2)
                drawEllipse(ctx, CGRect(x: 13, y: 12, width: 18, height: 20), fill: Palette.volcanoOrange, ink: ink, retro: retro, strokeW: 1.0)
                ctx.setFillColor(SKColor.white.withAlphaComponent(0.75).cgColor)
                ctx.fillEllipse(in: CGRect(x: 14, y: 26, width: 6, height: 8))
            case .malletUpgrade:
                drawEllipse(ctx, CGRect(x: 4, y: 4, width: 36, height: 36), fill: Palette.tropicalSky, ink: ink, retro: retro, strokeW: 2.0)
                drawPill(ctx, CGRect(x: 19, y: 8, width: 6, height: 18), fill: SKColor.hex(0x8B4E24), ink: ink, retro: retro, strokeW: 1.3)
                drawPill(ctx, CGRect(x: 11, y: 22, width: 22, height: 13), fill: SKColor.hex(0xDCE5F2), ink: ink, retro: retro, strokeW: 1.6)
            case .boneHammerUpgrade:
                drawEllipse(ctx, CGRect(x: 4, y: 4, width: 36, height: 36), fill: Palette.berryPurple, ink: ink, retro: retro, strokeW: 2.0)
                drawPill(ctx, CGRect(x: 19, y: 8, width: 6, height: 18), fill: Palette.amberGold, ink: ink, retro: retro, strokeW: 1.3)
                drawPill(ctx, CGRect(x: 10, y: 22, width: 24, height: 13), fill: Palette.boneCream, ink: ink, retro: retro, strokeW: 1.6)
            case .vitalitySteak:
                drawEllipse(ctx, CGRect(x: 6, y: 8, width: 32, height: 28), fill: Palette.clubCrimson, ink: ink, retro: retro, strokeW: 2.2)
                drawEllipse(ctx, CGRect(x: 20, y: 16, width: 10, height: 10), fill: Palette.boneCream, ink: ink, retro: retro, strokeW: 1.4)
            }
        }
    }

    // MARK: - 5. Interactive Stage Props (Springs, Secret Blocks, Spicy Peppers, Spit-Roast & Exit Cave)

    func springPadTexture(isMushroom: Bool, retro: Bool) -> SKTexture {
        cached("spring_\(isMushroom ? "mush" : "palm")", width: 64, height: 38, pixelArt: retro) { ctx, w, h in
            let ink = retro ? Palette.vgaBlack : SKColor.hex(0x141A14)
            if isMushroom {
                drawPill(ctx, CGRect(x: 23, y: 2, width: 18, height: 16), fill: Palette.boneCream, ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 6, y: 13, width: 52, height: 22), fill: SKColor.hex(0xFF4785), ink: ink, retro: retro, strokeW: 2.0)
                for sx in [16, 30, 42] {
                    ctx.setFillColor(Palette.amberGold.cgColor)
                    ctx.fillEllipse(in: CGRect(x: CGFloat(sx), y: 20, width: 7, height: 7))
                }
            } else {
                drawPill(ctx, CGRect(x: 24, y: 2, width: 16, height: 14), fill: SKColor.hex(0x9C5A25), ink: ink, retro: retro)
                drawEllipse(ctx, CGRect(x: 4, y: 12, width: 56, height: 22), fill: Palette.jungleEmerald, ink: ink, retro: retro, strokeW: 2.0)
                drawPill(ctx, CGRect(x: 14, y: 19, width: 36, height: 6), fill: Palette.amberGold, ink: ink, retro: retro, strokeW: 1.0)
            }
        }
    }

    func crackedStoneBlockTexture(retro: Bool) -> SKTexture {
        cached("cracked_stone", width: 52, height: 52, pixelArt: retro) { ctx, w, h in
            let ink = retro ? Palette.vgaBlack : SKColor.hex(0x161B24)
            let rock = retro ? Palette.vgaLightGrey : SKColor.hex(0x8D9AA8)
            drawPill(ctx, CGRect(x: 3, y: 3, width: 46, height: 46), fill: rock, ink: ink, retro: retro, strokeW: 2.2)
            // Golden secret food glint peeking through cracks!
            drawEllipse(ctx, CGRect(x: 19, y: 19, width: 14, height: 14), fill: Palette.amberGold, ink: ink, retro: retro, strokeW: 1.2)
            ctx.setStrokeColor(ink.cgColor)
            ctx.setLineWidth(2.2)
            ctx.move(to: CGPoint(x: 10, y: 42)); ctx.addLine(to: CGPoint(x: 25, y: 26)); ctx.addLine(to: CGPoint(x: 42, y: 12))
            ctx.move(to: CGPoint(x: 38, y: 40)); ctx.addLine(to: CGPoint(x: 25, y: 26)); ctx.addLine(to: CGPoint(x: 12, y: 14))
            ctx.strokePath()
        }
    }

    func spicyPepperTexture(retro: Bool) -> SKTexture {
        cached("spicy_pepper", width: 44, height: 44, pixelArt: retro) { ctx, w, h in
            let ink = retro ? Palette.vgaBlack : SKColor.hex(0x1A0F0D)
            drawPill(ctx, CGRect(x: 20, y: 31, width: 8, height: 10), fill: Palette.jungleEmerald, ink: ink, retro: retro, strokeW: 1.4)
            drawEllipse(ctx, CGRect(x: 9, y: 6, width: 26, height: 28), fill: Palette.clubCrimson, ink: ink, retro: retro, strokeW: 2.0)
            drawEllipse(ctx, CGRect(x: 15, y: 14, width: 8, height: 12), fill: Palette.amberGold, ink: ink, retro: retro, strokeW: 0)
        }
    }

    func hazardBallTexture(kind: HazardBallKind, retro: Bool) -> SKTexture {
        cached("hazard_\(kind.rawValue)", width: 38, height: 38, pixelArt: retro) { ctx, w, h in
            let ink = retro ? Palette.vgaBlack : SKColor.hex(0x141822)
            let fill: SKColor = {
                switch kind {
                case .boulder:     return retro ? Palette.vgaDarkGrey : SKColor.hex(0x7B8594)
                case .snowball:    return retro ? Palette.vgaWhite : SKColor.hex(0xEAF8FF)
                case .magmaMeteor: return retro ? Palette.vgaOrangeRed : Palette.volcanoOrange
                }
            }()
            drawEllipse(ctx, CGRect(x: 4, y: 4, width: 30, height: 30), fill: fill, ink: ink, retro: retro, strokeW: 2.0)
            if kind == .magmaMeteor {
                drawEllipse(ctx, CGRect(x: 11, y: 11, width: 14, height: 14), fill: Palette.amberGold, ink: ink, retro: retro, strokeW: 0)
            }
        }
    }

    func exitCaveTexture(isOpen: Bool, retro: Bool) -> SKTexture {
        cached("exit_cave_\(isOpen ? 1 : 0)", width: 108, height: 104, pixelArt: retro) { ctx, w, h in
            let ink = retro ? Palette.vgaBlack : SKColor.hex(0x141820)
            let arch = retro ? Palette.vgaLightGrey : SKColor.hex(0x7D8B9E)
            drawEllipse(ctx, CGRect(x: 6, y: 2, width: 96, height: 96), fill: arch, ink: ink, retro: retro, strokeW: 2.6)
            let innerFill = isOpen ? Palette.amberGold : SKColor.hex(0x201816)
            drawEllipse(ctx, CGRect(x: 22, y: 2, width: 64, height: 74), fill: innerFill, ink: ink, retro: retro, strokeW: 2.0)
            if !isOpen {
                // Wooden gate bars until Feast Meter reaches 100%!
                for gx in [34, 50, 66] {
                    drawPill(ctx, CGRect(x: CGFloat(gx), y: 4, width: 7, height: 64), fill: SKColor.hex(0x8C4D23), ink: ink, retro: retro, strokeW: 1.2)
                }
            }
            // Twin Torches
            for tx in [12, 88] {
                drawPill(ctx, CGRect(x: CGFloat(tx), y: 42, width: 8, height: 22), fill: SKColor.hex(0x8B4D24), ink: ink, retro: retro, strokeW: 1.2)
                drawEllipse(ctx, CGRect(x: CGFloat(tx - 2), y: 62, width: 12, height: 16), fill: isOpen ? Palette.jungleEmerald : Palette.volcanoOrange, ink: ink, retro: retro, strokeW: 1.2)
            }
        }
    }

    func campfireSpitRoastTexture(flipped: Bool, retro: Bool) -> SKTexture {
        cached("spit_roast_\(flipped ? 1 : 0)", width: 132, height: 92, pixelArt: retro) { ctx, w, h in
            let ink = retro ? Palette.vgaBlack : SKColor.hex(0x16100C)
            let wood = SKColor.hex(0x854922)
            // Stone ring & crackling flames
            for sx in stride(from: 24, through: 96, by: 18) {
                drawEllipse(ctx, CGRect(x: CGFloat(sx), y: 6, width: 20, height: 13), fill: SKColor.hex(0x788290), ink: ink, retro: retro, strokeW: 1.5)
            }
            drawEllipse(ctx, CGRect(x: 40, y: 14, width: 52, height: 32), fill: Palette.volcanoOrange, ink: ink, retro: retro, strokeW: 1.6)
            drawEllipse(ctx, CGRect(x: 50, y: 18, width: 32, height: 24), fill: Palette.amberGold, ink: ink, retro: retro, strokeW: 0)

            // Wooden Y-Fork Spit Supports & Horizontal Skewer
            drawPill(ctx, CGRect(x: 16, y: 10, width: 8, height: 54), fill: wood, ink: ink, retro: retro)
            drawPill(ctx, CGRect(x: 108, y: 10, width: 8, height: 54), fill: wood, ink: ink, retro: retro)
            drawPill(ctx, CGRect(x: 12, y: 54, width: 108, height: 6), fill: Palette.boneCream, ink: ink, retro: retro)

            // Sizzling Mammoth Roast on the Spit!
            let roastY: CGFloat = flipped ? 44 : 40
            drawEllipse(ctx, CGRect(x: 38, y: roastY, width: 56, height: 34), fill: SKColor.hex(0xC94F1E), ink: ink, retro: retro, strokeW: 2.2)
            ctx.setFillColor(Palette.amberGold.withAlphaComponent(0.75).cgColor)
            ctx.fillEllipse(in: CGRect(x: 48, y: roastY + (flipped ? 6 : 18), width: 34, height: 10))
        }
    }
}
