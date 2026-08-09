import AppKit
import Foundation

func drawBackground(to path: String) {
    let size = NSSize(width: 660, height: 400)
    let image = NSImage(size: size)
    image.lockFocus()

    let bg = NSGradient(colors: [
        NSColor(calibratedRed: 0.97, green: 0.98, blue: 1.0, alpha: 1.0),
        NSColor(calibratedRed: 0.90, green: 0.92, blue: 0.97, alpha: 1.0),
    ])!
    bg.draw(in: NSRect(origin: .zero, size: size), angle: 90)

    let title = NSAttributedString(string: "Clock Overlay", attributes: [
        .font: NSFont.systemFont(ofSize: 44, weight: .bold),
        .foregroundColor: NSColor(calibratedRed: 0.12, green: 0.19, blue: 0.45, alpha: 1.0),
    ])
    let subtitle = NSAttributedString(string: "Drag the clock to your Applications folder", attributes: [
        .font: NSFont.systemFont(ofSize: 16, weight: .regular),
        .foregroundColor: NSColor(calibratedRed: 0.32, green: 0.36, blue: 0.50, alpha: 1.0),
    ])
    let hint = NSAttributedString(string: "A floating clock that stays on top of everything", attributes: [
        .font: NSFont.systemFont(ofSize: 13, weight: .regular),
        .foregroundColor: NSColor(calibratedRed: 0.55, green: 0.58, blue: 0.68, alpha: 1.0),
    ])

    let tSize = title.size()
    title.draw(at: NSPoint(x: (size.width - tSize.width) / 2, y: size.height - 92))
    let sSize = subtitle.size()
    subtitle.draw(at: NSPoint(x: (size.width - sSize.width) / 2, y: size.height - 134))
    let hSize = hint.size()
    hint.draw(at: NSPoint(x: (size.width - hSize.width) / 2, y: size.height - 162))

    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fputs("failed to render background\n", stderr)
        exit(1)
    }
    try! png.write(to: URL(fileURLWithPath: path))
    print("Wrote \(path)")
}

guard CommandLine.arguments.count >= 2 else {
    fputs("usage: make_background.swift <output.png>\n", stderr)
    exit(1)
}
drawBackground(to: CommandLine.arguments[1])
