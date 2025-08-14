# Установка Mac Port Scanner Silicon

## Быстрый старт

### Автоматическая установка и запуск

```bash
# Перейдите в папку проекта
cd mac-port-scanner-silicon

# Запустите скрипт автоматической установки
./start.sh
```

Скрипт автоматически:
- Проверит системные требования
- Установит зависимости
- Скомпилирует приложение
- Запустит в режиме разработки

### Ручная установка

1. **Установите Node.js 18+**
   ```bash
   # Через Homebrew (рекомендуется)
   brew install node
   
   # Или скачайте с https://nodejs.org/
   ```

2. **Установите зависимости**
   ```bash
   npm install
   ```

3. **Запустите приложение**
   ```bash
   npm run dev
   ```

## Сборка готового приложения

### Автоматическая сборка

```bash
# Сборка для текущей архитектуры
./build.sh

# Сборка только для Apple Silicon
./build.sh arm64

# Универсальная сборка (Intel + Apple Silicon)
./build.sh universal
```

### Ручная сборка

```bash
# Компиляция TypeScript
npx tsc

# Сборка React приложения
npm run build

# Сборка Electron приложения
npm run build:mac
```

## Системные требования

### Минимальные требования
- **macOS**: 10.15 (Catalina) или новее
- **RAM**: 4 GB
- **Свободное место**: 500 MB

### Рекомендуемые требования
- **macOS**: 12.0 (Monterey) или новее
- **Процессор**: Apple Silicon (M1/M2/M3) для максимальной производительности
- **RAM**: 8 GB или больше
- **Свободное место**: 1 GB

## Установка зависимостей для разработки

### Node.js и npm

**Через Homebrew (рекомендуется):**
```bash
# Установка Homebrew (если не установлен)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Установка Node.js
brew install node

# Проверка установки
node --version
npm --version
```

**Через официальный сайт:**
1. Перейдите на https://nodejs.org/
2. Скачайте LTS версию для macOS
3. Установите пакет
4. Перезапустите терминал

### Дополнительные инструменты

**TypeScript (глобально):**
```bash
npm install -g typescript
```

**Electron Builder (для сборки):**
```bash
npm install -g electron-builder
```

## Устранение проблем

### Проблема: "command not found: node"

**Решение:**
```bash
# Проверьте PATH
echo $PATH

# Добавьте Node.js в PATH (для zsh)
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Для bash
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile
```

### Проблема: "Permission denied" при запуске скриптов

**Решение:**
```bash
# Дайте права на выполнение
chmod +x start.sh
chmod +x build.sh
```

### Проблема: Ошибки при установке зависимостей

**Решение:**
```bash
# Очистите кэш npm
npm cache clean --force

# Удалите node_modules и переустановите
rm -rf node_modules
rm package-lock.json
npm install
```

### Проблема: Приложение не запускается

**Решение:**
```bash
# Проверьте логи
npm run dev

# Проверьте версию Node.js
node --version

# Убедитесь, что все зависимости установлены
npm list --depth=0
```

### Проблема: Медленное сканирование

**Оптимизация:**
1. Убедитесь, что используете Apple Silicon Mac для максимальной производительности
2. Уменьшите таймаут в настройках
3. Сканируйте меньше портов одновременно
4. Проверьте сетевое соединение

## Безопасность

### Права доступа

Приложение может запросить следующие разрешения:
- **Сетевой доступ** - для сканирования портов
- **Доступ к файлам** - для экспорта результатов

### Брандмауэр

При первом запуске macOS может запросить разрешение на сетевые соединения. Нажмите "Разрешить" для корректной работы сканера.

### Антивирус

Некоторые антивирусы могут блокировать сканирование портов. Добавьте приложение в исключения если возникают проблемы.

## Обновление

### Обновление зависимостей

```bash
# Проверка устаревших пакетов
npm outdated

# Обновление всех зависимостей
npm update

# Обновление конкретного пакета
npm install package-name@latest
```

### Обновление Node.js

```bash
# Через Homebrew
brew upgrade node

# Проверка версии
node --version
```

## Поддержка

Если у вас возникли проблемы:

1. Проверьте [README.md](README.md) для основной информации
2. Убедитесь, что выполнены все системные требования
3. Попробуйте переустановить зависимости
4. Создайте issue в GitHub репозитории

## Полезные команды

```bash
# Проверка системы
system_profiler SPSoftwareDataType
uname -m

# Проверка Node.js
node --version
npm --version

# Очистка проекта
npm run clean  # если добавлен скрипт
rm -rf node_modules dist release

# Полная переустановка
rm -rf node_modules package-lock.json
npm install
```