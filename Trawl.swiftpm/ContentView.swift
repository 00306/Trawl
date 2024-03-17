import SwiftUI
import SpriteKit

struct ContentView: View {
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var soundManager: SoundManager

    var body: some View {
        Group {
            if gameManager.startGame {
                Map()
            } else {
                TitleScreen()
            }
        }
        .ignoresSafeArea()
    }

}
