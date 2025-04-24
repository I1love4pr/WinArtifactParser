.NOTES
    References:
    https://dfir.ru/2020/04/08/bam-internals/
    https://github.com/kacos2000/Win10/blob/master/Bam/bam1.ps1
#>

# ignore warnings
$ErrorActionPreference = "SilentlyContinue"

function Get-Signature {

    [CmdletBinding()]
     param (
        [string[]]$FilePath
    )

    $Existence = Test-Path -PathType "Leaf" -Path $FilePath
    $Authenticode = (Get-AuthenticodeSignature -FilePath $FilePath -ErrorAction SilentlyContinue).Status
    $Signature = "Invalid Signature (UnknownError)"

    if ($Existence) {
        if ($Authenticode -eq "Valid") {
            $Signature = "Valid Signature"
        }
        elseif ($Authenticode -eq "NotSigned") {
            $Signature = "Invalid Signature (NotSigned)"
        }
        elseif ($Authenticode -eq "HashMismatch") {
            $Signature = "Invalid Signature (HashMismatch)"
        }
        elseif ($Authenticode -eq "NotTrusted") {
            $Signature = "Invalid Signature (NotTrusted)"
        }
        elseif ($Authenticode -eq "UnknownError") {
            $Signature = "Invalid Signature (UnknownError)"
        }
        return $Signature
    } else {
        $Signature = "File Was Not Found"
        return $Signature
    }
}

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

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "Run script as admin"
    exit
}

if (!(Get-PSDrive -Name HKLM -PSProvider Registry)){
    Try{New-PSDrive -Name HKLM -PSProvider Registry -Root HKEY_LOCAL_MACHINE}
    Catch{Write-Warning "Error Mounting HKEY_Local_Machine"}
}

$bv = ("bam", "bam\State")
Try{$Users = foreach($ii in $bv){Get-ChildItem -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$($ii)\UserSettings\" | Select-Object -ExpandProperty PSChildName}}
Catch{
    Write-Warning "Error Parsing BAM Key. Likely unsupported Windows Version"
    Exit
}

$rpath = @("HKLM:\SYSTEM\CurrentControlSet\Services\bam\","HKLM:\SYSTEM\CurrentControlSet\Services\bam\state\")
$UserBias = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation").ActiveTimeBias

$Bam = Foreach ($Sid in $Users){$u++
    
        foreach($rp in $rpath){
           $BamItems = Get-Item -Path "$($rp)UserSettings\$Sid" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Property

            Try{
            $objSID = New-Object System.Security.Principal.SecurityIdentifier($Sid)
            $User = $objSID.Translate( [System.Security.Principal.NTAccount]) 
            $User = $User.Value
            }
            Catch{$User=""}
            $i=0
            ForEach ($Item in $BamItems){$i++
		    $Key = Get-ItemProperty -Path "$($rp)UserSettings\$Sid" -ErrorAction SilentlyContinue| Select-Object -ExpandProperty $Item
	
            If($key.length -eq 24){
                $Hex=[System.BitConverter]::ToString($key[7..0]) -replace "-",""
			    $Bias = -([convert]::ToInt32([Convert]::ToString($UserBias,2),2))
			    $TimeUser = (Get-Date ([DateTime]::FromFileTimeUtc([Convert]::ToInt64($Hex, 16))).addminutes($Bias) -Format "MM-dd HH:mm:ss") 
			    $d = if((((split-path -path $item) | ConvertFrom-String -Delimiter "\\").P3)-match '\d{1}')
			    {((split-path -path $item).Remove(23)).trimstart("\Device\HarddiskVolume")} else {$d = ""}
			    $file = if((((split-path -path $item) | ConvertFrom-String -Delimiter "\\").P3)-match '\d{1}')
			    {Split-path -leaf ($item).TrimStart()} else {$item}	
			    $cp = if((((split-path -path $item) | ConvertFrom-String -Delimiter "\\").P3)-match '\d{1}')
			    {($item).Remove(1,23)} else {$cp = ""}
			    $path = if((((split-path -path $item) | ConvertFrom-String -Delimiter "\\").P3)-match '\d{1}')
			    {Join-Path -Path "C:" -ChildPath $cp} else {$path = ""}			
			    $sig = if((((split-path -path $item) | ConvertFrom-String -Delimiter "\\").P3)-match '\d{1}')
			    {Get-Signature -FilePath $path} else {$sig = ""}				
                [PSCustomObject]@{
						    'Last Execution Time' = $TimeUser
						     Application = 	$file
						     Path =  		$path
                             Signature =    $Sig
						     User =         $User
                             }}}}}

$Bam | Out-GridView -PassThru -Title "gemakfy | files: $($Bam.count)"
