import Foundation

enum Constants {
    
    enum URLs {
        static let googleSearch = "https://www.google.com"
        static let safariURL = "com.apple.Safari"
        static let yandexTranslateHost = "translate.yandex.ru"
    }
    
    enum SearchTerms {
        static let translatorQuery = "Переводчик"
        static let yandexTranslatorText = "Яндекс Переводчик"
        static let yandexTranslateLinkText = "translate.yandex"
    }
    
    enum Identifiers {
        static let googleSearchField = "Search"
        static let safariAddressBar = "Address"
        static let safariURLField = "URL"
        static let searchButton = "Google Search"
    }
    
    enum Timeouts {
        static let standard: TimeInterval = 10
        static let extended: TimeInterval = 20
        static let short: TimeInterval = 5
    }
    
    enum ErrorMessages {
        static let elementNotFound = "Element not found within timeout"
        static let urlValidationFailed = "URL validation failed"
        static let safariNotLaunched = "Safari browser could not be launched"
        static let searchFailed = "Search operation failed"
    }
    
    enum Activities {
        static let launchingSafari = "Launching Safari browser"
        static let performingSearch = "Performing Google search"
        static let navigatingToTranslator = "Navigating to Yandex Translator"
        static let verifyingURL = "Verifying URL contains expected host"
        static let copyingURL = "Copying URL from address bar"
    }
    
}
