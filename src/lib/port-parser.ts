/**
 * Утилиты для парсинга и валидации портов и диапазонов портов
 */

export interface PortRange {
  start: number;
  end: number;
}

export interface ParsedPorts {
  individual: number[];
  ranges: PortRange[];
  expanded: number[];
  total: number;
}

export interface ValidationResult {
  isValid: boolean;
  errors: string[];
  warnings: string[];
  portCount: number;
}

export class PortValidationError extends Error {
  constructor(
    message: string,
    public code: string,
    public field?: string
  ) {
    super(message);
    this.name = 'PortValidationError';
  }
}

export class PortParser {
  private static readonly MIN_PORT = 1;
  private static readonly MAX_PORT = 65535;
  private static readonly WARNING_THRESHOLD = 100;
  private static readonly DANGER_THRESHOLD = 1000;

  /**
   * Парсит строку с портами и диапазонами
   * Поддерживает форматы: "22,80,443", "22-25", "22,80-90,443"
   */
  static parse(input: string): ParsedPorts {
    if (!input || typeof input !== 'string') {
      return {
        individual: [],
        ranges: [],
        expanded: [],
        total: 0
      };
    }

    const individual: number[] = [];
    const ranges: PortRange[] = [];
    
    // Очищаем строку от лишних пробелов и разбиваем по запятым
    const parts = input
      .trim()
      .split(',')
      .map(part => part.trim())
      .filter(part => part.length > 0);

    for (const part of parts) {
      if (part.includes('-')) {
        // Это диапазон
        const rangeParts = part.split('-').map(p => p.trim());
        
        if (rangeParts.length !== 2) {
          throw new PortValidationError(
            `Неверный формат диапазона: ${part}`,
            'INVALID_RANGE_FORMAT',
            part
          );
        }

        const start = parseInt(rangeParts[0], 10);
        const end = parseInt(rangeParts[1], 10);

        if (isNaN(start) || isNaN(end)) {
          throw new PortValidationError(
            `Диапазон содержит некорректные числа: ${part}`,
            'INVALID_PORT_NUMBER',
            part
          );
        }

        this.validatePort(start);
        this.validatePort(end);
        this.validateRange(start, end);

        ranges.push({ start, end });
      } else {
        // Это отдельный порт
        const port = parseInt(part, 10);
        
        if (isNaN(port)) {
          throw new PortValidationError(
            `Некорректный номер порта: ${part}`,
            'INVALID_PORT_NUMBER',
            part
          );
        }

        this.validatePort(port);
        individual.push(port);
      }
    }

    // Развертываем диапазоны и объединяем с отдельными портами
    const expandedRanges = this.expandRanges(ranges);
    const allPorts = [...individual, ...expandedRanges];
    
    // Удаляем дубликаты и сортируем
    const expanded = [...new Set(allPorts)].sort((a, b) => a - b);

    return {
      individual,
      ranges,
      expanded,
      total: expanded.length
    };
  }

  /**
   * Развертывает диапазоны портов в массивы
   */
  static expandRanges(ranges: PortRange[]): number[] {
    const expanded: number[] = [];
    
    for (const range of ranges) {
      for (let port = range.start; port <= range.end; port++) {
        expanded.push(port);
      }
    }
    
    return expanded;
  }

  /**
   * Валидирует отдельный порт
   */
  static validatePort(port: number): void {
    if (port < this.MIN_PORT || port > this.MAX_PORT) {
      throw new PortValidationError(
        `Порт должен быть в диапазоне ${this.MIN_PORT}-${this.MAX_PORT}`,
        'PORT_OUT_OF_RANGE',
        port.toString()
      );
    }
  }

  /**
   * Валидирует диапазон портов
   */
  static validateRange(start: number, end: number): void {
    if (start > end) {
      throw new PortValidationError(
        `Начальный порт (${start}) не может быть больше конечного (${end})`,
        'INVALID_RANGE_ORDER'
      );
    }
  }

  /**
   * Выполняет полную валидацию строки с портами
   */
  static validate(input: string): ValidationResult {
    const errors: string[] = [];
    const warnings: string[] = [];
    let portCount = 0;

    try {
      const parsed = this.parse(input);
      portCount = parsed.total;

      // Проверяем предупреждения
      if (portCount > this.DANGER_THRESHOLD) {
        warnings.push(
          `Сканирование ${portCount} портов может занять очень много времени. Рекомендуется использовать меньший диапазон.`
        );
      } else if (portCount > this.WARNING_THRESHOLD) {
        warnings.push(
          `Сканирование ${portCount} портов может занять продолжительное время.`
        );
      }

      return {
        isValid: true,
        errors,
        warnings,
        portCount
      };
    } catch (error) {
      if (error instanceof PortValidationError) {
        errors.push(error.message);
      } else {
        errors.push('Неизвестная ошибка при парсинге портов');
      }

      return {
        isValid: false,
        errors,
        warnings,
        portCount: 0
      };
    }
  }

  /**
   * Проверяет, является ли строка пустой или содержит только пробелы
   */
  static isEmpty(input: string): boolean {
    return !input || input.trim().length === 0;
  }

  /**
   * Форматирует список портов для отображения
   */
  static formatPortList(ports: number[], maxDisplay: number = 10): string {
    if (ports.length === 0) return '';
    
    if (ports.length <= maxDisplay) {
      return ports.join(', ');
    }
    
    const displayed = ports.slice(0, maxDisplay);
    const remaining = ports.length - maxDisplay;
    return `${displayed.join(', ')} и еще ${remaining}`;
  }
}

/**
 * Предустановленные наборы портов
 */
export const PORT_PRESETS = {
  popular: {
    label: 'Популярные',
    ports: '22,80,443,3389',
    description: 'SSH, HTTP, HTTPS, RDP'
  },
  webServers: {
    label: 'Веб-серверы',
    ports: '80-90,443,8000-8080,8443',
    description: 'HTTP, HTTPS и альтернативные веб-порты'
  },
  databases: {
    label: 'Базы данных',
    ports: '3306,5432,1433,27017,6379',
    description: 'MySQL, PostgreSQL, SQL Server, MongoDB, Redis'
  },
  mailServers: {
    label: 'Почтовые серверы',
    ports: '25,110,143,993,995',
    description: 'SMTP, POP3, IMAP'
  },
  commonServices: {
    label: 'Общие сервисы',
    ports: '21,22,23,25,53,80,110,143,443,993,995',
    description: 'FTP, SSH, Telnet, SMTP, DNS, HTTP, POP3, IMAP, HTTPS'
  },
  allPorts: {
    label: 'Все порты (ОСТОРОЖНО!)',
    ports: '1-65535',
    description: 'Полное сканирование всех портов - очень медленно!'
  }
} as const;

export type PresetKey = keyof typeof PORT_PRESETS;