/**
 * Тесты для хука usePortValidation
 */

import { renderHook, act } from '@testing-library/react';
import { usePortValidation } from '../usePortValidation';

describe('usePortValidation', () => {
  test('инициализируется с пустым состоянием', () => {
    const { result } = renderHook(() => usePortValidation());
    
    expect(result.current.isValid).toBe(true);
    expect(result.current.errors).toEqual([]);
    expect(result.current.warnings).toEqual([]);
    expect(result.current.portCount).toBe(0);
    expect(result.current.parsed).toBeNull();
  });

  test('валидирует корректный ввод', () => {
    const { result } = renderHook(() => usePortValidation());
    
    act(() => {
      result.current.validate('22,80,443');
    });
    
    expect(result.current.isValid).toBe(true);
    expect(result.current.errors).toEqual([]);
    expect(result.current.portCount).toBe(3);
    expect(result.current.parsed).toEqual({
      individual: [22, 80, 443],
      ranges: [],
      expanded: [22, 80, 443],
      total: 3
    });
  });

  test('валидирует диапазоны портов', () => {
    const { result } = renderHook(() => usePortValidation());
    
    act(() => {
      result.current.validate('22-25');
    });
    
    expect(result.current.isValid).toBe(true);
    expect(result.current.portCount).toBe(4);
    expect(result.current.parsed?.expanded).toEqual([22, 23, 24, 25]);
  });

  test('обнаруживает ошибки валидации', () => {
    const { result } = renderHook(() => usePortValidation());
    
    act(() => {
      result.current.validate('abc');
    });
    
    expect(result.current.isValid).toBe(false);
    expect(result.current.errors.length).toBeGreaterThan(0);
    expect(result.current.portCount).toBe(0);
    expect(result.current.parsed).toBeNull();
  });

  test('показывает предупреждения для больших диапазонов', () => {
    const { result } = renderHook(() => usePortValidation());
    
    act(() => {
      result.current.validate('1-200');
    });
    
    expect(result.current.isValid).toBe(true);
    expect(result.current.warnings.length).toBeGreaterThan(0);
    expect(result.current.portCount).toBe(200);
  });

  test('очищает состояние', () => {
    const { result } = renderHook(() => usePortValidation());
    
    // Сначала валидируем что-то
    act(() => {
      result.current.validate('22,80,443');
    });
    
    expect(result.current.portCount).toBe(3);
    
    // Затем очищаем
    act(() => {
      result.current.clear();
    });
    
    expect(result.current.isValid).toBe(true);
    expect(result.current.errors).toEqual([]);
    expect(result.current.warnings).toEqual([]);
    expect(result.current.portCount).toBe(0);
    expect(result.current.parsed).toBeNull();
  });

  test('обрабатывает пустой ввод', () => {
    const { result } = renderHook(() => usePortValidation());
    
    act(() => {
      result.current.validate('');
    });
    
    expect(result.current.isValid).toBe(true);
    expect(result.current.errors).toEqual([]);
    expect(result.current.portCount).toBe(0);
    expect(result.current.parsed).toBeNull();
  });

  test('инициализируется с начальным значением', () => {
    const { result } = renderHook(() => usePortValidation('22,80,443'));
    
    // Ждем пока useEffect отработает
    expect(result.current.portCount).toBe(3);
    expect(result.current.isValid).toBe(true);
  });

  test('валидирует комбинированный ввод', () => {
    const { result } = renderHook(() => usePortValidation());
    
    act(() => {
      result.current.validate('22,80-83,443');
    });
    
    expect(result.current.isValid).toBe(true);
    expect(result.current.portCount).toBe(6);
    expect(result.current.parsed?.expanded).toEqual([22, 80, 81, 82, 83, 443]);
  });
});