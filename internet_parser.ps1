Clear-Host 

Write-Host -ForegroundColor Yellow @"
8888888b.                           888        88888888888              d8b                           
888   Y88b                          888            888                  Y8P                           
888    888                          888            888                                                
888   d88P 888d888 .d88b.  .d8888b  888888 .d88b.  888  888d888 8888b.  888 88888b.   .d88b.  888d888 
8888888P"  888P"  d88""88b 88K      888   d88""88b 888  888P"      "88b 888 888 "88b d8P  Y8b 888P"   
888        888    888  888 "Y8888b. 888   888  888 888  888    .d888888 888 888  888 88888888 888     
888        888    Y88..88P      X88 Y88b. Y88..88P 888  888    888  888 888 888  888 Y8b.     888     
888        888     "Y88P"   88888P'  "Y888 "Y88P"  888  888    "Y888888 888 888  888  "Y8888  888     
                                                                                                       

"@

Write-Host -ForegroundColor White "created by gemakfy"

Start-Sleep -Seconds 1
Clear-Host

$interfaces = Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | 
              Sort-Object PSChildName

# Default values
$referenceValues = @{
    MTU = 1500
    TCPNoDelay = 1
    TcpAckFrequency = 1
    TcpDelAckTicks = 0
    TcpWindowSize = 64240
}

$allInterfacesData = foreach ($interface in $interfaces) {
    $params = Get-ItemProperty -Path $interface.PSPath
    
    [PSCustomObject]@{
        Interface = $interface.PSChildName
        MTU = if ($null -ne $params.MTU) { $params.MTU } else { "def" }
        TCPNoDelay = if ($null -ne $params.TCPNoDelay) { $params.TCPNoDelay } else { "def" }
        TcpAckFrequency = if ($null -ne $params.TcpAckFrequency) { $params.TcpAckFrequency } else { "def" } 
        TcpDelAckTicks = if ($null -ne $params.TcpDelAckTicks) { $params.TcpDelAckTicks } else { "def" }
        TcpWindowSize = if ($null -ne $params.TcpWindowSize) { $params.TcpWindowSize } else { "def" } 
    }
}

function Write-ColoredTable {
    param($data)
    
    # Заголовки таблицы
    Write-Host ("{0,-38} {1,-8} {2,-12} {3,-16} {4,-14} {5,-14}" -f `
        "Interface", "MTU", "TCPNoDelay", "TcpAckFrequency", "TcpDelAckTicks", "TcpWindowSize")
    
    foreach ($item in $data) {
        Write-Host ("{0,-38} " -f $item.Interface) -NoNewline
        
        $paramsToCheck = @('MTU', 'TCPNoDelay', 'TcpAckFrequency', 'TcpDelAckTicks', 'TcpWindowSize')
        foreach ($param in $paramsToCheck) {
            $value = $item.$param
            
            $width = switch ($param) {
                'MTU' { 8 }
                'TCPNoDelay' { 12 }
                'TcpAckFrequency' { 16 }
                default { 14 }
            }
            
            if ($value -eq "def") {
                Write-Host ("{0,-$width} " -f $value) -NoNewline -ForegroundColor Yellow
            }
            elseif ($value -eq $referenceValues[$param]) {
                Write-Host ("{0,-$width} " -f $value) -NoNewline -ForegroundColor Green
            }
            else {
                Write-Host ("{0,-$width} " -f $value) -NoNewline -ForegroundColor Red
            }
        }
        Write-Host ""
    }
}

# results 
Write-ColoredTable -data ($allInterfacesData | Sort-Object MTU)

# legend colors
Write-Host "`nColor legend:" -ForegroundColor Cyan
Write-Host "  Green" -NoNewline -ForegroundColor Green
Write-Host " - Default value"
Write-Host "  Red" -NoNewline -ForegroundColor Red
Write-Host " - Non-standard value"
Write-Host "  Yellow" -NoNewline -ForegroundColor Yellow
Write-Host " - Default value (not set in registry)"