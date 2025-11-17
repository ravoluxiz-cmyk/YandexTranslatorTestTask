## Инструкция по запуску

### Клонирование репозитория

```bash
git clone https://github.com/ВАШ_ЮЗЕРНЕЙМ/YandexTranslateUITests.git
cd YandexTranslateUITests
```

Или скачайте ZIP-архив с GitHub и распакуйте в удобное место.

### Предварительные требования
- macOS 13.0 или выше
- Xcode 13+ установлен
- Safari браузер

### Запуск через терминал

1. Откройте Terminal
2. Перейдите в папку с проектом (замените `/путь/до/папки` на ваш путь):

```bash
cd /путь/до/папки/YandexTranslateUITests
```

3. Запустите тесты:

```bash
xcodebuild test -scheme YandexTranslateUITests -destination 'platform=macOS'
```

### Запуск через Xcode

1. Откройте Terminal
2. Перейдите в папку с проектом (замените `/путь/до/папки` на ваш путь):

```bash
cd /путь/до/папки/YandexTranslateUITests
```

3. Откройте проект в Xcode:

```bash
open YandexTranslateUITests.xcodeproj
```

4. В Xcode нажмите `Cmd+U` для запуска тестов 
```