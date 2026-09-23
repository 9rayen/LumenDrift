import SpriteKit
import UIKit

/// Builds particle emitters in code (no .sks files needed).
enum EmitterFactory {
    static func trail(_ style: TrailStyle, fallbackColor: UInt32, radius: CGFloat) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = texture(for: style.particle)
        emitter.particleBirthRate = style.birthRate
        emitter.particleLifetime = style.lifetime
        emitter.particleLifetimeRange = style.lifetime * 0.3
        emitter.particlePositionRange = CGVector(dx: radius * 0.9, dy: radius * 0.4)
        emitter.emissionAngle = -.pi / 2
        emitter.emissionAngleRange = style.spread
        emitter.particleSpeed = 300
        emitter.particleSpeedRange = 60
        emitter.particleAlpha = 0.9
        emitter.particleAlphaSpeed = -0.9 / style.lifetime
        emitter.particleScale = style.scale
        emitter.particleScaleRange = style.scale * 0.3
        emitter.particleScaleSpeed = -style.scale / style.lifetime
        emitter.particleRotationRange = style.particle == .glow ? 0 : .pi * 2
        emitter.particleBlendMode = .add
        emitter.particleColorBlendFactor = 1

        let colors = (style.colors.isEmpty ? [fallbackColor] : style.colors).map { UIColor(hex: $0) }
        if colors.count == 1 {
            emitter.particleColor = colors[0]
        } else {
            let times = colors.indices.map { NSNumber(value: Double($0) / Double(colors.count - 1)) }
            emitter.particleColorSequence = SKKeyframeSequence(keyframeValues: colors, times: times)
        }
        return emitter
    }

    static func burst(color: UIColor, count: Int, speed: CGFloat, lifetime: CGFloat, scale: CGFloat,
                      texture: SKTexture? = nil) -> SKEmitterNode {
        let emitter = SKEmitterNode()
        emitter.particleTexture = texture ?? TextureFactory.glow
        emitter.numParticlesToEmit = count
        emitter.particleBirthRate = CGFloat(count) * 60
        emitter.particleLifetime = lifetime
        emitter.particleLifetimeRange = lifetime * 0.4
        emitter.emissionAngleRange = .pi * 2
        emitter.particleSpeed = speed
        emitter.particleSpeedRange = speed * 0.6
        emitter.particleAlpha = 1
        emitter.particleAlphaSpeed = -1 / lifetime
        emitter.particleScale = scale
        emitter.particleScaleRange = scale * 0.5
        emitter.particleScaleSpeed = -scale / lifetime
        emitter.particleColor = color
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = .add
        return emitter
    }

    private static func texture(for particle: TrailParticle) -> SKTexture {
        switch particle {
        case .glow: return TextureFactory.glow
        case .spark: return TextureFactory.spark
        case .pixel: return TextureFactory.pixel
        }
    }
}
