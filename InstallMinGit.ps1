# Author: Curious
# 作者：Curious

function Get-Path-Crs {
    param (
        [Parameter(ParameterSetName = 'GetPath')]
        [Switch]$Machine
    )
    $EnvironmentRegisterKey = 'HKCU:\Environment'
    if ($Machine) {
        $EnvironmentRegisterKey = 'HKLM:\SYSTEM\ControlSet001\Control\Session Manager\Environment\'
    }
    (Get-Item -Path $EnvironmentRegisterKey).GetValue(
        "PATH",
        "",
        [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames) -split ';'
}

function Add-Path-Crs {
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'AddPath', ValueFromPipeline = $true, Position = 0)]
        [String[]]$Input,
        [Parameter(ParameterSetName = 'AddPath')]
        [Switch]$Machine
    )
    PROCESS {
        $EnvironmentRegisterKey = 'HKCU:\Environment'
        if ($Machine) {
            $EnvironmentRegisterKey = 'HKLM:\SYSTEM\ControlSet001\Control\Session Manager\Environment'
        } 

        $InputCombiner = New-Object -TypeName System.Text.StringBuilder

        # 将要添加的值拼接到一个可变字符串中
        $Input | ForEach-Object {
            [Void]$InputCombiner.Append(';')
            [Void]$InputCombiner.Append($_.Trim())
        }

        # 获取环境变量Path
        $Path = (Get-Item -Path $EnvironmentRegisterKey).GetValue(
            "PATH",
            "",
            [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        if ($Path.EndsWith(';')) {
            $Path = $Path.remove($Path.length - 1, 1)
        }

        # 更新环境变量Path
        $Path = $Path + $InputCombiner.ToString()
        Set-ItemProperty -Path $EnvironmentRegisterKey -Name Path -Value $Path
    }
}

function Remove-Path-Crs {
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'RemovePath', ValueFromPipeline = $true, Position = 0)]
        [String[]]$Input,
        [Parameter(ParameterSetName = 'RemovePath')]
        [Switch]$Machine
    )

    PROCESS {
        $EnvironmentRegisterKey = 'HKCU:\Environment'
        if ($Machine) {
            $EnvironmentRegisterKey = 'HKLM:\SYSTEM\ControlSet001\Control\Session Manager\Environment'
        } 

        # 遍历 $Input ，删除环境变量Path中的对应的路径
        $Input | ForEach-Object {
            $Path = (Get-Item -Path $EnvironmentRegisterKey).GetValue(
                "PATH",
                "",
                [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)

            # 在参数开头添加分号，末尾添加反斜杠，以便后续先进行条件最严格的匹配，再逐步退让匹配条件，
            # 以免在Path中留下残余的无用符号
            $EntryToRemove = ';' + $_.Trim()
            if (!$EntryToRemove.EndsWith('\')) {
                $EntryToRemove += '\'
            }

            $EntryToRemove = [Regex]::Escape($EntryToRemove)

            # 检测 $EntryToRemove 在 $Path 中是否有匹配，如果 $EntryToRemove 在 $Path 中没有匹配，
            # 存在 $Path 中相应条目不以反斜杠结尾的可能性，尝试去掉 $EntryToRemove 末尾的反斜杠
            if (!($Path -Match $EntryToRemove)) {
                $EntryToRemove = $EntryToRemove.Substring(0, $EntryToRemove.LastIndexOf('\') - 1)
            }

            # 检测 $EntryToRemove 在 $Path 中是否有匹配，若存在对应值，则执行删除操作，并退出函数
            if ($Path -Match $EntryToRemove) {
                $Path = $Path -Replace $EntryToRemove, ""
                Set-ItemProperty -Path $EnvironmentRegisterKey -Name Path -Value $Path
                return
            }

            # 如果上述判断没有匹配，考虑到Path的结构形式，那么除了确实没有相应条目以外，还存在相应条
            # 目在Path第一条，以至于前边没有分号的可能性。接下来尝试使用不加分号的值进行匹配，流程与
            # 上述类似
            $EntryToRemove = $_.Trim()
            if (!$EntryToRemove.EndsWith('\')) {
                $EntryToRemove += '\'
            }
            $EntryToRemove = [Regex]::Escape($EntryToRemove)
            if (!($Path -Match $EntryToRemove)) {
                $EntryToRemove = $EntryToRemove.Substring(0, $EntryToRemove.LastIndexOf('\') - 1)
            }
            if ($Path -Match $EntryToRemove) {
                $Path = $Path -Replace $EntryToRemove, ""
                Set-ItemProperty -Path $EnvironmentRegisterKey -Name Path -Value $Path
            }

            # 如果仍然没有匹配，那么说明确实没有对应条目，函数运行完毕自动退出
        }
    }
}


# 设置Git安装路径
$InstallPath = "$env:LOCALAPPDATA\Programs\Git"

# 安装Git
function Install-Git-Crs {
    # 从GitHub下载最新发布的BusyBox版MinGit
    $LatestReleaseContent = Invoke-WebRequest https://github.com/git-for-windows/git/releases/latest |
    Select-Object -ExpandProperty Content
    $LatestReleaseContent -Match `
        "/git-for-windows/git/releases/download/v.*.windows.1/MinGit-.*-busybox-64-bit.zip"
    Write-Host "Download start."
    Invoke-WebRequest ("https://github.com" + $Matches[0]) -OutFile Git.zip
    Write-Host "Download complete."

    # 安装前清理Git安装路径
    if ((Test-Path $InstallPath) -eq 1) {
        Remove-Item -Recurse -Force $InstallPath
    } 

    # 解压到目标路径
    Write-Host "Decompressing..."
    Expand-Archive -LiteralPath Git.zip -DestinationPath $InstallPath
    Remove-Item Git.zip
    Write-Host "Complete."
}

# 移除由本脚本安装的Git
function Uninstall-Git-Crs {
    if ((Test-Path $InstallPath) -eq 1) {
        Remove-Item -Recurse -Force $InstallPath
    }
    Write-Host "Complete."
}

# 脚本运行入口
switch ($args) {
    "install" { 
        Install-Git-Crs
        # 启用Windows的长路径支持
        Write-Host "Enbaling long path supoort in Windows..."
        New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
            -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
        Write-Host "Please reboot your machine to make it take effect."
        Write-Host "Install complete."
        Return 
    }
    "update" { 
        Install-Git-Crs
        Write-Host "Update complete."
        Return 
    }
    "uninstall" { 
        Uninstall-Git-Crs
        Write-Host "Uninstall complete."
        Return 
    }
    Default { 
        Write-Host 'Only For "install", "update", "uninstall"'
        Return 
    }
}
