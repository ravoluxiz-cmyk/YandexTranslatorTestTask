import XCTest

final class YandexTranslateSearchTest: BaseTest {
    
    private lazy var googlePage = GoogleSearchPage(app: app)
    private lazy var yandexPage = YandexTranslatePage(app: app)
    
    func testSearchTranslatorAndVerifyYandexURL() throws {
        
        testStep("Браузер Safari запущен") {
            checkCondition("Safari работает в активном состоянии", app.state == .runningForeground)
            logStep("Safari успешно запущен")
        }
        
        testStep("Поиск 'Переводчик' через адресную строку Safari") {
            checkCondition("Поиск начат",
                          googlePage.searchFromAddressBar(Constants.SearchTerms.translatorQuery))
            
            _ = waitFor(condition: { self.app.webViews.links.count > 0 },
                       timeout: Constants.Timeouts.standard,
                       message: "Результаты поиска не загрузились")
            
            logStep("Результаты поиска успешно загружены")
        }
        
        testStep("Переход к Яндекс Переводчику из результатов поиска") {
            let clicked = googlePage.clickSearchResultContaining(Constants.SearchTerms.yandexTranslatorText)
            
            if !clicked {
                logStep("Попытка альтернативного поиска ссылки Яндекс")
                checkCondition("Ссылка на Яндекс Переводчик найдена и нажата",
                              googlePage.clickSearchResultContaining(Constants.SearchTerms.yandexTranslateLinkText))
            }
            
            checkCondition("Страница Яндекс Перевода загружена", yandexPage.waitForPageToLoad())
            logStep("Успешно перешли к Яндекс Переводу")
        }
        
        testStep("Быстрая проверка URL Яндекс") {
            let ok = yandexPage.quickVerifyTranslateHost()
            checkCondition("URL содержит translate.yandex.*", ok)
            logStep("Проверка URL Яндекс успешно завершена")
        }
        
    }
    
}