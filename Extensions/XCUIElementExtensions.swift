import XCTest

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

extension XCUIElement {
    
    @discardableResult
    func safeTap(timeout: TimeInterval = Constants.Timeouts.standard) -> Bool {
        guard waitForExistence(timeout: timeout) else {
            XCTContext.runActivity(named: "Failed to tap element") { _ in
                XCTFail("\(Constants.ErrorMessages.elementNotFound): \(self.description)")
            }
            return false
        }
        
        if isHittable {
            tap()
            return true
        } else {
            return scrollToElementAndTap()
        }
    }
    
    @discardableResult
    func safeTypeText(_ text: String,
                      clearFirst: Bool = true,
                      timeout: TimeInterval = Constants.Timeouts.standard) -> Bool {
        guard waitForExistence(timeout: timeout) else {
            XCTContext.runActivity(named: "Failed to type text") { _ in
                XCTFail("\(Constants.ErrorMessages.elementNotFound): \(self.description)")
            }
            return false
        }
        
        if !ensureFocus(timeout: timeout) {
            return false
        }
        
        if clearFirst {
            clearText()
        }
        
        typeText(text)
        return true
    }
    
    func clearText() {
        guard let stringValue = value as? String, !stringValue.isEmpty else { return }
        typeText(XCUIKeyboardKey.command.rawValue + "a")
        typeText(XCUIKeyboardKey.delete.rawValue)
    }
    
    func waitForValue(_ value: String, timeout: TimeInterval = Constants.Timeouts.standard) -> Bool {
        let predicate = NSPredicate(format: "value == %@", value)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
    
    func waitForTextContains(_ text: String, timeout: TimeInterval = Constants.Timeouts.standard) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@ OR value CONTAINS[c] %@", text, text)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter.wait(for: [expectation], timeout: timeout) == .completed
    }
    
    var isReady: Bool {
        return exists && isHittable
    }
    
    var isFocused: Bool {
        #if os(iOS)
        return exists && isHittable && XCUIApplication().keyboards.firstMatch.exists
        #elseif os(macOS)
        return exists && isHittable
        #else
        return exists
        #endif
    }
    
    @discardableResult
    func ensureFocus(timeout: TimeInterval = Constants.Timeouts.standard) -> Bool {
        if isFocused {
            return true
        }
        
        if isHittable {
            tap()
        } else {
            _ = scrollToElementAndTap()
        }
        
        #if os(iOS)
        return XCUIApplication().keyboards.firstMatch.waitForExistence(timeout: timeout)
        #elseif os(macOS)
        return true
        #else
        return true
        #endif
    }
    
    private func scrollToElementAndTap() -> Bool {
        let app = XCUIApplication()
        var attempts = 0
        let maxAttempts = 5
        
        while !isHittable && attempts < maxAttempts {
            app.swipeUp()
            attempts += 1
        }
        
        if isHittable {
            tap()
            return true
        }
        
        return false
    }
    
    func forceTap() {
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
    
    func copyText() -> String? {
        guard exists else { return nil }
        
        press(forDuration: 1.0)
        
        let copyButton = XCUIApplication().menuItems["Copy"]
        if copyButton.waitForExistence(timeout: Constants.Timeouts.short) {
            copyButton.tap()
        } else {
            let selectAllButton = XCUIApplication().menuItems["Select All"]
            if selectAllButton.waitForExistence(timeout: Constants.Timeouts.short) {
                selectAllButton.tap()
                if copyButton.waitForExistence(timeout: Constants.Timeouts.short) {
                    copyButton.tap()
                }
            }
        }
        
        #if os(iOS)
        return UIPasteboard.general.string
        #else
        return NSPasteboard.general.string(forType: .string)
        #endif
    }
    
}

extension XCUIElementQuery {
    
    func firstMatch(predicate: NSPredicate,
                   timeout: TimeInterval = Constants.Timeouts.standard) -> XCUIElement? {
        let element = matching(predicate).firstMatch
        return element.waitForExistence(timeout: timeout) ? element : nil
    }
    
    func elementContainingText(_ text: String,
                              timeout: TimeInterval = Constants.Timeouts.standard) -> XCUIElement? {
        let predicate = NSPredicate(format: "label CONTAINS[c] %@ OR value CONTAINS[c] %@ OR title CONTAINS[c] %@", 
                                   text, text, text)
        return firstMatch(predicate: predicate, timeout: timeout)
    }
    
}
