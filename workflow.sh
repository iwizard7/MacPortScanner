#!/bin/bash

# MacPortScanner Unified Workflow Script
# Единый скрипт для автоматизации всех процессов разработки

set -e

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${PURPLE}[WORKFLOW]${NC} $1"
}

# Показать справку
show_help() {
    echo "🚀 MacPortScanner Unified Workflow"
    echo "=================================="
    echo ""
    echo "Использование: $0 [ОПЦИИ]"
    echo ""
    echo "Основные действия:"
    echo "  --all              Выполнить все действия (коммит + changelog + push + build)"
    echo "  --commit           Создать умный коммит"
    echo "  --changelog        Обновить changelog"
    echo "  --push             Отправить в GitHub"
    echo "  --build            Собрать приложение"
    echo "  --package          Создать DMG пакет"
    echo ""
    echo "Опции для changelog:"
    echo "  --version X.Y.Z    Указать конкретную версию"
    echo "  --major            Увеличить major версию (X.0.0)"
    echo "  --minor            Увеличить minor версию (X.Y.0)"
    echo "  --patch            Увеличить patch версию (X.Y.Z) [по умолчанию]"
    echo ""
    echo "Дополнительные опции:"
    echo "  --no-readme        Не обновлять README.md"
    echo "  --force            Принудительно выполнить действия"
    echo "  --quiet            Тихий режим (минимум вывода)"
    echo "  --help             Показать эту справку"
    echo ""
    echo "Примеры:"
    echo "  $0 --all                    # Полный цикл разработки"
    echo "  $0 --commit --push          # Коммит и отправка"
    echo "  $0 --changelog --minor      # Обновить changelog с minor версией"
    echo "  $0 --build --package        # Сборка и создание DMG"
    echo ""
}

# Переменные по умолчанию
DO_COMMIT=false
DO_CHANGELOG=false
DO_PUSH=false
DO_BUILD=false
DO_PACKAGE=false
DO_ALL=false

VERSION=""
VERSION_TYPE="patch"
UPDATE_README=true
FORCE=false
QUIET=false

# Парсинг аргументов
while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            DO_ALL=true
            shift
            ;;
        --commit)
            DO_COMMIT=true
            shift
            ;;
        --changelog)
            DO_CHANGELOG=true
            shift
            ;;
        --push)
            DO_PUSH=true
            shift
            ;;
        --build)
            DO_BUILD=true
            shift
            ;;
        --package)
            DO_PACKAGE=true
            shift
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --major)
            VERSION_TYPE="major"
            shift
            ;;
        --minor)
            VERSION_TYPE="minor"
            shift
            ;;
        --patch)
            VERSION_TYPE="patch"
            shift
            ;;
        --no-readme)
            UPDATE_README=false
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --quiet)
            QUIET=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            print_error "Неизвестная опция: $1"
            echo "Используйте --help для справки"
            exit 1
            ;;
    esac
done

# Если --all, включаем все действия
if [ "$DO_ALL" = true ]; then
    DO_COMMIT=true
    DO_CHANGELOG=true
    DO_PUSH=true
    DO_BUILD=true
    DO_PACKAGE=true
fi

# Если ничего не выбрано, показываем справку
if [ "$DO_COMMIT" = false ] && [ "$DO_CHANGELOG" = false ] && [ "$DO_PUSH" = false ] && [ "$DO_BUILD" = false ] && [ "$DO_PACKAGE" = false ]; then
    show_help
    exit 0
fi

# Проверяем, что мы в правильной директории
if [ ! -f "Core/Cargo.toml" ] || [ ! -d "UI" ]; then
    print_error "Запустите скрипт из корневой директории MacPortScanner"
    exit 1
fi

print_header "Запуск MacPortScanner Workflow"
echo "======================================"

# Показываем план действий
echo "📋 План выполнения:"
[ "$DO_COMMIT" = true ] && echo "  ✅ Создать умный коммит"
[ "$DO_CHANGELOG" = true ] && echo "  ✅ Обновить changelog (тип: $VERSION_TYPE)"
[ "$DO_PUSH" = true ] && echo "  ✅ Отправить в GitHub"
[ "$DO_BUILD" = true ] && echo "  ✅ Собрать приложение"
[ "$DO_PACKAGE" = true ] && echo "  ✅ Создать DMG пакет"
echo ""

# Подтверждение если не force режим
if [ "$FORCE" = false ]; then
    read -p "Продолжить выполнение? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Выполнение отменено"
        exit 0
    fi
fi

# Функция для выполнения команд с проверкой
execute_step() {
    local step_name="$1"
    local command="$2"
    
    print_status "Выполняю: $step_name"
    
    if [ "$QUIET" = true ]; then
        eval "$command" >/dev/null 2>&1
    else
        eval "$command"
    fi
    
    if [ $? -eq 0 ]; then
        print_success "$step_name завершен"
    else
        print_error "Ошибка в шаге: $step_name"
        exit 1
    fi
}

# 1. Создание умного коммита
if [ "$DO_COMMIT" = true ]; then
    print_header "Шаг 1: Создание умного коммита"
    
    # Проверяем наличие изменений
    if git diff --quiet && git diff --cached --quiet; then
        print_warning "Нет изменений для коммита"
    else
        execute_step "Умный коммит" "./development/smart-commit.sh"
    fi
