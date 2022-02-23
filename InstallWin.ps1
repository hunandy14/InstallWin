# 壓縮磁碟
function CompressPartition {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory=$true)]
        [string]$srcDriveLetter,
        [Parameter(Position = 1, ParameterSetName = "", Mandatory=$true)]
        [string]$dstDriveLetter,
        [Parameter(Position = 2, ParameterSetName = "")]
        [Int64]$Size,
        [switch] $Force
    )
    # 載入磁碟代號
    $Dri = Get-Partition -DriveLetter:$srcDriveLetter
    if (!$Dri){ 
        Write-Host "[src曹位不存在]::" -ForegroundColor:Red -NoNewline
        Write-Host "磁碟 $srcDriveLetter 不存在，src請選擇其他曹位"; return 
    }
    $Dri2 = Get-Partition -DriveLetter:$dstDriveLetter -ErrorAction SilentlyContinue
    if($Dri2) { 
        Write-Host "[dst曹位被占用]::" -ForegroundColor:Red -NoNewline
        Write-Host "磁碟 $dstDriveLetter 已存在，dst請選擇其他曹位"; return 
    }
    if (!$Size) { $Size = 64GB; Write-Host "預設Size為 $($Size/1GB) GB" } 
    # 計算壓縮空間
    $DriSize = $Dri|Get-PartitionSupportedSize
    $CmpSize = $DriSize.SizeMax - $DriSize.SizeMin
    if ($Size -gt $CmpSize) { 
        Write-Host "[空間不足]::" -ForegroundColor:Red -NoNewline
        Write-Host "磁碟 $srcDriveLetter 只剩 $([convert]::ToInt64($CmpSize/1MB))MB。" -NoNewline
        Write-Host "無法壓縮出 $($Size/1MB)MB"
        return
    }
    # 壓縮
    Write-Host "  即將從 $srcDriveLetter 曹壓縮 $($Size/1GB)GB，並建立 $dstDriveLetter 曹" -ForegroundColor:Yellow
    if (!$Force) {
        $response = Read-Host "  沒有異議，請輸入Y (Y/N) ";
        if ($response -ne "Y" -or $response -ne "Y") { Write-Host "使用者中斷" -ForegroundColor:Red; return; }
    }
    # 壓縮磁區
    $Dri|Resize-Partition -Size:$($Dri.size-$Size-8MB); 
    ((($Dri|New-Partition -Size:$($Size+8MB) )|Format-Volume)|Get-Partition)|Set-Partition -NewDriveLetter:$dstDriveLetter
}
# 合併磁碟
function MergePartition {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory=$true)]
        [string]$DriveLetter,
        [switch]$Force
    )
    # 載入磁碟代號
    $Dri = Get-Partition -DriveLetter:$DriveLetter
    if (!$Dri){ Write-Host "DriveLetter 的曹位不存在"; return }
    # 合併到滿
    $Size = ($Dri|Get-PartitionSupportedSize).SizeMax
    if ($Size-$Dri.Size -eq 0) { Write-Host "磁碟 $DriveLetter 後方沒有多餘的空間可以合併"; return }
    Write-Host "磁碟 $DriveLetter 後還有 $(($Size-$Dri.Size)/1MB)MB 的空間，即將合併這些空間"
    if (!$Force) {
        $response = Read-Host "  沒有異議，請輸入Y (Y/N) ";
        if ($response -ne "Y" -or $response -ne "Y") { Write-Host "使用者中斷" -ForegroundColor:Red; return; }
    }
    $Dri|Resize-Partition -Size:$Size
}



