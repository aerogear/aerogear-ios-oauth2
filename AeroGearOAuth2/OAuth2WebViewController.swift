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

class OAuth2WebViewController: UIViewController, UIWebViewDelegate {
    var targetURL : NSURL = NSURL()
    var webView : UIWebView = UIWebView()
      
    override internal func viewDidLoad() {
        super.viewDidLoad()
        webView.frame = UIScreen.mainScreen().applicationFrame
        webView.delegate = self
        self.view.addSubview(webView)
        loadAddressURL()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.webView.frame = self.view.bounds
    }
    
    override internal func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func loadAddressURL() {
        let req = NSURLRequest(URL: targetURL)
        webView.loadRequest(req)
    }
}
