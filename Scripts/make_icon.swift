import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import Foundation

func drawIcon(pixels: Int) -> CGImage {
    let ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8,
                        bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    let s = CGFloat(pixels)
    let radius = s * 0.225

    ctx.addPath(CGPath(roundedRect: CGRect(x: 0, y: 0, width: s, height: s),
                       cornerWidth: radius, cornerHeight: radius, transform: nil))
    ctx.clip()

    let colors = [
        CGColor(red: 0.15, green: 0.33, blue: 0.94, alpha: 1.0),
        CGColor(red: 0.48, green: 0.19, blue: 0.86, alpha: 1.0),
    ] as CFArray
    let grad = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
                          colors: colors, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: 0, y: s), end: CGPoint(x: s, y: 0), options: [])

    let ink = CGColor(red: 0.10, green: 0.11, blue: 0.24, alpha: 1.0)

    let face = CGRect(x: s * 0.16, y: s * 0.16, width: s * 0.68, height: s * 0.68)
    ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.fillEllipse(in: face)
    ctx.setStrokeColor(ink)
    ctx.setLineWidth(s * 0.016)
    ctx.strokeEllipse(in: face.insetBy(dx: s * 0.012, dy: s * 0.012))

    let center = CGPoint(x: face.midX, y: face.midY)
    let rOuter = face.width * 0.48
    let rInner = face.width * 0.42
    ctx.setStrokeColor(ink)
    ctx.setLineWidth(s * 0.012)
    ctx.setLineCap(.round)
    for i in 0..<12 {
        let a = .pi / 2 - CGFloat(i) * .pi / 6
        let p1 = CGPoint(x: center.x + cos(a) * rOuter, y: center.y + sin(a) * rOuter)
        let p2 = CGPoint(x: center.x + cos(a) * rInner, y: center.y + sin(a) * rInner)
        ctx.move(to: p1)
        ctx.addLine(to: p2)
        ctx.strokePath()
    }

    ctx.setStrokeColor(ink)
    ctx.setLineWidth(s * 0.026)
    ctx.setLineCap(.round)
    let hourLen = face.width * 0.27
    let hourA = .pi / 2 - 10.0 * .pi / 6
    ctx.move(to: center)
    ctx.addLine(to: CGPoint(x: center.x + cos(hourA) * hourLen, y: center.y + sin(hourA) * hourLen))
    ctx.strokePath()

    ctx.setLineWidth(s * 0.018)
    let minLen = face.width * 0.37
    let minA = .pi / 2 - 10.0 * .pi / 30
    ctx.move(to: center)
    ctx.addLine(to: CGPoint(x: center.x + cos(minA) * minLen, y: center.y + sin(minA) * minLen))
    ctx.strokePath()

    ctx.setFillColor(ink)
    ctx.fillEllipse(in: CGRect(x: center.x - s * 0.035, y: center.y - s * 0.035,
                               width: s * 0.07, height: s * 0.07))

    return ctx.makeImage()!
}

func writePNG(_ image: CGImage, to url: URL) {
    let dest = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

guard CommandLine.arguments.count >= 2 else {
    fputs("usage: make_icon.swift <output.icns>\n", stderr)
    exit(1)
}

let output = URL(fileURLWithPath: CommandLine.arguments[1])
let tmp = FileManager.default.temporaryDirectory
    .appendingPathComponent("clockoverlay-iconset-\(UUID().uuidString)")
let iconset = tmp.appendingPathComponent("AppIcon.iconset")
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let entries: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]
for (name, px) in entries {
    writePNG(drawIcon(pixels: px), to: iconset.appendingPathComponent("\(name).png"))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconset.path, "-o", output.path]
try! process.run()
process.waitUntilExit()

try? FileManager.default.removeItem(at: tmp)
print("Wrote \(output.path)")
