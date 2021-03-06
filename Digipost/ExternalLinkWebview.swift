//
// Copyright (C) Posten Norge AS
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//         http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit
import WebKit

@objc class ExternalLinkWebview: UIViewController, UIWebViewDelegate, UIToolbarDelegate{
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var shareButton: UIBarButtonItem!    
    @IBOutlet weak var navBar: UINavigationBar!
    
    var screenEdgeRecognizer: UIScreenEdgePanGestureRecognizer!
    @objc var initUrl: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.setNavigationBarHidden(true, animated: true)
        self.navigationController?.setToolbarHidden(true, animated: true)
        screenEdgeRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(ExternalLinkWebview.backButtonPressed))
        
        if urlIsValid() {
            let myURL = URL(string: initUrl)
            self.navBar.topItem?.title = formatTitle(url: myURL!)
            webView.delegate = self
            webView.scrollView.contentInset = UIEdgeInsets.zero;
            webView.loadRequest(URLRequest(url: myURL!))
        }else{
            navigationController?.popViewController(animated: true)
        }
        setupToolbar()
    }
    
    func setupToolbar() {
        self.navBar.barTintColor = UIColor(red:0.98, green:0.98, blue:0.98, alpha:1.0)
        self.navBar.tintColor = UIColor(red:0.14, green:0.14, blue:0.14, alpha:1.0)
        self.navBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor(red:0.14, green:0.14, blue:0.14, alpha:1.0)]
        
        var toolbarItems = [UIBarButtonItem]()
        toolbarItems.append(
            UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(ExternalLinkWebview.webviewBack)))
        
        let fixedSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.fixedSpace, target: nil, action: nil)
        fixedSpace.width = 30.0
        toolbarItems.append(fixedSpace)

        toolbarItems.append(
            UIBarButtonItem(image: UIImage(named: "forwardarrow"), style: .plain, target: self, action: #selector(ExternalLinkWebview.webviewForward)))
        
        self.toolbar.setItems(toolbarItems, animated: true)
        toggleToolbarVisibility()
    }
    
    @objc func webviewBack(){
        if self.webView.canGoBack {
            self.webView.goBack()
        }
    }
    
    @objc func webviewForward(){
        if self.webView.canGoForward {
            self.webView.goForward()
        }
    }
    
    func urlIsValid() -> Bool{
        if let url  = NSURL(string: initUrl) {
            return UIApplication.shared.canOpenURL(url as URL)
        }
        return false;
    }
    
    func formatTitle(url: URL) -> String {
        return url.deletingPathExtension().scheme! + "://" + url.deletingPathExtension().host!
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        if let currentUrl = self.webView.request?.url?.absoluteString {
            if !currentUrl.isEmpty {
                self.navBar.topItem?.title = formatTitle(url: URL(string: currentUrl)!)
            }
        }
        toggleToolbarVisibility()
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if request.url?.scheme == "http" {
            openUrlInExternalBrowser(url: (request.url?.absoluteString)!)
            return false
        }
        return true
    }
    
    func toggleToolbarVisibility() {
        self.toolbar.isHidden = !(self.webView.canGoForward || self.webView.canGoBack)
        self.toolbar.items?[0].isEnabled = self.webView.canGoBack
        self.toolbar.items?[2].isEnabled = self.webView.canGoForward
    }
    
    @IBAction func share(_ sender: Any) {
        openUrlInExternalBrowser(url: initUrl)
    }
    
    func openUrlInExternalBrowser(url: String) {        
        let alertController = UIAlertController(title: url, message: nil, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("GENERIC_OPEN_IN_SAFARI_BUTTON_TITLE", comment: "Open in Safari"), style: .default) { (action) in
            UIApplication.shared.openURL(URL(string:url)!)
        })
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("GENERIC_CANCEL_BUTTON_TITLE", comment: "Cancel"), style: .cancel) { (action) in
            alertController.dismiss(animated: true, completion: {})
        })

        UIApplication.shared.keyWindow?.rootViewController?.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
