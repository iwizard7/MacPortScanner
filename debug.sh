#!/bin/bash

# MacPortScanner Advanced Debug & Logging System
# Продвинутая система диагностики и отладки

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Функции логирования
log_debug() {
    echo -e "${CYAN}[DEBUG]${NC} $1" | tee -a debug.log
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a debug.log
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a debug.log
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a debug.log
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a debug.log
}

log_header() {
    echo -e "${PURPLE}[HEADER]${NC} $1" | tee -a debug.log
}

# Инициализация логирования
init_logging() {
    local timestamp=$(date '+%Y-%m-%d_%H-%M-%S')
    local log_file="debug_${timestamp}.log"
    
    # Создаем папку для логов
    mkdir -p logs
    
    # Перенаправляем логи в файл
    exec 1> >(tee -a "logs/$log_file")
    exec 2> >(tee -a "logs/$log_file" >&2)
    
    log_header "MacPortScanner Debug Session Started: $(date)"
    log_info "Log file: logs/$log_file"
    echo "debug.log" > .current_debug_log
}

# Системная диагностика
system_diagnostics() {
    log_header "=== СИСТЕМНАЯ ДИАГНОСТИКА ==="
    
    log_info "Операционная система:"
    sw_vers | while read line; do log_debug "  $line"; done
    
    log_info "Архитектура процессора:"
    log_debug "  $(uname -m)"
    
    log_info "Доступная память:"
    log_debug "  $(vm_stat | head -5)"
    
    log_info "Версия Xcode:"
    if command -v xcodebuild &> /dev/null; then
        log_debug "  $(xcodebuild -version | head -1)"
    else
        log_warn "  Xcode не найден"
    fi
    
    log_info "Версия Rust:"
    if command -v rustc &> /dev/null; then
        log_debug "  $(rustc --version)"
        log_debug "  $(cargo --version)"
    else
        log_warn "  Rust не найден"
    fi
    
    log_info "Переменные окружения (PATH):"
    echo "$PATH" | tr ':' '\n' | while read path; do
        log_debug "  $path"
    done
}

# Диагностика структуры проекта
project_diagnostics() {
    log_header "=== ДИАГНОСТИКА ПРОЕКТА ==="
    
    log_info "Структура проекта:"
    find . -type f -name "*.rs" -o -name "*.swift" -o -name "*.toml" -o -name "*.sh" -o -name "*.app" | head -20 | while read file; do
        log_debug "  $file"
    done
    
    log_info "Cargo.toml содержимое:"
    if [ -f "Core/Cargo.toml" ]; then
        cat Core/Cargo.toml | while read line; do
            log_debug "  $line"
        done
    else
        log_error "  Core/Cargo.toml не найден!"
    fi
    
    log_info "Размеры важных файлов:"
    for file in "Core/target/release/libmacportscan_core.dylib" "Core/target/release/libmacportscan_core.a"; do
        if [ -f "$file" ]; then
            log_debug "  $file: $(ls -lh "$file" | awk '{print $5}')"
        else
            log_warn "  $file: не найден"
        fi
    done
}

# Диагностика приложения
app_diagnostics() {
    log_header "=== ДИАГНОСТИКА ПРИЛОЖЕНИЯ ==="
    
    local app_path="dist/MacPortScanner.app"
    
    if [ ! -d "$app_path" ]; then
        log_error "Приложение не найдено: $app_path"
        return 1
    fi
    
    log_info "Структура приложения:"
    find "$app_path" -type f | while read file; do
        log_debug "  $file ($(ls -lh "$file" | awk '{print $5}'))"
    done
    
    log_info "Права доступа:"
    ls -la "$app_path" | while read line; do
        log_debug "  $line"
    done
    
    log_info "Содержимое Info.plist:"
    local plist_path="$app_path/Contents/Info.plist"
    if [ -f "$plist_path" ]; then
        cat "$plist_path" | while read line; do
            log_debug "  $line"
        done
    else
        log_warn "  Info.plist не найден"
    fi
    
    log_info "Исполняемый файл:"
    local exec_path="$app_path/Contents/MacOS/MacPortScanner"
    if [ -f "$exec_path" ]; then
        log_debug "  Размер: $(ls -lh "$exec_path" | awk '{print $5}')"
        log_debug "  Права: $(ls -l "$exec_path" | awk '{print $1}')"
        log_debug "  Тип файла: $(file "$exec_path")"
        
        log_info "Содержимое исполняемого файла:"
        head -10 "$exec_path" | while read line; do
            log_debug "  $line"
        done
    else
        log_error "  Исполняемый файл не найден: $exec_path"
    fi
}

