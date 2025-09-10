# sshsupport.ps1
# Provides SSH session management for ESXi STIG checks using Posh-SSH.
# Requires: Posh-SSH module (vendored or installed).

# Cache: sessions by VMHost and run-scoped credential
$script:SshSessions   = @{}
$script:RunCredential = $null

function Get-RunCredential {
    [CmdletBinding()]
    param(
        [Parameter()][string]$UserPrompt = "SSH username",
        [Parameter()][string]$PassPrompt = "SSH password"
    )

    if ($script:RunCredential) { return $script:RunCredential }

    $u = Read-Host -Prompt $UserPrompt
    $p = Read-Host -Prompt $PassPrompt -AsSecureString
    $script:RunCredential = [pscredential]::new($u, $p)
    return $script:RunCredential
}

function Get-EsxiSshSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$VMHost,
        [Parameter()][pscredential]$Credential
    )

    if ($script:SshSessions.ContainsKey($VMHost)) {
        $session = $script:SshSessions[$VMHost]
        if ($session -and $session.Connected) { return $session }
        # Session exists but not connected; remove and recreate
        $script:SshSessions.Remove($VMHost) | Out-Null
    }

    if (-not $Credential) { $Credential = Get-RunCredential }

    $plain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Credential.Password)
    )

    try {
        $newSession = New-SSHSession -ComputerName $VMHost -Credential $Credential -AcceptKey -Force -ErrorAction Stop
        # New-SSHSession returns a wrapper; keep that
        $ssh = $newSession | Select-Object -First 1
        $script:SshSessions[$VMHost] = $ssh
        return $ssh
    }
    finally {
        if ($plain) { [System.Array]::Clear([char[]]$plain, 0, $plain.Length) | Out-Null }
    }
}

function Invoke-EsxiSsh {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$VMHost,
        [Parameter(Mandatory)][string]$Command,
        [Parameter()][pscredential]$Credential
    )

    $session = Get-EsxiSshSession -VMHost $VMHost -Credential $Credential
    $res     = Invoke-SSHCommand -SessionId $session.SessionId -Command $Command -TimeOut 600

    [pscustomobject]@{
        ExitStatus = $res.ExitStatus
        Output     = ($res.Output | Where-Object { $_ -ne $null }) -join "`n"
        Errors     = ($res.Error  | Where-Object { $_ -ne $null }) -join "`n"
    }
}

function Close-EsxiSshSessions {
    [CmdletBinding()]
    param()

    if ($script:SshSessions.Count -gt 0) {
        foreach ($kvp in $script:SshSessions.GetEnumerator()) {
            try {
                Remove-SSHSession -SessionId $kvp.Value.SessionId -ErrorAction SilentlyContinue | Out-Null
            } catch {}
        }
        $script:SshSessions.Clear()
    }
}

Export-ModuleMember -Function Get-RunCredential, Get-EsxiSshSession, Invoke-EsxiSsh, Close-EsxiSshSessions
