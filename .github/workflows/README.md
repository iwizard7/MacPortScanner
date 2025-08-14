# 🤖 GitHub Actions для MacPortScanner

Автоматизированные workflows для сборки, тестирования и релизов MacPortScanner.

## 📋 Доступные Workflows

### 1. 🚀 Build and Release (`release.yml`)

**Триггер**: Push тегов версий (`v*.*.*`)

**Что делает**:
- 🔨 Собирает приложение для macOS (ARM64 + Intel)
- 📦 Создает DMG и ZIP файлы
- 🚀 Автоматически создает GitHub Release
- 📝 Генерирует release notes из CHANGELOG.md

**Файлы релиза**:
- `MacPortScanner-X.X.X-arm64.dmg` - для Apple Silicon
- `MacPortScanner-X.X.X.dmg` - для Intel Mac
- `MacPortScanner-X.X.X-arm64-mac.zip` - ZIP для Apple Silicon
- `MacPortScanner-X.X.X-mac.zip` - ZIP для Intel Mac

### 2. 🔍 Build Check (`build-check.yml`)

**Триггер**: Push в `main`/`develop`, Pull Requests

**Что делает**:
- 🔍 Проверяет линтинг (ESLint)
- 🔧 Проверяет типы (TypeScript)
- 🔨 Тестирует сборку приложения
- 🧪 Проверяет electron-builder (dry run)

### 3. 📦 Auto Version Bump (`auto-version.yml`)

**Триггер**: Push в `main` (кроме коммитов с `[skip-version]`)

**Что делает**:
- 🔍 Анализирует коммит для определения типа версии
- 📦 Автоматически обновляет версию в package.json
- 📚 Обновляет CHANGELOG.md
- 🏷️ Создает и пушит git тег
- 🚀 Запускает workflow релиза

## 🎯 Логика версионирования

### Автоматическое определение типа версии:

| Ключевые слова в коммите | Тип версии | Пример |
|-------------------------|------------|---------|
| `BREAKING`, `💥`, `breaking` | **Major** | 1.0.0 → 2.0.0 |
| `feat`, `✨`, `feature`, `add` | **Minor** | 1.0.0 → 1.1.0 |
| `fix`, `🐛`, `bug`, `patch` | **Patch** | 1.0.0 → 1.0.1 |
| Остальные | **Patch** | 1.0.0 → 1.0.1 |

### Примеры коммитов:

```bash
# Major версия (1.0.0 → 2.0.0)
git commit -m "💥 BREAKING: redesign API interface"

# Minor версия (1.0.0 → 1.1.0)  
git commit -m "✨ feat: add UDP scanning support"

# Patch версия (1.0.0 → 1.0.1)
git commit -m "🐛 fix: resolve memory leak in scanner"

# Пропустить автоверсионирование
git commit -m "📝 docs: update README [skip-version]"
```

## 🚀 Workflow использования

### Автоматический релиз:
1. **Разработка** → Push коммитов в `main`
2. **Автоверсионирование** → Создается тег автоматически
3. **Сборка и релиз** → Автоматически создается GitHub Release

### Ручной релиз:
1. **Обновить версию** → `./.dev-scripts/version-bump.sh`
2. **Push тега** → `git push origin v1.2.3`
3. **Автоматическая сборка** → GitHub Action создает релиз

## 🔧 Настройка

### Требования:
- ✅ **macOS runner** для сборки нативных приложений
- ✅ **GITHUB_TOKEN** (автоматически доступен)
- ✅ **Node.js 18+** для сборки

### Переменные окружения:
```yaml
env:
  NODE_VERSION: '18'  # Версия Node.js
```

### Отключение подписания:
```yaml
env:
  CSC_IDENTITY_AUTO_DISCOVERY: false  # Отключает подписание в CI
```

## 📊 Мониторинг

### Статус workflows:
- 🟢 **Успешно** - все проверки прошли
- 🟡 **В процессе** - workflow выполняется
- 🔴 **Ошибка** - требует внимания

### Логи и отладка:
1. Перейдите в **Actions** на GitHub
2. Выберите нужный workflow run
3. Просмотрите логи каждого шага

## 🛠️ Кастомизация

### Изменение триггеров:
```yaml
on:
  push:
    branches: [ main, develop, feature/* ]  # Добавить ветки
    tags: [ 'v*.*.*', 'beta-*' ]           # Добавить теги
```

### Добавление уведомлений:
```yaml
- name: 📢 Slack Notification
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

### Добавление тестов:
```yaml
- name: 🧪 Run Tests
  run: npm test
```

## 🔒 Безопасность

### Secrets (не требуются):
- `GITHUB_TOKEN` - автоматически предоставляется GitHub

### Permissions:
```yaml
permissions:
  contents: write  # Для создания релизов
  actions: read    # Для чтения workflow статуса
```

## 🐛 Troubleshooting

### Проблема: Сборка не запускается
**Решение**: Проверьте формат тега (`v1.2.3`)

### Проблема: Файлы не загружаются в релиз
**Решение**: Проверьте пути к файлам в `build/release/`

### Проблема: Версия не обновляется автоматически
**Решение**: Убедитесь что коммит не содержит `[skip-version]`

### Проблема: electron-builder падает
**Решение**: Проверьте что все файлы (main.js, preload.js, index.html) созданы

## 📈 Статистика

Workflows автоматически собирают статистику:
- ⏱️ Время сборки
- 📦 Размеры файлов
- 🏷️ Количество релизов
- 📊 Успешность сборок

## 🎉 Результат

После настройки GitHub Actions:
- ✅ **Автоматические релизы** при push тегов
- ✅ **Проверка сборки** на каждый коммит
- ✅ **Автоверсионирование** по коммитам
- ✅ **DMG файлы** автоматически в релизах
- ✅ **Полная автоматизация** CI/CD процесса

---

**GitHub Actions готовы к использованию! 🚀**