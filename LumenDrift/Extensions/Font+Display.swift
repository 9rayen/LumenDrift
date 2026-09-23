import SwiftUI
import UIKit

extension Font {
    /// The game's display face: SF Pro Rounded.
    static func display(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Small, tracked, uppercase label style.
    static let eyebrow = Font.system(size: 11, weight: .bold, design: .rounded)
}

extension UIFont {
    static func rounded(_ size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let base = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = base.fontDescriptor.withDesign(.rounded) else { return base }
        return UIFont(descriptor: descriptor, size: size)
    }
}
