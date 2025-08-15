/**
 * Хук для валидации портов в реальном времени
 */

import { useState, useEffect, useCallback } from 'react';
import { PortParser } from '../lib/port-parser';
import type { ValidationResult, ParsedPorts } from '../types';

export interface UsePortValidationResult {
  validation: ValidationResult;
  parsed: ParsedPorts | null;
  isValid: boolean;
  errors: string[];
  warnings: string[];
  portCount: number;
  validate: (input: string) => void;
  clear: () => void;
}

export function usePortValidation(initialValue: string = ''): UsePortValidationResult {
  const [validation, setValidation] = useState<ValidationResult>({
    isValid: true,
    errors: [],
    warnings: [],
    portCount: 0
  });
  
  const [parsed, setParsed] = useState<ParsedPorts | null>(null);

  const validate = useCallback((input: string) => {
    if (PortParser.isEmpty(input)) {
      setValidation({
        isValid: true,
        errors: [],
        warnings: [],
        portCount: 0
      });
      setParsed(null);
      return;
    }

    try {
      const parsedPorts = PortParser.parse(input);
      const validationResult = PortParser.validate(input);
      
      setValidation(validationResult);
      setParsed(parsedPorts);
    } catch (error) {
      // Ошибки парсинга уже обрабатываются в PortParser.validate
      const validationResult = PortParser.validate(input);
      setValidation(validationResult);
      setParsed(null);
    }
  }, []);

  const clear = useCallback(() => {
    setValidation({
      isValid: true,
      errors: [],
      warnings: [],
      portCount: 0
    });
    setParsed(null);
  }, []);

  // Валидируем начальное значение
  useEffect(() => {
    if (initialValue) {
      validate(initialValue);
    }
  }, [initialValue, validate]);

  return {
    validation,
    parsed,
    isValid: validation.isValid,
    errors: validation.errors,
    warnings: validation.warnings,
    portCount: validation.portCount,
    validate,
    clear
  };
}