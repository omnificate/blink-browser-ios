import UIKit
import WebKit

class BrowserViewController: UIViewController {
    
    // MARK: - Properties
    private var tabManager = TabManager()
    private var urlBar: URLBarView!
    private var webViewContainer: UIView!
    private var progressView: UIProgressView!
    private var currentWebView: WKWebView? { tabManager.activeTab?.webView }
    private var progressObservation: NSKeyValueObservation?
    private var titleObservation: NSKeyValueObservation?
    private var urlObservation: NSKeyValueObservation?
    
    private let adBlocker = AdBlocker()
    private let bookmarkManager = BookmarkManager()
    private let historyManager = HistoryManager()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        tabManager.delegate = self
        tabManager.createTab()
    }
    
    override var prefersStatusBarHidden: Bool { false }
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
    
    // MARK: - UI Setup
    private func setupUI() {
        // WebView container
        webViewContainer = UIView()
        webViewContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webViewContainer)
        
        // Progress bar
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.tintColor = UIColor(red: 0, green: 0.48, blue: 1, alpha: 1)
        progressView.isHidden = true
        view.addSubview(progressView)
        
        // URL bar
        urlBar = URLBarView()
        urlBar.translatesAutoresizingMaskIntoConstraints = false
        urlBar.delegate = self
        view.addSubview(urlBar)
        
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            webViewContainer.topAnchor.constraint(equalTo: view.topAnchor),
            webViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webViewContainer.bottomAnchor.constraint(equalTo: urlBar.topAnchor, constant: -4),
            
            progressView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2),
            
            urlBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            urlBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            urlBar.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -4),
            urlBar.heightAnchor.constraint(equalToConstant: 52),
        ])
    }
    
    // MARK: - WebView Management
    private func attachWebView(_ webView: WKWebView) {
        webViewContainer.subviews.forEach { $0.removeFromSuperview() }
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webViewContainer.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: webViewContainer.topAnchor),
            webView.leadingAnchor.constraint(equalTo: webViewContainer.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: webViewContainer.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: webViewContainer.bottomAnchor),
        ])
        
        observeWebView(webView)
    }
    
    private func observeWebView(_ webView: WKWebView) {
        progressObservation?.invalidate()
        titleObservation?.invalidate()
        urlObservation?.invalidate()
        
        progressObservation = webView.observe(\.estimatedProgress) { [weak self] wv, _ in
            let progress = Float(wv.estimatedProgress)
            self?.progressView.setProgress(progress, animated: true)
            self?.progressView.isHidden = progress >= 1.0
        }
        
        titleObservation = webView.observe(\.title) { [weak self] wv, _ in
            self?.urlBar.updateTitle(wv.title ?? "")
        }
        
        urlObservation = webView.observe(\.url) { [weak self] wv, _ in
            guard let url = wv.url else { return }
            self?.urlBar.updateURL(url)
            self?.urlBar.updateNavState(canGoBack: wv.canGoBack, canGoForward: wv.canGoForward)
        }
    }
    
    func navigate(to urlString: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let url: URL
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            guard let parsed = URL(string: trimmed) else { return }
            url = parsed
        } else if trimmed.contains(".") && !trimmed.contains(" ") {
            guard let parsed = URL(string: "https://\(trimmed)") else { return }
            url = parsed
        } else {
            let query = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            guard let parsed = URL(string: "https://www.google.com/search?q=\(query)") else { return }
            url = parsed
        }
        
        currentWebView?.load(URLRequest(url: url))
    }
}

// MARK: - URLBarDelegate
extension BrowserViewController: URLBarDelegate {
    func urlBarDidTapBack() { currentWebView?.goBack() }
    func urlBarDidTapForward() { currentWebView?.goForward() }
    func urlBarDidTapReload() { currentWebView?.reload() }
    func urlBarDidSubmit(_ text: String) { navigate(to: text) }
    
    func urlBarDidTapTabs() {
        let tabSwitcher = TabSwitcherViewController(tabManager: tabManager)
        tabSwitcher.delegate = self
        tabSwitcher.modalPresentationStyle = .fullScreen
        present(tabSwitcher, animated: true)
    }
    
    func urlBarDidTapMenu() {
        let menu = MenuViewController()
        menu.delegate = self
        menu.isBookmarked = currentWebView?.url != nil && bookmarkManager.isBookmarked(url: currentWebView!.url!.absoluteString)
        menu.modalPresentationStyle = .pageSheet
        if let sheet = menu.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(menu, animated: true)
    }
    
