/**
 * Unit тесты для PortParser
 */

import { PortParser, PortValidationError, PORT_PRESETS } from '../port-parser';

describe('PortParser', () => {
  describe('parse', () => {
    test('парсит отдельные порты', () => {
      const result = PortParser.parse('22,80,443');
      
      expect(result.individual).toEqual([22, 80, 443]);
      expect(result.ranges).toEqual([]);
      expect(result.expanded).toEqual([22, 80, 443]);
      expect(result.total).toBe(3);
    });

    test('парсит простой диапазон', () => {
      const result = PortParser.parse('22-25');
      
      expect(result.individual).toEqual([]);
      expect(result.ranges).toEqual([{ start: 22, end: 25 }]);
      expect(result.expanded).toEqual([22, 23, 24, 25]);
      expect(result.total).toBe(4);
    });

    test('парсит комбинированный ввод', () => {
      const result = PortParser.parse('22,80-83,443');
      
      expect(result.individual).toEqual([22, 443]);
      expect(result.ranges).toEqual([{ start: 80, end: 83 }]);
      expect(result.expanded).toEqual([22, 80, 81, 82, 83, 443]);
      expect(result.total).toBe(6);
    });

    test('удаляет дубликаты и сортирует', () => {
      const result = PortParser.parse('80,22,80-82,443');
      
      expect(result.expanded).toEqual([22, 80, 81, 82, 443]);
      expect(result.total).toBe(5);
    });

    test('игнорирует лишние пробелы', () => {
      const result = PortParser.parse(' 22 , 80 - 82 , 443 ');
      
      expect(result.expanded).toEqual([22, 80, 81, 82, 443]);
      expect(result.total).toBe(5);
    });

    test('обрабатывает одинаковые порты в диапазоне', () => {
      const result = PortParser.parse('22-22');
      
      expect(result.ranges).toEqual([{ start: 22, end: 22 }]);
      expect(result.expanded).toEqual([22]);
      expect(result.total).toBe(1);
    });

    test('возвращает пустой результат для пустой строки', () => {
      const result = PortParser.parse('');
      
      expect(result.individual).toEqual([]);
      expect(result.ranges).toEqual([]);
      expect(result.expanded).toEqual([]);
      expect(result.total).toBe(0);
    });

    test('возвращает пустой результат для null/undefined', () => {
      const result1 = PortParser.parse(null as any);
      const result2 = PortParser.parse(undefined as any);
      
      expect(result1.total).toBe(0);
      expect(result2.total).toBe(0);
    });
  });

  describe('валидация ошибок', () => {
    test('выбрасывает ошибку для некорректного номера порта', () => {
      expect(() => PortParser.parse('abc')).toThrow(PortValidationError);
      expect(() => PortParser.parse('22,abc,443')).toThrow(PortValidationError);
    });

    test('выбрасывает ошибку для порта вне диапазона', () => {
      expect(() => PortParser.parse('0')).toThrow(PortValidationError);
      expect(() => PortParser.parse('65536')).toThrow(PortValidationError);
      expect(() => PortParser.parse('-1')).toThrow(PortValidationError);
    });

    test('выбрасывает ошибку для неверного порядка в диапазоне', () => {
      expect(() => PortParser.parse('80-22')).toThrow(PortValidationError);
    });

    test('выбрасывает ошибку для неверного формата диапазона', () => {
      expect(() => PortParser.parse('22--80')).toThrow(PortValidationError);
      expect(() => PortParser.parse('22-80-90')).toThrow(PortValidationError);
    });

    test('выбрасывает ошибку для диапазона с некорректными числами', () => {
      expect(() => PortParser.parse('22-abc')).toThrow(PortValidationError);
      expect(() => PortParser.parse('abc-80')).toThrow(PortValidationError);
    });
  });

  describe('expandRanges', () => {
    test('развертывает простой диапазон', () => {
      const ranges = [{ start: 22, end: 25 }];
      const result = PortParser.expandRanges(ranges);
      
      expect(result).toEqual([22, 23, 24, 25]);
    });

    test('развертывает множественные диапазоны', () => {
      const ranges = [
        { start: 22, end: 24 },
        { start: 80, end: 82 }
      ];
      const result = PortParser.expandRanges(ranges);
      
      expect(result).toEqual([22, 23, 24, 80, 81, 82]);
    });

    test('развертывает диапазон из одного порта', () => {
      const ranges = [{ start: 22, end: 22 }];
      const result = PortParser.expandRanges(ranges);
      
      expect(result).toEqual([22]);
    });

    test('возвращает пустой массив для пустого ввода', () => {
      const result = PortParser.expandRanges([]);
      
      expect(result).toEqual([]);
    });
  });

  describe('validatePort', () => {
    test('принимает корректные порты', () => {
      expect(() => PortParser.validatePort(1)).not.toThrow();
      expect(() => PortParser.validatePort(80)).not.toThrow();
      expect(() => PortParser.validatePort(65535)).not.toThrow();
    });

    test('отклоняет некорректные порты', () => {
      expect(() => PortParser.validatePort(0)).toThrow(PortValidationError);
      expect(() => PortParser.validatePort(-1)).toThrow(PortValidationError);
      expect(() => PortParser.validatePort(65536)).toThrow(PortValidationError);
    });
  });

  describe('validateRange', () => {
    test('принимает корректные диапазоны', () => {
      expect(() => PortParser.validateRange(22, 80)).not.toThrow();
      expect(() => PortParser.validateRange(22, 22)).not.toThrow();
    });

    test('отклоняет некорректные диапазоны', () => {
      expect(() => PortParser.validateRange(80, 22)).toThrow(PortValidationError);
    });
  });

  describe('validate', () => {
    test('возвращает успешную валидацию для корректного ввода', () => {
      const result = PortParser.validate('22,80,443');
      
      expect(result.isValid).toBe(true);
      expect(result.errors).toEqual([]);
      expect(result.portCount).toBe(3);
    });

    test('возвращает предупреждение для большого количества портов', () => {
      const result = PortParser.validate('1-200');
      
      expect(result.isValid).toBe(true);
      expect(result.warnings.length).toBeGreaterThan(0);
      expect(result.portCount).toBe(200);
    });

    test('возвращает серьезное предупреждение для очень большого количества портов', () => {
      const result = PortParser.validate('1-2000');
      
      expect(result.isValid).toBe(true);
      expect(result.warnings.length).toBeGreaterThan(0);
      expect(result.warnings[0]).toContain('очень много времени');
      expect(result.portCount).toBe(2000);
    });

    test('возвращает ошибку для некорректного ввода', () => {
      const result = PortParser.validate('abc');
      
      expect(result.isValid).toBe(false);
      expect(result.errors.length).toBeGreaterThan(0);
      expect(result.portCount).toBe(0);
    });
  });

  describe('isEmpty', () => {
    test('определяет пустые строки', () => {
      expect(PortParser.isEmpty('')).toBe(true);
      expect(PortParser.isEmpty('   ')).toBe(true);
      expect(PortParser.isEmpty('\t\n')).toBe(true);
    });

    test('определяет непустые строки', () => {
      expect(PortParser.isEmpty('22')).toBe(false);
      expect(PortParser.isEmpty(' 22 ')).toBe(false);
    });
  });

  describe('formatPortList', () => {
    test('форматирует короткий список', () => {
      const result = PortParser.formatPortList([22, 80, 443]);
      
      expect(result).toBe('22, 80, 443');
    });

    test('обрезает длинный список', () => {
      const ports = Array.from({ length: 15 }, (_, i) => i + 1);
      const result = PortParser.formatPortList(ports, 5);
      
      expect(result).toBe('1, 2, 3, 4, 5 и еще 10');
    });

    test('возвращает пустую строку для пустого массива', () => {
      const result = PortParser.formatPortList([]);
      
      expect(result).toBe('');
    });
  });

  describe('PORT_PRESETS', () => {
    test('содержит все необходимые предустановки', () => {
      expect(PORT_PRESETS.popular).toBeDefined();
      expect(PORT_PRESETS.webServers).toBeDefined();
      expect(PORT_PRESETS.databases).toBeDefined();
      expect(PORT_PRESETS.mailServers).toBeDefined();
      expect(PORT_PRESETS.commonServices).toBeDefined();
      expect(PORT_PRESETS.allPorts).toBeDefined();
    });

    test('все предустановки имеют корректную структуру', () => {
      Object.values(PORT_PRESETS).forEach(preset => {
        expect(preset.label).toBeDefined();
        expect(preset.ports).toBeDefined();
        expect(preset.description).toBeDefined();
        
        // Проверяем что порты можно распарсить
        expect(() => PortParser.parse(preset.ports)).not.toThrow();
      });
    });

    test('популярные порты парсятся корректно', () => {
      const result = PortParser.parse(PORT_PRESETS.popular.ports);
      
      expect(result.expanded).toEqual([22, 80, 443, 3389]);
    });

    test('веб-серверы содержат диапазоны', () => {
      const result = PortParser.parse(PORT_PRESETS.webServers.ports);
      
      expect(result.ranges.length).toBeGreaterThan(0);
      expect(result.total).toBeGreaterThan(10);
    });
  });
});