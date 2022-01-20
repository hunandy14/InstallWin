# 載入外部函式
irm "https://raw.githubusercontent.com/hunandy14/autoFixEFI/master/autoFixEFI.ps1"|iex
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
        [Parameter(Position = 0, ParameterSetName = "IsoFile", Mandatory=$true)]
        [string]$IsoFile,
        [Parameter(Position = 0, ParameterSetName = "WimFile", Mandatory=$true)]
        [string]$WimFile, 
        [Parameter(Position = 1, ParameterSetName = "", Mandatory=$true)]
        [string]$Index,
        [Parameter(Position = 2, ParameterSetName = "", Mandatory=$true)]
        [string]$DriveLetter,
        [switch]$FixEFI,
        [switch]$Force
    )
    
    # 載入磁碟代號
    $Dri = Get-Partition -DriveLetter:$DriveLetter
    if ($Dri){ #磁碟是否存在
        if (($Dri|Get-Disk).PartitionStyle -ne "GPT") { # 驗證GPT格式
            $Dri|Get-Disk
            Write-Host "該曹位的硬碟不是GPT格式，請先將該磁碟轉換成GPT格式"
            return
        }
    } else { Write-Host "DriveLetter 的曹位不存在"; return }
    
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
        $response = Read-Host "  沒有異議，請輸入Y (Y/N) ";
        if ($response -ne "Y" -or $response -ne "Y" -or $Force) { Write-Host "使用者中斷" -ForegroundColor:Red; return; }
        Write-Host "開始安裝 Windows..." -ForegroundColor:Yellow
        $WinPath = $DriveLetter+":\"
        Dism /apply-image /imagefile:$wim /index:$Index /applydir:$WinPath
    }
    if ($IsoFile) {
        $Mount = Dismount-DiskImage -InputObject:$Mount
    }
    
    # 修復引導
    if ($FixEFI) {
        autoFixEFI -DriveLetter:V -Force:$Force
    }
}
# 測試
function Test-InstallWin {
    $IsoFile = "D:\DATA\ISO_Files\Win11_Chinese(Traditional)_x64v1.iso"
    $WimFile = "D:\DATA\ISO_Files\install.wim"
    # 查看ISO資訊
    # Get-WIM_INFO -IsoFile:$IsoFile
    # Get-WIM_INFO -WimFile:$WimFile
    #  安裝Windows
    # InstallWin -IsoFile:$IsoFile -Index:1 -DriveLetter:V2/3cl
    InstallWin -WimFile:$WimFile -Index:1 -DriveLetter:V;
    # 修復引導(不小心打錯中斷了的話)
    # autoFixEFI -DriveLetter:V
} # Test-InstallWin
