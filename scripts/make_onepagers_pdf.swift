import AppKit
import CoreGraphics
import ImageIO
import Foundation

// Generates sleek A4 (595.28 x 841.89 pt) Designer One-Page Game Pitch / Sell-Sheet PDFs
// in BOTH English (DinoClub_OnePager_EN.pdf) and Hungarian (DinoClub_Egyoldalas_Jatekleiras.pdf)
// with strict single-line headers and crisp RGBA squircle app icon rendering.

let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
let defaultDir = scriptURL.deletingLastPathComponent().deletingLastPathComponent()
let projectDir = CommandLine.arguments.count >= 2
    ? URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
    : defaultDir

try? FileManager.default.createDirectory(at: projectDir.appendingPathComponent("Marketing", isDirectory: true), withIntermediateDirectories: true)
try? FileManager.default.createDirectory(at: projectDir.appendingPathComponent("dist", isDirectory: true), withIntermediateDirectories: true)

func loadCGImage(_ relPath: String) -> CGImage? {
    let url = projectDir.appendingPathComponent(relPath)
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

let bannerImg  = loadCGImage("Marketing/storefront_banner.png")
let iconRGBA   = loadCGImage("Resources/Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png")
let shotJungle = loadCGImage("dist/AppStore_Assets/Mac_2560x1600/01_jungle_club_bonk_feast.jpg")
let shotBoss   = loadCGImage("dist/AppStore_Assets/Mac_2560x1600/02_volcano_rex_boss_duel.jpg")
let shotGlider = loadCGImage("dist/AppStore_Assets/Mac_2560x1600/03_glider_sky_feast_bonus.jpg")

struct SheetCopy {
    let outName: String
    let subtitle: String
    let pills: [String]
    let leftTitle: String
    let leftBody: String
    let rightTitle: String
    let rightBody: String
    let stripTitle: String
    let cards: [(String, String, String)]
    let shotCaptions: [String]
    let footLeftTitle: String
    let footLeftBody: String
    let footRightTitle: String
    let footRightBody: String
}

let enCopy = SheetCopy(
    outName: "DinoClub_OnePager_EN.pdf",
    subtitle: "A 120Hz Cartoon Tribute to 1991/1993 Prehistoric Slapstick Platformers  •  © 2026 NGD",
    pills: [
        "iPhone • iPad • Mac Universal",
        "5 Worlds + Sky Glider Bonus",
        "1991 VGA + AdLib FM Synth",
        "Launch Sale $3.99 (Reg $6.99)"
    ],
    leftTitle: "BONK DINOS & FILL THE FEAST METER!",
    leftBody: "Guide Boga the Hungry Caveman in leopard tunic across lush prehistoric canyons in a hilarious, 100% family-friendly slapstick platformer.\n\n• Club Bash & Ground-Pound: Upgrade from Oak Club to Stone Mallet & Bone Hammer! Slam the earth to shake giant Mega-Croissants out of palm canopies!\n• Live Era Switch [V / B]: Morph anytime between 120Hz HD Cartoon Art and 1991 16-Color VGA + AdLib FM!",
    rightTitle: "5 PREHISTORIC WORLDS & SKY GLIDER",
    rightBody: "• PALM JUNGLE & AMBER CAVERN: Bouncy palm fronds, glowing mushrooms, Raptors, Pterodactyls & Cave Bears.\n• MAGMA RIDGE & GLACIER PEAK: Lava geysers, stone-wheel zip ledges, slippery ice slides & Snowball Yetis!\n• HANG-GLIDER & KING CHOMPER BOSS: Swoop for sky fruit rings, then bat Spicy Peppers into King Chomper T-Rex!",
    stripTitle: "SIX PILLARS OF DINO CLUB — SLAPSTICK BONKS, GIANT FOOD & 1991 RETRO",
    cards: [
        ("CLUB BASH",   "Oak Club, Stone Mallet & Bone Hammer", "3 WEAPONS"),
        ("FEAST BAR",   "Gobble Drumsticks, Burgers & Sundaes", "0 -> 100%"),
        ("TREE SLAM",   "Ground-Pound shakes hidden Croissants", "SECRETS"),
        ("SKY GLIDER",  "Bamboo glider fruit & amber gem rush", "BONUS SKY"),
        ("BOSS T-REX",  "Spicy Peppers stun King Chomper!",      "5-HP DUEL"),
        ("1991 RETRO",  "16-color VGA pixel + AdLib YM3812 FM", "LIVE [V/B]")
    ],
    shotCaptions: [
        "PALM JUNGLE CLUB BONK & FEAST",
        "KING CHOMPER T-REX BOSS ARENA",
        "BAMBOO HANG-GLIDER SKY BONUS"
    ],
    footLeftTitle: "UNIVERSAL CONTROLS & HARDWARE",
    footLeftBody: "• iPhone & iPad: Landscape Virtual Stick, CLUB/JUMP & Haptics\n• Mac: Keyboard (Arrows/WASD, Space/Z, X/Up, V & B) + Menus\n• Instant Modes: Adventure, Quick Dino Bash, Glider & Boss\n• Native PS5 DualSense, Xbox & MFi Bluetooth Gamepads",
    footRightTitle: "PRODUCT & APP STORE FACTSHEET",
    footRightBody: "• Developer & Publisher: NGD (Bundle ID: com.ngd.dinoclub)\n• 100% Original IP, Cartoon Art, Code & Dual-Chip Synth\n• Platforms: iOS 16+, iPadOS 16+, macOS 14+ Universal 2\n• Business Model: Pay-Once Universal • Zero Ads • Zero IAP"
)

let huCopy = SheetCopy(
    outName: "DinoClub_Egyoldalas_Jatekleiras.pdf",
    subtitle: "120Hz-es tisztelgés az 1991/1993-as őskori humoros platformer klasszikusok előtt  •  © 2026 NGD",
    pills: [
        "iPhone • iPad • Mac",
        "5 Világ + Siklórepülő Bónusz",
        "1991 VGA + AdLib FM Hang",
        "Akció: $3.99 ($6.99)"
    ],
    leftTitle: "PUFÖLD A DINÓKAT & TÖLTSD FEL A LAKOMÁT!",
    leftBody: "Vezesd Bogát, az éhes leopárdmintás ősembert 5 látványos őskori világon át egy vidám, családbarát rajzfilmes platformerben!\n\n• Bunkócsapás & Földbecsapódás: Fejleszd a Tölgy Bunkót Kőkalapáccsá és Csontpöröllyé! Rázd le a titkos Óriás Croissant-okat a pálmafákról!\n• Élő Időgép [V / B]: Válts bármikor a 120Hz HD Rajzfilm és az 1991-es 16-színű VGA + AdLib FM mód között!",
    rightTitle: "5 ŐSKORI VILÁG, SIKLÓ & T-REX FŐELLENSÉG",
    rightBody: "• PÁLMADZSUNGEL & BOROSTYÁN-BARLANG: Rugós pálmák, világító gombák, Raptorok, Pterodaktiluszok és Barlangi Medvék.\n• MAGMA-GERINC & GLECCSERCSÚCS: Lávagejzírek, kőkerék-liftek, csúszós jégpályák és hógolyózó Jetik!\n• SIKLÓREPÜLŐ & KING CHOMPER: Gyűjts égi gyümölcsöket, majd üss csípős paprikát a hatalmas T-Rex szájába!",
    stripTitle: "A DINO CLUB HAT PILLÉRE — HUMOR, ÓRIÁS ÉTELEK ÉS ÉLŐ 1991 RETRO",
    cards: [
        ("3 FEGYVER",   "Tölgy Bunkó, Kőkalapács, Csontpöröly", "FEJLESZTÉS"),
        ("LAKOMA SÁV",  "Mamutcomb, Burger, Ananász & Fagylalt", "0 -> 100%"),
        ("FA-RÁZÁS",    "Földbecsapás rejtett Croissant-okért!", "TITKOK"),
        ("SIKLÓ MÓD",   "Bambusz siklórepülés vulkánok felett",  "ÉGI BÓNUSZ"),
        ("T-REX HARC",  "Csípős paprika kábítja a T-Rexet!",     "BOSS ARÉNA"),
        ("1991 VGA",    "16-színű pixel + AdLib YM3812 FM",      "ÉLŐ [V/B]")
    ],
    shotCaptions: [
        "PÁLMADZSUNGEL BUNKÓCSAPÁS & LAKOMA",
        "KING CHOMPER T-REX BOSS ARÉNA",
        "BAMBUSZ SIKLÓREPÜLŐ ÉGI BÓNUSZ"
    ],
    footLeftTitle: "UNIVERZÁLIS IRÁNYÍTÁS & KONTROLLEREK",
    footLeftBody: "• iPhone & iPad: Virtuális kar, CLUB/JUMP gombok & Haptika\n• Mac: Billentyűzet (Nyilak/WASD, Space/Z, X/Fel, V & B)\n• Azonnali Módok: Kaland, Dino Bash, Siklórepülő & Boss\n• Natív PS5 DualSense, Xbox és MFi Bluetooth kontrollerek",
    footRightTitle: "TERMÉK & APP STORE ADATLAP",
    footRightBody: "• Fejlesztő & Kiadó: NGD (Bundle ID: com.ngd.dinoclub)\n• 100% Eredeti IP, Rajzfilm-Grafika, Kód & FM Szintetizátor\n• Platformok: iOS 16+, iPadOS 16+, macOS 14+ Universal 2\n• Üzleti modell: Egyszeri vásárlás • Reklám- és IAP-mentes"
)

func renderPDF(_ copy: SheetCopy) {
    let mktURL = projectDir.appendingPathComponent("Marketing/\(copy.outName)")
    let distURL = projectDir.appendingPathComponent("dist/\(copy.outName)")

    let pageW: CGFloat = 595.28
    let pageH: CGFloat = 841.89
    var mediaBox = CGRect(x: 0, y: 0, width: pageW, height: pageH)

    guard let consumer = CGDataConsumer(url: mktURL as CFURL),
          let pdfCtx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
        fputs("Failed to create PDF at \(mktURL.path)\n", stderr)
        return
    }

    let cs = CGColorSpaceCreateDeviceRGB()
    let amber   = NSColor(calibratedRed: 1.00, green: 0.82, blue: 0.25, alpha: 1.0)
    let skyBlue = NSColor(calibratedRed: 0.30, green: 0.72, blue: 1.00, alpha: 1.0)
    let volcano = NSColor(calibratedRed: 1.00, green: 0.44, blue: 0.24, alpha: 1.0)
    let emerald = NSColor(calibratedRed: 0.18, green: 0.90, blue: 0.48, alpha: 1.0)
    let cardBg  = NSColor(calibratedRed: 0.08, green: 0.11, blue: 0.19, alpha: 0.95)
    let muted   = NSColor(calibratedRed: 0.88, green: 0.92, blue: 0.98, alpha: 1.0)

    pdfCtx.beginPDFPage(nil)

    let bgGrad = CGGradient(
        colorsSpace: cs,
        colors: [
            NSColor(calibratedRed: 0.05, green: 0.07, blue: 0.13, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.11, green: 0.09, blue: 0.17, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.05, green: 0.08, blue: 0.14, alpha: 1).cgColor
        ] as CFArray,
        locations: [0.0, 0.52, 1.0]
    )!
    pdfCtx.drawLinearGradient(bgGrad, start: CGPoint(x: 0, y: pageH), end: CGPoint(x: pageW, y: 0), options: [])

    let outerFrame = CGPath(roundedRect: CGRect(x: 16, y: 16, width: pageW - 32, height: pageH - 32), cornerWidth: 14, cornerHeight: 14, transform: nil)
    pdfCtx.setStrokeColor(amber.withAlphaComponent(0.48).cgColor)
    pdfCtx.setLineWidth(1.3)
    pdfCtx.addPath(outerFrame)
    pdfCtx.strokePath()

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(cgContext: pdfCtx, flipped: false)

    func drawSingleLineHeader(_ text: String, rect: CGRect, maxFontSize: CGFloat, weight: NSFont.Weight = .heavy, color: NSColor, align: NSTextAlignment = .left) {
        var pt = maxFontSize
        var font = NSFont.systemFont(ofSize: pt, weight: weight)
        while pt > 6.2 {
            let w = (text as NSString).size(withAttributes: [.font: font]).width
            if w <= rect.width { break }
            pt -= 0.3
            font = NSFont.systemFont(ofSize: pt, weight: weight)
        }
        let style = NSMutableParagraphStyle()
        style.alignment = align
        style.lineBreakMode = .byClipping
        (text as NSString).draw(in: rect, withAttributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style
        ])
    }

    func drawText(_ text: String, rect: CGRect, font: NSFont, color: NSColor, align: NSTextAlignment = .left, lineSpacing: CGFloat = 1.45) {
        let style = NSMutableParagraphStyle()
        style.alignment = align
        style.lineSpacing = lineSpacing
        (text as NSString).draw(in: rect, withAttributes: [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: style
        ])
    }

    func drawCard(_ rect: CGRect, border: NSColor, fill: NSColor = cardBg, radius: CGFloat = 10) {
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        pdfCtx.setFillColor(fill.cgColor)
        pdfCtx.addPath(path)
        pdfCtx.fillPath()
        pdfCtx.setStrokeColor(border.withAlphaComponent(0.65).cgColor)
        pdfCtx.setLineWidth(1.15)
        pdfCtx.addPath(path)
        pdfCtx.strokePath()
    }

    func drawClippedImage(_ img: CGImage?, in rect: CGRect, radius: CGFloat = 8, border: NSColor? = nil) {
        let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
        pdfCtx.saveGState()
        pdfCtx.addPath(path)
        pdfCtx.clip()
        if let img = img {
            pdfCtx.interpolationQuality = .high
            pdfCtx.draw(img, in: rect)
        } else {
            pdfCtx.setFillColor(NSColor(calibratedRed: 0.12, green: 0.17, blue: 0.28, alpha: 1).cgColor)
            pdfCtx.fill(rect)
        }
        pdfCtx.restoreGState()
        if let b = border {
            pdfCtx.setStrokeColor(b.cgColor)
            pdfCtx.setLineWidth(1.2)
            pdfCtx.addPath(path)
            pdfCtx.strokePath()
        }
    }

    // 1. Hero Banner + RGBA Squircle App Icon
    let heroRect = CGRect(x: 28, y: pageH - 220, width: pageW - 56, height: 192)
    drawClippedImage(bannerImg, in: heroRect, radius: 12, border: amber.withAlphaComponent(0.88))

    let titleBarRect = CGRect(x: heroRect.minX + 8, y: heroRect.minY + 8, width: heroRect.width - 16, height: 64)
    let titleBarPath = CGPath(roundedRect: titleBarRect, cornerWidth: 10, cornerHeight: 10, transform: nil)
    pdfCtx.setFillColor(NSColor(calibratedRed: 0.06, green: 0.07, blue: 0.13, alpha: 0.90).cgColor)
    pdfCtx.addPath(titleBarPath)
    pdfCtx.fillPath()

    // Draw RGBA macOS squircle icon cleanly with alpha preserved!
    if let ic = iconRGBA {
        pdfCtx.saveGState()
        pdfCtx.interpolationQuality = .high
        pdfCtx.draw(ic, in: CGRect(x: pageW - 102, y: heroRect.minY + 10, width: 60, height: 60))
        pdfCtx.restoreGState()
    }

    drawSingleLineHeader(
        "DINO CLUB: STONE AGE FEAST",
        rect: CGRect(x: 46, y: heroRect.minY + 36, width: 430, height: 26),
        maxFontSize: 19.5,
        weight: .black,
        color: amber
    )
    drawSingleLineHeader(
        copy.subtitle,
        rect: CGRect(x: 46, y: heroRect.minY + 14, width: 435, height: 18),
        maxFontSize: 8.6,
        weight: .semibold,
        color: .white
    )

    // 2. 4 Pill Badges
    let pillColors = [amber, skyBlue, volcano, emerald]
    let pillW = (pageW - 56 - 24) / 4.0
    let pillY: CGFloat = pageH - 248
    for i in 0..<4 {
        let px = 28 + CGFloat(i) * (pillW + 8)
        let pRect = CGRect(x: px, y: pillY, width: pillW, height: 20)
        drawCard(pRect, border: pillColors[i], fill: pillColors[i].withAlphaComponent(0.14), radius: 10)
        drawSingleLineHeader(copy.pills[i], rect: CGRect(x: px + 4, y: pillY - 1, width: pillW - 8, height: 17), maxFontSize: 7.6, weight: .bold, color: pillColors[i], align: .center)
    }

    // 3. Two-Column Pitch & Worlds
    let colW: CGFloat = (pageW - 68) / 2.0
    let leftX: CGFloat = 28
    let rightX: CGFloat = 28 + colW + 12
    let midRowY: CGFloat = pageH - 408

    drawCard(CGRect(x: leftX, y: midRowY, width: colW, height: 150), border: amber)
    drawSingleLineHeader(copy.leftTitle, rect: CGRect(x: leftX + 12, y: midRowY + 125, width: colW - 24, height: 16), maxFontSize: 9.2, color: amber)
    drawText(copy.leftBody, rect: CGRect(x: leftX + 12, y: midRowY + 6, width: colW - 24, height: 115), font: .systemFont(ofSize: 7.7, weight: .regular), color: muted, lineSpacing: 1.32)

    drawCard(CGRect(x: rightX, y: midRowY, width: colW, height: 150), border: emerald)
    drawSingleLineHeader(copy.rightTitle, rect: CGRect(x: rightX + 12, y: midRowY + 125, width: colW - 24, height: 16), maxFontSize: 9.2, color: emerald)
    drawText(copy.rightBody, rect: CGRect(x: rightX + 12, y: midRowY + 6, width: colW - 24, height: 115), font: .systemFont(ofSize: 7.7, weight: .regular), color: muted, lineSpacing: 1.32)

    // 4. 6 Pillar Cards Strip
    let secBoxY: CGFloat = pageH - 528
    drawCard(CGRect(x: 28, y: secBoxY, width: pageW - 56, height: 110), border: amber)
    drawSingleLineHeader(copy.stripTitle, rect: CGRect(x: 40, y: secBoxY + 85, width: pageW - 80, height: 16), maxFontSize: 8.8, color: amber)

    let cardColors: [NSColor] = [volcano, amber, emerald, skyBlue, volcano, .white]
    let sCardW: CGFloat = (pageW - 80 - 25) / 6.0
    for (i, w) in copy.cards.enumerated() {
        let sx = 40 + CGFloat(i) * (sCardW + 5)
        let sRect = CGRect(x: sx, y: secBoxY + 10, width: sCardW, height: 70)
        drawCard(sRect, border: cardColors[i], fill: NSColor(calibratedRed: 0.05, green: 0.08, blue: 0.16, alpha: 0.96), radius: 7)
        drawSingleLineHeader(w.0, rect: CGRect(x: sx + 5, y: secBoxY + 59, width: sCardW - 10, height: 13), maxFontSize: 6.8, weight: .black, color: cardColors[i])
        drawText(w.1, rect: CGRect(x: sx + 5, y: secBoxY + 23, width: sCardW - 10, height: 34), font: .systemFont(ofSize: 6.7, weight: .regular), color: muted, lineSpacing: 1.05)
        drawSingleLineHeader(w.2, rect: CGRect(x: sx + 5, y: secBoxY + 9, width: sCardW - 10, height: 12), maxFontSize: 6.5, weight: .bold, color: .white)
    }

    // 5. Three Screenshot Gallery
    let galY: CGFloat = pageH - 666
    let shotW: CGFloat = (pageW - 56 - 16) / 3.0
    let shotH: CGFloat = shotW * (1600.0 / 2560.0)
    let shots: [(CGImage?, String, NSColor)] = [
        (shotJungle, copy.shotCaptions[0], amber),
        (shotBoss,   copy.shotCaptions[1], volcano),
        (shotGlider, copy.shotCaptions[2], emerald)
    ]
    for (i, item) in shots.enumerated() {
        let gx = 28 + CGFloat(i) * (shotW + 8)
        let imgRect = CGRect(x: gx, y: galY + 18, width: shotW, height: shotH)
        drawClippedImage(item.0, in: imgRect, radius: 8, border: item.2)
        drawSingleLineHeader(item.1, rect: CGRect(x: gx + 2, y: galY + 1, width: shotW - 4, height: 14), maxFontSize: 7.2, weight: .bold, color: item.2, align: .center)
    }

    // 6. Bottom Factsheet
    let footY: CGFloat = 28
    let footH: CGFloat = galY - footY - 8
    drawCard(CGRect(x: 28, y: footY, width: pageW - 56, height: footH), border: emerald)

    drawSingleLineHeader(copy.footLeftTitle, rect: CGRect(x: 42, y: footY + footH - 23, width: 255, height: 15), maxFontSize: 9.0, color: emerald)
    drawText(copy.footLeftBody, rect: CGRect(x: 42, y: footY + 8, width: 258, height: footH - 33), font: .systemFont(ofSize: 7.8, weight: .regular), color: muted, lineSpacing: 1.8)

    drawSingleLineHeader(copy.footRightTitle, rect: CGRect(x: 312, y: footY + footH - 23, width: 248, height: 15), maxFontSize: 9.0, color: amber)
    drawText(copy.footRightBody, rect: CGRect(x: 312, y: footY + 8, width: 248, height: footH - 33), font: .systemFont(ofSize: 7.8, weight: .regular), color: muted, lineSpacing: 1.8)

    NSGraphicsContext.restoreGraphicsState()
    pdfCtx.endPDFPage()
    pdfCtx.closePDF()

    try? FileManager.default.removeItem(at: distURL)
    try? FileManager.default.copyItem(at: mktURL, to: distURL)
    print("Generated \(mktURL.path) & \(distURL.path)")
}

renderPDF(enCopy)
renderPDF(huCopy)
