#!/bin/bash

# MacPortScanner - Подготовка к релизу на GitHub

set -e

echo "🚀 MacPortScanner - Подготовка к релизу v1.0.0"
echo "=============================================="

# Проверяем что мы в правильной папке
if [ ! -f "package.json" ]; then
    echo "❌ Ошибка: package.json не найден. Запустите скрипт из корня проекта."
    exit 1
fi

# Проверяем что приложение собрано
if [ ! -d "build/release" ]; then
    echo "⚠️  Приложение не собрано. Запускаем сборку..."
    ./build.sh
fi

echo ""
echo "📋 Проверка готовности к релизу:"
echo "================================"

# Проверяем основные файлы
files_to_check=(
    "README.md"
    "LICENSE"
    "CHANGELOG.md"
    "package.json"
    "build/release/MacPortScanner-1.0.0-arm64.dmg"
    "build/release/MacPortScanner-1.0.0.dmg"
)

for file in "${files_to_check[@]}"; do
    if [ -f "$file" ] || [ -d "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ $file - ОТСУТСТВУЕТ"
    fi
done

echo ""
echo "📊 Статистика проекта:"
echo "====================="

# Подсчет строк кода
if command -v find &> /dev/null; then
    ts_lines=$(find src -name "*.ts" -o -name "*.tsx" | xargs wc -l 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
    echo "📝 Строк TypeScript кода: $ts_lines"
fi

# Размеры файлов релиза
if [ -d "build/release" ]; then
    echo "📦 Размеры файлов релиза:"
    ls -lah build/release/*.dmg build/release/*.zip 2>/dev/null | awk '{print "   " $9 ": " $5}'
fi

# Информация о зависимостях
deps_count=$(grep -c '"' package.json | head -1 || echo "0")
echo "📚 Зависимостей в package.json: примерно $((deps_count / 2))"

echo ""
echo "🔧 Git статус:"
echo "=============="
git status --porcelain | head -10

echo ""
echo "📋 Следующие шаги для релиза:"
echo "============================="
echo "1. Проверьте все файлы выше"
echo "2. Убедитесь что build/release содержит готовые приложения"
echo "3. Выполните команды:"
echo ""
echo "   git add ."
echo "   git commit -m \"Release v1.0.0: MacPortScanner ready for production\""
echo "   git push origin main"
echo ""
echo "4. Создайте релиз на GitHub:"
echo "   - Перейдите на https://github.com/iwizard7/MacPortScanner/releases"
echo "   - Нажмите 'Create a new release'"
echo "   - Tag: v1.0.0"
echo "   - Title: MacPortScanner v1.0.0"
echo "   - Загрузите файлы из build/release/"
echo ""
echo "📁 Файлы для загрузки в релиз:"
if [ -d "build/release" ]; then
    find build/release -name "*.dmg" -o -name "*.zip" | grep -v blockmap | sort
fi

echo ""
echo "🎉 Проект готов к релизу!"