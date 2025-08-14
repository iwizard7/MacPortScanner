#!/bin/bash

# MacPortScanner - Скрипт сборки приложения

set -e

echo "🔨 MacPortScanner - Сборка приложения"
echo "===================================="

# Очищаем предыдущие сборки
echo "🧹 Очистка предыдущих сборок..."
rm -rf build/
rm -rf dist/

# Создаем папки
mkdir -p build/dist

# Компилируем TypeScript для Electron
echo "🔨 Компиляция Electron..."
npx tsc -p tsconfig.electron.json --outDir build/dist

# Собираем React приложение
echo "⚛️  Сборка React приложения..."
npx vite build --outDir build/dist

# Копируем файлы для electron-builder
echo "📁 Подготовка файлов для сборки..."
cp -r build/dist ./
# Убеждаемся что main.js и preload.js есть в dist
cp build/dist/main.js dist/ 2>/dev/null || echo "main.js уже в dist"
cp build/dist/preload.js dist/ 2>/dev/null || echo "preload.js уже в dist"

# Собираем приложение
echo "📦 Сборка macOS приложения..."
npx electron-builder --mac

# Перемещаем результаты в build
echo "🗂️  Организация файлов..."
if [ -d "release" ]; then
    mv release build/
fi

echo ""
echo "✅ Сборка завершена успешно!"
echo ""
echo "📁 Результаты сборки:"
if [ -d "build/release" ]; then
    ls -la build/release/
fi

echo ""
echo "🎉 Готово! Приложение находится в папке build/release/"