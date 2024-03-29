﻿# Author: Curious
# 作者：Curious


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
        & $PSScriptRoot\rustup-init.exe -y --default-host x86_64-pc-windows-msvc
        Remove-Item $PSScriptRoot\vs_buildtools.exe
        Remove-Item $PSScriptRoot\rustup-init.exe
        
        return
    }
    "uninstall" {
        Write-Host "VS Build Tools uninstalling..."
        Get-Package -Name "Microsoft Visual Studio Installer" | Uninstall-Package
    }
}

