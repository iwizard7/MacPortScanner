#!/bin/bash

# Mac Port Scanner Silicon - Скрипт запуска
# Автоматическая установка зависимостей и запуск приложения

set -e

echo "🚀 Mac Port Scanner Silicon - Запуск приложения"
echo "================================================"

# Проверяем наличие Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js не найден. Пожалуйста, установите Node.js 18+ с https://nodejs.org/"
    exit 1
fi

# Проверяем версию Node.js
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo "❌ Требуется Node.js версии 18 или выше. Текущая версия: $(node -v)"
    exit 1
fi

echo "✅ Node.js версия: $(node -v)"

# Проверяем архитектуру процессора
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    echo "🚀 Обнаружен Apple Silicon (ARM64) - будут применены оптимизации производительности"
else
    echo "💻 Обнаружен Intel процессор (x64)"
fi

# Проверяем наличие package.json
if [ ! -f "package.json" ]; then
    echo "❌ Файл package.json не найден. Убедитесь, что вы находитесь в корневой папке проекта."
    exit 1
fi

# Устанавливаем зависимости если нужно
if [ ! -d "node_modules" ]; then
    echo "📦 Установка зависимостей..."
    npm install
else
    echo "✅ Зависимости уже установлены"
fi

# Проверяем наличие TypeScript компилятора
if ! command -v tsc &> /dev/null; then
    echo "📦 Установка TypeScript..."
    npm install -g typescript
fi

echo "🔨 Компиляция TypeScript..."
npx tsc

echo "🎯 Запуск приложения в режиме разработки..."
echo "Приложение откроется автоматически..."
echo ""
echo "Горячие клавиши:"
echo "  ⌘+Q - Быстрое сканирование"
echo "  ⌘+F - Полное сканирование"
echo "  ⌘+S - Остановить сканирование"
echo "  ⌘+E - Экспорт результатов"
echo ""

# Запускаем приложение
npm run dev