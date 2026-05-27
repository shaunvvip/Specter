import SwiftUI

@main
struct SpecterApp: App {
    @State private var env = AppEnvironment()

    var body: some Scene {
        WindowGroup("Specter") {
            ContentView()
                .environment(env)
                .frame(minWidth: 1180, minHeight: 760)
                .preferredColorScheme(.dark)
                .task { await env.bootstrap() }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .defaultSize(width: 1280, height: 820)
    }
}