    func urlBarTabCount() -> Int { tabManager.tabs.count }
}

// MARK: - TabManagerDelegate
extension BrowserViewController: TabManagerDelegate {
    func tabManager(_ manager: TabManager, didActivateTab tab: WebViewTab) {
        attachWebView(tab.webView)
        if let url = tab.webView.url {
            urlBar.updateURL(url)
            urlBar.updateTitle(tab.webView.title ?? "")
        } else {
            urlBar.updateTitle("New Tab")
            urlBar.updateURL(nil)
        }
        urlBar.updateTabCount(manager.tabs.count)
        
        if adBlocker.isEnabled {
            adBlocker.injectBlockingRules(into: tab.webView)
        }
    }
    
    func tabManagerDidUpdateTabs(_ manager: TabManager) {
        urlBar.updateTabCount(manager.tabs.count)
    }
}

// MARK: - TabSwitcherDelegate
extension BrowserViewController: TabSwitcherDelegate {
    func tabSwitcherDidSelectTab(at index: Int) {
        tabManager.switchToTab(at: index)
        dismiss(animated: true)
    }
    
    func tabSwitcherDidCloseTab(at index: Int) {
        tabManager.closeTab(at: index)
    }
    
    func tabSwitcherDidRequestNewTab() {
        tabManager.createTab()
        dismiss(animated: true)
    }
}

// MARK: - MenuDelegate
extension BrowserViewController: MenuDelegate {
    func menuDidSelectAction(_ action: MenuAction) {
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            switch action {
            case .bookmark:
                guard let url = self.currentWebView?.url?.absoluteString else { return }
                let title = self.currentWebView?.title ?? url
                if self.bookmarkManager.isBookmarked(url: url) {
                    self.bookmarkManager.removeBookmark(url: url)
                } else {
                    self.bookmarkManager.addBookmark(url: url, title: title)
                }
            case .share:
                guard let url = self.currentWebView?.url else { return }
                let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                self.present(vc, animated: true)
            case .reload:
                self.currentWebView?.reload()
            case .findInPage:
                self.showFindInPage()
            case .readerMode:
                self.activateReaderMode()
            case .desktopSite:
                self.toggleDesktopMode()
            case .bookmarks:
                self.showBookmarks()
            case .history:
                self.showHistory()
            case .settings:
                self.showSettings()
            case .newIncognitoTab:
                self.tabManager.createTab(incognito: true)
            }
        }
    }
    
    private func showFindInPage() {
        let alert = UIAlertController(title: "Find in Page", message: nil, preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Search text..." }
        alert.addAction(UIAlertAction(title: "Find", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else { return }
            let js = "window.find('\(text.replacingOccurrences(of: "'", with: "\\'"))')"
            self?.currentWebView?.evaluateJavaScript(js)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func activateReaderMode() {
        currentWebView?.evaluateJavaScript(ReaderMode.injectionScript)
    }
    
    private func toggleDesktopMode() {
        guard let wv = currentWebView else { return }
        let desktopUA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        wv.customUserAgent = wv.customUserAgent == desktopUA ? nil : desktopUA
        wv.reload()
    }
    
    private func showBookmarks() {
        let vc = UITableViewController(style: .insetGrouped)
        vc.title = "Bookmarks"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissModal))
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    private func showHistory() {
        let vc = UITableViewController(style: .insetGrouped)
        vc.title = "History"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissModal))
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    private func showSettings() {
        let vc = UITableViewController(style: .insetGrouped)
        vc.title = "Settings"
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissModal))
        let nav = UINavigationController(rootViewController: vc)
        present(nav, animated: true)
    }
    
    @objc private func dismissModal() {
        dismiss(animated: true)
    }
}

// MARK: - WKNavigationDelegate
extension BrowserViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        
        if adBlocker.isEnabled && adBlocker.shouldBlock(url: url.absoluteString) {
            decisionHandler(.cancel)
            return
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let url = webView.url, !tabManager.activeTab!.isIncognito else { return }
        historyManager.addEntry(url: url.absoluteString, title: webView.title ?? "")
        
        if adBlocker.isEnabled {
            adBlocker.injectCSSBlocking(into: webView)
        }
    }
}

// MARK: - WKUIDelegate
extension BrowserViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
}
