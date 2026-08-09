import AppKit
import Foundation

let W: CGFloat = 1600
let H: CGFloat = 1000

let image = NSImage(size: NSSize(width: W, height: H))
image.lockFocus()

let base = NSGradient(colors: [
    NSColor(calibratedRed: 0.10, green: 0.14, blue: 0.23, alpha: 1.0),
    NSColor(calibratedRed: 0.03, green: 0.04, blue: 0.08, alpha: 1.0),
])!
base.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)

func glow(_ color: NSColor, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
    let g = NSGradient(colors: [color, color.withAlphaComponent(0)])!
    g.draw(fromCenter: NSPoint(x: cx, y: cy), radius: 0,
           toCenter: NSPoint(x: cx, y: cy), radius: r,
           options: [.drawsBeforeStartingLocation])
}

glow(NSColor(calibratedRed: 0.22, green: 0.38, blue: 0.85, alpha: 0.42), 1190, 640, 480)
glow(NSColor(calibratedRed: 0.55, green: 0.22, blue: 0.80, alpha: 0.30), 220, 760, 400)
glow(NSColor(calibratedRed: 0.16, green: 0.55, blue: 0.75, alpha: 0.25), 640, 860, 360)

var rng = SystemRandomNumberGenerator()
let starCount = 140
for _ in 0..<starCount {
    let x = CGFloat.random(in: 0...W, using: &rng)
    let y = CGFloat.random(in: H * 0.45...H, using: &rng)
    let r = CGFloat.random(in: 0.8...2.4, using: &rng)
    let alpha = CGFloat.random(in: 0.12...0.5, using: &rng)
    NSColor(calibratedWhite: 1, alpha: alpha).setFill()
    NSBezierPath(ovalIn: NSRect(x: x, y: y, width: r, height: r)).fill()
}

func ridge(_ fill: NSColor, _ path: NSBezierPath) {
    fill.setFill()
    path.fill()
}

func makeRidge(_ yStart: CGFloat, _ bumps: [(CGFloat, CGFloat)]) -> NSBezierPath {
    let p = NSBezierPath()
    p.move(to: NSPoint(x: -20, y: -20))
    var x: CGFloat = -20
    var y: CGFloat = yStart
    for (dx, dy) in bumps {
        x += dx
        y += dy
        p.line(to: NSPoint(x: x, y: y))
    }
    p.line(to: NSPoint(x: W + 20, y: -20))
    p.close()
    return p
}

ridge(NSColor(calibratedRed: 0.05, green: 0.07, blue: 0.13, alpha: 0.95),
      makeRidge(240, [(340, 60), (320, -90), (360, 120), (400, -60), (200, 30)]))

ridge(NSColor(calibratedRed: 0.06, green: 0.09, blue: 0.16, alpha: 0.9),
      makeRidge(150, [(420, 50), (380, -80), (420, 90), (380, -40)]))

let now = Date()
let timeFormatter = DateFormatter()
timeFormatter.dateFormat = "h:mm:ss a"
let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "EEE MMM d"

let timeFont = NSFont.monospacedSystemFont(ofSize: 84, weight: .semibold)
let dateFont = NSFont.systemFont(ofSize: 28, weight: .medium)

let shadow = NSShadow()
shadow.shadowColor = NSColor(calibratedWhite: 0, alpha: 0.65)
shadow.shadowBlurRadius = 12
shadow.shadowOffset = NSSize(width: 0, height: -3)

let style = NSMutableParagraphStyle()
style.alignment = .center

func drawCentered(_ text: String, font: NSFont, y: CGFloat, alpha: CGFloat) {
    let attrs: [NSAttributedString.Key: Any] = [
        .font: font,
        .foregroundColor: NSColor(calibratedWhite: 1, alpha: alpha),
        .paragraphStyle: style,
        .shadow: shadow,
    ]
    let str = NSAttributedString(string: text, attributes: attrs)
    let size = str.size()
    str.draw(at: NSPoint(x: (W - size.width) / 2, y: y))
}

drawCentered(timeFormatter.string(from: now).uppercased(), font: timeFont, y: H - 330, alpha: 0.96)
drawCentered(dateFormatter.string(from: now).uppercased(), font: dateFont, y: H - 430, alpha: 0.80)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    fputs("failed to render preview\n", stderr)
    exit(1)
}
let out = CommandLine.arguments.count >= 2 ? CommandLine.arguments[1] : "assets/hero.png"
try! png.write(to: URL(fileURLWithPath: out))
print("Wrote \(out)")
