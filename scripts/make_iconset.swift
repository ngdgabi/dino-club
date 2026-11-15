import AppKit
import CoreGraphics
import Foundation

// Generates all macOS squircle icons (16..1024, RGBA) AND the opaque full-bleed 1024x1024 iOS App Store icon
// (24-bit RGB, zero alpha channel) inside Resources/Assets.xcassets/AppIcon.appiconset,
// plus Marketing/app_icon_source.png, Marketing/storefront_banner.png, and AppClip_Card_Header_1800x1200.jpg.
//
// Supports:
//   1. swift scripts/make_iconset.swift  (procedural fallback icon + banner!)
//   2. swift scripts/make_iconset.swift --source <icon.png> [--banner <banner.png>] [--out <appiconset>] [--root <dir>]
//   3. swift scripts/make_iconset.swift <source_icon_image> <output.appiconset> [banner_image] [project_root]

let scriptURL = URL(fileURLWithPath: CommandLine.arguments[0]).standardizedFileURL
let defaultRoot = scriptURL.deletingLastPathComponent().deletingLastPathComponent()

var sourceIconPath: String? = nil
var bannerPath: String? = nil
var projectRoot = defaultRoot
var appiconsetURL = defaultRoot.appendingPathComponent("Resources/Assets.xcassets/AppIcon.appiconset", isDirectory: true)

let args = CommandLine.arguments
if args.contains("--source") || args.contains("--out") || args.contains("--banner") || args.contains("--root") {
    var i = 1
    while i < args.count {
        switch args[i] {
        case "--source":
            if i + 1 < args.count { sourceIconPath = args[i + 1]; i += 1 }
        case "--out":
            if i + 1 < args.count { appiconsetURL = URL(fileURLWithPath: args[i + 1], isDirectory: true); i += 1 }
        case "--banner":
            if i + 1 < args.count { bannerPath = args[i + 1]; i += 1 }
        case "--root":
            if i + 1 < args.count { projectRoot = URL(fileURLWithPath: args[i + 1], isDirectory: true); i += 1 }
        default:
            break
        }
        i += 1
    }
} else if args.count >= 3 {
    sourceIconPath = args[1]
    appiconsetURL = URL(fileURLWithPath: args[2], isDirectory: true)
    if args.count >= 4 { bannerPath = args[3] }
    if args.count >= 5 { projectRoot = URL(fileURLWithPath: args[4], isDirectory: true) }
}

try FileManager.default.createDirectory(at: appiconsetURL, withIntermediateDirectories: true)
let cs = CGColorSpaceCreateDeviceRGB()

