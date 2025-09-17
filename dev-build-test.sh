#!/bin/bash

# MacPortScanner - Скрипт для разработки: сборка, создание DMG и тестирование
# Использование: ./dev-build-test.sh

set -e

echo "🚀 MacPortScanner - Скрипт разработки: сборка + DMG + тесты"
echo "=========================================================="

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

echo ""
echo "🧪 Запускаем тесты..."
npm run test

echo ""
echo "🏗️ Собираем приложение и создаем DMG..."
npm run build:electron
npm run build:react
echo "📁 Подготавливаем файлы для electron-builder..."
rm -rf dist
cp -r build/dist ./dist
echo "📦 Создаем DMG файл..."
CSC_IDENTITY_AUTO_DISCOVERY=false npx electron-builder --mac --publish never || echo "⚠️  Предупреждение: ошибка при создании DMG, но файлы могут быть созданы"

echo ""
echo "📂 Проверяем результат сборки..."
if [ -d "build/release" ]; then
    echo "✅ Сборка завершена успешно!"
    echo "📁 Содержимое build/release/:"
    ls -la build/release/

    # Проверяем наличие DMG файлов
    if ls build/release/*.dmg 1> /dev/null 2>&1; then
        echo "✅ DMG файлы созданы:"
        ls -la build/release/*.dmg
    else
        echo "❌ DMG файлы не найдены"
        exit 1
    fi
else
    echo "❌ Ошибка: папка build/release не найдена"
    exit 1
fi

echo ""
echo "🧪 Тестируем собранное приложение..."
./test-app.sh

echo ""
echo "🎉 Все этапы завершены успешно!"
echo ""
echo "📋 Следующие шаги:"
echo "1. Проверьте работу приложения в открывшемся окне"
echo "2. Для тестирования Gatekeeper: ./test-gatekeeper.sh /Applications/MacPortScanner.app"
echo "3. Для полной проверки: ./test-build.sh"