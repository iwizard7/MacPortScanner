import React from 'react'
import { Input } from './input'
import { Label } from './label'
import { Button } from './button'
import { Badge } from './badge'
import { Card, CardContent, CardHeader, CardTitle } from './card'
import { Separator } from './separator'
import { Search, Filter, X } from 'lucide-react'

interface ScanFiltersProps {
  searchText: string
  onSearchChange: (value: string) => void
  statusFilter: string[]
  onStatusFilterChange: (statuses: string[]) => void
  portFilter: string
  onPortFilterChange: (value: string) => void
  serviceFilter: string
  onServiceFilterChange: (value: string) => void
  onResetFilters: () => void
  totalResults: number
  filteredResults: number
}

const STATUS_OPTIONS = [
  { value: 'open', label: 'Открытые', color: 'bg-green-500' },
  { value: 'closed', label: 'Закрытые', color: 'bg-gray-500' },
  { value: 'filtered', label: 'Фильтрованные', color: 'bg-yellow-500' },
  { value: 'timeout', label: 'Таймаут', color: 'bg-red-500' }
]

export function ScanFilters({
  searchText,
  onSearchChange,
  statusFilter,
  onStatusFilterChange,
  portFilter,
  onPortFilterChange,
  serviceFilter,
  onServiceFilterChange,
  onResetFilters,
  totalResults,
  filteredResults
}: ScanFiltersProps) {
  const toggleStatusFilter = (status: string) => {
    if (statusFilter.includes(status)) {
      onStatusFilterChange(statusFilter.filter(s => s !== status))
    } else {
      onStatusFilterChange([...statusFilter, status])
    }
  }

  const hasActiveFilters = searchText || statusFilter.length > 0 || portFilter || serviceFilter

  return (
    <Card className="backdrop-blur-sm bg-white/80 dark:bg-slate-800/80 border-0 shadow-xl">
      <CardHeader className="pb-3">
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2 text-lg">
            <Filter className="h-5 w-5" />
            Фильтры и поиск
          </CardTitle>
          {hasActiveFilters && (
            <Button
              variant="outline"
              size="sm"
              onClick={onResetFilters}
              className="text-xs"
            >
              <X className="h-3 w-3 mr-1" />
              Сбросить
            </Button>
          )}
        </div>
        {totalResults > 0 && (
          <div className="text-sm text-muted-foreground">
            {filteredResults !== totalResults
              ? `Показано ${filteredResults} из ${totalResults} результатов`
              : `Всего ${totalResults} результатов`
            }
          </div>
        )}
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Поиск */}
        <div>
          <Label htmlFor="search" className="text-sm font-medium">
            Поиск
          </Label>
          <div className="relative mt-1">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
            <Input
              id="search"
              placeholder="Поиск по порту, сервису, баннеру или IP..."
              value={searchText}
              onChange={(e) => onSearchChange(e.target.value)}
              className="pl-10"
            />
          </div>
        </div>

        {/* Фильтр по статусу */}
        <div>
          <Label className="text-sm font-medium mb-2 block">
            Статус порта
          </Label>
          <div className="flex flex-wrap gap-2">
            {STATUS_OPTIONS.map((option) => (
              <Badge
                key={option.value}
                variant={statusFilter.includes(option.value) ? "default" : "outline"}
                className={`cursor-pointer transition-colors ${
                  statusFilter.includes(option.value) ? option.color : ''
                }`}
                onClick={() => toggleStatusFilter(option.value)}
              >
                {option.label}
              </Badge>
            ))}
          </div>
        </div>

        <Separator />

        {/* Фильтр по порту */}
        <div>
          <Label htmlFor="port-filter" className="text-sm font-medium">
            Порт
          </Label>
          <Input
            id="port-filter"
            placeholder="80 или 80-443"
            value={portFilter}
            onChange={(e) => onPortFilterChange(e.target.value)}
            className="mt-1"
          />
          <p className="text-xs text-muted-foreground mt-1">
            Укажите порт или диапазон (например: 80 или 22-443)
          </p>
        </div>

        {/* Фильтр по сервису */}
        <div>
          <Label htmlFor="service-filter" className="text-sm font-medium">
            Сервис
          </Label>
          <Input
            id="service-filter"
            placeholder="HTTP, SSH, MySQL..."
            value={serviceFilter}
            onChange={(e) => onServiceFilterChange(e.target.value)}
            className="mt-1"
          />
          <p className="text-xs text-muted-foreground mt-1">
            Фильтр по названию сервиса
          </p>
        </div>
      </CardContent>
    </Card>
  )
}