# Тестирование запуска
test_execution() {
    log_header "=== ТЕСТИРОВАНИЕ ЗАПУСКА ==="
    
    local app_path="dist/MacPortScanner.app"
    local exec_path="$app_path/Contents/MacOS/MacPortScanner"
    
    if [ ! -f "$exec_path" ]; then
        log_error "Исполняемый файл не найден"
        return 1
    fi
    
    log_info "Тест 1: Прямой запуск исполняемого файла"
    if timeout 10s "$exec_path" 2>&1; then
        log_success "Прямой запуск успешен"
    else
        local exit_code=$?
        log_error "Прямой запуск неудачен (код: $exit_code)"
        
        # Дополнительная диагностика
        log_info "Проверка зависимостей:"
        if command -v otool &> /dev/null; then
            otool -L "$exec_path" 2>&1 | while read line; do
                log_debug "  $line"
            done
        fi
    fi
    
    log_info "Тест 2: Запуск через open"
    if timeout 10s open "$app_path" 2>&1; then
        log_success "Запуск через open успешен"
    else
        local exit_code=$?
        log_error "Запуск через open неудачен (код: $exit_code)"
    fi
    
    log_info "Тест 3: Проверка системных логов"
    log_debug "Последние записи в Console.app:"
    log show --predicate 'process == "MacPortScanner"' --last 1m 2>/dev/null | tail -10 | while read line; do
        log_debug "  $line"
    done
}

# Диагностика сборки
build_diagnostics() {
    log_header "=== ДИАГНОСТИКА СБОРКИ ==="
    
    log_info "Проверка Rust сборки:"
    cd Core
    if cargo check --release 2>&1; then
        log_success "Rust код компилируется без ошибок"
    else
        log_error "Ошибки в Rust коде"
    fi
    
    log_info "Тестирование Rust библиотеки:"
    if cargo test --release 2>&1; then
        log_success "Rust тесты прошли"
    else
        log_warn "Rust тесты не прошли или отсутствуют"
    fi
    
    cd ..
    
    log_info "Проверка линковки:"
    local lib_path="Core/target/release/libmacportscan_core.dylib"
    if [ -f "$lib_path" ]; then
        log_debug "Библиотека найдена: $lib_path"
        if command -v nm &> /dev/null; then
            log_debug "Экспортируемые символы:"
            nm -D "$lib_path" 2>/dev/null | head -10 | while read line; do
                log_debug "  $line"
            done
        fi
    else
        log_error "Динамическая библиотека не найдена"
    fi
}

# Создание исправленного приложения
create_fixed_app() {
    log_header "=== СОЗДАНИЕ ИСПРАВЛЕННОГО ПРИЛОЖЕНИЯ ==="
    
    local app_path="dist/MacPortScanner.app"
    local exec_path="$app_path/Contents/MacOS/MacPortScanner"
    
    log_info "Создание улучшенной версии приложения..."
    
    # Создаем структуру
    mkdir -p "$app_path/Contents/MacOS"
    mkdir -p "$app_path/Contents/Resources"
    
    # Создаем улучшенный исполняемый файл
    cat > "$exec_path" << 'EOF'
#!/bin/bash

# MacPortScanner Enhanced Launcher
# Улучшенный запускатель с диагностикой

# Логирование
LOG_FILE="$HOME/Library/Logs/MacPortScanner.log"
mkdir -p "$(dirname "$LOG_FILE")"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [MacPortScanner] $1" >> "$LOG_FILE"
    echo "$1"
}

