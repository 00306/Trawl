import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(GameManager())
                .environmentObject(SoundManager())
                .preferredColorScheme(.dark)
        }
    }
}
