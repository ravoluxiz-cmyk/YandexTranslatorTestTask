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
    
    @discardableResult
    func waitForPageToLoad() -> Bool {
        return true
    }
    
    func getCurrentURL() -> String? {
        let addressBar = app.comboBoxes.firstMatch.exists ? app.comboBoxes.firstMatch : app.textFields.firstMatch
        
        if addressBar.exists {
            if let urlValue = addressBar.value as? String {
                return urlValue
            }
            
            addressBar.tap()
            addressBar.press(forDuration: 0.5)
            
            let selectAllButton = app.menuItems["Select All"]
            if selectAllButton.waitForExistence(timeout: Constants.Timeouts.short) {
                selectAllButton.tap()
                
                let copyButton = app.menuItems["Copy"]
                if copyButton.waitForExistence(timeout: Constants.Timeouts.short) {
                    copyButton.tap()
                    
                    #if os(iOS)
                    return UIPasteboard.general.string
                    #else
                    return NSPasteboard.general.string(forType: .string)
                    #endif
                }
            }
            
            addressBar.tap()
            app.typeText(XCUIKeyboardKey.command.rawValue + "l")
            _ = addressBar.waitForExistence(timeout: Constants.Timeouts.short)
            
            #if os(macOS)
            let initialChangeCount = NSPasteboard.general.changeCount
            app.typeText(XCUIKeyboardKey.command.rawValue + "l")
            app.typeText(XCUIKeyboardKey.command.rawValue + "c")
            
            let startTime = Date()
            while Date().timeIntervalSince(startTime) < 1.0 {
                if NSPasteboard.general.changeCount > initialChangeCount {
                    return NSPasteboard.general.string(forType: .string)
                }
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
            }
            return NSPasteboard.general.string(forType: .string)
            #else
            app.typeText(XCUIKeyboardKey.command.rawValue + "l")
            app.typeText(XCUIKeyboardKey.command.rawValue + "c")
            
            let startTime = Date()
            while Date().timeIntervalSince(startTime) < 1.0 {
                if let content = UIPasteboard.general.string, !content.isEmpty {
                    return content
                }
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
            }
            return UIPasteboard.general.string
            #endif
        }
        
        return nil
    }
    
    func logStep(_ message: String) {
        XCTContext.runActivity(named: message) { _ in
        }
    }
    
}
