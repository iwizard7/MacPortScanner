#!/bin/bash

# MacPortScanner Workflow Wrapper
# Простая обертка для запуска основного workflow скрипта

# Проверяем наличие основного скрипта
if [ ! -f "Development/dev-workflow.sh" ]; then
    echo "❌ Скрипт Development/dev-workflow.sh не найден"
    echo "Убедитесь, что вы находитесь в корне проекта MacPortScanner"
    exit 1
fi

# Делаем скрипт исполняемым
chmod +x Development/dev-workflow.sh

# Передаем все аргументы основному скрипту
exec ./Development/dev-workflow.sh "$@"