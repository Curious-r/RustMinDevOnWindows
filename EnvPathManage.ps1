# Author: Curious
# 作者：Curious

function Get-Path-Crs {
    [CmdletBinding()]
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
    [CmdletBinding()]
    param (
        # 声明可以接受管道输入的参数 $InputObject ，PowerShell原生cmdlet中承接管道输入的参数都叫这个名字，因此，
        # 在自定义函数中尽量也要继承这个写法，以增加代码的可读性。
        [Parameter(Mandatory = $true, ParameterSetName = 'AddPath', ValueFromPipeline = $true, Position = 0)]
        [String[]]$InputObject,
        [Parameter(ParameterSetName = 'AddPath')]
        [Switch]$Machine
    )
    PROCESS {
        $EnvironmentRegisterKey = 'HKCU:\Environment'
        if ($Machine) {
            $EnvironmentRegisterKey = 'HKLM:\SYSTEM\ControlSet001\Control\Session Manager\Environment'
        } 

        $InputCombiner = New-Object -TypeName System.Text.StringBuilder

        # 将要添加的值拼接到一个可变字符串中：
        $InputObject | ForEach-Object {
            [Void]$InputCombiner.Append(';')
            [Void]$InputCombiner.Append($_.Trim())
        }

        # 获取环境变量Path：
        $Path = (Get-Item -Path $EnvironmentRegisterKey).GetValue(
            "PATH",
            "",
            [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        if ($Path.EndsWith(';')) {
            $Path = $Path.Remove($Path.length - 1, 1)
        }

        # 更新环境变量Path：
        $Path = $Path + $InputCombiner.ToString()
        Set-ItemProperty -Path $EnvironmentRegisterKey -Name Path -Value $Path
    }
}

function Remove-Path-Crs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = 'RemovePath', ValueFromPipeline = $true, Position = 0)]
        [String[]]$InputObject,
        [Parameter(ParameterSetName = 'RemovePath')]
        [Switch]$Machine
    )

    PROCESS {
        $EnvironmentRegisterKey = 'HKCU:\Environment'
        if ($Machine) {
            $EnvironmentRegisterKey = 'HKLM:\SYSTEM\ControlSet001\Control\Session Manager\Environment'
        } 

        # 遍历 $InputObject ，删除环境变量Path中的对应的路径：
        $InputObject | ForEach-Object {
            $Path = (Get-Item -Path $EnvironmentRegisterKey).GetValue(
                "PATH",
                "",
                [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)

            # 在参数开头添加分号，末尾添加反斜杠，以便后续先进行条件最严格的匹配，再逐步退让匹配条件，
            # 以免在Path中留下残余的无用符号。
            $EntryToRemove = ';' + $_.Trim()
            if (!$EntryToRemove.EndsWith('\')) {
                $EntryToRemove += '\'
            }

            $EntryToRemove = [Regex]::Escape($EntryToRemove)

            # 检测 $EntryToRemove 在 $Path 中是否有匹配，如果 $EntryToRemove 在 $Path 中没有匹配，
            # 存在 $Path 中相应条目不以反斜杠结尾的可能性，尝试去掉 $EntryToRemove 末尾的反斜杠。
            if (!($Path -match $EntryToRemove)) {
                $EntryToRemove = $EntryToRemove.SubString(0, $EntryToRemove.LastIndexOf('\') - 1)
            }

            # 检测 $EntryToRemove 在 $Path 中是否有匹配，若存在对应值，则执行删除操作，并提前返回，
            # ForEach-Object 将处理管道传入的集合中的下一个对象。
            if ($Path -match $EntryToRemove) {
                $Path = $Path -replace $EntryToRemove, ""
                Set-ItemProperty -Path $EnvironmentRegisterKey -Name Path -Value $Path
                return
            }

            # 如果上述判断没有匹配，考虑到Path的结构形式，那么除了确实没有相应条目以外，还存在相应条目在
            # Path第一条，以至于前边没有分号的可能性。接下来尝试使用不加分号的值进行匹配，流程与前述类似。
            $EntryToRemove = $_.Trim()
            if (!$EntryToRemove.EndsWith('\')) {
                $EntryToRemove += '\'
            }
            # 转义反斜杠以适应正则表达式：
            $EntryToRemove = [Regex]::Escape($EntryToRemove)
            if (!($Path -match $EntryToRemove)) {
                $EntryToRemove = $EntryToRemove.Substring(0, $EntryToRemove.LastIndexOf('\') - 1)
            }
            if ($Path -match $EntryToRemove) {
                $Path = $Path -replace $EntryToRemove, ""
                Set-ItemProperty -Path $EnvironmentRegisterKey -Name Path -Value $Path
            }

            # 如果仍然没有匹配，那么说明确实没有对应条目，流程运行完毕自动退出。
        }
    }
}
