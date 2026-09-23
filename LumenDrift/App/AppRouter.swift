import Combine
import SwiftUI

final class AppRouter: ObservableObject {
    enum Screen: Equatable {
        case launch, home, game
    }

    @Published private(set) var screen: Screen = .launch

    func go(_ screen: Screen) {
        guard screen != self.screen else { return }
        self.screen = screen
    }
}
