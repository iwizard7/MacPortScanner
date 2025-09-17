/**
 * Общие типы для MacPortScanner
 */

// Импортируем типы из port-parser
export type { PortRange, ParsedPorts, ValidationResult, PresetKey } from '../lib/port-parser';

export interface ScanRequest {
  target: string;
  ports: number[];
  portInput: string; // Оригинальная строка ввода (например, "22,80-90,443")
  scanType: 'single' | 'range';
  timeout?: number;
  method?: 'tcp' | 'syn' | 'udp';
  portCount: number; // Количество портов для UI отображения
}

export interface ScanResult {
  ip: string;
  port: number;
  status: 'open' | 'closed' | 'filtered' | 'timeout';
  service?: string;
  responseTime?: number;
  banner?: string;
}

export interface SystemInfo {
  platform: string;
  arch: string;
  cpuModel: string;
  totalMemory: number;
  networkInterfaces: any;
}

export interface ScanProgress {
  current: number;
  total: number;
  percentage: number;
  currentPort?: number;
  currentIP?: string;
}

export interface ScanMetrics {
  startTime: number;
  endTime?: number;
  duration?: number;
  totalPorts: number;
  scannedPorts: number;
  openPorts: number;
  closedPorts: number;
  timeoutPorts: number;
  scanSpeed?: number; // портов в секунду
  averageResponseTime?: number;
  peakMemoryUsage?: number;
  totalMemoryUsage?: number;
}

export interface AppSettings {
  // Настройки сканирования
  target?: string;
  ports?: string;
  timeout?: number;
  scanMethod?: 'tcp' | 'syn' | 'udp';
  
  // Системные настройки
  defaultTimeout: number;
  defaultMethod: 'tcp' | 'syn' | 'udp';
  maxConcurrentConnections: number;
  theme: 'light' | 'dark' | 'system';
  autoSave: boolean;
  recentTargets: string[];
  recentPortInputs: string[];
}

// UI типы экспортируются из отдельного файла
export * from './ui';

// Константы
export const SCAN_METHODS = ['tcp', 'syn', 'udp'] as const;
export const SCAN_TYPES = ['single', 'range'] as const;
export const PORT_STATUS = ['open', 'closed', 'filtered', 'timeout'] as const;

export type ScanMethod = typeof SCAN_METHODS[number];
export type ScanType = typeof SCAN_TYPES[number];
export type PortStatus = typeof PORT_STATUS[number];