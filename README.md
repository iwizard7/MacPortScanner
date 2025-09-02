# MacPortScanner

<div align="center">

![MacPortScanner Logo](https://img.shields.io/badge/MacPortScanner-v1.4.2-blue?style=for-the-badge&logo=apple)

**🚀 Профессиональный сканер портов для macOS с оптимизацией для Apple Silicon**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![macOS](https://img.shields.io/badge/macOS-10.15+-blue.svg)](https://www.apple.com/macos/)
[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-Optimized-green.svg)](https://www.apple.com/mac/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.0+-blue.svg)](https://www.typescriptlang.org/)
[![Electron](https://img.shields.io/badge/Electron-28+-purple.svg)](https://www.electronjs.org/)

[Скачать](https://github.com/iwizard7/MacPortScanner/releases) • [Документация](#документация) • [Примеры](#примеры-использования) • [Поддержка](#поддержка)

</div>

## 📦 Установка

### Скачивание

1. Перейдите на страницу [Releases](https://github.com/iwizard7/MacPortScanner/releases)
2. Скачайте подходящий файл:
   - **MacPortScanner-X.X.X-arm64.dmg** - для Apple Silicon (M1/M2/M3)
   - **MacPortScanner-X.X.X.dmg** - для Intel Mac

### Первый запуск

⚠️ **Важно**: При первом запуске macOS может показать предупреждение о безопасности.

**Решение:**
1. **Способ 1**: Щелкните правой кнопкой по приложению → **"Открыть"** → **"Открыть"**
2. **Способ 2**: Откройте **Терминал** и выполните:
   ```bash
   xattr -cr /Applications/MacPortScanner.app
   ```
3. **Способ 3**: **Системные настройки** → **Защита и безопасность** → **Основные** → **"Все равно открыть"**

### Системные требования

- macOS 10.15 (Catalina) или новее
- Рекомендуется: Apple Silicon для максимальной производительности

## ✨ Особенности

- 🚀 **Оптимизация для Apple Silicon** - До 100 параллельных соединений на M1/M2/M3
- 🎨 **Нативный macOS интерфейс** - Современный UI в стиле macOS с темной темой
- ⚡ **Высокая производительность** - Асинхронное сканирование с контролем нагрузки
- 🔧 **Гибкие настройки** - TCP/SYN/UDP сканирование, настраиваемые таймауты
- 💾 **Автосохранение** - Сохранение пользовательских настроек
- 📊 **Экспорт результатов** - JSON и CSV форматы
- ⌨️ **Горячие клавиши** - Быстрый доступ к функциям
- 🌐 **Диапазоны IP** - Сканирование одиночных IP и подсетей
- 🔒 **Безопасность** - Контекстная изоляция Electron

## 📋 Системные требования

- **macOS**: 10.15 (Catalina) или новее
- **Архитектура**: Apple Silicon (M1/M2/M3) или Intel
- **RAM**: Рекомендуется 8 GB
- **Место на диске**: ~300 MB

## 🚀 Быстрый старт

### Готовые приложения

Скачайте готовое приложение из [Releases](https://github.com/iwizard7/MacPortScanner/releases):

- **Apple Silicon (M1/M2/M3)**: `MacPortScanner-1.4.2-arm64.dmg`
- **Intel Mac**: `MacPortScanner-1.4.2.dmg`

### Установка

1. Скачайте DMG файл для вашей архитектуры
2. Откройте DMG и перетащите приложение в папку Applications
3. Запустите MacPortScanner из Launchpad

### Разработка

```bash
# Клонирование репозитория
git clone https://github.com/iwizard7/MacPortScanner.git
cd MacPortScanner

# Установка зависимостей
npm install

# Запуск в режиме разработки
npm run dev

# Сборка приложения
npm run build:mac
```

## 🎯 Использование

### Основные функции

| Функция | Горячая клавиша | Описание |
|---------|----------------|----------|
| Быстрое сканирование | `⌘+Q` | Сканирование популярных портов |
| Полное сканирование | `⌘+F` | Сканирование портов 1-1000 |
| Остановка | `⌘+S` | Прерывание сканирования |
| Экспорт | `⌘+E` | Сохранение результатов |

### Методы сканирования

- **TCP Connect** - Стандартное TCP соединение (рекомендуется)
- **SYN Scan** - Быстрое SYN сканирование (требует sudo)
- **UDP Scan** - Сканирование UDP портов

### Настройки

- **Таймаут**: 100-10000 мс (по умолчанию 3000 мс)
- **Параллелизм**: Автоматически оптимизируется для архитектуры
- **Порты**: Список через запятую или диапазоны (например: `80,443,8000-8080`)

## 📊 Производительность

### Оптимизации для Apple Silicon

MacPortScanner автоматически определяет архитектуру процессора:

| Архитектура | Параллельные соединения | Производительность |
|-------------|------------------------|-------------------|
| Apple Silicon (ARM64) | 100 | 🚀 Максимальная |
| Intel (x64) | 50 | ⚡ Высокая |

### Бенчмарки

- **Локальная сеть**: ~1000 портов за 10-15 секунд
- **Интернет**: ~100 портов за 30-60 секунд
- **Память**: ~50-100 MB во время сканирования

## 🏗️ Архитектура

```
MacPortScanner/
├── src/
│   ├── main.ts          # Главный процесс Electron
│   ├── preload.ts       # IPC мост
│   ├── App.tsx          # React приложение
│   ├── main.tsx         # Точка входа React
│   ├── components/ui/   # UI компоненты
│   └── lib/            # Утилиты
├── build/              # Сборка (игнорируется Git)
├── package.json        # Конфигурация проекта
└── README.md          # Документация
```

### Технологический стек

- **Frontend**: React 18 + TypeScript + Tailwind CSS
- **Backend**: Electron 28 + Node.js
- **UI**: Radix UI + shadcn/ui компоненты
- **Сборка**: Vite + electron-builder
- **Сканирование**: Node.js net модуль

## 🔒 Безопасность

- **Контекстная изоляция** Electron для защиты от XSS
- **IPC коммуникация** через безопасные каналы
- **Валидация входных данных** на всех уровнях
- **Нет прямого доступа** к Node.js API из рендера
- **Песочница** для веб-контента

## 📖 Примеры использования

### Сканирование локального сервера

```
IP: 127.0.0.1
Порты: 22,80,443,3306,5432
Метод: TCP Connect
Таймаут: 1000 мс
```

### Аудит домашней сети

```
IP: 192.168.1.1-254
Порты: 22,23,80,443,8080
Метод: TCP Connect
Таймаут: 2000 мс
```

### Проверка веб-сервера

```
IP: example.com
Порты: 80,443,8080,8443,3000
Метод: TCP Connect
Таймаут: 5000 мс
```

## 🛠️ Разработка

### Структура проекта

- **Electron Main Process** - Системные вызовы и сканирование
- **React Frontend** - Пользовательский интерфейс
- **IPC Communication** - Безопасная связь процессов
- **Electron Store** - Сохранение настроек

### Команды разработки

```bash
# Разработка
npm run dev              # Запуск в режиме разработки
npm run dev:electron     # Только Electron процесс
npm run dev:react        # Только React приложение

# Сборка
npm run build           # Полная сборка
npm run build:electron  # Сборка Electron
npm run build:react     # Сборка React

# Создание приложения
npm run build:mac       # Для текущей архитектуры
npm run build:mac-arm64 # Только Apple Silicon
npm run build:mac-universal # Универсальная сборка

# Тестирование
npm run lint           # ESLint
npm run type-check     # TypeScript проверка
./test-app.sh         # Тестирование собранного приложения
```

### 🤖 CI/CD с GitHub Actions

**Автоматизированные процессы:**

- 🔍 **Build Check** - проверка сборки на каждый push
- 📦 **Auto Version** - автоматическое версионирование по коммитам  
- 🚀 **Release** - автоматическая сборка и публикация DMG файлов

```bash
# Автоматический релиз
git commit -m "✨ feat: add new scanning feature"
git push origin main
# → Автоматически создается версия и релиз

# Ручной релиз  
./.dev-scripts/version-bump.sh
git push origin v1.2.3
# → Автоматически собирается и публикуется
```

**Логика версионирования:**
- `💥 BREAKING` → Major (1.0.0 → 2.0.0)
- `✨ feat` → Minor (1.0.0 → 1.1.0)
- `🐛 fix` → Patch (1.0.0 → 1.0.1)

### Добавление функций

1. **IPC обработчик** в `src/main.ts`
2. **Типы** в `src/preload.ts`
3. **UI логика** в `src/App.tsx`
4. **Компоненты** в `src/components/ui/`

## 📝 Changelog

### v1.4.2 (2025-09-02)

- ✨ Интегрирован PortInput компонент в основное приложение
- 🔧 Обновлены типы ScanRequest с полями portInput и portCount
- 🎨 Добавлена валидация портов в реальном времени в UI
- ⚡ Кнопка сканирования отключается при ошибках валидации
- 🐛 Исправлены все ошибки TypeScript в App.tsx
- 💾 Обновлены обработчики сохранения настроек
- 🌐 Поддержка диапазонов портов теперь полностью интегрирована

## 🤝 Вклад в проект

Мы приветствуем вклад в развитие MacPortScanner!

1. Fork репозитория
2. Создайте feature branch (`git checkout -b feature/amazing-feature`)
3. Commit изменения (`git commit -m 'Add amazing feature'`)
4. Push в branch (`git push origin feature/amazing-feature`)
5. Откройте Pull Request

### Правила разработки

- Используйте TypeScript для типобезопасности
- Следуйте ESLint правилам
- Добавляйте тесты для новых функций
- Обновляйте документацию

## 📄 Лицензия

Этот проект лицензирован под MIT License - см. файл [LICENSE](LICENSE) для деталей.

## 🆘 Поддержка

### Получить помощь

- 📖 [Документация](https://github.com/iwizard7/MacPortScanner/wiki)
- 🐛 [Сообщить об ошибке](https://github.com/iwizard7/MacPortScanner/issues)
- 💡 [Предложить функцию](https://github.com/iwizard7/MacPortScanner/issues)
- 💬 [Обсуждения](https://github.com/iwizard7/MacPortScanner/discussions)

### FAQ

**Q: Почему приложение не запускается?**
A: Убедитесь, что у вас macOS 10.15+ и разрешите запуск в System Preferences → Security & Privacy.

**Q: Можно ли сканировать IPv6?**
A: В текущей версии поддерживается только IPv4. IPv6 планируется в будущих версиях.

**Q: Безопасно ли использовать приложение?**
A: Да, приложение использует современные практики безопасности Electron и не собирает личные данные.

## 🙏 Благодарности

- [Electron](https://www.electronjs.org/) - Кроссплатформенные приложения
- [React](https://reactjs.org/) - UI библиотека
- [Tailwind CSS](https://tailwindcss.com/) - CSS фреймворк
- [Radix UI](https://www.radix-ui.com/) - UI компоненты
- [Vite](https://vitejs.dev/) - Быстрая сборка

---

<div align="center">

**Сделано с ❤️ для macOS сообщества**

[⭐ Поставьте звезду](https://github.com/iwizard7/MacPortScanner) если проект вам понравился!

</div>

## 📝 Последние изменения

### v1.4.2 - 2025-09-02

✨ **Интеграция валидации портов**
- 🎯 Полностью интегрирован PortInput компонент с валидацией в реальном времени
- 🔧 Обновлены типы для поддержки диапазонов портов и подсчета
- 🎨 Улучшен пользовательский интерфейс с цветовой индикацией валидации
- ⚡ Автоматическое отключение кнопки сканирования при ошибках
- 🐛 Исправлены все TypeScript ошибки в основном приложении
- 💾 Улучшена система сохранения пользовательских настроек

📋 **Документация:**
- [Полный changelog](CHANGELOG.md)
- [Руководство по релизам](RELEASE_GUIDE.md)
