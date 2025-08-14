# 🚀 Руководство по созданию релизов MacPortScanner

## Проблема с GitHub Releases

GitHub автоматически создает только Source code архивы (zip/tar.gz), но не загружает DMG файлы. Для полноценного релиза нужно загрузить DMG файлы вручную.

## 📋 Пошаговая инструкция

### Вариант 1: Автоматический (рекомендуется)

Используйте dev-скрипты для автоматизации:

```bash
# 1. Обновите версию
./.dev-scripts/version-bump.sh

# 2. Соберите приложение
./build.sh

# 3. Создайте релиз с DMG файлами
./.dev-scripts/create-release.sh
```

### Вариант 2: Ручной

#### Шаг 1: Подготовка
```bash
# Убедитесь что версия обновлена в package.json
# Убедитесь что приложение собрано
./build.sh

# Проверьте наличие файлов
ls -la build/release/
```

#### Шаг 2: Создание тега
```bash
# Создайте и отправьте тег
git tag v1.0.1
git push origin v1.0.1
```

#### Шаг 3: Создание релиза на GitHub

1. Перейдите на https://github.com/iwizard7/MacPortScanner/releases
2. Нажмите **"Create a new release"**
3. Выберите тег: `v1.0.1`
4. Заполните:
   - **Title**: `MacPortScanner v1.0.1`
   - **Description**: Скопируйте из CHANGELOG.md

#### Шаг 4: Загрузка файлов

Перетащите следующие файлы в область "Attach binaries":

- `MacPortScanner-1.0.1-arm64.dmg` (для Apple Silicon)
- `MacPortScanner-1.0.1.dmg` (для Intel)
- `MacPortScanner-1.0.1-arm64-mac.zip` (ZIP для Apple Silicon)
- `MacPortScanner-1.0.1-mac.zip` (ZIP для Intel)

#### Шаг 5: Публикация
Нажмите **"Publish release"**

## 📦 Структура файлов релиза

```
build/release/
├── MacPortScanner-1.0.1-arm64.dmg      # DMG для Apple Silicon
├── MacPortScanner-1.0.1.dmg            # DMG для Intel
├── MacPortScanner-1.0.1-arm64-mac.zip  # ZIP для Apple Silicon
├── MacPortScanner-1.0.1-mac.zip        # ZIP для Intel
├── mac-arm64/
│   └── MacPortScanner.app               # Приложение для Apple Silicon
└── mac/
    └── MacPortScanner.app               # Приложение для Intel
```

## 🎯 Шаблон описания релиза

```markdown
## MacPortScanner v1.0.1

🚀 Профессиональный сканер портов для macOS с оптимизацией для Apple Silicon

### 📦 Файлы для скачивания

- **MacPortScanner-1.0.1-arm64.dmg** - Для Apple Silicon (M1/M2/M3) - Рекомендуется
- **MacPortScanner-1.0.1.dmg** - Для Intel Mac
- **ZIP архивы** - Альтернативный формат установки

### ✨ Что нового

- Исправлены ошибки сканирования
- Улучшена производительность на Apple Silicon
- Обновлен интерфейс

### 🔧 Системные требования

- macOS 10.15 (Catalina) или новее
- Рекомендуется: Apple Silicon для максимальной производительности

### 📝 Установка

1. Скачайте DMG файл для вашей архитектуры
2. Откройте DMG и перетащите приложение в папку Applications
3. Запустите MacPortScanner из Launchpad

### 🐛 Известные проблемы

- При первом запуске macOS может запросить разрешение на сетевые соединения
- Некоторые антивирусы могут блокировать сканирование портов

### 📊 Статистика

- Размер приложения: ~256 MB
- Поддерживаемые архитектуры: ARM64, x64
- Языки интерфейса: Русский, English
```

## 🤖 Автоматизация с GitHub CLI

Если установлен GitHub CLI:

```bash
# Установка GitHub CLI
brew install gh
gh auth login

# Создание релиза с файлами
gh release create v1.0.1 \
  --title "MacPortScanner v1.0.1" \
  --notes-file RELEASE_NOTES.md \
  build/release/MacPortScanner-1.0.1-arm64.dmg \
  build/release/MacPortScanner-1.0.1.dmg \
  build/release/MacPortScanner-1.0.1-arm64-mac.zip \
  build/release/MacPortScanner-1.0.1-mac.zip
```

## 🔍 Проверка релиза

После создания релиза проверьте:

1. ✅ Все файлы загружены
2. ✅ Размеры файлов корректны
3. ✅ Описание содержит всю необходимую информацию
4. ✅ Ссылки работают
5. ✅ DMG файлы открываются на macOS

## 📈 Аналитика релизов

GitHub предоставляет статистику скачиваний:
- Перейдите в Insights → Traffic
- Посмотрите статистику в разделе Releases

## 🚨 Troubleshooting

### DMG файлы не создаются
```bash
# Проверьте electron-builder
npm list electron-builder

# Пересоберите приложение
rm -rf build/ dist/
./build.sh
```

### GitHub CLI не работает
```bash
# Проверьте авторизацию
gh auth status

# Переавторизация
gh auth login --web
```

### Файлы слишком большие
GitHub имеет лимит 2GB на файл. Если файлы больше:
1. Оптимизируйте сборку
2. Используйте внешние хранилища (AWS S3, etc.)
3. Разбейте на части

## 📝 Чеклист релиза

- [ ] Версия обновлена в package.json
- [ ] CHANGELOG.md обновлен
- [ ] Приложение собрано (`./build.sh`)
- [ ] Все DMG файлы созданы
- [ ] Тег создан и отправлен на GitHub
- [ ] Релиз создан на GitHub
- [ ] Все файлы загружены в релиз
- [ ] Описание релиза заполнено
- [ ] Релиз протестирован на разных Mac
- [ ] Анонс в социальных сетях (опционально)

---

**Используйте dev-скрипты для автоматизации этого процесса!**