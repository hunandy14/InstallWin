### 安裝Windows


```
# ISO 檔案
$IsoFile = "D:\DATA\ISO_Files\Win11_Chinese(Traditional)_x64v1.iso"
irm bit.ly/33SZpuu|iex; InstallWin -IsoFile:$IsoFile -Index:1 -DriveLetter:V2/3cl

# Wim 檔案
$WimFile = "D:\DATA\ISO_Files\install.wim"
irm bit.ly/33SZpuu|iex; InstallWin -WimFile:$WimFile -Index:1 -DriveLetter:V
```