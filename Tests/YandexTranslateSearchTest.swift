import XCTest

final class YandexTranslateSearchTest: BaseTest {
    
    private lazy var googlePage = GoogleSearchPage(app: app)
    private lazy var yandexPage = YandexTranslatePage(app: app)
    
    func testSearchTranslatorAndVerifyYandexURL() throws {
        
        testStep("Safari browser launched") {
            checkCondition("Safari is running in foreground", app.state == .runningForeground)
            takeScreenshot(name: "Safari_Launched")
        }
        
        testStep("Search 'Переводчик' via Safari address bar") {
            checkCondition("Search initiated",
                          googlePage.searchFromAddressBar(Constants.SearchTerms.translatorQuery))
            
            _ = waitFor(condition: { self.app.webViews.links.count > 0 },
                       timeout: Constants.Timeouts.standard,
                       message: "Search results not loaded")
            
            takeScreenshot(name: "Search_Query_Entered")
        }
        
        testStep("Navigate to Yandex Translator from search results") {
            let clicked = googlePage.clickSearchResultContaining(Constants.SearchTerms.yandexTranslatorText)
            
            if !clicked {
                logStep("Trying alternative search for Yandex link")
                checkCondition("Yandex Translator link found and clicked",
                              googlePage.clickSearchResultContaining(Constants.SearchTerms.yandexTranslateLinkText))
            }
            
            checkCondition("Yandex Translate page loaded", yandexPage.waitForPageToLoad())
            takeScreenshot(name: "Google_Search_Results")
        }
        
        testStep("Quick verify Yandex URL") {
            let ok = yandexPage.quickVerifyTranslateHost()
            checkCondition("URL contains translate.yandex.*", ok)
            takeScreenshot(name: "Yandex_Translate_Loaded")
            takeScreenshot(name: "Verification_Complete")
        }
        
    }
    
}