fi

# 2. Обновление changelog
if [ "$DO_CHANGELOG" = true ]; then
    print_header "Шаг 2: Обновление changelog"
    
    CHANGELOG_CMD="./development/update-changelog.sh --$VERSION_TYPE --auto-commit"
    [ -n "$VERSION" ] && CHANGELOG_CMD="$CHANGELOG_CMD --version $VERSION"
    [ "$UPDATE_README" = false ] && CHANGELOG_CMD="$CHANGELOG_CMD --no-readme"
    
    execute_step "Обновление changelog" "$CHANGELOG_CMD"
fi

# 3. Отправка в GitHub
if [ "$DO_PUSH" = true ]; then
    print_header "Шаг 3: Отправка в GitHub"
    
    # Проверяем наличие удаленного репозитория
    if git remote get-url origin >/dev/null 2>&1; then
        execute_step "Push в main" "git push origin main"
        
        # Отправляем теги если есть
        if git tag -l | grep -q "v"; then
            execute_step "Push тегов" "git push origin --tags"
        fi
    else
        print_warning "Удаленный репозиторий не настроен"
    fi
fi

# 4. Сборка приложения
if [ "$DO_BUILD" = true ]; then
    print_header "Шаг 4: Сборка приложения"
    
    # Проверяем наличие необходимых инструментов
    if ! command -v cargo &> /dev/null; then
        print_error "Rust не найден. Установите с https://rustup.rs/"
        exit 1
    fi
    
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode command line tools не найдены"
        exit 1
    fi
    
    # Очищаем предыдущие сборки
    execute_step "Очистка предыдущих сборок" "rm -rf dist/ Core/target/release/ UI/build/"
    
    # Собираем Rust библиотеку
    execute_step "Сборка Rust библиотеки" "cd Core && cargo build --release && cd .."
    
    # Проверяем наличие Xcode проекта
    if [ -f "UI/MacPortScanner.xcodeproj/project.pbxproj" ]; then
        # Собираем Swift приложение
        execute_step "Сборка Swift приложения" "cd UI && xcodebuild build -project MacPortScanner.xcodeproj -scheme MacPortScanner -configuration Release -derivedDataPath build && cd .."
        
        # Создаем дистрибутив
        execute_step "Создание дистрибутива" "mkdir -p dist && cp -R UI/build/Build/Products/Release/MacPortScanner.app dist/"
    else
        print_warning "Xcode проект не найден. Создаем заглушку приложения..."
        execute_step "Создание заглушки приложения" "mkdir -p dist/MacPortScanner.app/Contents/MacOS && cat > dist/MacPortScanner.app/Contents/MacOS/MacPortScanner << 'EOF'
#!/bin/bash
echo '🚀 MacPortScanner v1.0.0'
echo 'Rust Core библиотека готова к использованию!'
echo 'UI компонент в разработке...'
EOF
chmod +x dist/MacPortScanner.app/Contents/MacOS/MacPortScanner"
    fi
    
    print_success "Приложение собрано: dist/MacPortScanner.app"
fi

# 5. Создание DMG пакета
if [ "$DO_PACKAGE" = true ]; then
    print_header "Шаг 5: Создание DMG пакета"
    
    if [ ! -d "dist/MacPortScanner.app" ]; then
        print_error "Приложение не найдено. Сначала выполните сборку (--build)"
        exit 1
    fi
    
    # Получаем версию для имени файла
    CURRENT_VERSION=$(grep '^version = ' Core/Cargo.toml | head -1 | sed 's/version = "\(.*\)"/\1/')
    DMG_NAME="MacPortScanner-${CURRENT_VERSION}.dmg"
    
    execute_step "Создание DMG пакета" "./development/create-dmg.sh"
    
    if [ -f "$DMG_NAME" ]; then
        print_success "DMG пакет создан: $DMG_NAME"
    fi
fi

# Финальный отчет
print_header "Workflow завершен! 🎉"
echo "=========================="

echo "📊 Выполненные действия:"
[ "$DO_COMMIT" = true ] && echo "  ✅ Создан умный коммит"
[ "$DO_CHANGELOG" = true ] && echo "  ✅ Обновлен changelog"
[ "$DO_PUSH" = true ] && echo "  ✅ Отправлено в GitHub"
[ "$DO_BUILD" = true ] && echo "  ✅ Собрано приложение"
[ "$DO_PACKAGE" = true ] && echo "  ✅ Создан DMG пакет"

echo ""
echo "📁 Результаты:"
[ -d "dist/MacPortScanner.app" ] && echo "  📱 Приложение: dist/MacPortScanner.app"
[ -f "MacPortScanner-*.dmg" ] && echo "  📦 DMG пакет: $(ls MacPortScanner-*.dmg 2>/dev/null | head -1)"

echo ""
echo "🚀 Следующие шаги:"
echo "  • Протестируйте приложение: open dist/MacPortScanner.app"
echo "  • Установите: cp -R dist/MacPortScanner.app /Applications/"
echo "  • Создайте релиз на GitHub с DMG файлом"

print_success "Все готово! 🎊"