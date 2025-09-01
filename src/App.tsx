import React, { useState, useEffect, useCallback } from 'react'
import { Button } from './components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from './components/ui/card'
import { Input } from './components/ui/input'
import { Label } from './components/ui/label'
import { Textarea } from './components/ui/textarea'
import { Badge } from './components/ui/badge'
import { Progress } from './components/ui/progress'
import { Tabs, TabsContent, TabsList, TabsTrigger } from './components/ui/tabs'
import { Alert, AlertDescription } from './components/ui/alert'
import { Separator } from './components/ui/separator'
import { PortInput } from './components/ui/PortInput'
import {
  Play,
  Square,
  Wifi,
  Shield,
  Clock,
  Target,
  Cpu,
  HardDrive,
  Download,
  Settings,
  Zap
} from 'lucide-react'
import type { ScanRequest, ScanResult, SystemInfo, AppSettings, ParsedPorts } from './types'

function App() {
  const [target, setTarget] = useState('127.0.0.1')
  const [portInput, setPortInput] = useState('22,80,443,3389,5432,3306')
  const [parsedPorts, setParsedPorts] = useState<ParsedPorts | null>(null)
  const [isScanning, setIsScanning] = useState(false)
  const [progress, setProgress] = useState(0)
  const [results, setResults] = useState<ScanResult[]>([])
  const [scanType, setScanType] = useState<'single' | 'range'>('single')
  const [startTime, setStartTime] = useState<Date | null>(null)
  const [endTime, setEndTime] = useState<Date | null>(null)
  const [systemInfo, setSystemInfo] = useState<SystemInfo | null>(null)
  const [scanMethod, setScanMethod] = useState<'tcp' | 'syn' | 'udp'>('tcp')
  const [timeout, setTimeout] = useState(3000)
  const [portValidationErrors, setPortValidationErrors] = useState<string[]>([])

  const commonPorts = [
    { port: 21, service: 'FTP' },
    { port: 22, service: 'SSH' },
    { port: 23, service: 'Telnet' },
    { port: 25, service: 'SMTP' },
    { port: 53, service: 'DNS' },
    { port: 80, service: 'HTTP' },
    { port: 110, service: 'POP3' },
    { port: 143, service: 'IMAP' },
    { port: 443, service: 'HTTPS' },
    { port: 993, service: 'IMAPS' },
    { port: 995, service: 'POP3S' },
    { port: 1433, service: 'MSSQL' },
    { port: 3306, service: 'MySQL' },
    { port: 3389, service: 'RDP' },
    { port: 5432, service: 'PostgreSQL' },
    { port: 5900, service: 'VNC' },
    { port: 6379, service: 'Redis' },
    { port: 27017, service: 'MongoDB' },
  ]

  const quickScanPorts = [22, 80, 443, 3389, 5432, 3306]
  const fullScanPorts = Array.from({ length: 1000 }, (_, i) => i + 1)

  useEffect(() => {
    // Загружаем системную информацию
    window.electronAPI.getSystemInfo().then(setSystemInfo)

    // Загружаем сохраненные настройки
    window.electronAPI.loadSettings().then((settings: AppSettings) => {
      if (settings.target) setTarget(settings.target)
      if (settings.ports) setPortInput(settings.ports)
      if (settings.timeout) setTimeout(settings.timeout)
      if (settings.scanMethod) setScanMethod(settings.scanMethod)
    })

    // Подписываемся на события прогресса
    window.electronAPI.onScanProgress((progress: number) => {
      setProgress(progress)
    })

    // Подписываемся на горячие клавиши
    window.electronAPI.onQuickScan(() => {
      handleQuickScan()
    })

    window.electronAPI.onFullScan(() => {
      handleFullScan()
    })

    window.electronAPI.onStopScan(() => {
      handleStopScan()
    })

    window.electronAPI.onExportResults(() => {
      handleExportResults()
    })

    return () => {
      window.electronAPI.removeAllListeners('scan-progress')
      window.electronAPI.removeAllListeners('quick-scan')
      window.electronAPI.removeAllListeners('full-scan')
      window.electronAPI.removeAllListeners('stop-scan')
      window.electronAPI.removeAllListeners('export-results')
    }
  }, [])

  // Обработчики для PortInput компонента
  const handlePortInputChange = useCallback((value: string, parsed: ParsedPorts) => {
    setPortInput(value)
    setParsedPorts(parsed)
  }, [])

  const handlePortValidationChange = useCallback((isValid: boolean, errors: string[]) => {
    setPortValidationErrors(errors)
  }, [])

  const setCommonPorts = () => {
    setPortInput(commonPorts.map(p => p.port).join(','))
  }

  const handleQuickScan = () => {
    setPortInput(quickScanPorts.join(','))
    startScan()
  }

  const handleFullScan = () => {
    setPortInput(fullScanPorts.join(','))
    startScan()
  }

  const startScan = async () => {
    if (!target || !portInput || !parsedPorts || portValidationErrors.length > 0) return

    setIsScanning(true)
    setProgress(0)
    setResults([])
    setStartTime(new Date())
    setEndTime(null)

    const request: ScanRequest = {
      target,
      ports: parsedPorts.expanded,
      portInput,
      portCount: parsedPorts.total,
      scanType,
      timeout,
      method: scanMethod
    }

    // Сохраняем настройки
    const settings: Partial<AppSettings> = {
      target,
      ports: portInput,
      timeout,
      scanMethod,
      defaultTimeout: timeout,
      defaultMethod: scanMethod,
      maxConcurrentConnections: 100,
      theme: 'system',
      autoSave: true,
      recentTargets: [target],
      recentPortInputs: [portInput]
    }
    
    await window.electronAPI.saveSettings(settings as AppSettings)

    try {
      const scanResults = await window.electronAPI.startScan(request)
      setResults(scanResults)
      setEndTime(new Date())
    } catch (error) {
      console.error('Scan failed:', error)
    } finally {
      setIsScanning(false)
    }
  }

  const handleStopScan = async () => {
    await window.electronAPI.stopScan()
    setIsScanning(false)
    setEndTime(new Date())
  }

  const handleExportResults = async () => {
    if (results.length > 0) {
      await window.electronAPI.exportResults(results)
    }
  }

  const openResults = results.filter(r => r.status === 'open')
  const closedResults = results.filter(r => r.status === 'closed')
  const filteredResults = results.filter(r => r.status === 'filtered')
  const timeoutResults = results.filter(r => r.status === 'timeout')
  const scanDuration = startTime && endTime ? Math.round((endTime.getTime() - startTime.getTime()) / 1000) : 0

  const getArchBadge = () => {
    if (!systemInfo) return null
    const isAppleSilicon = systemInfo.arch === 'arm64'
    return (
      <Badge variant={isAppleSilicon ? 'default' : 'secondary'} className={isAppleSilicon ? 'bg-green-500' : ''}>
        {isAppleSilicon ? '🚀 Apple Silicon' : '💻 Intel'}
      </Badge>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 to-slate-100 dark:from-slate-900 dark:to-slate-800">
      <div className="container mx-auto p-6 max-w-7xl">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="flex items-center justify-center gap-3 mb-4">
            <div className="p-3 bg-blue-500 rounded-2xl">
              <Shield className="h-8 w-8 text-white" />
            </div>
            <h1 className="text-4xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
              MacPortScanner
            </h1>
            {getArchBadge()}
          </div>
          <p className="text-muted-foreground text-lg">
            Профессиональный сканер портов для macOS с оптимизацией для Apple Silicon
          </p>
          {systemInfo && (
            <div className="flex items-center justify-center gap-4 mt-4 text-sm text-muted-foreground">
              <div className="flex items-center gap-1">
                <Cpu className="h-4 w-4" />
                {systemInfo.cpuModel.split(' ').slice(0, 3).join(' ')}
              </div>
              <div className="flex items-center gap-1">
                <HardDrive className="h-4 w-4" />
                {Math.round(systemInfo.totalMemory / 1024 / 1024 / 1024)} GB RAM
              </div>
            </div>
          )}
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Настройки сканирования */}
          <div className="lg:col-span-1">
            <Card className="backdrop-blur-sm bg-white/80 dark:bg-slate-800/80 border-0 shadow-xl">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <Target className="h-5 w-5" />
                  Настройки сканирования
                </CardTitle>
                <CardDescription>Настройте параметры для сканирования портов</CardDescription>
              </CardHeader>
              <CardContent className="space-y-6">
                <Tabs value={scanType} onValueChange={(v) => setScanType(v as 'single' | 'range')}>
                  <TabsList className="grid w-full grid-cols-2">
                    <TabsTrigger value="single">Один IP</TabsTrigger>
                    <TabsTrigger value="range">Диапазон</TabsTrigger>
                  </TabsList>

                  <TabsContent value="single" className="space-y-4">
                    <div>
                      <Label htmlFor="target">IP адрес или домен</Label>
                      <Input
                        id="target"
                        placeholder="192.168.1.1 или example.com"
                        value={target}
                        onChange={(e) => setTarget(e.target.value)}
                        className="mt-1"
                      />
                    </div>
                  </TabsContent>

                  <TabsContent value="range" className="space-y-4">
                    <div>
                      <Label htmlFor="range">Диапазон IP</Label>
                      <Input
                        id="range"
                        placeholder="192.168.1.1-254"
                        value={target}
                        onChange={(e) => setTarget(e.target.value)}
                        className="mt-1"
                      />
                    </div>
                  </TabsContent>
                </Tabs>

                <div>
                  <div className="flex items-center justify-between mb-2">
                    <Label htmlFor="ports">Порты для сканирования</Label>
                    <Button variant="outline" size="sm" onClick={setCommonPorts} className="text-xs bg-transparent">
                      Популярные
                    </Button>
                  </div>
                  <PortInput
                    value={portInput}
                    onChange={handlePortInputChange}
                    onValidationChange={handlePortValidationChange}
                    placeholder="22,80,443 или 22-443 или 22,80-90,443"
                    disabled={isScanning}
                  />
                </div>

                {/* Дополнительные настройки */}
                <div className="space-y-4">
                  <div>
                    <Label htmlFor="method">Метод сканирования</Label>
                    <select
                      id="method"
                      value={scanMethod}
                      onChange={(e) => setScanMethod(e.target.value as 'tcp' | 'syn' | 'udp')}
                      className="w-full mt-1 p-2 border rounded-md bg-background"
                    >
                      <option value="tcp">TCP Connect</option>
                      <option value="syn">SYN Scan</option>
                      <option value="udp">UDP Scan</option>
                    </select>
                  </div>

                  <div>
                    <Label htmlFor="timeout">Таймаут (мс)</Label>
                    <Input
                      id="timeout"
                      type="number"
                      value={timeout}
                      onChange={(e) => setTimeout(parseInt(e.target.value))}
                      className="mt-1"
                      min="100"
                      max="10000"
                      step="100"
                    />
                  </div>
                </div>

                <div className="flex gap-2">
                  <Button
                    onClick={startScan}
                    disabled={isScanning || !target || !portInput || !parsedPorts || portValidationErrors.length > 0}
                    className="flex-1 bg-gradient-to-r from-blue-500 to-purple-500 hover:from-blue-600 hover:to-purple-600"
                  >
                    {isScanning ? (
                      <>
                        <Square className="h-4 w-4 mr-2" />
                        Сканирование...
                      </>
                    ) : (
                      <>
                        <Play className="h-4 w-4 mr-2" />
                        Начать
                      </>
                    )}
                  </Button>

                  {isScanning && (
                    <Button variant="destructive" onClick={handleStopScan} size="icon">
                      <Square className="h-4 w-4" />
                    </Button>
                  )}
                </div>

                {/* Быстрые действия */}
                <div className="space-y-2">
                  <Label>Быстрые действия</Label>
                  <div className="grid grid-cols-2 gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={handleQuickScan}
                      disabled={isScanning}
                      className="text-xs"
                    >
                      <Zap className="h-3 w-3 mr-1" />
                      Быстро
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={handleFullScan}
                      disabled={isScanning}
                      className="text-xs"
                    >
                      <Settings className="h-3 w-3 mr-1" />
                      Полное
                    </Button>
                  </div>
                </div>

                {isScanning && (
                  <div className="space-y-2">
                    <div className="flex justify-between text-sm">
                      <span>Прогресс</span>
                      <span>{Math.round(progress)}%</span>
                    </div>
                    <Progress value={progress} className="h-2" />
                  </div>
                )}
              </CardContent>
            </Card>
          </div>

          {/* Результаты */}
          <div className="lg:col-span-2">
            <Card className="backdrop-blur-sm bg-white/80 dark:bg-slate-800/80 border-0 shadow-xl">
              <CardHeader>
                <div className="flex items-center justify-between">
                  <div>
                    <CardTitle className="flex items-center gap-2">
                      <Wifi className="h-5 w-5" />
                      Результаты сканирования
                    </CardTitle>
                    <CardDescription>
                      {results.length > 0 && (
                        <>
                          Найдено {openResults.length} открытых портов из {results.length} проверенных
                          {scanDuration > 0 && (
                            <span className="ml-2 inline-flex items-center gap-1">
                              <Clock className="h-3 w-3" />
                              {scanDuration}с
                            </span>
                          )}
                        </>
                      )}
                    </CardDescription>
                  </div>

                  <div className="flex items-center gap-2">
                    {results.length > 0 && (
                      <>
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={handleExportResults}
                          className="text-xs"
                        >
                          <Download className="h-3 w-3 mr-1" />
                          Экспорт
                        </Button>
                        <div className="flex gap-2">
                          <Badge variant="default" className="bg-green-500">
                            Открыто: {openResults.length}
                          </Badge>
                          <Badge variant="secondary">Закрыто: {closedResults.length}</Badge>
                          {filteredResults.length > 0 && (
                            <Badge variant="outline">Фильтровано: {filteredResults.length}</Badge>
                          )}
                          {timeoutResults.length > 0 && (
                            <Badge variant="destructive">Таймаут: {timeoutResults.length}</Badge>
                          )}
                        </div>
                      </>
                    )}
                  </div>
                </div>
              </CardHeader>
              <CardContent>
                {results.length === 0 && !isScanning && (
                  <Alert>
                    <Shield className="h-4 w-4" />
                    <AlertDescription>
                      Настройте параметры сканирования и нажмите "Начать" для проверки портов
                    </AlertDescription>
                  </Alert>
                )}

                {results.length > 0 && (
                  <div className="space-y-4 max-h-96 overflow-y-auto">
                    {/* Открытые порты */}
                    {openResults.length > 0 && (
                      <div>
                        <h3 className="font-semibold text-green-600 dark:text-green-400 mb-3 flex items-center gap-2">
                          <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                          Открытые порты ({openResults.length})
                        </h3>
                        <div className="grid gap-2">
                          {openResults.map((result, index) => (
                            <div
                              key={`${result.ip}-${result.port}`}
                              className="flex items-center justify-between p-3 bg-green-50 dark:bg-green-900/20 rounded-lg border border-green-200 dark:border-green-800"
                            >
                              <div className="flex items-center gap-3">
                                <Badge variant="default" className="bg-green-500">
                                  {result.ip}:{result.port}
                                </Badge>
                                {result.service && (
                                  <span className="text-sm font-medium text-green-700 dark:text-green-300">
                                    {result.service}
                                  </span>
                                )}
                                {result.banner && (
                                  <span className="text-xs text-muted-foreground truncate max-w-xs">
                                    {result.banner}
                                  </span>
                                )}
                              </div>
                              <div className="text-xs text-muted-foreground">
                                {result.responseTime}ms
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    )}

                    {(openResults.length > 0 && (closedResults.length > 0 || filteredResults.length > 0 || timeoutResults.length > 0)) && <Separator />}

                    {/* Остальные результаты в свернутом виде */}
                    {(closedResults.length > 0 || filteredResults.length > 0 || timeoutResults.length > 0) && (
                      <div className="space-y-2">
                        {closedResults.length > 0 && (
                          <details className="group">
                            <summary className="cursor-pointer font-semibold text-muted-foreground flex items-center gap-2">
                              <div className="w-2 h-2 bg-gray-400 rounded-full"></div>
                              Закрытые порты ({closedResults.length})
                            </summary>
                            <div className="mt-2 grid gap-1 max-h-32 overflow-y-auto">
                              {closedResults.slice(0, 20).map((result) => (
                                <div
                                  key={`${result.ip}-${result.port}`}
                                  className="flex items-center justify-between p-2 bg-muted/50 rounded text-sm"
                                >
                                  <span className="text-muted-foreground">
                                    {result.ip}:{result.port} {result.service && `(${result.service})`}
                                  </span>
                                  <span className="text-xs text-muted-foreground">{result.responseTime}ms</span>
                                </div>
                              ))}
                              {closedResults.length > 20 && (
                                <div className="text-xs text-muted-foreground text-center p-2">
                                  ... и еще {closedResults.length - 20} портов
                                </div>
                              )}
                            </div>
                          </details>
                        )}
                      </div>
                    )}
                  </div>
                )}
              </CardContent>
            </Card>
          </div>
        </div>
      </div>
    </div>
  )
}

export default App