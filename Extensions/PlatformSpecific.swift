import XCTest

#if os(iOS)
import UIKit

extension XCUIElement {
    
    func copyURLiOS() -> String? {
        UIPasteboard.general.string = ""
        typeText(XCUIKeyboardKey.command.rawValue + "a")
        typeText(XCUIKeyboardKey.command.rawValue + "c")
        
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < 1.0 {
            if let content = UIPasteboard.general.string, !content.isEmpty {
                return content
            }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        }
        
        return UIPasteboard.general.string
    }
    
    func clearTextIOS() {
        guard let stringValue = value as? String, !stringValue.isEmpty else { return }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue,
                                 count: stringValue.count)
        typeText(deleteString)
    }
    
}

class SafariiOSPage: BasePage {
    
    private var urlBar: XCUIElement {
        if app.buttons["URL"].exists {
            return app.buttons["URL"]
        } else if app.textFields["URL"].exists {
            return app.textFields["URL"]
        } else if app.otherElements["URL"].exists {
            return app.otherElements["URL"]
        } else {
            return app.otherElements["TabBarItemTitle"].firstMatch
        }
    }
    
    func navigateToURLiOS(_ urlString: String) {
        urlBar.tap()
        _ = app.keyboards.firstMatch.waitForExistence(timeout: Constants.Timeouts.short)
        
        if let textField = app.textFields["URL"].exists ? app.textFields["URL"] : app.textFields.firstMatch {
            textField.tap()
            textField.clearTextIOS()
            textField.typeText(urlString)
            app.buttons["Go"].tap()
        }
    }
    
    func getURLiOS() -> String? {
        if urlBar.exists {
            urlBar.tap()
            let textField = app.textFields["URL"].exists ? app.textFields["URL"] : app.textFields.firstMatch
            if textField.waitForExistence(timeout: Constants.Timeouts.short) {
                return textField.value as? String
            }
        }
        return nil
    }
    
}

#endif

#if os(macOS)
import AppKit

extension XCUIElement {
    
    func copyURLMac() -> String? {
        NSPasteboard.general.clearContents()
        let initialChangeCount = NSPasteboard.general.changeCount
        
        typeText(XCUIKeyboardKey.command.rawValue + "a")
        typeText(XCUIKeyboardKey.command.rawValue + "c")
        
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < 1.0 {
            if NSPasteboard.general.changeCount > initialChangeCount {
                return NSPasteboard.general.string(forType: .string)
            }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        }
        
        return NSPasteboard.general.string(forType: .string)
    }
    
    func clearTextMac() {
        XCUIApplication().typeText(XCUIKeyboardKey.command.rawValue + "a")
        XCUIApplication().typeText(XCUIKeyboardKey.delete.rawValue)
    }
    
}

class SafariMacPage: BasePage {
    
    private var addressBar: XCUIElement {
        if app.textFields["Address"].exists {
            return app.textFields["Address"]
        } else if app.comboBoxes.firstMatch.exists {
            return app.comboBoxes.firstMatch
        } else {
            return app.textFields.firstMatch
        }
    }
    
    func navigateToURLMac(_ urlString: String) {
        app.typeText(XCUIKeyboardKey.command.rawValue + "l")
        let addressBar = app.textFields.firstMatch
        _ = addressBar.waitForExistence(timeout: Constants.Timeouts.short)
        
        app.typeText(XCUIKeyboardKey.command.rawValue + "a")
        app.typeText(urlString)
        app.typeText("\n")
    }
    
    func getURLMac() -> String? {
        app.typeText(XCUIKeyboardKey.command.rawValue + "l")
        let addressBar = app.textFields.firstMatch
        _ = addressBar.waitForExistence(timeout: Constants.Timeouts.short)
        
        let initialChangeCount = NSPasteboard.general.changeCount
        app.typeText(XCUIKeyboardKey.command.rawValue + "a")
        app.typeText(XCUIKeyboardKey.command.rawValue + "c")
        
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < 1.0 {
            if NSPasteboard.general.changeCount > initialChangeCount {
                return NSPasteboard.general.string(forType: .string)
            }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        }
        
        return NSPasteboard.general.string(forType: .string)
    }
    
}

extension BasePage {
    
    func getPasteboardString() -> String? {
        return NSPasteboard.general.string(forType: .string)
    }
    
    func setPasteboardString(_ string: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
    }
    
}

#endif

class PlatformHelper {
    
    static var isiOS: Bool {
        #if os(iOS)
        return true
        #else
        return false
        #endif
    }
    
    static var isMac: Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
    
    static func copyURL(from element: XCUIElement) -> String? {
        #if os(iOS)
        return element.copyURLiOS()
        #elseif os(macOS)
        return element.copyURLMac()
        #else
        return nil
        #endif
    }
    
    static func clearText(in element: XCUIElement) {
        #if os(iOS)
        element.clearTextIOS()
        #elseif os(macOS)
        element.clearTextMac()
        #endif
    }
    
}

extension BaseTest {
    
    func configurePlatformSpecific() {
        if PlatformHelper.isiOS {
            app = XCUIApplication()
            app.launchArguments += ["-UITestingEnabled", "YES"]
        } else if PlatformHelper.isMac {
            app = XCUIApplication(bundleIdentifier: "com.apple.Safari")
            app.launchEnvironment = ["XCTEST": "1"]
        }
    }
    
    func safariPage() -> BasePage {
        #if os(iOS)
        return SafariiOSPage(app: app)
        #elseif os(macOS)
        return SafariMacPage(app: app)
        #else
        return BasePage(app: app)
        #endif
    }
    
}
