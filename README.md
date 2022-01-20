### 安裝Windows
![](img/InstallWin.png)

```
# 這兩行選一行先打進去
$IsoFile = "D:\DATA\ISO_Files\Win11_Chinese(Traditional)_x64v1.iso"
$WimFile = "D:\DATA\ISO_Files\install.wim"

# 查看映像檔資訊
irm bit.ly/33SZpuu|iex; Get-WIM_INFO -IsoFile:$IsoFile
irm bit.ly/33SZpuu|iex; Get-WIM_INFO -IsoFile:$IsoFile -Index:1
irm bit.ly/33SZpuu|iex; Get-WIM_INFO -WimFile:$WimFile
irm bit.ly/33SZpuu|iex; Get-WIM_INFO -WimFile:$WimFile -Index:1

# 從 ISO 檔案安裝
irm bit.ly/33SZpuu|iex; InstallWin -IsoFile:$IsoFile -Index:1 -DriveLetter:V
# 從 Wim 檔案安裝
irm bit.ly/33SZpuu|iex; InstallWin -WimFile:$WimFile -Index:1 -DriveLetter:V

# 修復引導(不小心打錯中斷了的話)
# autoFixEFI -DriveLetter:V
```