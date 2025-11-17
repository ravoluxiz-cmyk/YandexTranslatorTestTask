import XCTest

class BaseTest: XCTestCase {
    
    var app: XCUIApplication!
    var testStartTime: Date!
    
    override func setUp() {
        super.setUp()
        
        continueAfterFailure = false
        testStartTime = Date()
        
        app = XCUIApplication(bundleIdentifier: Constants.URLs.safariURL)
        app.launchArguments = [
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        
        clearSafariState()
        
        XCTContext.runActivity(named: Constants.Activities.launchingSafari) { _ in
            app.launch()
            _ = app.wait(for: .runningForeground, timeout: Constants.Timeouts.extended)
        }
        
        if app.state != .runningForeground {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 2.0))
        }
        
        XCTAssertTrue(app.state == .runningForeground, Constants.ErrorMessages.safariNotLaunched)
        additionalSetup()
    }
    
    override func tearDown() {
        if let testRun = testRun, testRun.hasBeenSkipped || testRun.failureCount > 0 {
            takeFailureScreenshot()
        }
        
        if let startTime = testStartTime {
            let duration = Date().timeIntervalSince(startTime)
            XCTContext.runActivity(named: "Test Duration: \(String(format: "%.2f", duration)) seconds") { _ in }
        }
        
        additionalTeardown()
        app.terminate()
        super.tearDown()
    }
    
    func additionalSetup() {
    }
    
    func additionalTeardown() {
    }
    
    func takeFailureScreenshot() {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Failure_Screenshot_\(name)_\(Date().timeIntervalSince1970)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func takeScreenshot(name: String) {
        XCTContext.runActivity(named: "Screenshot: \(name)") { _ in
            let screenshot = XCUIScreen.main.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
    
    private func clearSafariState() {
        if app.state == .runningForeground {
            app.terminate()
        }
    }
    
    @discardableResult
    func waitFor(condition: () -> Bool,
                 timeout: TimeInterval = Constants.Timeouts.standard,
                 message: String = "Condition not met") -> Bool {
        let startTime = Date()
        let pollInterval: TimeInterval = 0.1
        
        while Date().timeIntervalSince(startTime) < timeout {
            if condition() {
                return true
            }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: pollInterval))
        }
        
        XCTFail(message)
        return false
    }
    
    @discardableResult
    func waitForPageStability(timeout: TimeInterval = Constants.Timeouts.standard) -> Bool {
        return waitFor(condition: {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
            return true
        }, timeout: timeout, message: "Page did not stabilize")
    }
    
    @discardableResult
    func waitForElementStability(_ element: XCUIElement,
                                  timeout: TimeInterval = Constants.Timeouts.standard) -> Bool {
        return element.waitForExistence(timeout: timeout) &&
               waitFor(condition: { element.isHittable }, timeout: timeout, message: "Element not hittable")
    }
    
    #if os(macOS)
    func waitForPasteboardChange(timeout: TimeInterval = Constants.Timeouts.short,
                                  operation: () -> Void) -> String? {
        let initialChangeCount = NSPasteboard.general.changeCount
        operation()
        
        let result = waitFor(condition: {
            NSPasteboard.general.changeCount > initialChangeCount
        }, timeout: timeout, message: "Pasteboard did not change")
        
        return result ? NSPasteboard.general.string(forType: .string) : nil
    }
    #endif
    
    func logStep(_ message: String) {
        XCTContext.runActivity(named: message) { _ in
        }
    }
    
    func testStep(_ description: String, closure: () throws -> Void) {
        XCTContext.runActivity(named: "Step: \(description)") { _ in
            if self.app == nil {
                self.app = XCUIApplication(bundleIdentifier: Constants.URLs.safariURL)
            }
            
            if self.app.state != .runningForeground {
                self.app.activate()
                self.app.launch()
                _ = self.app.wait(for: .runningForeground, timeout: Constants.Timeouts.extended)
            }
            
            do {
                try closure()
            } catch {
                XCTFail("Failed to perform step: \(description)")
            }
        }
    }
    
    func checkCondition(_ description: String,
                        _ condition: Bool,
                        file: StaticString = #file,
                        line: UInt = #line) {
        XCTContext.runActivity(named: "Checking that \(description)") { _ in
            XCTAssertTrue(condition,
                          "Check \"\(description)\" was unsuccessful",
                          file: file,
                          line: line)
        }
    }
    
    func verifyWithScreenshot(_ condition: Bool, message: String) {
        if !condition {
            takeFailureScreenshot()
            XCTFail(message)
        }
    }
    
    func googleSearchPage() -> GoogleSearchPage {
        return GoogleSearchPage(app: app)
    }
    
    func yandexTranslatePage() -> YandexTranslatePage {
        return YandexTranslatePage(app: app)
    }
    
    func openNewTab() {
        app.typeText(XCUIKeyboardKey.command.rawValue + "t")
        waitFor(condition: { self.app.textFields.firstMatch.exists },
                timeout: Constants.Timeouts.short,
                message: "New tab did not open")
    }
    
    func closeCurrentTab() {
        app.typeText(XCUIKeyboardKey.command.rawValue + "w")
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
    }
    
    func navigateToURL(_ url: String) {
        logStep("Navigating to: \(url)")
        
        app.activate()
        app.typeText(XCUIKeyboardKey.command.rawValue + "l")
        
        let addressBar = app.textFields.firstMatch
        _ = addressBar.waitForExistence(timeout: Constants.Timeouts.short)
        
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(url, forType: .string)
        #endif
        
        _ = addressBar.ensureFocus(timeout: Constants.Timeouts.short)
        app.typeText(XCUIKeyboardKey.command.rawValue + "a")
        app.typeText(XCUIKeyboardKey.command.rawValue + "v")
        app.typeText("\n")
    }
    
    func getCurrentURL() -> String? {
        let addressBar = app.textFields.firstMatch
        if addressBar.exists {
            return addressBar.value as? String
        }
        return nil
    }
    
    func assertExists(_ element: XCUIElement, message: String? = nil) {
        let errorMessage = message ?? "Element does not exist: \(element.description)"
        XCTAssertTrue(element.exists, errorMessage)
    }
    
    func assertContainsText(_ element: XCUIElement, text: String, message: String? = nil) {
        let errorMessage = message ?? "Element does not contain text: \(text)"
        let elementText = (element.label + (element.value as? String ?? "")).lowercased()
        XCTAssertTrue(elementText.contains(text.lowercased()), errorMessage)
    }
    
}