# 獲取Wim資訊
function Get-WIM_INFO {
    param (
        [Parameter(Position = 0, ParameterSetName = "IsoFile", Mandatory=$true)]
        [string]$IsoFile,
        [Parameter(Position = 0, ParameterSetName = "WimFile", Mandatory=$true)]
        [string]$WimFile,
        [Parameter(Position = 1, ParameterSetName = "")]
        [string]$Index
    )
    if ($IsoFile) {
        $Mount = Mount-DiskImage $IsoFile
        $wim = (($Mount)|Get-Volume).DriveLetter+":\sources\install.wim";
    } elseif ($WimFile) {
        $wim = $WimFile
    }
    
    if ($Index) {
        Dism /Get-ImageInfo /ImageFile:$wim /index:$Index
    } else {
        Dism /Get-ImageInfo /ImageFile:$wim
    }
    
    if ($IsoFile) { $Mount = Dismount-DiskImage -InputObject:$Mount }
}
# 安裝Windows
function InstallWin {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory=$true)]
        [string]$DriveLetter,
        [Parameter(Position = 1, ParameterSetName = "IsoFile", Mandatory=$true)]
        [string]$IsoFile,
        [Parameter(Position = 1, ParameterSetName = "WimFile", Mandatory=$true)]
        [string]$WimFile, 
        [Parameter(Position = 2, ParameterSetName = "")]
        [string]$Index,
        [switch]$Compact,
        [switch]$Force
    )
    if (!$Index) { $Index="1" }
    # 載入磁碟代號
    $Dri = Get-Partition -DriveLetter:$DriveLetter
    if (!$Dri){ Write-Host "DriveLetter 的曹位不存在"; return }
    
    # 掛載映像檔
    if ($IsoFile) {
        $Mount = Mount-DiskImage $IsoFile
        if (!$Mount) { Write-Host "無法載入映像檔，檢查映像檔位置是否正確"; return}
        $wim = (($Mount)|Get-Volume).DriveLetter+":\sources\install.wim";
    } elseif ($WimFile) {
        $wim = $WimFile
    }
    
    # 安裝到指定曹位
    if ($Dri) {
        Write-Host "即將開始安裝Windows到" -NoNewline
        Write-Host " ($DriveLetter`:\) " -ForegroundColor:Yellow -NoNewline
        Write-Host "曹位。程序不會自動格式化" -NoNewline
        Write-Host "請確保該曹位已經格式化" -ForegroundColor:Red
        if (!$Force) {
            $response = Read-Host "  沒有異議，請輸入Y (Y/N) ";
            if ($response -ne "Y" -or $response -ne "Y") { Write-Host "使用者中斷" -ForegroundColor:Red; return; }
        }
        Write-Host "開始安裝 Windows..." -ForegroundColor:Yellow
        $WinPath = $DriveLetter+":\"
        $cmd = "Dism /apply-image /imagefile:$wim /index:$Index /applydir:$WinPath"
        if ($Compact) {$cmd = $cmd+" /compact"}
        Invoke-Expression $cmd
    }
    if ($IsoFile) {
        $Mount = Dismount-DiskImage -InputObject:$Mount
    }
    
    # 修復引導
    irm "https://raw.githubusercontent.com/hunandy14/autoFixEFI/master/autoFixBoot.ps1" | iex
    autoFixBoot -DriveLetter:$DriveLetter -Force
}



# 建立 WimIgnore.ini 檔案
function WimIgnore {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory=$true)]
        [string] $DriveLetter,
        [string] $Out
    )
    if ($PSScriptRoot) { $curDir = $PSScriptRoot } else { $curDir = (Get-Location).Path }
    $ignore = Invoke-RestMethod "raw.githubusercontent.com/hunandy14/WimIgnore/master/WimScript.ini"
    $onedrive = (Get-ChildItem "$($DriveLetter):\Users" -Dir | ForEach-Object {
        Get-ChildItem $_.FullName -Dir -Filter:"Onedrive*"
    })
    Write-Host "WimIgnore will ignore the following paths"  -ForegroundColor:Yellow
    $onedrive.FullName | ForEach-Object {
        Write-Host "  - $_"
        $path=$_ -replace ("$DriveLetter`:", "")
        $ignore = $ignore + "$path`n"
    }
    if (!$Out) { $Out = "$curDir\WimScript.ini" }
    [System.IO.File]::WriteAllText($Out, $ignore.trim("`n"));
} # WimIgnore -DriveLetter:C -Out:"Z:\WimScript.ini"
# 備份系統
function CaptureWim {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory=$true)]
        [string] $DriveLetter,
        [Parameter(Position = 1, ParameterSetName = "", Mandatory=$true)]
        [string] $ImageFile,
        [Parameter(Position = 2, ParameterSetName = "")]
        [string] $Name,
        [switch] $Compress
        
    )
    $CaptureDir= "$DriveLetter`:\"
    $WimScript = "$env:TEMP\WimScript.ini"
    if (!$Name) { $Name = "SystemBackup" }
    
    WimIgnore $DriveLetter -Out:$WimScript
    $cmd = "Dism /Capture-Image /ImageFile:$ImageFile /CaptureDir:$CaptureDir /Name:$Name /ConfigFile:$WimScript"
    if ($Compress) { $cmd = "$cmd /Compress:max" }
    Invoke-Expression $cmd
}



# 測試
# function Test-InstallWin {
    # $IsoFile = "D:\DATA\ISO_Files\Win11_Chinese(Traditional)_x64v1.iso"
    # $WimFile = "D:\DATA\ISO_Files\install.wim"
    # 查看ISO資訊
    # Get-WIM_INFO -IsoFile:$IsoFile
    # Get-WIM_INFO -WimFile:$WimFile
    #  安裝Windows
    # InstallWin -IsoFile:$IsoFile -Index:1 -DriveLetter:V2/3cl
    # InstallWin -WimFile:$WimFile -Index:1 -DriveLetter:V;
    # 修復引導(不小心打錯中斷了的話)
    # autoFixEFI -DriveLetter:V
    
    # CompressPartition -srcDriveLetter:D -dstDriveLetter:E -Size:64GB
    
    # MergePartition -DriveLetter:D -Force
    
    # CaptureWim -Dri:W -Image:"Z:\install.wim" -Compress
# } # Test-InstallWin
