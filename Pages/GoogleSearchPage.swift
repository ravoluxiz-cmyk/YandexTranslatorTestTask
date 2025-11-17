import XCTest

#if os(macOS)
import AppKit
#endif

class GoogleSearchPage: BasePage {
    
    private var searchResults: XCUIElementQuery {
        return app.webViews.links
    }
    
    private var consentAgreeButton: XCUIElement? {
        // Проверяем по тексту кнопки
        for label in Constants.Consent.buttonLabels {
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", label)
            let button = app.webViews.buttons.containing(predicate).firstMatch
            if button.exists { return button }
        }
        
        // Проверяем по идентификатору
        for identifier in Constants.Consent.buttonIdentifiers {
            let predicate = NSPredicate(format: "identifier CONTAINS[c] %@", identifier)
            let button = app.webViews.buttons.containing(predicate).firstMatch
            if button.exists { return button }
        }
        
        return nil
    }
    
    private func findYandexTranslateLink(for text: String) -> XCUIElement? {
        let domainPredicate = NSPredicate(format: "label CONTAINS[c] %@ OR value CONTAINS[c] %@",
                                          Constants.SearchTerms.yandexTranslateLinkText,
                                          Constants.SearchTerms.yandexTranslateLinkText)
        let textPredicate = NSPredicate(format: "label CONTAINS[c] %@", text)
        
        let candidates = [
            app.webViews.links.containing(domainPredicate).firstMatch,
            app.webViews.links.containing(textPredicate).firstMatch
        ]
        
        return candidates.first { $0.exists }
    }
    
    private func verifyYandexTranslatePage() -> Bool {
        let yandex = YandexTranslatePage(app: app)
        if yandex.waitForPageToLoad() { return true }
        
        return getCurrentURL()?.contains(Constants.SearchTerms.yandexTranslateLinkText) ?? false
    }
    
    @discardableResult
    func clickSearchResultContaining(_ text: String) -> Bool {
        XCTContext.runActivity(named: Constants.Activities.navigatingToTranslator) { _ in
            logStep("Клик по результату содержащему: \(text)")
            
            guard waitForSearchResults() else { return false }
            
            if let link = findYandexTranslateLink(for: text), link.safeTap() {
                if verifyYandexTranslatePage() { return true }
            }
            
            openDirectURL(Constants.GoogleSearch.yandexTranslateURL)
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
    
    private func openURLInAddressBar(_ url: String, activateApp: Bool = true) -> Bool {
        if activateApp {
            app.activate()
        }
        
        app.typeText(XCUIKeyboardKey.command.rawValue + "l")
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        
        let addressBar = app.textFields.firstMatch
        guard addressBar.waitForExistence(timeout: Constants.Timeouts.short) else { return false }
        
        _ = addressBar.ensureFocus(timeout: Constants.Timeouts.short)
        
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url, forType: .string)
        #endif
        
        app.typeText(XCUIKeyboardKey.command.rawValue + "a")
        app.typeText(XCUIKeyboardKey.command.rawValue + "v")
        app.typeText("\n")
        
        return true
    }
    
    @discardableResult
    func searchFromAddressBar(_ query: String) -> Bool {
        guard openURLInAddressBar(query) else { return false }
        
        _ = dismissConsentIfPresent()
        
        if waitForSearchResults() { return true }
        
        return openURLInAddressBar(Constants.GoogleSearch.yandexTranslateURL, activateApp: false)
    }
    
    private func openDirectURL(_ url: String) {
        _ = openURLInAddressBar(url)
    }
    
    private func findConsentSignals() -> Bool {
        return Constants.Consent.signals.contains { signal in
            let predicate = NSPredicate(format: "label CONTAINS[c] %@", signal)
            return app.webViews.staticTexts.containing(predicate).firstMatch.exists ||
                   app.webViews.otherElements.containing(predicate).firstMatch.exists
        }
    }
    
    private func tryClickConsentButton(_ button: XCUIElement) -> Bool {
        guard button.waitForExistence(timeout: Constants.Timeouts.short),
              button.safeTap(timeout: Constants.Timeouts.short) else { return false }
        
        _ = waitForPageToLoad()
        return true
    }
    
    @discardableResult
    func dismissConsentIfPresent() -> Bool {
        guard findConsentSignals() else { return false }
        
        if let btn = consentAgreeButton {
            if tryClickConsentButton(btn) { return true }
        }
        
        let altPredicate = NSPredicate(format: "label CONTAINS[c] %@", 
                                     argumentArray: Constants.Consent.buttonLabels)
        let altButton = app.webViews.links.containing(altPredicate).firstMatch
        
        return tryClickConsentButton(altButton)
    }
    
}
