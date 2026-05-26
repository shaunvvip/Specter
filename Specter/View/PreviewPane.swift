import SwiftUI
import WebKit

struct PreviewPane: NSViewRepresentable {
    @Environment(AppEnvironment.self) private var env

    func makeNSView(context: Context) -> WKWebView {
        let cfg = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: cfg)
        webView.setValue(false, forKey: "drawsBackground")
        if let url = Bundle.main.url(forResource: "index", withExtension: "html",
                                     subdirectory: "preview") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        } else {
            // No bundle yet — display a placeholder via data URL so the app is still usable pre-bundle.
            let html = """
            <html><body style="background:#1e1e2e;color:#cdd6f4;font-family:monospace;padding:20px">
            <p>Preview not bundled yet.</p>
            <p>Run: <code>./scripts/build-preview-bundle.sh</code></p>
            </body></html>
            """
            webView.loadHTMLString(html, baseURL: nil)
        }
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        let opts = PreviewBridge.translate(env.configModel, themeColors: env.currentThemeColors)
        guard let data = try? JSONEncoder().encode(opts),
              let json = String(data: data, encoding: .utf8) else { return }
        let js = "window.applyPreview && window.applyPreview(\(json));"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
}
