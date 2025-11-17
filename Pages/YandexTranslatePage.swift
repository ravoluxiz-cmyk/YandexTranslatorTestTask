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
    
    private var addressBar: XCUIElement {
        if app.comboBoxes.firstMatch.exists {
            return app.comboBoxes.firstMatch
        } else if app.textFields["Address"].exists {
            return app.textFields["Address"]
        } else if app.textFields["URL"].exists {
            return app.textFields["URL"]
        } else if app.textFields.containing(NSPredicate(format: "value CONTAINS[c] 'yandex'"))
                    .firstMatch.exists {
            return app.textFields.containing(NSPredicate(format: "value CONTAINS[c] 'yandex'"))
                      .firstMatch
        } else {
            return app.textFields.firstMatch
        }
    }
    
    func getURLFromAddressBar() -> String? {
        guard addressBar.waitForExistence(timeout: timeout) else { return nil }
        
        if let direct = addressBar.value as? String, !direct.isEmpty { return direct }
        
        #if os(macOS)
        let initial = NSPasteboard.general.changeCount
        app.typeText(XCUIKeyboardKey.command.rawValue + "l")
        app.typeText(XCUIKeyboardKey.command.rawValue + "c")
        
        let start = Date()
        while Date().timeIntervalSince(start) < 1.0 {
            if NSPasteboard.general.changeCount > initial {
                if let s = NSPasteboard.general.string(forType: .string), s.contains("://") { return s }
            }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        }
        
        if let s = NSPasteboard.general.string(forType: .string), s.contains("://") { return s }
        #else
        app.typeText(XCUIKeyboardKey.command.rawValue + "l")
        app.typeText(XCUIKeyboardKey.command.rawValue + "c")
        
        let start = Date()
        while Date().timeIntervalSince(start) < 1.0 {
            if let s = UIPasteboard.general.string, s.contains("://") { return s }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        }
        
        if let s = UIPasteboard.general.string, s.contains("://") { return s }
        #endif
        
        let label = addressBar.label
        if !label.isEmpty && label.contains("://") { return label }
        
        return nil
    }
    
    @discardableResult
    func quickVerifyTranslateHost(timeout: TimeInterval = Constants.Timeouts.short) -> Bool {
        _ = app.webViews.firstMatch.waitForExistence(timeout: timeout)
        
        #if os(macOS)
        let initial = NSPasteboard.general.changeCount
        app.typeText(XCUIKeyboardKey.command.rawValue + "l")
        app.typeText(XCUIKeyboardKey.command.rawValue + "c")
        
        let start = Date()
        while Date().timeIntervalSince(start) < 1.0 {
            if NSPasteboard.general.changeCount > initial,
               let s = NSPasteboard.general.string(forType: .string) {
                let ok = s.contains(Constants.URLs.yandexTranslateHost) ||
                         s.contains(Constants.SearchTerms.yandexTranslateLinkText)
                if ok { return true }
            }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        }
        
        if let s = NSPasteboard.general.string(forType: .string) {
            if s.contains(Constants.URLs.yandexTranslateHost) || s.contains(Constants.SearchTerms.yandexTranslateLinkText) { 
                return true 
            }
        }
        #else
        app.typeText(XCUIKeyboardKey.command.rawValue + "l")
        app.typeText(XCUIKeyboardKey.command.rawValue + "c")
        
        let start = Date()
        while Date().timeIntervalSince(start) < 1.0 {
            if let s = UIPasteboard.general.string {
                let ok = s.contains(Constants.URLs.yandexTranslateHost) ||
                         s.contains(Constants.SearchTerms.yandexTranslateLinkText)
                if ok { return true }
            }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        }
        
        if let s = UIPasteboard.general.string {
            if s.contains(Constants.URLs.yandexTranslateHost) || s.contains(Constants.SearchTerms.yandexTranslateLinkText) { 
                return true 
            }
        }
        #endif
        
        let title = app.windows.firstMatch.label.lowercased()
        return title.contains("yandex") || title.contains("translate")
    }
    
    override func waitForPageToLoad() -> Bool {
        let start = Date()
        let maxWait: TimeInterval = 5
        let interval: TimeInterval = 0.2
        
        while Date().timeIntervalSince(start) < maxWait {
            if self.app.webViews.firstMatch.exists { return true }
            
            let w = self.app.windows.firstMatch
            if w.exists {
                let t = w.title.lowercased()
                if t.contains("yandex") || t.contains("translate") { return true }
            }
            
            RunLoop.current.run(until: Date(timeIntervalSinceNow: interval))
        }
        
        return self.app.webViews.firstMatch.exists
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
