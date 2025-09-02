#!/bin/bash

# Скрипт для исправления пустой версии в package.json
# Использование: ./fix-version.sh [version]

if [ $# -eq 0 ]; then
    VERSION="1.4.3"
    echo "⚠️ Версия не указана, используем дефолтную: $VERSION"
else
    VERSION="$1"
fi

echo "🔧 Исправляем версию в package.json на: $VERSION"

# Проверяем существование package.json
if [ ! -f "package.json" ]; then
    echo "❌ package.json не найден"
    exit 1
fi

# Обновляем версию используя Node.js
node -e "
    const fs = require('fs');
    const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
    const oldVersion = pkg.version;
    pkg.version = '$VERSION';
    fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
    console.log('✅ Версия обновлена:', oldVersion, '→', '$VERSION');
"

# Проверяем результат
UPDATED_VERSION=$(node -p "require('./package.json').version" 2>/dev/null || echo "")
if [ "$UPDATED_VERSION" = "$VERSION" ]; then
    echo "✅ Версия успешно установлена: $VERSION"
else
    echo "❌ Ошибка при обновлении версии"
    exit 1
fi

echo ""
echo "📝 Для применения изменений:"
echo "  git add package.json"
echo "  git commit -m '🐛 fix: исправлена версия на $VERSION'"
echo "  git push origin main"