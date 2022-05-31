# 安裝Windows
![](img/InstallWin.png)

安裝之前先把硬碟格格式化成一個大分區，然後把 `-DriveLetter:` 設定到那個硬碟的曹位就可以了。
> 要切D曹等你裝好後再從磁碟管理員壓縮出來就可以了。


## 安裝Windows
- Index:1 -> 家用版
- Index:3 -> 專業版
- 其他版本參考下面的查看映像檔資訊

```bash
# 簡短版(預設 Index=1)
irm bit.ly/33SZpuu|iex; InstallWin "D:\Win11.iso" W
irm bit.ly/33SZpuu|iex; InstallWin "D:\install.wim" W
```

```bash
# 從 ISO 檔案安裝
$IsoFile = "D:\DATA\ISO_Files\Win11_Chinese(Traditional)_x64v1.iso"
irm bit.ly/33SZpuu|iex; InstallWin -Path:$IsoFile -Index:1 -DriveLetter:W

# 從 Wim 檔案安裝
$WimFile = "D:\DATA\ISO_Files\install.wim"
irm bit.ly/33SZpuu|iex; InstallWin -Path:$WimFile -Index:1 -DriveLetter:W

# 修復引導(不小心打錯中斷了的話)
irm bit.ly/340Pi6W|iex; autoFixBoot W
```

## 查看映像檔資訊
```bash
# 查看映像檔資訊
irm bit.ly/33SZpuu|iex; Get-WIM_INFO "D:\DATA\ISO_Files\Win11_Chinese(Traditional)_x64v1.iso"
irm bit.ly/33SZpuu|iex; Get-WIM_INFO "D:\DATA\ISO_Files\install.wim"
```


## 壓縮磁碟機
```bash
# 從D曹壓縮64G，並新增E曹
irm bit.ly/33SZpuu|iex; CompressPartition -src:D -dst:E -Size:64GB
```


## 備份系統檔案
```bash
# 備份 W 曹的系統到 Z:\install.wim
irm bit.ly/33SZpuu|iex; CaptureWim -Dri:W -Image:"Z:\install.wim" -Compress
```