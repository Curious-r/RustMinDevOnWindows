# How to Install
# First Visual Studio needs to be installed, but not as much as usual. Using powershell:

Invoke-WebRequest https://aka.ms/vs/17/release/vs_buildtools.exe -OutFile vs_buildtools.exe
$VSInstallerProcess = Start-Process -FilePath .\vs_buildtools -ArgumentList "--installPath", "$env:ProgramFiles\Microsoft Visual Studio", "--add", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64", "--add", "Microsoft.Component.VC.Runtime.UCRTSDK", "--passive", "--wait" -Wait -PassThru
Write-Host "Return Code: $VSInstallerProcess"
if ($VSInstallerProcess -eq 0) {
    Write-Host "VS build tools installation completed."
}
else {
    Write-Host "VS build tools installation failed, please check and try to uninstall VS installer manually."
    Write-Host "Then you can install it with :"
    Write-Host ".\vs_buildtoos.exe --installPath $env:ProgramFiles\Microsoft Visual Studio --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -add Microsoft.Component.VC.Runtime.UCRTSDK --passive"
}

# This will install the Visual Studio package manager then open up the GUI installer. You can click straight on install. All the necessary components are already selected.

# Wait for that to finish then run this installer. Alternatively, see Manually Install Only the Libs.

Invoke-WebRequest https://github.com/ChrisDenton/minwinsdk/releases/download/0.0.1/minwinsdk.exe  -OutFile minwinsdk.exe
.\minwinsdk
# If all goes well you should finally be able to install rustup

Invoke-WebRequest https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe -OutFile rustup-init.exe
.\rustup-init -y --default-host x86_64-pc-windows-msvc
