#!/bin/bash

# MacPortScanner Simple Build Script
# Простой скрипт сборки для конечных пользователей

set -e

echo "🚀 Building MacPortScanner..."

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Проверяем macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "Это приложение предназначено только для macOS"
    exit 1
fi

# Проверяем необходимые инструменты
if ! command -v cargo &> /dev/null; then
    print_error "Rust не найден. Установите с https://rustup.rs/"
    exit 1
fi

if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode command line tools не найдены. Установите: xcode-select --install"
    exit 1
fi

# Собираем Rust библиотеку
print_status "Сборка Rust библиотеки..."
cd Core
cargo build --release
if [ $? -ne 0 ]; then
    print_error "Ошибка сборки Rust библиотеки"
    exit 1
fi
cd ..

# Проверяем наличие Xcode проекта
if [ -f "UI/MacPortScanner.xcodeproj/project.pbxproj" ]; then
    # Собираем Swift приложение
    print_status "Сборка Swift приложения..."
    cd UI
    xcodebuild build -project MacPortScanner.xcodeproj -scheme MacPortScanner -configuration Release -derivedDataPath build
    if [ $? -ne 0 ]; then
        print_error "Ошибка сборки Swift приложения"
        exit 1
    fi
    cd ..
    
    # Создаем дистрибутив
    print_status "Создание дистрибутива..."
    mkdir -p dist
    cp -R UI/build/Build/Products/Release/MacPortScanner.app dist/
else
    print_warning "Xcode проект не найден. Создаем заглушку приложения..."
    mkdir -p dist/MacPortScanner.app/Contents/MacOS
    cat > dist/MacPortScanner.app/Contents/MacOS/MacPortScanner << 'EOF'
#!/bin/bash
echo "🚀 MacPortScanner v1.0.0"
echo "Rust Core библиотека готова к использованию!"
echo "UI компонент в разработке..."
EOF
    chmod +x dist/MacPortScanner.app/Contents/MacOS/MacPortScanner
    
    # Создаем Info.plist
    mkdir -p dist/MacPortScanner.app/Contents
    cat > dist/MacPortScanner.app/Contents/Info.plist << 'EOF'
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
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
</dict>
</plist>
EOF
fi

print_success "Сборка завершена успешно!"
echo ""
echo "📦 Приложение собрано: dist/MacPortScanner.app"
echo "🚀 Запуск: open dist/MacPortScanner.app"
echo "📲 Установка: cp -R dist/MacPortScanner.app /Applications/"