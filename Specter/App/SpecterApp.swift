import SwiftUI

@main
struct SpecterApp: App {
    @State private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup("Specter") {
            ContentView()
                .environment(env)
                .frame(minWidth: 980, minHeight: 620)
                .task { await env.bootstrap() }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
    }
}
