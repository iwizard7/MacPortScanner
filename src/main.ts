import { app, BrowserWindow, ipcMain, Menu, shell } from 'electron'
import { exec } from 'child_process'
import { promisify } from 'util'
import * as path from 'path'
import Store from 'electron-store'
import { PortScanner } from './lib/port-scanner'
import type { ScanRequest, ScanResult, SystemInfo, AppSettings, ScanProgress } from './types'

const execAsync = promisify(exec)
const store = new Store()

const scanner = new PortScanner()

// Включаем garbage collection для предотвращения утечек памяти
if (process.env.NODE_ENV === 'development') {
  app.commandLine.appendSwitch('--expose-gc')
  app.commandLine.appendSwitch('--max-old-space-size', '4096') // Увеличиваем лимит памяти до 4GB
}

function createWindow(): void {
  const mainWindow = new BrowserWindow({
    width: 1400,
    height: 900,
    minWidth: 1200,
    minHeight: 800,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      preload: path.join(__dirname, 'preload.js')
    },
    titleBarStyle: 'hiddenInset',
    trafficLightPosition: { x: 20, y: 20 },
    backgroundColor: '#1e293b',
    show: false
  })

  // Загружаем приложение
  if (process.env.NODE_ENV === 'development') {
    mainWindow.loadURL('http://localhost:5173')
    mainWindow.webContents.openDevTools()
  } else {
    mainWindow.loadFile(path.join(__dirname, 'index.html'))
  }

  mainWindow.once('ready-to-show', () => {
    mainWindow.show()
  })

  // Создаем меню для macOS
  const template: Electron.MenuItemConstructorOptions[] = [
    {
      label: 'MacPortScanner',
      submenu: [
        { role: 'about' },
        { type: 'separator' },
        { role: 'services' },
        { type: 'separator' },
        { role: 'hide' },
        { role: 'hideOthers' },
        { role: 'unhide' },
        { type: 'separator' },
        { role: 'quit' }
      ]
    },
    {
      label: 'Файл',
      submenu: [
        {
          label: 'Экспорт результатов',
          accelerator: 'CmdOrCtrl+E',
          click: () => {
            mainWindow.webContents.send('export-results')
          }
        },
        { type: 'separator' },
        { role: 'close' }
      ]
    },
    {
      label: 'Правка',
      submenu: [
        { role: 'undo' },
        { role: 'redo' },
        { type: 'separator' },
        { role: 'cut' },
        { role: 'copy' },
        { role: 'paste' },
        { role: 'selectAll' }
      ]
    },
    {
      label: 'Вид',
      submenu: [
        { role: 'reload' },
        { role: 'forceReload' },
        { role: 'toggleDevTools' },
        { type: 'separator' },
        { role: 'resetZoom' },
        { role: 'zoomIn' },
        { role: 'zoomOut' },
        { type: 'separator' },
        { role: 'togglefullscreen' }
      ]
    },
    {
      label: 'Сканирование',
      submenu: [
        {
          label: 'Быстрое сканирование',
          accelerator: 'CmdOrCtrl+Q',
          click: () => {
            mainWindow.webContents.send('quick-scan')
          }
        },
        {
          label: 'Полное сканирование',
          accelerator: 'CmdOrCtrl+F',
          click: () => {
            mainWindow.webContents.send('full-scan')
          }
        },
        { type: 'separator' },
        {
          label: 'Остановить сканирование',
          accelerator: 'CmdOrCtrl+S',
          click: () => {
            mainWindow.webContents.send('stop-scan')
          }
        }
      ]
    },
    {
      label: 'Окно',
      submenu: [
        { role: 'minimize' },
        { role: 'close' }
      ]
    },
    {
      label: 'Справка',
      submenu: [
        {
          label: 'О программе',
          click: async () => {
            await shell.openExternal('https://github.com/iwizard7/MacPortScanner')
          }
        }
      ]
    }
  ]

  const menu = Menu.buildFromTemplate(template)
  Menu.setApplicationMenu(menu)
}

// IPC обработчики
ipcMain.handle('start-scan', async (event, request: ScanRequest) => {
  return await scanner.performScan(request, (progress) => {
    event.sender.send('scan-progress', progress)
  })
})

ipcMain.handle('stop-scan', () => {
  scanner.stopScan()
})

ipcMain.handle('get-scan-metrics', () => {
  return scanner.getMetrics()
})

ipcMain.handle('get-system-info', async (): Promise<SystemInfo> => {
  const os = require('os')
  return {
    platform: process.platform,
    arch: process.arch,
    cpuModel: os.cpus()[0].model,
    totalMemory: os.totalmem(),
    networkInterfaces: os.networkInterfaces()
  }
})

ipcMain.handle('save-settings', (event, settings) => {
  store.set('settings', settings)
})

ipcMain.handle('load-settings', () => {
  return store.get('settings', {})
})

ipcMain.handle('export-results', (event, results: ScanResult[]) => {
  const { dialog } = require('electron')
  const fs = require('fs')
  
  dialog.showSaveDialog({
    title: 'Экспорт результатов сканирования',
    defaultPath: `scan-results-${new Date().toISOString().split('T')[0]}.json`,
    filters: [
      { name: 'JSON файлы', extensions: ['json'] },
      { name: 'CSV файлы', extensions: ['csv'] },
      { name: 'Все файлы', extensions: ['*'] }
    ]
  }).then((result: any) => {
    if (!result.canceled && result.filePath) {
      const data = JSON.stringify(results, null, 2)
      fs.writeFileSync(result.filePath, data)
    }
  })
})

// Обработчики приложения
app.whenReady().then(() => {
  createWindow()

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow()
    }
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})