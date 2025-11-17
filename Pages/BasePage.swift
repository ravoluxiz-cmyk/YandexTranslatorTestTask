import XCTest

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

class BasePage {
    
    let app: XCUIApplication
    let timeout: TimeInterval
    
    init(app: XCUIApplication = XCUIApplication(),
         timeout: TimeInterval = Constants.Timeouts.standard) {
        self.app = app
        self.timeout = timeout
    }
    
    private var addressBar: XCUIElement {
        app.comboBoxes.firstMatch.exists ? app.comboBoxes.firstMatch : app.textFields.firstMatch
    }
    
    func copyURLFromAddressBar() -> String? {
        addressBar.tap()
        app.typeText("lc")
        waitForPasteboardChange()
        return pasteboardString()
    }

    private func waitForPasteboardChange() {
        #if os(macOS)
        let initial = NSPasteboard.general.changeCount
        while Date().timeIntervalSince(Date()) < 1,
              NSPasteboard.general.changeCount == initial {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        }
        #else
        while Date().timeIntervalSince(Date()) < 1,
              UIPasteboard.general.string?.isEmpty != false {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
        #endif
    }
    
    private func pasteboardString() -> String? {
        #if os(iOS)
        return UIPasteboard.general.string
        #else
        return NSPasteboard.general.string(forType: .string)
        #endif
    }
    
    @discardableResult
    func waitForPageToLoad() -> Bool {
        return true
    }
    
    func getCurrentURL() -> String? {
        guard addressBar.exists else { return nil }
        
        if let urlValue = addressBar.value as? String {
            return urlValue
        }
        
        return copyURLFromAddressBar()
    }
    
    func logStep(_ message: String) {
        XCTContext.runActivity(named: message) { _ in
        }
    }
    
}
