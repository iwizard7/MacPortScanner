#!/bin/bash

# MacPortScanner Simple Build Script
# Простой скрипт сборки для конечных пользователей

set -e

echo "🚀 Building MacPortScanner..."

# Цвета для вывода
GREEN='\033[0;32m'
BLUE='\033[0;34m'
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

print_success "Сборка завершена успешно!"
echo ""
echo "📦 Приложение собрано: dist/MacPortScanner.app"
echo "🚀 Запуск: open dist/MacPortScanner.app"
echo "📲 Установка: cp -R dist/MacPortScanner.app /Applications/"