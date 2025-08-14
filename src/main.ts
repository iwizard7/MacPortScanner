import { app, BrowserWindow, ipcMain, Menu, shell } from 'electron'
import { createConnection, Socket } from 'net'
import { exec } from 'child_process'
import { promisify } from 'util'
import * as path from 'path'
import Store from 'electron-store'

const execAsync = promisify(exec)
const store = new Store()

interface ScanRequest {
  target: string
  ports: number[]
  scanType: 'single' | 'range'
  timeout?: number
  method?: 'tcp' | 'syn' | 'udp'
}

interface ScanResult {
  ip: string
  port: number
  status: 'open' | 'closed' | 'filtered' | 'timeout'
  service?: string
  responseTime?: number
  banner?: string
}

interface SystemInfo {
  platform: string
  arch: string
  cpuModel: string
  totalMemory: number
  networkInterfaces: any
}

const commonServices: Record<number, string> = {
  21: 'FTP',
  22: 'SSH',
  23: 'Telnet',
  25: 'SMTP',
  53: 'DNS',
  80: 'HTTP',
  110: 'POP3',
  143: 'IMAP',
  443: 'HTTPS',
  993: 'IMAPS',
  995: 'POP3S',
  1433: 'MSSQL',
  3306: 'MySQL',
  3389: 'RDP',
  5432: 'PostgreSQL',
  5900: 'VNC',
  6379: 'Redis',
  27017: 'MongoDB',
}

class PortScanner {
  private isScanning = false
  private scanResults: ScanResult[] = []

  async scanPort(host: string, port: number, timeout = 3000): Promise<ScanResult> {
    return new Promise((resolve) => {
      const startTime = Date.now()
      const socket = new Socket()

      const cleanup = () => {
        socket.removeAllListeners()
        socket.destroy()
      }

      const timer = setTimeout(() => {
        cleanup()
        resolve({
          ip: host,
          port,
          status: 'timeout',
          responseTime: timeout,
          service: commonServices[port]
        })
      }, timeout)

      socket.connect(port, host, () => {
        const responseTime = Date.now() - startTime
        clearTimeout(timer)
        cleanup()
        resolve({
          ip: host,
          port,
          status: 'open',
          responseTime,
          service: commonServices[port]
        })
      })

      socket.on('error', () => {
        const responseTime = Date.now() - startTime
        clearTimeout(timer)
        cleanup()
        resolve({
          ip: host,
          port,
          status: 'closed',
          responseTime,
          service: commonServices[port]
        })
      })
    })
  }

  async scanWithNmap(host: string, ports: number[]): Promise<ScanResult[]> {
    try {
      const portRange = ports.join(',')
      const { stdout } = await execAsync(`nmap -p ${portRange} ${host} --open -T4`)
      
      const results: ScanResult[] = []
      const lines = stdout.split('\n')
      
      for (const line of lines) {
        const match = line.match(/(\d+)\/tcp\s+open\s+(\w+)?/)
        if (match) {
          const port = parseInt(match[1])
          const service = match[2] || commonServices[port]
          results.push({
            ip: host,
            port,
            status: 'open',
            service,
            responseTime: 0
          })
        }
      }
      
      return results
    } catch (error) {
      console.error('Nmap scan failed:', error)
      return []
    }
  }

  generateIPRange(range: string): string[] {
    if (range.includes('-')) {
      const [baseIP, endRange] = range.split('-')
      const baseParts = baseIP.split('.')
      const start = parseInt(baseParts[3])
      const end = parseInt(endRange)

      const ips = []
      for (let i = start; i <= end; i++) {
        ips.push(`${baseParts[0]}.${baseParts[1]}.${baseParts[2]}.${i}`)
      }
      return ips
    }
    return [range]
  }

  async performScan(request: ScanRequest, progressCallback: (progress: number) => void): Promise<ScanResult[]> {
    this.isScanning = true
    this.scanResults = []

    const { target, ports, scanType, timeout = 3000, method = 'tcp' } = request
    const targets = scanType === 'single' ? [target] : this.generateIPRange(target)
    
    const totalScans = targets.length * ports.length
    let completed = 0

    // Оптимизация для Apple Silicon - увеличиваем параллелизм
    const maxConcurrent = process.arch === 'arm64' ? 100 : 50
    const results: ScanResult[] = []

    for (const ip of targets) {
      if (!this.isScanning) break

      const chunks = []
      for (let i = 0; i < ports.length; i += maxConcurrent) {
        chunks.push(ports.slice(i, i + maxConcurrent))
      }

      for (const chunk of chunks) {
        if (!this.isScanning) break

        const promises = chunk.map(port => this.scanPort(ip, port, timeout))
        const chunkResults = await Promise.all(promises)
        
        results.push(...chunkResults)
        completed += chunk.length
        progressCallback((completed / totalScans) * 100)
      }
    }

    this.isScanning = false
    this.scanResults = results
    return results
  }

  stopScan(): void {
    this.isScanning = false
  }

  getResults(): ScanResult[] {
    return this.scanResults
  }
}

const scanner = new PortScanner()

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