# MacPortScanner - Быстрый старт

## 🚀 Для пользователей

### Установка
1. Скачайте DMG файл с [GitHub Releases](https://github.com/iwizard7/MacPortScanner/releases)
2. Откройте DMG и перетащите приложение в Applications
3. Запустите MacPortScanner

### Сборка из исходников
```bash
git clone https://github.com/iwizard7/MacPortScanner.git
cd MacPortScanner
./build.sh
open dist/MacPortScanner.app
```

## 🛠️ Для разработчиков

### Быстрая разработка
```bash
# Полный цикл разработки
./workflow.sh --all

# Отдельные действия
./workflow.sh --commit     # Умный коммит
./workflow.sh --build      # Сборка
./workflow.sh --package    # Создать DMG
```

### Обратная совместимость
```bash
make build      # Простая сборка
make run        # Собрать и запустить
make package    # Создать DMG
make all        # Полный цикл
```

## 📋 Системные требования

- macOS 14.0+
- Xcode Command Line Tools
- Rust (для сборки из исходников)

## 🆘 Помощь

- `./workflow.sh --help` - Полная справка
- [WORKFLOW.md](WORKFLOW.md) - Подробное руководство
- [GitHub Issues](https://github.com/iwizard7/MacPortScanner/issues) - Поддержка