# MacPortScanner Workflow Guide

Руководство по использованию единого скрипта автоматизации разработки.

## 🚀 Быстрый старт

### Полный цикл разработки
```bash
./workflow.sh --all
```
Выполняет: коммит → changelog → push → build → package

### Отдельные действия
```bash
./workflow.sh --commit           # Умный коммит
./workflow.sh --changelog        # Обновить changelog
./workflow.sh --push             # Отправить в GitHub
./workflow.sh --build            # Собрать приложение
./workflow.sh --package          # Создать DMG
```

## 📋 Подробное описание

### 1. Умный коммит (--commit)
- Анализирует изменения в коде
- Создает подробное сообщение коммита на русском языке
- Определяет тип изменений (UI, Core, документация и т.д.)
- Добавляет статистику изменений

### 2. Обновление changelog (--changelog)
- Автоматически увеличивает версию (patch/minor/major)
- Анализирует коммиты и группирует изменения
- Обновляет CHANGELOG.md и README.md
- Создает git тег для новой версии

### 3. Отправка в GitHub (--push)
- Отправляет коммиты в main ветку
- Отправляет теги версий
- Проверяет наличие удаленного репозитория

### 4. Сборка приложения (--build)
- Собирает Rust библиотеку в release режиме
- Собирает Swift приложение с Xcode
- Создает готовый .app файл в папке dist/

### 5. Создание DMG пакета (--package)
- Создает DMG файл для распространения
- Включает версию в имя файла
- Готов для загрузки на GitHub Releases

## ⚙️ Опции версионирования

### Типы версий
```bash
./workflow.sh --changelog --patch    # 1.0.0 → 1.0.1
./workflow.sh --changelog --minor    # 1.0.0 → 1.1.0
./workflow.sh --changelog --major    # 1.0.0 → 2.0.0
```

### Конкретная версия
```bash
./workflow.sh --changelog --version 2.1.0
```

## 🔧 Дополнительные опции

### Режимы выполнения
```bash
./workflow.sh --all --force         # Без подтверждения
./workflow.sh --all --quiet         # Минимум вывода
./workflow.sh --changelog --no-readme  # Не обновлять README
```

## 📁 Структура проекта

После реорганизации:
```
MacPortScanner/
├── build.sh              # Простая сборка для пользователей
├── workflow.sh            # Единый скрипт автоматизации
├── Makefile              # Обратная совместимость
├── WORKFLOW.md           # Это руководство
├── development/          # Файлы разработки (в .gitignore)
│   ├── smart-commit.sh
│   ├── update-changelog.sh
│   ├── create-dmg.sh
│   ├── build-local.sh
│   └── ...
├── Core/                 # Rust код
├── UI/                   # Swift UI
└── dist/                 # Результаты сборки
```

## 🎯 Типичные сценарии

### Ежедневная разработка
```bash
# Работаете над кодом...
# Готовы к коммиту:
./workflow.sh --commit --push
```

### Релиз новой версии
```bash
# Patch релиз (исправления)
./workflow.sh --changelog --patch --push

# Minor релиз (новые функции)
./workflow.sh --changelog --minor --build --package

# Major релиз (большие изменения)
./workflow.sh --all --major
```

### Только сборка
```bash
# Быстрая сборка для тестирования
./build.sh

# Полная сборка с DMG
./workflow.sh --build --package
```

## 🚨 Важные замечания

1. **Файлы разработки** теперь в папке `development/` и исключены из git
2. **Простой build.sh** для конечных пользователей в корне проекта
3. **Makefile** сохранен для обратной совместимости
4. **Автоматические коммиты** создаются при обновлении changelog
5. **Теги версий** создаются автоматически

## 🔄 Миграция со старых скриптов

Старые команды → Новые команды:
```bash
# Было:
./smart-commit.sh
./update-changelog.sh --minor
git push
make build
make dmg

# Стало:
./workflow.sh --all --minor
```

## 🆘 Помощь и отладка

```bash
./workflow.sh --help        # Полная справка
./workflow.sh --all --quiet # Тихий режим для отладки
```

При ошибках проверьте:
- Наличие изменений для коммита
- Настройку удаленного репозитория
- Установку Rust и Xcode tools
- Права доступа к файлам

## 📚 Дополнительные ресурсы

- [BUILD.md](BUILD.md) - Подробные инструкции по сборке
- [CHANGELOG.md](development/CHANGELOG.md) - История изменений
- [GitHub Issues](https://github.com/iwizard7/MacPortScanner/issues) - Сообщения об ошибках