// Procedural Crisp Stone Age Fallback Artwork (1024x1024 Icon & 1600x900 Banner)
func renderProceduralDinoClubArtwork(width: Int, height: Int, includeLogoBanner: Bool) -> CGImage? {
    guard let ctx = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: cs,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { return nil }

    let w = CGFloat(width)
    let h = CGFloat(height)

    // Sunset Volcano Jungle Sky Gradient
    let skyGrad = CGGradient(
        colorsSpace: cs,
        colors: [
            NSColor(calibratedRed: 0.08, green: 0.16, blue: 0.36, alpha: 1).cgColor,
            NSColor(calibratedRed: 0.56, green: 0.18, blue: 0.28, alpha: 1).cgColor,
            NSColor(calibratedRed: 1.00, green: 0.58, blue: 0.18, alpha: 1).cgColor
        ] as CFArray,
        locations: [0.0, 0.55, 1.0]
    )!
    ctx.drawLinearGradient(skyGrad, start: CGPoint(x: 0, y: h), end: CGPoint(x: 0, y: 0), options: [])

    // Glowing Sun
    ctx.setFillColor(NSColor(calibratedRed: 1.0, green: 0.86, blue: 0.32, alpha: 0.92).cgColor)
    let sunR = min(w, h) * 0.18
    ctx.fillEllipse(in: CGRect(x: w * 0.62 - sunR, y: h * 0.66 - sunR, width: sunR * 2, height: sunR * 2))

    // Smoking Prehistoric Volcano
    ctx.beginPath()
    ctx.move(to: CGPoint(x: w * 0.16, y: h * 0.20))
    ctx.addLine(to: CGPoint(x: w * 0.45, y: h * 0.66))
    ctx.addLine(to: CGPoint(x: w * 0.56, y: h * 0.66))
    ctx.addLine(to: CGPoint(x: w * 0.84, y: h * 0.20))
    ctx.closePath()
    ctx.setFillColor(NSColor(calibratedRed: 0.22, green: 0.13, blue: 0.20, alpha: 1).cgColor)
    ctx.fillPath()

    ctx.setFillColor(NSColor(calibratedRed: 1.0, green: 0.38, blue: 0.14, alpha: 1).cgColor)
    ctx.fillEllipse(in: CGRect(x: w * 0.44, y: h * 0.63, width: w * 0.13, height: h * 0.05))

    // Lush Jungle Turf Ground
    ctx.setFillColor(NSColor(calibratedRed: 0.42, green: 0.22, blue: 0.10, alpha: 1).cgColor)
    ctx.fill(CGRect(x: 0, y: 0, width: w, height: h * 0.22))
    ctx.setFillColor(NSColor(calibratedRed: 0.18, green: 0.84, blue: 0.42, alpha: 1).cgColor)
    ctx.fill(CGRect(x: 0, y: h * 0.19, width: w, height: h * 0.05))

    let ink = NSColor(calibratedRed: 0.09, green: 0.06, blue: 0.05, alpha: 1).cgColor
    func pill(_ rect: CGRect, _ r: CGFloat, _ g: CGFloat, _ b: CGFloat) {
        let rad = min(rect.width, rect.height) * 0.36
        let p = CGPath(roundedRect: rect, cornerWidth: rad, cornerHeight: rad, transform: nil)
        ctx.setFillColor(NSColor(calibratedRed: r, green: g, blue: b, alpha: 1).cgColor)
        ctx.addPath(p); ctx.fillPath()
        ctx.setStrokeColor(ink); ctx.setLineWidth(max(3, min(w, h) * 0.014))
        ctx.addPath(p); ctx.strokePath()
    }

    let u = min(w, h)
    let cx = w * 0.36
    let cy = h * 0.24

    // Boga the Hungry Caveman (Leopard Tunic + Spiky Hair + Topknot Bone + Giant Knobby Oak Club!)
    pill(CGRect(x: cx - u * 0.10, y: cy, width: u * 0.22, height: u * 0.24), 1.0, 0.70, 0.16) // Tunic
    pill(CGRect(x: cx - u * 0.10, y: cy + u * 0.20, width: u * 0.23, height: u * 0.21), 1.0, 0.76, 0.54) // Head
    pill(CGRect(x: cx - u * 0.12, y: cy + u * 0.34, width: u * 0.22, height: u * 0.11), 0.12, 0.09, 0.08) // Hair
    pill(CGRect(x: cx - u * 0.06, y: cy + u * 0.43, width: u * 0.12, height: u * 0.045), 1.0, 0.96, 0.86) // Bone pin
    pill(CGRect(x: cx + u * 0.03, y: cy + u * 0.28, width: u * 0.075, height: u * 0.085), 1, 1, 1) // Eye
    ctx.setFillColor(ink)
    ctx.fillEllipse(in: CGRect(x: cx + u * 0.065, y: cy + u * 0.30, width: u * 0.035, height: u * 0.045))

    // Giant Swinging Knobby Oak Club!
    ctx.saveGState()
    ctx.translateBy(x: cx + u * 0.12, y: cy + u * 0.16)
    ctx.rotate(by: 0.42)
    pill(CGRect(x: 0, y: -u * 0.05, width: u * 0.34, height: u * 0.15), 0.64, 0.34, 0.14)
    ctx.restoreGState()

    // Grumpy Green Raptor on Right + Giant Mammoth Drumstick!
    let rx = w * 0.68
    pill(CGRect(x: rx - u * 0.12, y: cy, width: u * 0.24, height: u * 0.25), 0.20, 0.84, 0.38)
    pill(CGRect(x: rx - u * 0.16, y: cy + u * 0.20, width: u * 0.26, height: u * 0.17), 0.20, 0.84, 0.38)
    pill(CGRect(x: rx - u * 0.08, y: cy + u * 0.25, width: u * 0.075, height: u * 0.075), 1.0, 0.86, 0.22)
    // Giant Mammoth Drumstick above center
    pill(CGRect(x: w * 0.43, y: h * 0.68, width: u * 0.10, height: u * 0.05), 1.0, 0.96, 0.86)
    pill(CGRect(x: w * 0.49, y: h * 0.63, width: u * 0.18, height: u * 0.15), 0.82, 0.32, 0.12)

    return ctx.makeImage()
}

