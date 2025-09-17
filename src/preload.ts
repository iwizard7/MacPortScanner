import { contextBridge, ipcRenderer } from 'electron'
import type { ScanRequest, ScanResult, SystemInfo, AppSettings, ScanMetrics } from './types'

// Реэкспортируем типы для использования в renderer процессе
export type { ScanRequest, ScanResult, SystemInfo, AppSettings } from './types'

// Expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('electronAPI', {
  // Сканирование
  startScan: (request: ScanRequest) => ipcRenderer.invoke('start-scan', request),
  stopScan: () => ipcRenderer.invoke('stop-scan'),
  
  // Системная информация
  getSystemInfo: () => ipcRenderer.invoke('get-system-info'),
  
  // Настройки
  saveSettings: (settings: AppSettings) => ipcRenderer.invoke('save-settings', settings),
  loadSettings: () => ipcRenderer.invoke('load-settings'),
  
  // Экспорт
  exportResults: (results: ScanResult[]) => ipcRenderer.invoke('export-results', results),

  // Метрики производительности
  getScanMetrics: () => ipcRenderer.invoke('get-scan-metrics'),
  
  // События
  onScanProgress: (callback: (progress: number) => void) => {
    ipcRenderer.on('scan-progress', (event, progress) => callback(progress))
  },
  
  onQuickScan: (callback: () => void) => {
    ipcRenderer.on('quick-scan', callback)
  },
  
  onFullScan: (callback: () => void) => {
    ipcRenderer.on('full-scan', callback)
  },
  
  onStopScan: (callback: () => void) => {
    ipcRenderer.on('stop-scan', callback)
  },
  
  onExportResults: (callback: () => void) => {
    ipcRenderer.on('export-results', callback)
  },
  
  // Очистка слушателей
  removeAllListeners: (channel: string) => {
    ipcRenderer.removeAllListeners(channel)
  }
})

declare global {
  interface Window {
    electronAPI: {
      startScan: (request: ScanRequest) => Promise<ScanResult[]>
      stopScan: () => Promise<void>
      getSystemInfo: () => Promise<SystemInfo>
      saveSettings: (settings: AppSettings) => Promise<void>
      loadSettings: () => Promise<AppSettings>
      exportResults: (results: ScanResult[]) => Promise<void>
      getScanMetrics: () => Promise<ScanMetrics | null>
      onScanProgress: (callback: (progress: number) => void) => void
      onQuickScan: (callback: () => void) => void
      onFullScan: (callback: () => void) => void
      onStopScan: (callback: () => void) => void
      onExportResults: (callback: () => void) => void
      removeAllListeners: (channel: string) => void
    }
  }
}