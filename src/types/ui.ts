/**
 * Типы для UI компонентов
 */

import type { ParsedPorts } from '../lib/port-parser';

export interface PortInputProps {
  value: string;
  onChange: (value: string, parsed: ParsedPorts) => void;
  onValidationChange: (isValid: boolean, errors: string[]) => void;
  placeholder?: string;
  disabled?: boolean;
}

export interface PortInputState {
  isValid: boolean;
  errors: string[];
  warnings: string[];
  portCount: number;
  showWarning: boolean;
}

export interface PortCounterProps {
  count: number;
  showWarning?: boolean;
  warningThreshold?: number;
  dangerThreshold?: number;
}

export interface PortPresetsProps {
  onSelect: (ports: string) => void;
  disabled?: boolean;
}