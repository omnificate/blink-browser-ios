import WebKit

class AdBlocker {
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: "adblock_enabled") }
        set { UserDefaults.standard.set(newValue, forKey: "adblock_enabled") }
    }
    
    private let blockedDomains = [
        "doubleclick.net", "googlesyndication.com", "googleadservices.com",
        "adservice.google.com", "pagead2.googlesyndication.com",
        "ads.google.com", "adnxs.com", "advertising.com", "adsrvr.org",
        "outbrain.com", "taboola.com", "criteo.com", "criteo.net",
        "pubmatic.com", "openx.net", "rubiconproject.com",
        "casalemedia.com", "moatads.com", "scorecardresearch.com",
        "quantserve.com", "bluekai.com", "amazon-adsystem.com",
        "sharethrough.com", "smartadserver.com", "yieldmo.com",
        "indexexchange.com", "bidswitch.net", "media.net",
        "google-analytics.com", "googletagmanager.com",
        "hotjar.com", "mixpanel.com", "clarity.ms",
        "fullstory.com", "newrelic.com", "nr-data.net",
        "facebook.net", "analytics.tiktok.com", "ads.twitter.com",
    ]
    
    init() {
        if !UserDefaults.standard.bool(forKey: "adblock_initialized") {
            isEnabled = true
            UserDefaults.standard.set(true, forKey: "adblock_initialized")
        }
    }
    
    func shouldBlock(url: String) -> Bool {
        let lower = url.lowercased()
        return blockedDomains.contains { lower.contains($0) }
    }
    
    func injectBlockingRules(into webView: WKWebView) {
        let ruleList = blockedDomains.map { domain in
            """
            {"trigger":{"url-filter":".*\\\\.\(domain.replacingOccurrences(of: ".", with: "\\\\.")).*"},"action":{"type":"block"}}
            """
        }.joined(separator: ",")
        
        let json = "[\(ruleList)]"
        WKContentRuleListStore.default().compileContentRuleList(
            forIdentifier: "adblock",
            encodedContentRuleList: json
        ) { ruleList, error in
            guard let ruleList = ruleList, error == nil else { return }
            DispatchQueue.main.async {
                webView.configuration.userContentController.add(ruleList)
            }
        }
    }
    
    func injectCSSBlocking(into webView: WKWebView) {
        let css = "[class*=\\\"ad-\\\"],[class*=\\\"ads-\\\"],[id*=\\\"ad-\\\"],[id*=\\\"ads-\\\"],[class*=\\\"advert\\\"],[id*=\\\"advert\\\"],.ad,.ads,.adsbygoogle,.sponsored,.promoted{display:none!important;height:0!important;overflow:hidden!important}"
        let js = "var s=document.createElement('style');s.textContent='\(css)';document.head.appendChild(s);"
        webView.evaluateJavaScript(js)
    }
}

struct ReaderMode {
    static let injectionScript = """
    (function(){
        try{
            var a=document.querySelector('article')||document.querySelector('[role="main"]')||document.querySelector('main');
            if(!a){var b=document.body,m=0;document.querySelectorAll('div,section').forEach(function(e){var c=e.querySelectorAll('p').length;if(c>m){m=c;b=e}});a=b}
            var c=a.innerHTML,t=document.title;
            document.documentElement.innerHTML='<head><meta name="viewport" content="width=device-width,initial-scale=1"><style>*{margin:0;padding:0;box-sizing:border-box}body{font-family:Georgia,serif;line-height:1.8;color:#222;background:#FAFAFA;padding:20px 16px;max-width:680px;margin:0 auto}h1{font-size:24px;margin-bottom:20px;line-height:1.3;font-family:-apple-system,sans-serif;font-weight:700}p{margin:0 0 16px;font-size:17px}img{max-width:100%;height:auto;border-radius:8px;margin:12px 0}a{color:#007AFF}blockquote{border-left:3px solid #007AFF;padding-left:14px;margin:14px 0;color:#666;font-style:italic}@media(prefers-color-scheme:dark){body{background:#1A1A1A;color:#E0E0E0}}</style></head><body><h1>'+t+'</h1>'+c+'</body>';
        }catch(e){}
    })();
    """
}
