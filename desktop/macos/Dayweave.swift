import AppKit
import WebKit

private let homeURL = URL(string: "https://dayweave-project-planner.l371156018.chatgpt.site/")!

@main
struct Dayweave {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        withExtendedLifetime(delegate) { app.run() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainWindow: BrowserWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMenu()
        showMainWindow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    private func showMainWindow() {
        if mainWindow == nil { mainWindow = BrowserWindow() }
        mainWindow?.showWindow(nil)
        mainWindow?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func installMenu() {
        let menu = NSMenu()
        let application = NSMenu(title: "日序")
        application.addItem(withTitle: "关于日序", action: #selector(about), keyEquivalent: "")
        application.addItem(.separator())
        application.addItem(withTitle: "隐藏日序", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        application.addItem(withTitle: "显示全部", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        application.addItem(.separator())
        application.addItem(withTitle: "退出日序", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let appItem = NSMenuItem(); appItem.submenu = application; menu.addItem(appItem)

        let edit = NSMenu(title: "编辑")
        for (title, action, key) in [("撤销", "undo:", "z"), ("重做", "redo:", "Z"), ("剪切", "cut:", "x"), ("复制", "copy:", "c"), ("粘贴", "paste:", "v"), ("全选", "selectAll:", "a")] {
            edit.addItem(withTitle: title, action: Selector(action), keyEquivalent: key)
        }
        let editItem = NSMenuItem(); editItem.submenu = edit; menu.addItem(editItem)

        let view = NSMenu(title: "显示")
        for (title, action, key) in [("刷新", #selector(reload), "r"), ("回到日序", #selector(goHome), "1"), ("放大", #selector(zoomIn), "+"), ("缩小", #selector(zoomOut), "-"), ("实际大小", #selector(resetZoom), "0"), ("在浏览器中打开", #selector(openBrowser), "B")] {
            let item = view.addItem(withTitle: title, action: action, keyEquivalent: key)
            item.target = self
        }
        let viewItem = NSMenuItem(); viewItem.submenu = view; menu.addItem(viewItem)

        let windows = NSMenu(title: "窗口")
        windows.addItem(withTitle: "最小化", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windows.addItem(withTitle: "关闭窗口", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        let windowItem = NSMenuItem(); windowItem.submenu = windows; menu.addItem(windowItem)
        NSApp.windowsMenu = windows
        NSApp.mainMenu = menu
    }

    @objc private func about() {
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "日序 · Dayweave",
            .applicationVersion: "1.0.0",
            .credits: NSAttributedString(string: "个人项目与每日安排\nMac 客户端 · 云端同步\nhttps://github.com/MOONLZH/dayweave-planner")
        ])
    }
    @objc private func reload() { mainWindow?.reloadPage() }
    @objc private func goHome() { mainWindow?.goHome() }
    @objc private func openBrowser() { NSWorkspace.shared.open(homeURL) }
    @objc private func zoomIn() { mainWindow?.changeZoom(0.1) }
    @objc private func zoomOut() { mainWindow?.changeZoom(-0.1) }
    @objc private func resetZoom() { mainWindow?.resetZoom() }
}

final class BrowserWindow: NSWindowController, WKNavigationDelegate, WKUIDelegate, NSWindowDelegate {
    private let webView: WKWebView
    private let originLabel = NSTextField(labelWithString: "正在连接日序…")
    private let progress = NSProgressIndicator()
    private let errorPanel = NSStackView()
    private let errorText = NSTextField(wrappingLabelWithString: "")
    private var observations: [NSKeyValueObservation] = []
    private var popups: [BrowserWindow] = []
    private var isPopup = false

    init(configuration: WKWebViewConfiguration? = nil, popup: Bool = false) {
        let config = configuration ?? WKWebViewConfiguration()
        if configuration == nil {
            config.websiteDataStore = .default()
            config.preferences.javaScriptCanOpenWindowsAutomatically = false
        }
        webView = WKWebView(frame: .zero, configuration: config)
        isPopup = popup
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: popup ? 620 : 1340, height: popup ? 760 : 880), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        super.init(window: window)
        window.title = popup ? "日序 · 登录" : "日序 · Dayweave"
        window.minSize = NSSize(width: popup ? 480 : 840, height: 600)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.titlebarAppearsTransparent = true
        window.backgroundColor = .windowBackgroundColor
        if !popup { window.setFrameAutosaveName("DayweaveMainWindow") }
        window.center()
        configureContent()
        if !popup { goHome() }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func button(_ symbol: String, title: String, action: Selector) -> NSButton {
        let image = NSImage(systemSymbolName: symbol, accessibilityDescription: title)!
        let button = NSButton(image: image, target: self, action: action)
        button.bezelStyle = .texturedRounded
        button.toolTip = title
        button.setAccessibilityLabel(title)
        button.widthAnchor.constraint(equalToConstant: 32).isActive = true
        return button
    }

    private func configureContent() {
        guard let root = window?.contentView else { return }
        let back = button("chevron.left", title: "返回", action: #selector(goBack))
        let forward = button("chevron.right", title: "前进", action: #selector(goForward))
        let reload = button("arrow.clockwise", title: "刷新 · ⌘R", action: #selector(reloadPage))
        let home = button("house", title: "回到日序 · ⌘1", action: #selector(goHome))
        let browser = button("safari", title: "在默认浏览器中打开", action: #selector(openInBrowser))
        originLabel.font = .systemFont(ofSize: 11)
        originLabel.textColor = .secondaryLabelColor
        originLabel.lineBreakMode = .byTruncatingMiddle
        originLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        progress.style = .spinning
        progress.controlSize = .small
        progress.isDisplayedWhenStopped = false
        let spacer = NSView()
        let bar = NSStackView(views: [back, forward, reload, home, originLabel, spacer, progress, browser])
        bar.spacing = 8
        bar.alignment = .centerY
        bar.edgeInsets = NSEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        bar.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(bar)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        root.addSubview(webView)
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: root.topAnchor), bar.leadingAnchor.constraint(equalTo: root.leadingAnchor), bar.trailingAnchor.constraint(equalTo: root.trailingAnchor), bar.heightAnchor.constraint(equalToConstant: 46),
            webView.topAnchor.constraint(equalTo: bar.bottomAnchor), webView.leadingAnchor.constraint(equalTo: root.leadingAnchor), webView.trailingAnchor.constraint(equalTo: root.trailingAnchor), webView.bottomAnchor.constraint(equalTo: root.bottomAnchor)
        ])

        let icon = NSImageView(image: NSImage(systemSymbolName: "wifi.exclamationmark", accessibilityDescription: nil)!)
        icon.contentTintColor = .secondaryLabelColor
        let heading = NSTextField(labelWithString: "暂时无法连接日序")
        heading.font = .systemFont(ofSize: 22, weight: .semibold)
        errorText.alignment = .center
        errorText.textColor = .secondaryLabelColor
        let retry = NSButton(title: "重新连接", target: self, action: #selector(goHome))
        retry.bezelStyle = .rounded
        let external = NSButton(title: "在浏览器中打开", target: self, action: #selector(openInBrowser))
        external.bezelStyle = .rounded
        errorPanel.orientation = .vertical
        errorPanel.spacing = 16
        errorPanel.alignment = .centerX
        [icon, heading, errorText, retry, external].forEach { errorPanel.addArrangedSubview($0) }
        errorPanel.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(errorPanel)
        NSLayoutConstraint.activate([errorPanel.centerXAnchor.constraint(equalTo: webView.centerXAnchor), errorPanel.centerYAnchor.constraint(equalTo: webView.centerYAnchor), errorPanel.widthAnchor.constraint(equalToConstant: 400)])
        errorPanel.isHidden = true

        observations.append(webView.observe(\.isLoading, options: [.new]) { [weak self] view, _ in
            if view.isLoading { self?.progress.startAnimation(nil) } else { self?.progress.stopAnimation(nil) }
        })
        observations.append(webView.observe(\.canGoBack, options: [.initial, .new]) { view, _ in back.isEnabled = view.canGoBack })
        observations.append(webView.observe(\.canGoForward, options: [.initial, .new]) { view, _ in forward.isEnabled = view.canGoForward })
        observations.append(webView.observe(\.url, options: [.new]) { [weak self] view, _ in
            self?.originLabel.stringValue = view.url?.host ?? "正在连接日序…"
        })
    }

    @objc func goHome() {
        hideError()
        webView.load(URLRequest(url: homeURL))
    }
    @objc func reloadPage() { hideError(); if webView.url == nil { goHome() } else { webView.reload() } }
    @objc private func goBack() { hideError(); webView.goBack() }
    @objc private func goForward() { hideError(); webView.goForward() }
    @objc private func openInBrowser() { NSWorkspace.shared.open(homeURL) }
    func changeZoom(_ amount: Double) { webView.pageZoom = min(1.8, max(0.7, webView.pageZoom + amount)) }
    func resetZoom() { webView.pageZoom = 1 }
    private func hideError() { errorPanel.isHidden = true; webView.isHidden = false }

    private func showError(_ error: Error) {
        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled || (nsError.domain == "WebKitErrorDomain" && nsError.code == 102) { return }
        errorText.stringValue = "请检查网络连接后重试。你的已保存安排仍在云端。\n\n" + error.localizedDescription
        webView.isHidden = true
        errorPanel.isHidden = false
        progress.stopAnimation(nil)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) { hideError() }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { showError(error) }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { showError(error) }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        showError(NSError(domain: "Dayweave", code: 1, userInfo: [NSLocalizedDescriptionKey: "页面进程已退出，请重新连接。"] ))
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        // Login providers may redirect across HTTPS origins. The real host remains
        // visible in the native toolbar. No native bridge or injected script is exposed.
        if url.scheme == "https" || url.absoluteString == "about:blank" {
            decisionHandler(.allow)
        } else if ["mailto", "tel"].contains(url.scheme ?? ""), navigationAction.navigationType == .linkActivated {
            NSWorkspace.shared.open(url)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.cancel)
        }
    }

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let popup = BrowserWindow(configuration: configuration, popup: true)
        popups.append(popup)
        popup.showWindow(nil)
        popup.window?.makeKeyAndOrderFront(nil)
        return popup.webView
    }
    func webViewDidClose(_ webView: WKWebView) { if isPopup { window?.close() } }
    func windowWillClose(_ notification: Notification) { popups.forEach { $0.close() }; popups.removeAll() }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = NSAlert(); alert.messageText = frame.request.url?.host ?? "日序"; alert.informativeText = message; alert.addButton(withTitle: "好")
        guard let window else { completionHandler(); return }
        alert.beginSheetModal(for: window) { _ in completionHandler() }
    }
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = NSAlert(); alert.messageText = frame.request.url?.host ?? "日序"; alert.informativeText = message; alert.addButton(withTitle: "确定"); alert.addButton(withTitle: "取消")
        guard let window else { completionHandler(false); return }
        alert.beginSheetModal(for: window) { response in completionHandler(response == .alertFirstButtonReturn) }
    }
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        let alert = NSAlert(); alert.messageText = frame.request.url?.host ?? "日序"; alert.informativeText = prompt
        let input = NSTextField(string: defaultText ?? ""); input.frame = NSRect(x: 0, y: 0, width: 280, height: 24); alert.accessoryView = input
        alert.addButton(withTitle: "确定"); alert.addButton(withTitle: "取消")
        guard let window else { completionHandler(nil); return }
        alert.beginSheetModal(for: window) { response in completionHandler(response == .alertFirstButtonReturn ? input.stringValue : nil) }
    }
}
