/**
 * Класс для сканирования портов с детектированием сервисов по баннерам
 */

import { createConnection, Socket } from 'net'
import { exec } from 'child_process'
import { promisify } from 'util'
import type { ScanResult, ScanRequest } from '../types'

const execAsync = promisify(exec)

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

export class PortScanner {
  private isScanning = false
  private scanResults: ScanResult[] = []

  async getServiceBanner(host: string, port: number, timeout = 5000): Promise<{ banner: string; service: string }> {
    return new Promise((resolve) => {
      const socket = new Socket()
      let banner = ''
      let service = commonServices[port] || 'Unknown'

      const cleanup = () => {
        socket.removeAllListeners()
        socket.destroy()
      }

      const timer = setTimeout(() => {
        cleanup()
        resolve({ banner, service })
      }, timeout)

      socket.connect(port, host, () => {
        // Для разных портов отправляем разные запросы
        switch (port) {
          case 80:
          case 8080:
          case 8000:
          case 8888:
            // HTTP
            socket.write('GET / HTTP/1.1\r\nHost: ' + host + '\r\nConnection: close\r\n\r\n')
            break
          case 443:
          case 8443:
            // HTTPS - для простоты используем обычное TCP подключение
            socket.write('GET / HTTP/1.1\r\nHost: ' + host + '\r\nConnection: close\r\n\r\n')
            break
          case 21:
            // FTP
            break // FTP отправляет banner автоматически
          case 22:
            // SSH
            break // SSH отправляет banner автоматически
          case 25:
          case 587:
            // SMTP
            setTimeout(() => socket.write('EHLO localhost\r\n'), 100)
            break
          case 110:
            // POP3
            setTimeout(() => socket.write('USER test\r\n'), 100)
            break
          case 143:
            // IMAP
            setTimeout(() => socket.write('a001 LOGIN test test\r\n'), 100)
            break
          case 3306:
            // MySQL
            break // MySQL handshake происходит автоматически
          case 5432:
            // PostgreSQL
            break // PostgreSQL handshake происходит автоматически
          case 6379:
            // Redis
            setTimeout(() => socket.write('INFO\r\n'), 100)
            break
          case 27017:
            // MongoDB
            break // MongoDB handshake происходит автоматически
          default:
            // Для неизвестных портов просто ждем данные
            break
        }
      })

      socket.on('data', (data) => {
        banner += data.toString()

        // Парсим баннер для определения сервиса
        if (banner.includes('SSH-')) {
          service = 'SSH'
        } else if (banner.includes('220') && banner.includes('FTP')) {
          service = 'FTP'
        } else if (banner.includes('220') && (banner.includes('SMTP') || banner.includes('mail'))) {
          service = 'SMTP'
        } else if (banner.includes('220') && banner.includes('POP3')) {
          service = 'POP3'
        } else if (banner.includes('* OK') && banner.includes('IMAP')) {
          service = 'IMAP'
        } else if (banner.includes('HTTP/')) {
          service = port === 443 ? 'HTTPS' : 'HTTP'
        } else if (banner.includes('MySQL')) {
          service = 'MySQL'
        } else if (banner.includes('PostgreSQL')) {
          service = 'PostgreSQL'
        } else if (banner.includes('Redis')) {
          service = 'Redis'
        } else if (banner.includes('MongoDB')) {
          service = 'MongoDB'
        }

        // Закрываем соединение после получения достаточных данных
        if (banner.length > 100 || banner.includes('\n')) {
          clearTimeout(timer)
          cleanup()
          resolve({ banner: banner.trim(), service })
        }
      })

      socket.on('error', () => {
        clearTimeout(timer)
        cleanup()
        resolve({ banner, service })
      })
    })
  }

  async scanPort(host: string, port: number, timeout = 3000): Promise<ScanResult> {
    return new Promise(async (resolve) => {
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

      socket.connect(port, host, async () => {
        const responseTime = Date.now() - startTime
        clearTimeout(timer)

        // Получаем баннер для открытых портов
        let banner = ''
        let detectedService = commonServices[port]

        try {
          const bannerResult = await this.getServiceBanner(host, port, 2000)
          banner = bannerResult.banner
          detectedService = bannerResult.service
        } catch (error) {
          // Если не удалось получить баннер, используем стандартное определение
        }

        cleanup()
        resolve({
          ip: host,
          port,
          status: 'open',
          responseTime,
          service: detectedService,
          banner: banner || undefined
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
      const result = await execAsync(`nmap -p ${portRange} ${host} --open -T4 -sV --version-light`)
      const stdout = typeof result === 'string' ? result : (result?.stdout || '')

      const results: ScanResult[] = []
      const lines = stdout.split('\n')

      for (const line of lines) {
        const match = line.match(/(\d+)\/tcp\s+open\s+(.+)/)
        if (match) {
          const port = parseInt(match[1])
          const serviceInfo = match[2].trim()
          let service = commonServices[port] || 'Unknown'
          let banner = ''

          // Парсим информацию о сервисе из nmap
          if (serviceInfo.includes('http')) {
            service = port === 443 ? 'HTTPS' : 'HTTP'
            if (serviceInfo.includes('title:')) {
              const titleMatch = serviceInfo.match(/title:\s*([^|]+)/)
              if (titleMatch) {
                banner = titleMatch[1].trim()
              }
            }
          } else if (serviceInfo.includes('ssh')) {
            service = 'SSH'
            if (serviceInfo.includes('protocol')) {
              const protocolMatch = serviceInfo.match(/protocol\s+(\d+\.\d+)/)
              if (protocolMatch) {
                banner = `SSH-${protocolMatch[1]}`
              }
            }
          } else if (serviceInfo.includes('ftp')) {
            service = 'FTP'
          } else if (serviceInfo.includes('smtp')) {
            service = 'SMTP'
          } else if (serviceInfo.includes('pop3')) {
            service = 'POP3'
          } else if (serviceInfo.includes('imap')) {
            service = 'IMAP'
          } else if (serviceInfo.includes('mysql')) {
            service = 'MySQL'
          } else if (serviceInfo.includes('postgresql')) {
            service = 'PostgreSQL'
          } else if (serviceInfo.includes('redis')) {
            service = 'Redis'
          } else if (serviceInfo.includes('mongodb')) {
            service = 'MongoDB'
          }

          results.push({
            ip: host,
            port,
            status: 'open',
            service,
            banner: banner || undefined,
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