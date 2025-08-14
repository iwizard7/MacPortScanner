# MacPortScanner Makefile
# Простой Makefile для обратной совместимости

.PHONY: help build quick dev test run clean package all

help:
	@echo "MacPortScanner Build System"
	@echo "==========================="
	@echo ""
	@echo "Основные команды:"
	@echo "  make build     - Простая сборка приложения"
	@echo "  make run       - Собрать и запустить"
	@echo "  make package   - Создать DMG пакет"
	@echo "  make clean     - Очистить артефакты сборки"
	@echo "  make all       - Полный цикл (build + package)"
	@echo ""
	@echo "Workflow команды:"
	@echo "  make dev       - Полный цикл разработки"
	@echo "  make commit    - Создать умный коммит"
	@echo "  make changelog - Обновить changelog"
	@echo "  make push      - Отправить в GitHub"
	@echo ""
	@echo "Для расширенных возможностей используйте:"
	@echo "  ./workflow.sh --help"

build:
	@echo "🚀 Сборка MacPortScanner..."
	./build.sh

quick: build

run: build
	@echo "🚀 Запуск MacPortScanner..."
	open dist/MacPortScanner.app

package:
	@echo "📦 Создание DMG пакета..."
	./workflow.sh --package

clean:
	@echo "🧹 Очистка артефактов сборки..."
	rm -rf dist/
	rm -rf Core/target/
	rm -rf UI/build/
	rm -f *.dmg

all: build package

# Workflow команды
dev:
	@echo "🔄 Полный цикл разработки..."
	./workflow.sh --all

commit:
	@echo "💾 Создание умного коммита..."
	./workflow.sh --commit

changelog:
	@echo "📝 Обновление changelog..."
	./workflow.sh --changelog

push:
	@echo "📤 Отправка в GitHub..."
	./workflow.sh --push

test:
	@echo "🧪 Запуск тестов..."
	cd Core && cargo test
	@echo "✅ Тесты пройдены"

check:
	@echo "🔍 Проверка качества кода..."
	cd Core && cargo clippy -- -D warnings
	cd Core && cargo fmt --check
	@echo "✅ Проверки пройдены"