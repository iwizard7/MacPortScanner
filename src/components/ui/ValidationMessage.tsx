/**
 * Компонент для отображения сообщений валидации
 */

import React from 'react';
import { AlertCircle, AlertTriangle, Info } from 'lucide-react';
import { cn } from '../../lib/utils';

export interface ValidationMessageProps {
  errors?: string[];
  warnings?: string[];
  className?: string;
}

export function ValidationMessage({ errors = [], warnings = [], className }: ValidationMessageProps) {
  if (errors.length === 0 && warnings.length === 0) {
    return null;
  }

  return (
    <div className={cn('space-y-1', className)}>
      {/* Ошибки */}
      {errors.map((error, index) => (
        <div
          key={`error-${index}`}
          className="flex items-start gap-2 text-sm text-red-600 dark:text-red-400"
        >
          <AlertCircle className="h-4 w-4 mt-0.5 flex-shrink-0" />
          <span>{error}</span>
        </div>
      ))}
      
      {/* Предупреждения */}
      {warnings.map((warning, index) => (
        <div
          key={`warning-${index}`}
          className="flex items-start gap-2 text-sm text-amber-600 dark:text-amber-400"
        >
          <AlertTriangle className="h-4 w-4 mt-0.5 flex-shrink-0" />
          <span>{warning}</span>
        </div>
      ))}
    </div>
  );
}

export interface ValidationIndicatorProps {
  isValid: boolean;
  hasWarnings: boolean;
  className?: string;
}

export function ValidationIndicator({ isValid, hasWarnings, className }: ValidationIndicatorProps) {
  if (isValid && !hasWarnings) {
    return (
      <div className={cn('flex items-center gap-1 text-green-600 dark:text-green-400', className)}>
        <div className="h-2 w-2 rounded-full bg-green-500" />
        <span className="text-xs">Корректно</span>
      </div>
    );
  }

  if (isValid && hasWarnings) {
    return (
      <div className={cn('flex items-center gap-1 text-amber-600 dark:text-amber-400', className)}>
        <AlertTriangle className="h-3 w-3" />
        <span className="text-xs">Предупреждение</span>
      </div>
    );
  }

  return (
    <div className={cn('flex items-center gap-1 text-red-600 dark:text-red-400', className)}>
      <AlertCircle className="h-3 w-3" />
      <span className="text-xs">Ошибка</span>
    </div>
  );
}