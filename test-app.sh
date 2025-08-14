#!/bin/bash

# MacPortScanner - Скрипт тестирования собранного приложения

set -e

echo "🧪 MacPortScanner - Тестирование приложения"
echo "===================================================="

# Определяем архитектуру
ARCH=$(uname -m)
echo "🖥️  Архитектура системы: $ARCH"

# Выбираем подходящее приложение
if [ "$ARCH" = "arm64" ]; then
    APP_PATH="build/release/mac-arm64/MacPortScanner.app"
    echo "🚀 Используем версию для Apple Silicon"
else
    APP_PATH="build/release/mac/MacPortScanner.app"
    echo "💻 Используем версию для Intel"
fi

# Проверяем существование приложения
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Приложение не найдено: $APP_PATH"
    echo "Сначала соберите приложение командой: npm run build:mac"
    exit 1
fi

echo "✅ Приложение найдено: $APP_PATH"

# Показываем информацию о приложении
echo ""
echo "📊 Информация о приложении:"
echo "Размер: $(du -sh "$APP_PATH" | cut -f1)"
echo "Путь: $(pwd)/$APP_PATH"

# Проверяем права доступа
echo ""
echo "🔐 Проверка прав доступа..."
if [ -x "$APP_PATH/Contents/MacOS/MacPortScanner" ]; then
    echo "✅ Исполняемый файл имеет права на выполнение"
else
    echo "⚠️  Устанавливаем права на выполнение..."
    chmod +x "$APP_PATH/Contents/MacOS/MacPortScanner"
fi

# Проверяем подпись (если есть)
echo ""
echo "📝 Проверка подписи приложения..."
codesign -dv "$APP_PATH" 2>/dev/null || echo "⚠️  Приложение не подписано (это нормально для разработки)"

echo ""
echo "🚀 Запуск приложения..."
echo "Приложение откроется в новом окне..."
echo ""
echo "Для ручного запуска используйте:"
echo "  open \"$APP_PATH\""
echo ""
echo "Или через Finder:"
echo "  1. Откройте папку build/release/mac-arm64/ (или build/release/mac/)"
echo "  2. Дважды кликните на 'MacPortScanner.app'"
echo ""

# Запускаем приложение
open "$APP_PATH"

echo "✅ Приложение запущено!"
echo ""
echo "🎯 Функции для тестирования:"
echo "  • Сканирование localhost (127.0.0.1)"
echo "  • Проверка популярных портов"
echo "  • Тестирование горячих клавиш (⌘+Q, ⌘+F, ⌘+S)"
echo "  • Экспорт результатов (⌘+E)"
echo "  • Проверка темной/светлой темы"
echo ""
echo "🔧 Для отладки откройте Developer Tools в меню View"