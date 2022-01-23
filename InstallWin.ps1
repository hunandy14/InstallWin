# ���J�~���禡
irm "https://raw.githubusercontent.com/hunandy14/autoFixEFI/master/autoFixEFI.ps1"|iex
# ���Wim��T
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
# �w��Windows
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
    
    # ���J�ϺХN��
    $Dri = Get-Partition -DriveLetter:$DriveLetter
    if ($Dri){ #�ϺЬO�_�s�b
        if (($Dri|Get-Disk).PartitionStyle -ne "GPT") { # ����GPT�榡
            $Dri|Get-Disk
            Write-Host "�ӱ�쪺�w�Ф��OGPT�榡�A�Х��N�ӺϺ��ഫ��GPT�榡"
            return
        }
    } else { Write-Host "DriveLetter ����줣�s�b"; return }
    
    # �����M����
    if ($IsoFile) {
        $Mount = Mount-DiskImage $IsoFile
        if (!$Mount) { Write-Host "�L�k���J�M���ɡA�ˬd�M���ɦ�m�O�_���T"; return}
        $wim = (($Mount)|Get-Volume).DriveLetter+":\sources\install.wim";
    } elseif ($WimFile) {
        $wim = $WimFile
    }
    
    # �w�˨���w���
    if ($Dri) {
        Write-Host "�Y�N�}�l�w��Windows��" -NoNewline
        Write-Host " ($DriveLetter`:\) " -ForegroundColor:Yellow -NoNewline
        Write-Host "���C�{�Ǥ��|�۰ʮ榡��" -NoNewline
        Write-Host "�нT�O�ӱ��w�g�榡��" -ForegroundColor:Red
        if (!$Force) {
            $response = Read-Host "  �S����ĳ�A�п�JY (Y/N) ";
            if ($response -ne "Y" -or $response -ne "Y") { Write-Host "�ϥΪ̤��_" -ForegroundColor:Red; return; }
        }
        Write-Host "�}�l�w�� Windows..." -ForegroundColor:Yellow
        $WinPath = $DriveLetter+":\"
        Dism /apply-image /imagefile:$wim /index:$Index /applydir:$WinPath
    }
    if ($IsoFile) {
        $Mount = Dismount-DiskImage -InputObject:$Mount
    }
    
    # �״_�޾�
    if ($FixEFI) {
        autoFixEFI -DriveLetter:V -Force:$Force
    }
}
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
    # ���J�ϺХN��
    $Dri = Get-Partition -DriveLetter:$srcDriveLetter
    
    if (!$Dri){ Write-Host "DriveLetter ����줣�s�b"; return }
    if (!$Size) {
        $Size = 64GB; Write-Host "�w�]Size�� $($Size/1GB) GB"
    } 
    # �p�����Y�Ŷ�
    $DriSize = $Dri|Get-PartitionSupportedSize
    $CmpSize = $DriSize.SizeMax - $DriSize.SizeMin
    if ($Size -gt $CmpSize) { 
        Write-Host "[�Ŷ�����]::" -ForegroundColor:Red -NoNewline
        Write-Host "�Ϻ� $srcDriveLetter �u�� $([convert]::ToInt64($CmpSize/1GB))GB�C" -NoNewline
        Write-Host "�L�k���Y�X $($Size/1GB)GB"
        return
    }
    # ���Y
    Write-Host "  �Y�N�q $srcDriveLetter �����Y $($Size/1GB)GB�A�ëإ� $dstDriveLetter ��" -ForegroundColor:Yellow
    if (!$Force) {
        $response = Read-Host "  �S����ĳ�A�п�JY (Y/N) ";
        if ($response -ne "Y" -or $response -ne "Y") { Write-Host "�ϥΪ̤��_" -ForegroundColor:Red; return; }
    }
    # ���Y�ϰ�
    $Size = $Size + 8MB
    $Dri|Resize-Partition -Size:($Dri.size-$Size); 
    ((($Dri|New-Partition -Size:$Size )|Format-Volume)|Get-Partition)|Set-Partition -NewDriveLetter:$dstDriveLetter
}

function MergePartition {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory=$true)]
        [string]$DriveLetter,
        [switch]$Force
    )
    # ���J�ϺХN��
    $Dri = Get-Partition -DriveLetter:$DriveLetter
    if (!$Dri){ Write-Host "DriveLetter ����줣�s�b"; return }
    # �X�֨캡
    $Size = ($Dri|Get-PartitionSupportedSize).SizeMax
    if ($Size-$Dri.Size -eq 0) { Write-Host "�Ϻ� $DriveLetter ���S���h�l���Ŷ��i�H�X��"; return }
    Write-Host "�Ϻ� $DriveLetter ���٦� $(($Size-$Dri.Size)/1MB)MB ���Ŷ��A�Y�N�X�ֳo�ǪŶ�"
    if (!$Force) {
        $response = Read-Host "  �S����ĳ�A�п�JY (Y/N) ";
        if ($response -ne "Y" -or $response -ne "Y") { Write-Host "�ϥΪ̤��_" -ForegroundColor:Red; return; }
    }
    $Dri|Resize-Partition -Size:$Size
}
# ����
function Test-InstallWin {
    $IsoFile = "D:\DATA\ISO_Files\Win11_Chinese(Traditional)_x64v1.iso"
    $WimFile = "D:\DATA\ISO_Files\install.wim"
    # �d��ISO��T
    # Get-WIM_INFO -IsoFile:$IsoFile
    # Get-WIM_INFO -WimFile:$WimFile
    #  �w��Windows
    # InstallWin -IsoFile:$IsoFile -Index:1 -DriveLetter:V2/3cl
    # InstallWin -WimFile:$WimFile -Index:1 -DriveLetter:V;
    # �״_�޾�(���p�ߥ������_�F����)
    # autoFixEFI -DriveLetter:V
    
    CompressPartition -srcDriveLetter:D -dstDriveLetter:E -Size:64GB
    
    # MergePartition -DriveLetter:D -Force
} 
Test-InstallWin
