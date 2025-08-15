/**
 * Компонент для отображения количества портов
 */

import React from 'react';
import { Hash, Clock, AlertTriangle } from 'lucide-react';
import { cn } from '../../lib/utils';
import type { PortCounterProps } from '../../types/ui';

export function PortCounter({ 
  count, 
  showWarning = false,
  warningThreshold = 100,
  dangerThreshold = 1000,
  className 
}: PortCounterProps & { className?: string }) {
  const isDanger = count > dangerThreshold;
  const isWarning = count > warningThreshold && count <= dangerThreshold;
  const shouldShowWarning = showWarning && (isWarning || isDanger);

  const getEstimatedTime = (portCount: number): string => {
    if (portCount <= 10) return '< 1 сек';
    if (portCount <= 50) return '1-5 сек';
    if (portCount <= 100) return '5-15 сек';
    if (portCount <= 500) return '15-60 сек';
    if (portCount <= 1000) return '1-3 мин';
    return '> 3 мин';
  };

  if (count === 0) {
    return null;
  }

  return (
    <div className={cn('space-y-2', className)}>
      {/* Основная информация */}
      <div className="flex items-center justify-between text-sm">
        <div className="flex items-center gap-2">
          <Hash className="h-4 w-4 text-muted-foreground" />
          <span className="text-muted-foreground">
            Портов для сканирования:
          </span>
          <span className={cn(
            'font-medium',
            isDanger && 'text-red-600 dark:text-red-400',
            isWarning && 'text-amber-600 dark:text-amber-400',
            !isWarning && !isDanger && 'text-foreground'
          )}>
            {count.toLocaleString()}
          </span>
        </div>

        <div className="flex items-center gap-2 text-muted-foreground">
          <Clock className="h-4 w-4" />
          <span className="text-xs">
            ~{getEstimatedTime(count)}
          </span>
        </div>
      </div>

      {/* Предупреждения */}
      {shouldShowWarning && (
        <div className={cn(
          'flex items-start gap-2 p-2 rounded-md text-sm',
          isDanger && 'bg-red-50 dark:bg-red-950/20 text-red-700 dark:text-red-300',
          isWarning && 'bg-amber-50 dark:bg-amber-950/20 text-amber-700 dark:text-amber-300'
        )}>
          <AlertTriangle className="h-4 w-4 mt-0.5 flex-shrink-0" />
          <div>
            {isDanger ? (
              <>
                <div className="font-medium">Очень большой диапазон</div>
                <div className="text-xs mt-1">
                  Сканирование {count.toLocaleString()} портов может занять очень много времени. 
                  Рекомендуется использовать меньший диапазон.
                </div>
              </>
            ) : (
              <>
                <div className="font-medium">Большой диапазон</div>
                <div className="text-xs mt-1">
                  Сканирование {count.toLocaleString()} портов может занять продолжительное время.
                </div>
              </>
            )}
          </div>
        </div>
      )}

      {/* Прогресс-бар для визуализации размера диапазона */}
      <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-1">
        <div 
          className={cn(
            'h-1 rounded-full transition-all duration-300',
            isDanger && 'bg-red-500',
            isWarning && 'bg-amber-500',
            !isWarning && !isDanger && 'bg-green-500'
          )}
          style={{ 
            width: `${Math.min((count / dangerThreshold) * 100, 100)}%` 
          }}
        />
      </div>
    </div>
  );
}