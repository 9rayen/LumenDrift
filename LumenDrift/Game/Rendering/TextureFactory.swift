import SpriteKit
import UIKit

/// Procedurally draws every game texture, so the game needs no image files.
/// To use your own art, add an image named `orb_<skinID>` (e.g. `orb_nova`) or
/// `background_<themeID>` (e.g. `background_abyss`) to Assets.xcassets — it takes priority.
enum TextureFactory {
    static let barPadding: CGFloat = 10

    private static var cache: [String: SKTexture] = [:]

    // MARK: - Shared textures

    static var glow: SKTexture {
        cached("glow") {
            render(CGSize(width: 48, height: 48)) { ctx, rect in
                let center = CGPoint(x: rect.midX, y: rect.midY)
                let colors = [
                    UIColor.white.cgColor,
                    UIColor.white.withAlphaComponent(0.35).cgColor,
                    UIColor.white.withAlphaComponent(0).cgColor,
                ] as CFArray
                guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.35, 1]) else { return }
                ctx.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: rect.width / 2, options: [])
            }
        }
    }

    static var spark: SKTexture {
        cached("spark") {
            render(CGSize(width: 24, height: 24)) { ctx, rect in
                let c = CGPoint(x: rect.midX, y: rect.midY)
                let outer = rect.width / 2 - 2
                let inner = outer * 0.28
                let path = CGMutablePath()
                for i in 0..<8 {
                    let r = i.isMultiple(of: 2) ? outer : inner
                    let a = CGFloat(i) * .pi / 4 - .pi / 2
                    let p = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
                    if i == 0 { path.move(to: p) } else { path.addLine(to: p) }
                }
                path.closeSubpath()
                ctx.setShadow(offset: .zero, blur: 3, color: UIColor.white.cgColor)
                ctx.addPath(path)
                ctx.setFillColor(UIColor.white.cgColor)
                ctx.fillPath()
            }
        }
    }

    static var pixel: SKTexture {
        cached("pixel") {
            render(CGSize(width: 8, height: 8)) { ctx, rect in
                ctx.setFillColor(UIColor.white.cgColor)
                ctx.fill(rect.insetBy(dx: 1, dy: 1))
            }
        }
    }

    static var ring: SKTexture {
        cached("ring") {
            render(CGSize(width: 64, height: 64)) { ctx, rect in
                ctx.setShadow(offset: .zero, blur: 5, color: UIColor.white.cgColor)
                ctx.setStrokeColor(UIColor.white.cgColor)
                ctx.setLineWidth(2.5)
                ctx.strokeEllipse(in: rect.insetBy(dx: 7, dy: 7))
            }
        }
    }

    static var dashedRing: SKTexture {
        cached("dashedRing") {
            render(CGSize(width: 64, height: 64)) { ctx, rect in
                ctx.setStrokeColor(UIColor.white.cgColor)
                ctx.setLineWidth(2)
                ctx.setLineDash(phase: 0, lengths: [5, 6])
                ctx.strokeEllipse(in: rect.insetBy(dx: 4, dy: 4))
            }
        }
    }

    // MARK: - Themed textures

    static func orb(_ skin: OrbSkin) -> SKTexture {
        if let custom = UIImage(named: "orb_\(skin.id)") {
            return cached("orb-custom-\(skin.id)") { custom }
        }
        return cached("orb-\(skin.id)") {
            render(CGSize(width: 48, height: 48)) { ctx, rect in
                let body = rect.insetBy(dx: 4, dy: 4)
                let core = UIColor(hex: skin.core)
                let glow = UIColor(hex: skin.glow)

                if skin.shape == .ring {
                    ctx.saveGState()
                    ctx.setShadow(offset: .zero, blur: 6, color: glow.cgColor)
                    ctx.setStrokeColor(core.cgColor)
                    ctx.setLineWidth(6)
                    ctx.strokeEllipse(in: body.insetBy(dx: 3, dy: 3))
                    ctx.restoreGState()
                    ctx.setFillColor(UIColor.white.cgColor)
                    ctx.fillEllipse(in: CGRect(x: rect.midX - 4, y: rect.midY - 4, width: 8, height: 8))
                    return
                }

                let path = skin.shape.cgPath(in: body)
                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: 6, color: glow.cgColor)
                ctx.addPath(path)
                ctx.setFillColor(core.cgColor)
                ctx.fillPath()
                ctx.restoreGState()

                // Glossy highlight.
                ctx.saveGState()
                ctx.addPath(path)
                ctx.clip()
                let colors = [UIColor.white.withAlphaComponent(0.95).cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                    let hc = CGPoint(x: body.minX + body.width * 0.38, y: body.minY + body.height * 0.32)
                    ctx.drawRadialGradient(gradient, startCenter: hc, startRadius: 0, endCenter: hc, endRadius: body.width * 0.6, options: [])
                }
                ctx.restoreGState()

                ctx.addPath(path)
                ctx.setStrokeColor(glow.withAlphaComponent(0.95).cgColor)
                ctx.setLineWidth(1.5)
                ctx.strokePath()
            }
        }
    }

    /// Rounded glass bar with a baked glow. The texture includes `barPadding` on every side.
    static func bar(size: CGSize, color hex: UInt32) -> SKTexture {
        let width = max(16, (size.width / 8).rounded() * 8)
        let height = size.height
        return cached("bar-\(Int(width))-\(Int(height))-\(hex)") {
            let pad = barPadding
            return render(CGSize(width: width + pad * 2, height: height + pad * 2)) { ctx, rect in
                let body = rect.insetBy(dx: pad, dy: pad)
                let radius = min(body.height / 2, 9)
                let path = UIBezierPath(roundedRect: body, cornerRadius: radius).cgPath
                let tint = UIColor(hex: hex)

                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: 9, color: tint.withAlphaComponent(0.9).cgColor)
                ctx.addPath(path)
                ctx.setFillColor(tint.withAlphaComponent(0.4).cgColor)
                ctx.fillPath()
                ctx.restoreGState()

                ctx.saveGState()
                ctx.addPath(path)
                ctx.clip()
                let colors = [
                    UIColor.white.withAlphaComponent(0.4).cgColor,
                    UIColor.white.withAlphaComponent(0.02).cgColor,
                    tint.withAlphaComponent(0.35).cgColor,
                ] as CFArray
                if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 0.5, 1]) {
                    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: body.minY), end: CGPoint(x: 0, y: body.maxY), options: [])
                }
                ctx.restoreGState()

                ctx.addPath(path)
                ctx.setStrokeColor(tint.cgColor)
                ctx.setLineWidth(1.5)
                ctx.strokePath()

                ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.6).cgColor)
                ctx.setLineWidth(1)
                ctx.move(to: CGPoint(x: body.minX + radius, y: body.minY + 2.5))
                ctx.addLine(to: CGPoint(x: body.maxX - radius, y: body.minY + 2.5))
                ctx.strokePath()
            }
        }
    }

    static func powerUp(_ kind: PowerUpKind) -> SKTexture {
        cached("powerup-\(kind.rawValue)") {
            render(CGSize(width: 48, height: 48)) { ctx, rect in
                let tint = UIColor(hex: kind.color)
                let circle = rect.insetBy(dx: 6, dy: 6)
                ctx.saveGState()
                ctx.setShadow(offset: .zero, blur: 8, color: tint.cgColor)
                ctx.setFillColor(tint.withAlphaComponent(0.3).cgColor)
                ctx.fillEllipse(in: circle)
                ctx.restoreGState()
                ctx.setStrokeColor(tint.cgColor)
                ctx.setLineWidth(2)
                ctx.strokeEllipse(in: circle)

                let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .black)
                if let symbol = UIImage(systemName: kind.symbol, withConfiguration: config)?
                    .withTintColor(.white, renderingMode: .alwaysOriginal) {
                    let s = symbol.size
                    symbol.draw(in: CGRect(x: rect.midX - s.width / 2, y: rect.midY - s.height / 2, width: s.width, height: s.height))
                }
            }
        }
    }

    static func background(for theme: WorldTheme) -> SKTexture {
        if let custom = UIImage(named: "background_\(theme.id)") {
            return cached("bg-custom-\(theme.id)") { custom }
        }
        return cached("bg-\(theme.id)") {
            render(CGSize(width: 4, height: 128)) { ctx, rect in
                let colors = [UIColor(hex: theme.top).cgColor, UIColor(hex: theme.bottom).cgColor] as CFArray
                guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) else { return }
                ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: rect.minY), end: CGPoint(x: 0, y: rect.maxY), options: [])
            }
        }
    }

    // MARK: - Helpers

    private static func cached(_ key: String, _ make: () -> UIImage) -> SKTexture {
        if let texture = cache[key] { return texture }
        let texture = SKTexture(image: make())
        cache[key] = texture
        return texture
    }

    private static func render(_ size: CGSize, _ draw: (CGContext, CGRect) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 3
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            draw(context.cgContext, CGRect(origin: .zero, size: size))
        }
    }
}
