# ============================================================
# Скрипт сканирования подсети 192.168.1.3 – 192.168.1.254
# Определяет IP, имя хоста и ОС (по TTL)
# Результат сохраняется в CSV с меткой времени
# ============================================================

$networkPrefix = "192.168.1."
$startIP = 3
$endIP = 254
$outputFile = "subnet_scan_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"

$results = @()

Write-Host "Начинаем сканирование подсети 192.168.1.3 – 192.168.1.254..." -ForegroundColor Cyan

for ($i = $startIP; $i -le $endIP; $i++) {
    $ip = $networkPrefix + $i
    Write-Progress -Activity "Сканирование IP-адресов" -Status "Проверка $ip" -PercentComplete (($i - $startIP + 1) / ($endIP - $startIP + 1) * 100)

    # Создаём объект Ping
    $ping = New-Object System.Net.NetworkInformation.Ping
    try {
        $reply = $ping.Send($ip, 1000)   # таймаут 1 секунда
        if ($reply.Status -eq 'Success') {
            $ttl = $reply.Options.Ttl

            # Приблизительное определение ОС по TTL
            if ($ttl -le 64) {
                $os = "Linux/Unix (TTL=$ttl)"
            } elseif ($ttl -le 128) {
                $os = "Windows (TTL=$ttl)"
            } elseif ($ttl -le 255) {
                $os = "Cisco/Other (TTL=$ttl)"
            } else {
                $os = "Unknown (TTL=$ttl)"
            }

            # Попытка получить имя хоста через DNS
            $hostname = "Unknown"
            try {
                $hostEntry = [System.Net.Dns]::GetHostEntry($ip)
                $hostname = $hostEntry.HostName
            } catch {
                # Если DNS не помог, пробуем nbtstat для NetBIOS-имени
                try {
                    $nbtOutput = & nbtstat -A $ip 2>$null
                    if ($nbtOutput) {
                        $lines = $nbtOutput -split "`r`n"
                        foreach ($line in $lines) {
                            if ($line -match "^\s*(\S+)\s+<00>\s+UNIQUE") {
                                $hostname = $matches[1]
                                break
                            } elseif ($line -match "^\s*(\S+)\s+<20>\s+UNIQUE") {
                                $hostname = $matches[1]
                                break
                            }
                        }
                    }
                } catch {
                    # Игнорируем ошибки nbtstat
                }
            }

            # Сохраняем результат
            $result = [PSCustomObject]@{
                IP       = $ip
                Hostname = $hostname
                OS       = $os
                TTL      = $ttl
                Status   = "Alive"
            }
            $results += $result
            Write-Host "Найден активный хост: $ip - $hostname - $os" -ForegroundColor Green
        }
    } catch {
        # Ошибка при пинге (например, таймаут) – пропускаем
    }
}

# Сохраняем все найденные записи в CSV
if ($results.Count -gt 0) {
    $results | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8
    Write-Host "`nСканирование завершено. Найдено $($results.Count) активных хостов." -ForegroundColor Yellow
    Write-Host "Результаты сохранены в файл: $outputFile" -ForegroundColor Yellow
} else {
    Write-Host "`nАктивных хостов не найдено." -ForegroundColor Red
}