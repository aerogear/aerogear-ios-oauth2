/*
* JBoss, Home of Professional Open Source.
* Copyright Red Hat, Inc., and individual contributors
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*     http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

import Foundation

import UIKit
import WebKit

/**
OAuth2WebViewController is a UIViewController to be used when the Oauth2 flow used an embedded view controller
rather than an external browser approach.
*/
open class OAuth2WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UIScrollViewDelegate {
    /// Login URL for OAuth.
    var targetURL: URL!
    /// WebView instance used to load login page.
    var webView: WKWebView = WKWebView()
    let SESSION_STATE: String = "session_state"
    let CODE: String = "code"

    /// Override of viewDidLoad to load the login page.
    override open func viewDidLoad() {
        super.viewDidLoad()
        intializeWKWebview()
        loadAddressURL()
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        webView.cleanAllCookies()
        webView.refreshCookies()
    }

    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.webView.frame = self.view.bounds
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    fileprivate func intializeWKWebview() {
        webView.frame = UIScreen.main.bounds
        webView.navigationDelegate = self
        let contentController = WKUserContentController()
        //Script to disable zoomin and zoomout in webview
        let source: String = "var meta = document.createElement('meta');" +
            "meta.name = 'viewport';" +
            "meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';" +
            "var head = document.getElementsByTagName('head')[0];" +
        "head.appendChild(meta);"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        contentController.addUserScript(script)
        let config = WKWebViewConfiguration()
        config.userContentController = contentController
        webView = WKWebView(frame: .zero, configuration: config )
        webView.scrollView.delegate = self
        webView.sizeToFit()
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view = webView
    }

    func loadAddressURL() {
        let req = URLRequest(url: targetURL)
        webView.load(req)
    }
    
    /**
            WKWebview delegate methods
     */
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping ((WKNavigationActionPolicy) -> Void)) {
        if let url = navigationAction.request.url?.absoluteString {
            if url.contains(SESSION_STATE) && url.contains(CODE) {
                if let urlReq = URL(string: url) {
                    let notification = Notification(name: Notification.Name(AGAppLaunchedWithURLNotification), object: nil, userInfo: [UIApplication.LaunchOptionsKey.url: urlReq])
                    NotificationCenter.default.post(notification)
                }
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
    }
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation?) {
        
    }
}
extension WKWebView {
    func cleanAllCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
            }
        }
    }
    func refreshCookies() {
        self.configuration.processPool = WKProcessPool()
    }
}

