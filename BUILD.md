# MacPortScanner Build Guide

Подробное руководство по локальной сборке MacPortScanner.

## 🎯 Быстрый старт

### Минимальные требования
- macOS 14.0 или новее
- Rust 1.70+ (установить с [rustup.rs](https://rustup.rs/))
- Xcode Command Line Tools: `xcode-select --install`

### Самый быстрый способ
```bash
git clone https://github.com/iwizard7/MacPortScanner.git
cd MacPortScanner
make quick && make run
```

## 🛠️ Варианты сборки

### 1. Быстрая сборка (`quick-build.sh`)
**Время:** ~2-3 минуты  
**Назначение:** Быстрые итерации разработки

```bash
./quick-build.sh
# или
make quick
```

**Что делает:**
- Собирает Rust библиотеку в release режиме
- Создает минимальный app bundle
- Выводит: `dist-quick/MacPortScanner.app`

### 2. Полная сборка (`build-local.sh`)
**Время:** ~5-10 минут  
**Назначение:** Производственная сборка

```bash
./build-local.sh
# или
make build
```

**Опции:**
```bash
./build-local.sh --help
./build-local.sh --debug          # Debug сборка
./build-local.sh --skip-tests     # Пропустить тесты
./build-local.sh --clean          # Очистить перед сборкой
./build-local.sh --verbose        # Подробный вывод
```

**Что делает:**
- Проверяет все зависимости
- Собирает Rust библиотеку
- Запускает тесты
- Пытается собрать Swift UI (если доступен Xcode)
- Создает полный app bundle с документацией
- Выводит: `dist/MacPortScanner.app`

### 3. Сборка для разработки (`dev-build.sh`)
**Время:** ~3-5 минут  
**Назначение:** Разработка с проверками качества

```bash
./dev-build.sh
# или
make dev
```

**Опции:**
```bash
./dev-build.sh --help
./dev-build.sh --no-tests      # Пропустить тесты
./dev-build.sh --no-clippy     # Пропустить clippy
./dev-build.sh --benchmarks    # Запустить бенчмарки
./dev-build.sh --docs          # Сгенерировать документацию
./dev-build.sh --watch         # Режим наблюдения за изменениями
```

**Что делает:**
- Форматирует код (`cargo fmt`)
- Собирает в debug режиме (быстрее)
- Запускает тесты
- Проверяет код с clippy
- Создает development app bundle с интерактивным меню
- Выводит: `dev-dist/MacPortScanner-Dev.app`

## 📦 Создание DMG

```bash
./create-dmg.sh
# или
make dmg
```

**Требования:**
- Установленный `create-dmg`: `brew install create-dmg`
- Собранное приложение в `dist/`

**Результат:** `MacPortScanner-0.1.0.dmg`

## 🎮 Makefile команды

### Основные команды
```bash
make quick         # Быстрая сборка
make build         # Полная сборка  
make dev           # Сборка для разработки
make clean         # Очистить все артефакты
```

### Тестирование и качество
```bash
make test          # Запустить тесты
make lint          # Проверить с clippy
make format        # Отформатировать код
make check         # format + lint + test
make bench         # Запустить бенчмарки
make audit         # Проверка безопасности
```

### Запуск
```bash
make run           # Собрать и запустить
make run-dev       # Запустить dev версию
```

### Документация
```bash
make docs          # Сгенерировать и открыть документацию
```

### Распространение
```bash
make dmg           # Создать DMG
make package       # Полная сборка + DMG
make install       # Установить в /Applications
make uninstall     # Удалить из /Applications
```

### Разработка
```bash
make watch         # Наблюдать за изменениями
make setup         # Настроить среду разработки
make update        # Обновить зависимости
```

### Информация
```bash
make help          # Показать все команды
make status        # Показать статус проекта
```

## 🔧 Структура сборки

### Выходные директории
```
MacPortScanner/
├── dist-quick/           # Быстрая сборка
│   └── MacPortScanner.app
├── dist/                 # Полная сборка
│   ├── MacPortScanner.app
│   ├── README.txt
│   └── BUILD_INFO.txt
├── dev-dist/             # Сборка для разработки
│   └── MacPortScanner-Dev.app
└── *.dmg                 # DMG файлы
```

### Rust артефакты
```
Core/target/
├── debug/                # Debug сборка
│   ├── libmacportscan_core.a
│   └── libmacportscan_core.dylib
└── release/              # Release сборка
    ├── libmacportscan_core.a
    └── libmacportscan_core.dylib
```

## 🚨 Решение проблем

### Rust не найден
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
```

### Xcode Command Line Tools не найдены
```bash
xcode-select --install
```

### create-dmg не найден
```bash
brew install create-dmg
```

### Ошибки компиляции Rust
```bash
# Обновить Rust
rustup update

# Очистить кэш
cargo clean

# Переустановить зависимости
rm Cargo.lock
cargo build
```

### Проблемы с правами доступа
```bash
# Сделать скрипты исполняемыми
chmod +x *.sh

# Исправить права на app bundle
chmod +x dist/MacPortScanner.app/Contents/MacOS/MacPortScanner
```

## ⚡ Оптимизация сборки

### Ускорение компиляции Rust
```bash
# Добавить в ~/.cargo/config.toml
[build]
jobs = 8  # Количество CPU ядер

[target.x86_64-apple-darwin]
rustflags = ["-C", "link-arg=-fuse-ld=lld"]
```

### Кэширование зависимостей
```bash
# Использовать sccache
cargo install sccache
export RUSTC_WRAPPER=sccache
```

## 📊 Бенчмарки производительности

```bash
# Запустить бенчмарки
make bench

# Профилирование
cargo install flamegraph
cargo flamegraph --bench benchmark_portscan
```

## 🎯 Continuous Integration

Симуляция CI локально:
```bash
make ci  # clean + format + lint + test
```

## 📝 Логи сборки

Все скрипты создают подробные логи:
- `BUILD_INFO.txt` - информация о сборке
- Цветной вывод в терминал
- Детальная информация об ошибках

---

**Нужна помощь?** Создайте [issue на GitHub](https://github.com/iwizard7/MacPortScanner/issues)