#!/bin/bash

# Скрипт для тестирования обхода Gatekeeper на macOS
# Использование: ./test-gatekeeper.sh /path/to/MacPortScanner.app

if [ $# -eq 0 ]; then
    echo "Использование: $0 /path/to/MacPortScanner.app"
    exit 1
fi

APP_PATH="$1"

echo "🔍 Тестирование Gatekeeper для: $APP_PATH"

# Проверяем существует ли приложение
if [ ! -d "$APP_PATH" ]; then
    echo "❌ Приложение не найдено: $APP_PATH"
    exit 1
fi

echo "📋 Текущие атрибуты карантина:"
xattr -d com.apple.quarantine "$APP_PATH" 2>/dev/null || echo "ℹ️  Карантин не установлен или уже удален"

echo "🧹 Очистка всех атрибутов:"
xattr -cr "$APP_PATH"

echo "✅ Готово! Теперь попробуйте открыть приложение двойным кликом."
echo ""
echo "Если приложение все еще не открывается:"
echo "1. Щелкните правой кнопкой по приложению → 'Открыть'"
echo "2. Или откройте 'Системные настройки' → 'Защита и безопасность' → 'Все равно открыть'"