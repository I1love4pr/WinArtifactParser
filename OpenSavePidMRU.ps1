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

$basePath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU"

if (-not (Test-Path $basePath)) {
    Write-Host "OpenSavePidlMRU registry path not found!" -ForegroundColor Red
    exit
}

$mruItems = Get-ChildItem $basePath | ForEach-Object {
    $extensionKey = $_.PSChildName
    $values = Get-ItemProperty -Path $_.PSPath
    $valueNames = $values.PSObject.Properties | Where-Object { $_.Name -match '^\d+$' }
    
    foreach ($value in $valueNames) {
        $fileData = $value.Value
        $filePath = ""
        
        try {
            $shell = New-Object -ComObject Shell.Application
            $parent = Split-Path $fileData -Parent
            $leaf = Split-Path $fileData -Leaf
            $fileItem = $shell.NameSpace($parent).ParseName($leaf)
            $filePath = if ($fileItem) { $fileItem.Path } else { "Binary data" }
        } catch {
            try { 
                $filePath = [System.Text.Encoding]::Unicode.GetString($fileData) -replace "[^\u0020-\u007E]", ""
                if ([string]::IsNullOrEmpty($filePath)) { $filePath = "Binary data" }
            }
            catch { $filePath = "Binary data" }
        }
        
        # raw data cleaning
        $cleanPath = if ($filePath -ne "Binary data") {
            $fileName = Split-Path $filePath -Leaf
            $cleanName = $fileName -replace '^(?=(.*?\.){2,}).*?\.', ''
            $cleanName = $cleanName.Trim()
            if ([string]::IsNullOrWhiteSpace($cleanName)) { $fileName } else { $cleanName }
        } else {
            "Binary data"
        }
        
        [PSCustomObject]@{
            Extension = $extensionKey
            FilePath = $cleanPath
        }
    }
}

function Display-Results {
    param([array]$items, [string]$filterExtension = $null)
    
    $items = if ($filterExtension) { $items | Where-Object { $_.Extension -eq $filterExtension } } else { $items }
    $items | Sort-Object -Property Extension | Format-Table -AutoSize -Wrap
}

while ($true) {
    Write-Host "
    1. Show all entries
    2. Filter by file type
    3. Exit
    "

    switch (Read-Host "Select") {
        '1' { 
            Clear-Host
            Display-Results $mruItems }
        
        '2' { Clear-Host
            Display-Results $mruItems (Read-Host "Enter file type (exe, dll)") }
        
        '3' { Clear-Host
            exit }

        default { Write-Host "Invalid input" -ForegroundColor Red }
    }
}