let cgSrc: CGImage = {
    if let p = sourceIconPath,
       let nsImg = NSImage(contentsOfFile: p),
       let cg = nsImg.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        return cg
    }
    guard let fallback = renderProceduralDinoClubArtwork(width: 1024, height: 1024, includeLogoBanner: false) else {
        fputs("Failed to generate procedural fallback icon\n", stderr)
        exit(1)
    }
    return fallback
}()

let macSpecs: [(String, Int)] = [
    ("icon_16x16.png", 16),
    ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32),
    ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128),
    ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256),
    ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512),
    ("icon_512x512@2x.png", 1024)
]

// 1. Render macOS rounded-squircle RGBA icons with warm amber-gold specular rim
for (filename, px) in macSpecs {
    guard let ctx = CGContext(
        data: nil,
        width: px,
        height: px,
        bitsPerComponent: 8,
        bytesPerRow: px * 4,
        space: cs,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else { continue }

    let s = CGFloat(px)
    let inset = s * 0.085
    let bodyRect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let radius = bodyRect.width * 0.225

    ctx.interpolationQuality = .high
    let clipPath = CGPath(roundedRect: bodyRect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    ctx.saveGState()
    ctx.addPath(clipPath)
    ctx.clip()
    ctx.draw(cgSrc, in: bodyRect)

    ctx.setStrokeColor(NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.25, alpha: 0.55).cgColor)
    ctx.setLineWidth(max(1.0, s * 0.013))
    ctx.addPath(clipPath)
    ctx.strokePath()
    ctx.restoreGState()

    if let outCG = ctx.makeImage() {
        let rep = NSBitmapImageRep(cgImage: outCG)
        if let png = rep.representation(using: .png, properties: [:]) {
            try png.write(to: appiconsetURL.appendingPathComponent(filename))
        }
    }
}

// 2. Render opaque full-bleed 1024x1024 iOS/iPadOS App Store icon (24-bit RGB, zero alpha!)
if let iosCtx = CGContext(
    data: nil,
    width: 1024,
    height: 1024,
    bitsPerComponent: 8,
    bytesPerRow: 1024 * 4,
    space: cs,
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) {
    iosCtx.interpolationQuality = .high
    iosCtx.setFillColor(NSColor(calibratedRed: 0.08, green: 0.12, blue: 0.22, alpha: 1.0).cgColor)
    iosCtx.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
    iosCtx.draw(cgSrc, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
    if let iosCG = iosCtx.makeImage(),
       let rgbRep = NSBitmapImageRep(
           bitmapDataPlanes: nil,
           pixelsWide: 1024,
           pixelsHigh: 1024,
           bitsPerSample: 8,
           samplesPerPixel: 3,
           hasAlpha: false,
           isPlanar: false,
           colorSpaceName: .deviceRGB,
           bytesPerRow: 1024 * 3,
           bitsPerPixel: 24
       ) {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rgbRep)
        NSGraphicsContext.current?.cgContext.draw(iosCG, in: CGRect(x: 0, y: 0, width: 1024, height: 1024))
        NSGraphicsContext.restoreGraphicsState()
        if let png = rgbRep.representation(using: .png, properties: [:]) {
            try png.write(to: appiconsetURL.appendingPathComponent("icon_ios_1024.png"))
        }
    }
}

// 3. Write Contents.json for Universal iOS + macOS Asset Catalog
let contentsJSON = """
{
  "images" : [
    { "filename" : "icon_ios_1024.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "filename" : "icon_16x16.png", "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "icon_16x16@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "icon_32x32.png", "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "icon_32x32@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "icon_128x128.png", "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "icon_128x128@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "icon_256x256.png", "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "icon_256x256@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "icon_512x512.png", "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "icon_512x512@2x.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
"""
try contentsJSON.write(to: appiconsetURL.appendingPathComponent("Contents.json"), atomically: true, encoding: .utf8)

let rootContentsJSON = """
{
  "info" : { "author" : "xcode", "version" : 1 }
}
"""
try rootContentsJSON.write(
    to: appiconsetURL.deletingLastPathComponent().appendingPathComponent("Contents.json"),
    atomically: true,
    encoding: .utf8
)

// 4. Marketing Icon, Storefront Banner & 1800x1200 AppClip Header export
let mktDir = projectRoot.appendingPathComponent("Marketing", isDirectory: true)
let ascDir = projectRoot.appendingPathComponent("dist/AppStore_Assets", isDirectory: true)
try FileManager.default.createDirectory(at: mktDir, withIntermediateDirectories: true)
try FileManager.default.createDirectory(at: ascDir, withIntermediateDirectories: true)

let mktIconDest = mktDir.appendingPathComponent("app_icon_source.png")
_ = try? FileManager.default.removeItem(at: mktIconDest)
try FileManager.default.copyItem(at: appiconsetURL.appendingPathComponent("icon_ios_1024.png"), to: mktIconDest)

let bannerCG: CGImage? = {
    if let bp = bannerPath,
       let bImg = NSImage(contentsOfFile: bp),
       let cg = bImg.cgImage(forProposedRect: nil, context: nil, hints: nil) {
        return cg
    }
    return renderProceduralDinoClubArtwork(width: 1600, height: 900, includeLogoBanner: true)
}()

if let bCG = bannerCG {
    let rep = NSBitmapImageRep(cgImage: bCG)
    if let png = rep.representation(using: .png, properties: [:]) {
        try png.write(to: mktDir.appendingPathComponent("storefront_banner.png"))
    }
    let tw = 1800, th = 1200
    if let clipCtx = CGContext(data: nil, width: tw, height: th, bitsPerComponent: 8, bytesPerRow: tw * 4, space: cs, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) {
        clipCtx.interpolationQuality = .high
        let sw = CGFloat(bCG.width), sh = CGFloat(bCG.height)
        let scale = max(CGFloat(tw) / sw, CGFloat(th) / sh)
        let dw = sw * scale, dh = sh * scale
        clipCtx.draw(bCG, in: CGRect(x: (CGFloat(tw) - dw) * 0.5, y: (CGFloat(th) - dh) * 0.5, width: dw, height: dh))
        if let outCG = clipCtx.makeImage() {
            let jpgRep = NSBitmapImageRep(cgImage: outCG)
            if let jpg = jpgRep.representation(using: .jpeg, properties: [.compressionFactor: 0.94]) {
                try jpg.write(to: ascDir.appendingPathComponent("AppClip_Card_Header_1800x1200.jpg"))
            }
        }
    }
}

print("Generated Universal macOS + iOS AppIcon.appiconset & Marketing banners at \(appiconsetURL.path)")
