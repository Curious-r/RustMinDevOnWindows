# Author: Curious
# 作者：Curious

function Add-ConfigIfNotExists {
    <#
    .SYNOPSIS
    检查配置文件中是否存在特定配置行，不存在则添加

    .DESCRIPTION
    此函数会检查指定配置文件中是否存在特定配置行，
    如果不存在，则将其添加到文件末尾。

    .PARAMETER ConfigFile
    配置文件路径，默认为 PowerShell 配置文件

    .PARAMETER ConfigLine
    要检查并添加的配置行内容

    .PARAMETER Comment
    可选注释，添加在配置行上方

    .EXAMPLE
    Add-ConfigIfNotExists -ConfigLine '$env:RUSTUP_DIST_SERVER = "https://rsproxy.cn"' -Comment "Rust 镜像配置"
    #>
    param (
        [string]$ConfigFile = $PROFILE,
        [Parameter(Mandatory = $true)]
        [string]$ConfigLine,
        [string]$Comment
    )

    # 确保配置文件存在
    if (!(Test-Path $ConfigFile)) {
        New-Item -ItemType File -Path $ConfigFile -Force | Out-Null
        Write-Host "已创建配置文件: $ConfigFile" -ForegroundColor Cyan
    }

    # 检查配置是否已存在
    $content = Get-Content -Path $ConfigFile -Raw
    if ($content -notmatch [regex]::Escape($ConfigLine)) {
        # 添加可选注释
        $lineToAdd = if ($Comment) { "# $Comment`n$ConfigLine" } else { $ConfigLine }

        # 追加配置行
        Add-Content -Path $ConfigFile -Value "`n$lineToAdd"
        Write-Host "已添加配置: $ConfigLine" -ForegroundColor Green
    } else {
        Write-Host "配置已存在: $ConfigLine" -ForegroundColor Yellow
    }
}

function Remove-ConfigLine {
    <#
    .SYNOPSIS
    从 PowerShell 配置文件中检查并删除特定配置行

    .DESCRIPTION
    此函数会检查 PowerShell 配置文件中是否存在指定的配置行，
    如果存在则安全删除，同时保留文件的其他内容。

    .PARAMETER ConfigLine
    要删除的配置行内容

    .EXAMPLE
    Remove-ConfigLine -ConfigLine '$env:RUSTUP_DIST_SERVER = "https://rsproxy.cn"'

    .EXAMPLE
    Remove-ConfigLine -ConfigLine '$env:RUSTUP_UPDATE_ROOT = "https://rsproxy.cn/rustup"'
    #>
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigLine
    )

    # 确保配置文件存在
    if (Test-Path $PROFILE) {
        $content = Get-Content -Path $PROFILE

        # 检查配置是否存在
        if ($content -match [regex]::Escape($ConfigLine)) {
            # 移除匹配的行并保存文件
            $newContent = $content | Where-Object { $_ -notmatch [regex]::Escape($ConfigLine) }
            $newContent | Set-Content -Path $PROFILE
            Write-Host "已成功从 $PROFILE 中移除配置: $ConfigLine" -ForegroundColor Green
        } else {
            Write-Host "未找到配置: $ConfigLine，无需删除" -ForegroundColor Yellow
        }
    } else {
        Write-Host "PowerShell 配置文件不存在: $PROFILE" -ForegroundColor Red
    }
}

switch ($args) {
    "install" {
        # 在最小限度内安装Visual Studio构建工具
        $VSVersion = 17
        $SDKVersion = 22621
        Write-Host "Downloading vs_buildtools and rustup-init..."
        Invoke-WebRequest https://aka.ms/vs/$VSVersion/release/vs_buildtools.exe -OutFile $PSScriptRoot\vs_buildtools.exe
        Invoke-WebRequest https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe -OutFile $PSScriptRoot\rustup-init.exe
        Write-Host "Complete."
        Write-Host "VS Build Tools installing..."
        $VSInstall = Start-Process -FilePath $PSScriptRoot\vs_buildtools.exe -ArgumentList `
            "--add", `
            "Microsoft.VisualStudio.Component.VC.Tools.x86.x64", `
            "--add", `
            "Microsoft.VisualStudio.Component.Windows11SDK.$SDKVersion", `
            "--passive", `
            "--wait" `
            -Wait -PassThru
        if ($VSInstall.ExitCode -eq 0) {
            Write-Host "VS build tools installation completed." -ForegroundColor Green
        }
        else {
            Write-Host "VS build tools installation failed." -ForegroundColor Red
            Write-Host "Exit Code: $VSInstall.ExitCode" -ForegroundColor DarkYellow
            Write-Host "Go here and check the meaning of the error code:"
            Write-Host "https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022#error-codes"
        }
        Write-Host "Rustup initing..."
        if (!(Test-Path $PROFILE)) { New-Item -Path $PROFILE -ItemType File -Force }
        # 添加 Rust 镜像配置
        $Mirrors = @{
            '$env:RUSTUP_DIST_SERVER = "https://rsproxy.cn"' = "Rust 组件下载服务器"
            '$env:RUSTUP_UPDATE_ROOT = "https://rsproxy.cn/rustup"' = "Rustup 更新服务器"
        }

        foreach ($ConfigLine in $Mirrors.Keys) {
            Add-ConfigIfNotExists -ConfigLine $ConfigLine -Comment $Mirrors[$ConfigLine]
        }
        & $PSScriptRoot\rustup-init.exe -y --default-host x86_64-pc-windows-msvc
        if (Test-Path "$HOME\.cargo\config.toml") {Remove-Item "$HOME\.cargo\config.toml"}
        New-Item -Path "$HOME\.cargo\config.toml" -ItemType File -Force
        $CargoInitConfig = @'
            [source.crates-io]
            replace-with = 'rsproxy-sparse'

            [source.rsproxy]
            registry = "https://rsproxy.cn/crates.io-index"

            [source.rsproxy-sparse]
            registry = "sparse+https://rsproxy.cn/index/"

            [registries.rsproxy]
            index = "https://rsproxy.cn/crates.io-index"

            [net]
            git-fetch-with-cli = true
        '@

        $CargoInitConfig | Set-Content -Path "$HOME\.cargo\config.toml" -Encoding UTF8
        Write-Host "已生成 Cargo 初始配置文件" -ForegroundColor Green
        Remove-Item $PSScriptRoot\vs_buildtools.exe
        Remove-Item $PSScriptRoot\rustup-init.exe

        return
    }
    "uninstall" {
        Write-Host "VS Build Tools uninstalling..."
        Get-Package -Name "Microsoft Visual Studio Installer" | Uninstall-Package
        # 定义要删除的配置行
        $LinesToRemove = @(
            '$env:RUSTUP_DIST_SERVER = "https://rsproxy.cn"',
            '$env:RUSTUP_UPDATE_ROOT = "https://rsproxy.cn/rustup"'
        )
        # 分别删除每个配置行
        foreach ($Line in $LinesToRemove) {
            Remove-ConfigLine -ConfigLine $Line
        }
        if (Test-Path "$HOME\.cargo\config.toml") {Remove-Item "$HOME\.cargo\config.toml"}
    }
}
