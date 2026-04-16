import WebKit

protocol TabManagerDelegate: AnyObject {
    func tabManager(_ manager: TabManager, didActivateTab tab: WebViewTab)
    func tabManagerDidUpdateTabs(_ manager: TabManager)
}

class TabManager {
    weak var delegate: TabManagerDelegate?
    private(set) var tabs: [WebViewTab] = []
    private(set) var activeIndex: Int = 0
    
    var activeTab: WebViewTab? {
        guard activeIndex >= 0 && activeIndex < tabs.count else { return nil }
        return tabs[activeIndex]
    }
    
    @discardableResult
    func createTab(url: URL? = nil, incognito: Bool = false) -> WebViewTab {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        if incognito {
            config.websiteDataStore = .nonPersistent()
        }
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        
        let tab = WebViewTab(webView: webView, isIncognito: incognito)
        tabs.append(tab)
        activeIndex = tabs.count - 1
        
        delegate?.tabManagerDidUpdateTabs(self)
        delegate?.tabManager(self, didActivateTab: tab)
        
        if let url = url {
            webView.load(URLRequest(url: url))
        }
        
        return tab
    }
    
    func switchToTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        activeIndex = index
        delegate?.tabManager(self, didActivateTab: tabs[index])
    }
    
    func closeTab(at index: Int) {
        guard index >= 0 && index < tabs.count else { return }
        tabs[index].webView.stopLoading()
        tabs.remove(at: index)
        
        if tabs.isEmpty {
            createTab()
            return
        }
        
        if activeIndex >= tabs.count {
            activeIndex = tabs.count - 1
        }
        
        delegate?.tabManagerDidUpdateTabs(self)
        delegate?.tabManager(self, didActivateTab: tabs[activeIndex])
    }
}

class WebViewTab {
    let webView: WKWebView
    let isIncognito: Bool
    let id = UUID()
    
    init(webView: WKWebView, isIncognito: Bool = false) {
        self.webView = webView
        self.isIncognito = isIncognito
    }
    
    var title: String { webView.title ?? "New Tab" }
    var url: URL? { webView.url }
}
