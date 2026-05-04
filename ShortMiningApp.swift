import SwiftUI
import FirebaseCore

@main
struct ShortMiningApp: App {
    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            LoginView()
        }
    }
}
