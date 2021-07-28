//
//  ViewController.swift
//  WebViewCaches
//
//  Created by Sam Symons on 2021-07-28.
//

import UIKit
import WebKit

class ViewController: UIViewController, WKNavigationDelegate {

    @IBOutlet var urlTextField: UITextField!
    @IBOutlet var toggleWebViewButton: UIButton!
    @IBOutlet var webViewContainer: UIView! {
        didSet {
            webViewContainer.layer.masksToBounds = false
            webViewContainer.layer.borderWidth = 2.0
            webViewContainer.layer.borderColor = UIColor.lightGray.cgColor
        }
    }

    private let defaultURL = URL(string: "https://youtube.com")!

    private var webView: WKWebView?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let libraryLocation = FileManager.default.urls(for: .libraryDirectory, in: .allDomainsMask).first {
            print("App Data Directory: \(libraryLocation)")
        }

        self.urlTextField.text = defaultURL.absoluteString
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard)))
        createAndAddWebView()
        loadCurrentURL()
    }

    @IBAction func loadURLFromTextField(_ sender: UIButton) {
        loadCurrentURL()
        urlTextField.resignFirstResponder()
    }

    @IBAction func toggleWebView(_ sender: UIButton) {
        if self.webView != nil {
            tearDownWebView()
            toggleWebViewButton.setTitle("Create New Web View", for: .normal)
        } else {
            createAndAddWebView()
            loadCurrentURL()
            toggleWebViewButton.setTitle("Tear Down Web View", for: .normal)
        }
    }

    func loadCurrentURL() {
        if let text = urlTextField.text, let url = URL(string: text) {
            let request = URLRequest(url: url)
            webView?.load(request)
        } else {
            let request = URLRequest(url: defaultURL)
            webView?.load(request)
        }
    }

    @objc
    private func dismissKeyboard() {
        urlTextField.resignFirstResponder()
    }

    private func tearDownWebView() {
        self.webView?.removeFromSuperview()
        self.webView = nil

        removeWebViewData {
            print("WebView data removal complete")
        }
    }

    private func createAndAddWebView() {
        let configuration = WKWebViewConfiguration.persistent()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self

        webViewContainer.addSubview(webView)

        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.topAnchor.constraint(equalTo: webViewContainer.topAnchor).isActive = true
        webView.leadingAnchor.constraint(equalTo: webViewContainer.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: webViewContainer.trailingAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: webViewContainer.bottomAnchor).isActive = true

        self.webView = webView
    }

    private func removeWebViewData(completion: @escaping () -> Void) {
        HSTSCache.delete()

        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: Date.distantPast, completionHandler: completion)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
}

extension WKWebViewConfiguration {

    public static func persistent() -> WKWebViewConfiguration {
        return configuration(persistsData: true)
    }

    public static func nonPersistent() -> WKWebViewConfiguration {
        return configuration(persistsData: false)
    }

    private static func configuration(persistsData: Bool) -> WKWebViewConfiguration {
        let configuration = WKWebViewConfiguration()

        if !persistsData {
            configuration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        }

        return configuration
    }

}

public class HSTSCache {

     public static func delete() {
         if let hstsCache = FileManager.default.urls(for: .cachesDirectory, in: .allDomainsMask).first?
             .appendingPathComponent("com.apple.WebKit.Networking/HSTS.plist") {
             try? FileManager.default.removeItem(at: hstsCache)
         }
     }

 }

