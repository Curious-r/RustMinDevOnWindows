# Author: Curious
# 作者：Curious


. $PSScriptRoot\EnvPathManager.ps1
# 在最小限度内安装Visual Studio构建工具
$VSVersion = 17
Write-Host "Downloading vs_buildtools and rustup-init..."
Invoke-WebRequest https://aka.ms/vs/$VSVersion/release/vs_buildtools.exe -OutFile $PSScriptRoot\vs_buildtools.exe 
Invoke-WebRequest https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe -OutFile $PSScriptRoot\rustup-init.exe
Write-Host "Complete."

switch ($args) {
    "install" {
        Write-Host "VS Build Tools installing..."
        $VSInstall = Start-Process -FilePath $PSScriptRoot\vs_buildtools.exe -ArgumentList `
            "--add", `
            "Microsoft.VisualStudio.Component.VC.Tools.x86.x64", `
            "--add", `
            "Microsoft.Component.VC.Runtime.UCRTSDK", `
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

        return
    }
    "uninstall" {
          Write-Host "VS Build Tools uninstalling..."
        $VSInstall = Start-Process -FilePath $PSScriptRoot\vs_buildtools.exe -ArgumentList `
            "uninstall", `
            "--all", `
            "--force", `
            "--passive", `
            "--wait" `
            -Wait -PassThru
        if ($VSInstall.ExitCode -eq 0) {
            Write-Host "VS build tools uninstallation completed."
        }
        else {
            Write-Host "VS build tools uninstall failed." -ForegroundColor Red
            Write-Host "Exit Code: $VSInstall.ExitCode" -ForegroundColor DarkYellow
            Write-Host "Go here and check the meaning of the error code:"
            Write-Host "https://learn.microsoft.com/en-us/visualstudio/install/use-command-line-parameters-to-install-visual-studio?view=vs-2022#error-codes"
        }
    }
}

Remove-Item $PSScriptRoot\vs_buildtools.exe
Remove-Item $PSScriptRoot\rustup-init.exe
