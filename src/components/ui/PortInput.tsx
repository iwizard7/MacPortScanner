/**
 * Расширенное поле ввода портов с валидацией в реальном времени
 */

import React, { useState, useEffect, useCallback } from 'react';
import { Input } from './input';
import { ValidationMessage, ValidationIndicator } from './ValidationMessage';
import { PortCounter } from './PortCounter';
import { usePortValidation } from '../../hooks/usePortValidation';
import { cn } from '../../lib/utils';
import type { PortInputProps } from '../../types/ui';

export function PortInput({
  value,
  onChange,
  onValidationChange,
  placeholder = "Например: 22,80-90,443,8000-8080",
  disabled = false,
  className
}: PortInputProps & { className?: string }) {
  const [inputValue, setInputValue] = useState(value);
  const [showValidation, setShowValidation] = useState(false);
  
  const {
    validation,
    parsed,
    isValid,
    errors,
    warnings,
    portCount,
    validate
  } = usePortValidation();

  // Обновляем внутреннее состояние при изменении внешнего значения
  useEffect(() => {
    setInputValue(value);
  }, [value]);

  // Валидируем при изменении значения
  useEffect(() => {
    validate(inputValue);
  }, [inputValue, validate]);

  // Уведомляем родительский компонент об изменениях валидации
  useEffect(() => {
    onValidationChange(isValid, errors);
  }, [isValid, errors, onValidationChange]);

  // Уведомляем родительский компонент об изменениях значения и парсинга
  useEffect(() => {
    if (parsed) {
      onChange(inputValue, parsed);
    }
  }, [inputValue, parsed, onChange]);

  const handleInputChange = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const newValue = e.target.value;
    setInputValue(newValue);
    
    // Показываем валидацию только после того как пользователь начал вводить
    if (!showValidation && newValue.length > 0) {
      setShowValidation(true);
    }
  }, [showValidation]);

  const handleBlur = useCallback(() => {
    setShowValidation(true);
  }, []);

  const getInputClassName = () => {
    if (!showValidation || inputValue.length === 0) {
      return '';
    }
    
    if (!isValid) {
      return 'border-red-500 focus:border-red-500 focus:ring-red-500';
    }
    
    if (warnings.length > 0) {
      return 'border-amber-500 focus:border-amber-500 focus:ring-amber-500';
    }
    
    return 'border-green-500 focus:border-green-500 focus:ring-green-500';
  };

  return (
    <div className={cn('space-y-3', className)}>
      {/* Поле ввода */}
      <div className="relative">
        <Input
          value={inputValue}
          onChange={handleInputChange}
          onBlur={handleBlur}
          placeholder={placeholder}
          disabled={disabled}
          className={cn(
            'transition-colors duration-200',
            getInputClassName()
          )}
        />
        
        {/* Индикатор валидации */}
        {showValidation && inputValue.length > 0 && (
          <div className="absolute right-3 top-1/2 -translate-y-1/2">
            <ValidationIndicator 
              isValid={isValid} 
              hasWarnings={warnings.length > 0}
            />
          </div>
        )}
      </div>

      {/* Счетчик портов */}
      {portCount > 0 && (
        <PortCounter 
          count={portCount}
          showWarning={true}
          warningThreshold={100}
          dangerThreshold={1000}
        />
      )}

      {/* Сообщения валидации */}
      {showValidation && (
        <ValidationMessage 
          errors={errors}
          warnings={warnings}
        />
      )}

      {/* Подсказка с примерами */}
      {!showValidation && inputValue.length === 0 && (
        <div className="text-xs text-muted-foreground space-y-1">
          <div>Поддерживаемые форматы:</div>
          <div className="ml-2 space-y-0.5">
            <div>• Отдельные порты: <code className="text-xs bg-muted px-1 rounded">22,80,443</code></div>
            <div>• Диапазоны: <code className="text-xs bg-muted px-1 rounded">80-90</code></div>
            <div>• Комбинированный: <code className="text-xs bg-muted px-1 rounded">22,80-90,443</code></div>
          </div>
        </div>
      )}
    </div>
  );
}