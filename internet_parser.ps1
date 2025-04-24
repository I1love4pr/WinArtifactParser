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

$interfaces = Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | 
              Sort-Object PSChildName

$allInterfacesData = foreach ($interface in $interfaces) {
    $params = Get-ItemProperty -Path $interface.PSPath
    
    # Формируем объект с параметрами
    [PSCustomObject]@{
        Interface = $interface.PSChildName
        MTU = if ($null -ne $params.MTU) { $params.MTU } else { "def" }
        TCPNoDelay = if ($null -ne $params.TCPNoDelay) { $params.TCPNoDelay } else { "def" }
        TcpAckFrequency = if ($null -ne $params.TcpAckFrequency ) { $params.TcpAckFrequency } else { "def" } 
        TcpDelAckTicks = if ($null -ne $params.TcpDelAckTicks ) { $params.TcpDelAckTicks } else { "def" }
        TcpWindowSize = if ($null -ne $params.TcpWindowSize ) { $params.TcpWindowSize } else { "def" } 
    }
}

$allInterfacesData | Sort-Object MTU | Format-Table -AutoSize -Wrap -Property *