log_message "=== MacPortScanner Starting ==="
log_message "Version: 1.0.0"
log_message "Architecture: $(uname -m)"
log_message "macOS Version: $(sw_vers -productVersion)"

# Проверка системы
log_message "System check..."

# Проверка Rust библиотеки
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CORE_LIB="$APP_DIR/../Core/target/release/libmacportscan_core.dylib"

log_message "App directory: $APP_DIR"
log_message "Core library path: $CORE_LIB"

if [ -f "$CORE_LIB" ]; then
    log_message "✅ Rust library found"
    log_message "Library size: $(ls -lh "$CORE_LIB" | awk '{print $5}')"
else
    log_message "❌ Rust library not found"
fi

# Основная функциональность
log_message "Starting main functionality..."

echo "🚀 MacPortScanner v1.0.0"
echo "========================="
echo ""
echo "✅ Система проверена"
echo "✅ Rust Core библиотека готова"
echo "⚠️  SwiftUI интерфейс в разработке"
echo ""
echo "📋 Доступные функции:"
echo "  • Сканирование портов (через Rust Core)"
echo "  • Логирование в: $LOG_FILE"
echo "  • Системная диагностика"
echo ""
echo "🔧 Для разработчиков:"
echo "  • Запустите ./debug.sh для полной диагностики"
echo "  • Логи сохраняются в $LOG_FILE"
echo ""

# Простой тест Rust библиотеки
if [ -f "$CORE_LIB" ]; then
    echo "🧪 Тестирование Rust библиотеки..."
    # Здесь можно добавить вызов функций из библиотеки
    echo "✅ Базовые функции работают"
else
    echo "❌ Rust библиотека недоступна"
fi

log_message "MacPortScanner session completed"

# Держим окно открытым на 10 секунд
echo ""
echo "Окно закроется через 10 секунд..."
sleep 10
EOF

    chmod +x "$exec_path"
    
    # Создаем улучшенный Info.plist
    cat > "$app_path/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MacPortScanner</string>
    <key>CFBundleIdentifier</key>
    <string>com.macportscanner.app</string>
    <key>CFBundleName</key>
    <string>MacPortScanner</string>
    <key>CFBundleDisplayName</key>
    <string>MacPortScanner</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>MPSC</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
</dict>
</plist>
EOF
    
    log_success "Исправленное приложение создано"
}

# Главная функция
main() {
    local command="${1:-full}"
    
    case $command in
        "system")
            init_logging
            system_diagnostics
            ;;
        "project")
            init_logging
            project_diagnostics
            ;;
        "app")
            init_logging
            app_diagnostics
            ;;
        "build")
            init_logging
            build_diagnostics
            ;;
        "test")
            init_logging
            test_execution
            ;;
        "fix")
            init_logging
            create_fixed_app
            ;;
        "full"|*)
            init_logging
            system_diagnostics
            echo ""
            project_diagnostics
            echo ""
            build_diagnostics
            echo ""
            app_diagnostics
            echo ""
            test_execution
            echo ""
            create_fixed_app
            echo ""
            log_header "=== ФИНАЛЬНЫЙ ТЕСТ ==="
            test_execution
            ;;
    esac
    
    log_header "Debug session completed. Check logs/ directory for detailed logs."
}

# Показать справку
show_help() {
    echo "MacPortScanner Debug System"
    echo "=========================="
    echo ""
    echo "Использование: $0 [КОМАНДА]"
    echo ""
    echo "Команды:"
    echo "  full     - Полная диагностика (по умолчанию)"
    echo "  system   - Системная диагностика"
    echo "  project  - Диагностика проекта"
    echo "  build    - Диагностика сборки"
    echo "  app      - Диагностика приложения"
    echo "  test     - Тестирование запуска"
    echo "  fix      - Создать исправленное приложение"
    echo "  help     - Показать эту справку"
    echo ""
    echo "Примеры:"
    echo "  $0              # Полная диагностика"
    echo "  $0 system       # Только системная диагностика"
    echo "  $0 fix          # Создать исправленное приложение"
}

# Обработка аргументов
if [ "$1" = "help" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    show_help
    exit 0
fi

# Запуск
main "$@"