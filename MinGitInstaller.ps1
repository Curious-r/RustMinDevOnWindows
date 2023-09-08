# Author: Curious
# 作者：Curious


. $PSScriptRoot\EnvPathManager.ps1
# 设置Git安装位置，以下两行为默认安装在用户安装目录，如需改动请一并修改。
$GitInstallationLocation = "$env:LOCALAPPDATA\Programs\Git"
# 用户环境变量Path中Git的内容：
$GitPath = ($GitInstallationLocation -replace [Regex]::Escape($env:LOCALAPPDATA), "%LOCALAPPDATA%") `
    + "\cmd"

# 安装Git的函数封装：
function Expand-Git-Crs {
    # 从GitHub下载最新发布的BusyBox版MinGit：
    $LatestReleaseContent = Invoke-WebRequest https://github.com/git-for-windows/git/releases |
    Select-Object -ExpandProperty Content
    $LatestReleaseContent -match `
        "/git-for-windows/git/releases/download/v.*.windows.*/MinGit-.*-busybox-64-bit.zip"
    Write-Host "Download MinGit-busybox-64bit.zip."
    Invoke-WebRequest ("https://github.com" + $Matches[0]) -OutFile $PSScriptRoot\Git.zip

    # 安装前清理Git安装路径：
    if ((Test-Path $GitInstallationLocation) -eq 1) {
        Remove-Item -Recurse -Force $GitInstallationLocation
    } 

    # 解压到目标路径：
    Write-Host "Decompressing..."
    Expand-Archive -LiteralPath $PSScriptRoot\Git.zip -DestinationPath $GitInstallationLocation
    Remove-Item $PSScriptRoot\Git.zip
    Write-Host "Complete."
}

# 移除由本脚本安装的Git的函数封装：
function Remove-Git-Crs {
    if ((Test-Path $GitInstallationLocation) -eq 1) {
        Remove-Item -Recurse -Force $GitInstallationLocation
    }
    Write-Host "Complete."
}

# 脚本运行入口
switch ($args) {
    "install" { 
        Expand-Git-Crs
        # 添加到用户环境变量,支持管道写法
        #$GitPath | Add-Path-Crs
        Add-Path-Crs $GitPath
        # 启用Windows的长路径支持：
        Write-Host "Enbaling long path supoort in Windows, this will take effect after reboot."
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
            -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force

        Write-Host "Install complete."
        Return 
    }
    "update" { 
        Expand-Git-Crs
        Write-Host "Update complete."
        Return 
    }
    "uninstall" { 
        Remove-Git-Crs
        # 删除注册的环境变量,支持管道写法
        #$GitPath | Remove-Path-Crs
        Remove-Path-Crs $GitPath
        Write-Host "Uninstall complete."
        Return 
    }
    Default { 
        Write-Host 'Only For "install", "update", "uninstall"'
        Return 
    }
}