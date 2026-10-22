# Credential vault for prod-to-local. Secrets are DPAPI-encrypted: only this Windows user on this PC can decrypt them.
#   set <profile>     opens a password dialog (the value never goes through the terminal)
#   has <profile>     exit 0 if the profile exists
#   list              profile names only
#   remove <profile>  deletes the profile
#   get <profile>     prints the secret; only for askpass.sh / lib.sh pipes (the plugin hook blocks it for Claude)
param(
    [Parameter(Mandatory = $true)][ValidateSet('set', 'get', 'has', 'list', 'remove')][string]$Action,
    [string]$Name
)
$ErrorActionPreference = 'Stop'
$dir = Join-Path $HOME '.prod-to-local\vault'

if ($Action -eq 'list') {
    if (Test-Path $dir) { Get-ChildItem $dir -Filter *.cred | ForEach-Object { $_.BaseName } }
    exit 0
}
if ($Name -notmatch '^[A-Za-z0-9._-]+$') { [Console]::Error.WriteLine("invalid profile name: '$Name'"); exit 2 }
$file = Join-Path $dir "$Name.cred"

switch ($Action) {
    'set' {
        $cred = Get-Credential -UserName $Name -Message "prod-to-local: enter the secret for profile '$Name'"
        if (-not $cred) { [Console]::Error.WriteLine('cancelled'); exit 1 }
        New-Item -ItemType Directory -Force $dir | Out-Null
        $cred.Password | ConvertFrom-SecureString | Set-Content -Path $file -Encoding ascii
        Write-Output "saved profile '$Name'"
    }
    'has' {
        if (Test-Path $file) { Write-Output "profile '$Name' exists"; exit 0 }
        exit 1
    }
    'remove' {
        if (Test-Path $file) { Remove-Item $file; Write-Output "removed profile '$Name'" } else { Write-Output "profile '$Name' not found" }
    }
    'get' {
        if (-not (Test-Path $file)) { [Console]::Error.WriteLine("profile '$Name' not found"); exit 1 }
        $secure = Get-Content $file | ConvertTo-SecureString
        $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try { $plain = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) } finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
        # LF only: a trailing CR would become part of the password on the Linux side.
        $out = [Console]::OpenStandardOutput()
        $bytes = [Text.Encoding]::UTF8.GetBytes($plain + "`n")
        $out.Write($bytes, 0, $bytes.Length); $out.Flush()
    }
}
