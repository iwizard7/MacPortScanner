#!/bin/bash

# Скрипт для локального тестирования сборки приложения
# Использование: ./test-build.sh

echo "🏗️ Тестирование сборки MacPortScanner..."

# Проверяем наличие Node.js и npm
if ! command -v node &> /dev/null; then
    echo "❌ Node.js не установлен"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "❌ npm не установлен"
    exit 1
fi

echo "📦 Устанавливаем зависимости..."
npm install

echo "⚛️ Собираем React приложение..."
npm run build:react

echo "🔨 Компилируем Electron..."
npm run build:electron

echo "📁 Подготавливаем файлы..."
cp -r build/dist ./dist

echo "🏗️ Собираем macOS приложение..."
npm run build:mac-local

echo "✅ Сборка завершена!"
echo "📂 Проверьте папку build/release/"
ls -la build/release/

echo ""
echo "🧪 Для тестирования Gatekeeper:"
echo "1. Откройте build/release/MacPortScanner-*.dmg"
echo "2. Перетащите приложение в Applications"
echo "3. Попробуйте запустить"
echo "4. Если 'приложение повреждено', используйте: ./test-gatekeeper.sh /Applications/MacPortScanner.app"