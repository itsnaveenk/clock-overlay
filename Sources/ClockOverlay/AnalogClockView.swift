import SwiftUI

struct AnalogClockView: View {
    @ObservedObject var store: SettingsStore
    @State private var now = Date()

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var faceSize: CGFloat { store.fontSize * 4.2 }
    private var appearance: ThemeAppearance { store.appearance }

    var body: some View {
        ZStack {
            face
            ticks
            hands
        }
        .frame(width: faceSize, height: faceSize)
        .onReceive(timer) { now = $0 }
    }

    @ViewBuilder
    private var face: some View {
        Group {
            switch appearance.backgroundStyle {
            case .transparent:
                Circle().fill(appearance.solidBackground.opacity(0.12))
            case .solid:
                Circle().fill(appearance.solidBackground.opacity(store.opacity))
            case .frosted:
                FrostedGlass(cornerRadius: faceSize / 2)
            }
        }
        .overlay(
            Circle().strokeBorder(appearance.foreground.opacity(0.35), lineWidth: max(store.fontSize * 0.03, 1.5))
        )
    }

    private var ticks: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = size.width / 2
            let fg = appearance.foreground
            for i in 0..<60 {
                let angle = CGFloat(i) * .pi * 2 / 60 - .pi / 2
                let isMajor = i % 5 == 0
                let outer = radius * (isMajor ? 0.92 : 0.96)
                let inner = radius * (isMajor ? 0.84 : 0.905)
                var line = Path()
                line.move(to: point(center, angle, outer))
                line.addLine(to: point(center, angle, inner))
                context.stroke(line, with: .color(fg.opacity(isMajor ? 0.9 : 0.4)),
                               lineWidth: isMajor ? 3 : 1.4)
            }
        }
    }

    private var hands: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = size.width / 2
            let fg = appearance.foreground
            let c = Calendar.current
            let hour = CGFloat(c.component(.hour, from: now) % 12)
            let minute = CGFloat(c.component(.minute, from: now))
            let second = CGFloat(c.component(.second, from: now))

            let hourAngle = (hour + minute / 60) / 12 * .pi * 2 - .pi / 2
            let minuteAngle = (minute + second / 60) / 60 * .pi * 2 - .pi / 2
            let secondAngle = second / 60 * .pi * 2 - .pi / 2

            context.stroke(strokePath(center, hourAngle, radius * 0.5),
                           with: .color(fg), lineWidth: max(store.fontSize * 0.06, 5))
            context.stroke(strokePath(center, minuteAngle, radius * 0.72),
                           with: .color(fg), lineWidth: max(store.fontSize * 0.045, 3.5))
            context.stroke(strokePath(center, secondAngle, radius * 0.8),
                           with: .color(fg.opacity(0.7)), lineWidth: 1.5)
            context.fill(Path(ellipseIn: CGRect(x: center.x - 4, y: center.y - 4, width: 8, height: 8)),
                         with: .color(fg))
        }
    }

    private func strokePath(_ center: CGPoint, _ angle: CGFloat, _ radius: CGFloat) -> Path {
        var p = Path()
        p.move(to: center)
        p.addLine(to: point(center, angle, radius))
        return p
    }

    private func point(_ center: CGPoint, _ angle: CGFloat, _ radius: CGFloat) -> CGPoint {
        CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
    }
}
