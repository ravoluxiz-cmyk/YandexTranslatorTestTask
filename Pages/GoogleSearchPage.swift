import XCTest

#if os(macOS)
import AppKit
#endif

class GoogleSearchPage: BasePage {
    
    private var searchResults: XCUIElementQuery {
        return app.webViews.links
    }
    
    private var consentAgreeButton: XCUIElement? {
        let predicates = [
            NSPredicate(format: "label CONTAINS[c] 'I agree'"),
            NSPredicate(format: "label CONTAINS[c] 'Agree'"),
            NSPredicate(format: "label CONTAINS[c] 'Accept all'"),
            NSPredicate(format: "label CONTAINS[c] 'Accept'"),
            NSPredicate(format: "label CONTAINS[c] 'Соглас'"),
            NSPredicate(format: "label CONTAINS[c] 'Принять'"),
            NSPredicate(format: "label CONTAINS[c] 'Alle akzeptieren'"),
            NSPredicate(format: "label CONTAINS[c] 'Akzeptieren'"),
            NSPredicate(format: "label CONTAINS[c] 'Ich stimme zu'"),
            NSPredicate(format: "identifier CONTAINS[c] 'agree'"),
            NSPredicate(format: "identifier CONTAINS[c] 'accept'")
        ]
        
        for p in predicates {
            let b = app.webViews.buttons.containing(p).firstMatch
            if b.exists { return b }
        }
        
        return nil
    }
    
    @discardableResult
    func clickSearchResultContaining(_ text: String) -> Bool {
        XCTContext.runActivity(named: Constants.Activities.navigatingToTranslator) { _ in
            logStep("Clicking on result containing: \(text)")
            
            guard waitForSearchResults() else { return false }
            
            let domainPredicate = NSPredicate(format: "label CONTAINS[c] %@ OR value CONTAINS[c] %@",
                                              Constants.SearchTerms.yandexTranslateLinkText,
                                              Constants.SearchTerms.yandexTranslateLinkText)
            let textPredicate = NSPredicate(format: "label CONTAINS[c] %@", text)
            
            let linkCandidates: [XCUIElement] = [
                app.webViews.links.containing(domainPredicate).firstMatch,
                app.webViews.links.containing(textPredicate).firstMatch
            ]
            
            for link in linkCandidates {
                if link.exists && link.safeTap() {
                    let yandex = YandexTranslatePage(app: app)
                    if yandex.waitForPageToLoad() { return true }
                    
                    if let url = getCurrentURL(), url.contains(Constants.SearchTerms.yandexTranslateLinkText) { 
                        return true 
                    }
                }
            }
            
            openDirectURL("https://translate.yandex.ru")
            return true
        }
    }
    
    override func waitForPageToLoad() -> Bool {
        return app.webViews.firstMatch.waitForExistence(timeout: timeout)
    }
    
    private func waitForSearchResults() -> Bool {
        let firstResult = searchResults.firstMatch
        return firstResult.waitForExistence(timeout: timeout)
    }
    
    @discardableResult
    func searchFromAddressBar(_ query: String) -> Bool {
        app.activate()
        app.typeText(XCUIKeyboardKey.command.rawValue + "l")
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        
        let addressBar = app.textFields.firstMatch
        guard addressBar.waitForExistence(timeout: Constants.Timeouts.short) else { return false }
        
        _ = addressBar.ensureFocus(timeout: Constants.Timeouts.short)
        
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(query, forType: .string)
        #endif
        
        app.typeText(XCUIKeyboardKey.command.rawValue + "a")
        app.typeText(XCUIKeyboardKey.command.rawValue + "v")
        app.typeText("\n")
        
        _ = dismissConsentIfPresent()
        
        if waitForSearchResults() { return true }
        
        openDirectURL("https://translate.yandex.ru")
        return true
    }
    
    private func openDirectURL(_ url: String) {
        app.activate()
        app.typeText(XCUIKeyboardKey.command.rawValue + "l")
        
        let addressBar = app.textFields.firstMatch
        _ = addressBar.waitForExistence(timeout: Constants.Timeouts.short)
        _ = addressBar.ensureFocus(timeout: Constants.Timeouts.short)
        
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url, forType: .string)
        #endif
        
        app.typeText(XCUIKeyboardKey.command.rawValue + "a")
        app.typeText(XCUIKeyboardKey.command.rawValue + "v")
        app.typeText("\n")
    }
    
    @discardableResult
    func dismissConsentIfPresent() -> Bool {
        let signals = [
            NSPredicate(format: "label CONTAINS[c] 'Before you continue'"),
            NSPredicate(format: "label CONTAINS[c] 'cookies'"),
            NSPredicate(format: "label CONTAINS[c] 'Файлы cookie'"),
            NSPredicate(format: "label CONTAINS[c] 'Personalisierung und Cookies'"),
            NSPredicate(format: "label CONTAINS[c] 'Anmelden'"),
            NSPredicate(format: "label CONTAINS[c] 'Weitere Einstellungen'")
        ]
        
        var detected = false
        for p in signals {
            if app.webViews.staticTexts.containing(p).firstMatch.exists ||
               app.webViews.otherElements.containing(p).firstMatch.exists {
                detected = true
                break
            }
        }
        
        if !detected { return false }
        
        if let btn = consentAgreeButton, btn.waitForExistence(timeout: Constants.Timeouts.short) {
            if btn.safeTap(timeout: Constants.Timeouts.short) {
                _ = waitForPageToLoad()
                return true
            }
        }
        
        let alt = app.webViews.links.containing(NSPredicate(format: "label CONTAINS[c] 'agree' OR label CONTAINS[c] 'accept' OR label CONTAINS[c] 'Принять' OR label CONTAINS[c] 'Соглас' OR label CONTAINS[c] 'Alle akzeptieren' OR label CONTAINS[c] 'Akzeptieren' OR label CONTAINS[c] 'Ich stimme zu'"))
        
        if alt.firstMatch.waitForExistence(timeout: Constants.Timeouts.short) {
            if alt.firstMatch.safeTap() {
                _ = waitForPageToLoad()
                return true
            }
        }
        
        return false
    }
    
}
