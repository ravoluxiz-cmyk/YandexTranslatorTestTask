import XCTest

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

class YandexTranslatePage: BasePage {
    
    private var translateInput: XCUIElement {
        if app.webViews.textViews.firstMatch.exists {
            return app.webViews.textViews.firstMatch
        } else if app.textViews.firstMatch.exists {
            return app.textViews.firstMatch
        } else {
            return app.webViews.otherElements.containing(
                NSPredicate(format: "identifier CONTAINS[c] 'input' OR identifier CONTAINS[c] 'source'")
            ).firstMatch
        }
    }
    
    func getURLFromAddressBar() -> String? {
        guard let url = super.getCurrentURL(), url.contains("://") else { return nil }
        return url
    }
    
    private func containsYandexTranslate(_ url: String) -> Bool {
        url.contains(Constants.URLs.yandexTranslateHost) || 
        url.contains(Constants.SearchTerms.yandexTranslateLinkText)
    }
    
    @discardableResult
    func quickVerifyTranslateHost(timeout: TimeInterval = Constants.Timeouts.short) -> Bool {
        _ = app.webViews.firstMatch.waitForExistence(timeout: timeout)
        
        if let url = getURLFromAddressBar(), containsYandexTranslate(url) {
            return true
        }
        
        let title = app.windows.firstMatch.label.lowercased()
        return title.contains("yandex") || title.contains("translate")
    }
    
    override func waitForPageToLoad() -> Bool {
        let start = Date()
        let maxWait: TimeInterval = 5
        let interval: TimeInterval = 0.2
        
        while Date().timeIntervalSince(start) < maxWait {
            if app.webViews.firstMatch.exists { return true }
            
            let window = app.windows.firstMatch
            guard window.exists else {
                RunLoop.current.run(until: Date(timeIntervalSinceNow: interval))
                continue
            }
            
            let title = window.title.lowercased()
            if title.contains("yandex") || title.contains("translate") {
                return true
            }
            
            RunLoop.current.run(until: Date(timeIntervalSinceNow: interval))
        }
        
        return app.webViews.firstMatch.exists
    }
    
    func isOnYandexTranslate() -> Bool {
        if let url = getURLFromAddressBar() {
            if url.contains(Constants.URLs.yandexTranslateHost) {
                return true
            }
        }
        
        let windows = app.windows.firstMatch
        if windows.exists && windows.title.lowercased().contains("translate") {
            return true
        }
        
        return translateInput.exists || app.webViews.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] 'translate' OR label CONTAINS[c] 'перевод'")
        ).count > 0
    }
    
}
