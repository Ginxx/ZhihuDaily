//
//  NewsDetailViewController.swift
//  ZhihuDaily
//
//  Created by 高 on 2018/1/22.
//  Copyright © 2018年 gaoX. All rights reserved.
//

import UIKit
import WebKit

class NewsDetailViewController: BaseViewController, Routable {

    var newsID = ""
    
    lazy var webView: WKWebView = {
        let webView = WKWebView(frame: view.bounds)
        webView.navigationDelegate = self
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.delegate = self
        return webView
    }()
    
    lazy var headerView: UIImageView = {
        let headerView = UIImageView(frame: CGRect(x: 0, y: 0, width: UIScreen.width, height: 200))
        headerView.backgroundColor = UIColor.global
        return headerView
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white
        label.font = UIFont.systemFont(ofSize: 18)
        label.numberOfLines = 2
        return label
    }()
    
    lazy var statusBarBackView: UIView = {
        let backView = UIView()
        backView.backgroundColor = UIColor.white
        backView.isHidden = true
        return backView
    }()
    
    var statusBarStyle: UIStatusBarStyle = .lightContent
    
    
    static func initializeRoute(parameters: [String : Any]?) -> Routable {
        return NewsDetailViewController()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        addSubviews()
        requestNewsDetail()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - private
    private func addSubviews() {
        disableAdjustsScrollViewInsets(webView.scrollView)
        view.addSubview(webView)
        webView.scrollView.addSubview(headerView)
        headerView.addSubview(titleLabel)
        view.addSubview(statusBarBackView)
        
        titleLabel.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-20)
            make.centerX.equalToSuperview()
            make.width.equalTo(UIScreen.width - 30)
        }
        
        statusBarBackView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(UIApplication.shared.statusBarFrame.height)
        }
    }
    
    private func requestNewsDetail() {
        HomeComponent().requestNewsDetail(newsID: newsID, success: { (model) in
            model?.image.flatMap({
                self.headerView.kf.setImage(with: URL(string: $0))
            })
            model?.title.flatMap({
                self.titleLabel.text = $0
            })
            if let body = model?.body {
                var html = """
                    <!DOCTYPE html>
                    <html>
                    <head>
                      <meta charset="utf-8">
                      <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
                      <link rel="stylesheet" type="text/css" href="\(model?.css?.first ?? "")">
                    </head>
                    <body>
                    </body>
                    </html>
                """
                html = html.replacingOccurrences(of: "</body>", with: "\(body)</body>")
                self.webView.loadHTMLString(html, baseURL: nil)
            }
        }) { (error) in
            
        }
    }
}

// MARK: - WKNavigationDelegate
extension NewsDetailViewController: WKNavigationDelegate {
    
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        webView.reload()
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let url = navigationAction.request.url?.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        if url == "about:blank" {
            decisionHandler(.allow)
        }
        else {
            push(WebViewController.self, parameters: ["url": url ?? ""], animated: true, configuration: nil)
            decisionHandler(.cancel)
        }
    }
}

extension NewsDetailViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y < 0 {
            if scrollView.contentOffset.y > -60 {
                var frame = headerView.frame
                frame.origin.y = scrollView.contentOffset.y
                frame.size.height = 200 - scrollView.contentOffset.y
                headerView.frame = frame
            }
            else {
                headerView.frame = CGRect(x: 0, y: -60, width: UIScreen.width, height: 260)
                scrollView.contentOffset = CGPoint(x: 0, y: -60)
            }
        }
        statusBarBackView.isHidden = scrollView.contentOffset.y < 180
        statusBarStyle = scrollView.contentOffset.y < 180 ? .lightContent : .default
        setNeedsStatusBarAppearanceUpdate()
    }
}