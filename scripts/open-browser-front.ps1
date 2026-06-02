# 打开预览页并将浏览器窗口置顶到桌面最前（Windows）
param([string]$Url)
if (-not $Url) { $Url = 'http://127.0.0.1:5173/' }

$TitlePatterns = @("XPlayer", "127.0.0.1:5173", "127.0.0.1")

$ErrorActionPreference = "Stop"

$isWindows = ($env:OS -eq 'Windows_NT') -or ($IsWindows -eq $true)
if (-not $isWindows) {
    Start-Process $Url
    return
}

Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public static class WinFront {
  public delegate bool EnumProc(IntPtr hWnd, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc lpEnum, IntPtr lParam);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hWnd);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)]
  public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr hWnd);
  [DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, UIntPtr dwExtraInfo);
  public const int SW_RESTORE = 9;
  public const byte VK_MENU = 0x12;
  public const uint KEYEVENTF_KEYUP = 0x0002;
}
"@

function Get-EdgePath {
    @(
        "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe",
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
}

function Find-WindowHandle([string[]]$patterns) {
    $found = [IntPtr]::Zero
    $proc = [WinFront+EnumProc]{
        param($hWnd, $lParam)
        if (-not [WinFront]::IsWindowVisible($hWnd)) { return $true }
        $sb = New-Object System.Text.StringBuilder 512
        [void][WinFront]::GetWindowText($hWnd, $sb, 512)
        $title = $sb.ToString()
        if ([string]::IsNullOrWhiteSpace($title)) { return $true }
        foreach ($p in $patterns) {
            if ($title -like "*$p*") {
                $script:found = $hWnd
                return $false
            }
        }
        return $true
    }
    [void][WinFront]::EnumWindows($proc, [IntPtr]::Zero)
    return $found
}

function Set-WindowForeground([IntPtr]$hwnd) {
    if ($hwnd -eq [IntPtr]::Zero) { return $false }
    # 允许从脚本进程抢前台（Windows 限制 SetForegroundWindow）
    [void][WinFront]::keybd_event([WinFront]::VK_MENU, 0, 0, [UIntPtr]::Zero)
    [void][WinFront]::keybd_event([WinFront]::VK_MENU, 0, [WinFront]::KEYEVENTF_KEYUP, [UIntPtr]::Zero)
    [void][WinFront]::ShowWindow($hwnd, [WinFront]::SW_RESTORE)
    [void][WinFront]::BringWindowToTop($hwnd)
    return [WinFront]::SetForegroundWindow($hwnd)
}

function Invoke-AppActivateByTitle([string[]]$patterns) {
    $shell = New-Object -ComObject WScript.Shell
    foreach ($p in $patterns) {
        if ($shell.AppActivate($p)) { return $true }
    }
    return $false
}

$edge = Get-EdgePath
if ($edge) {
    Start-Process -FilePath $edge -ArgumentList @("--new-window", $Url)
} else {
    Start-Process $Url
}

$focused = $false
for ($i = 0; $i -lt 40; $i++) {
    Start-Sleep -Milliseconds 400
    $hwnd = Find-WindowHandle $TitlePatterns
    if ($hwnd -ne [IntPtr]::Zero) {
        $focused = Set-WindowForeground $hwnd
        if ($focused) { break }
    }
}

if (-not $focused) {
    $focused = Invoke-AppActivateByTitle $TitlePatterns
}

if (-not $focused) {
    $edgeProc = Get-Process -Name "msedge" -ErrorAction SilentlyContinue |
        Sort-Object StartTime -Descending |
        Select-Object -First 1
    if ($edgeProc) {
        try {
            Add-Type -AssemblyName Microsoft.VisualBasic -ErrorAction Stop
            $focused = [Microsoft.VisualBasic.Interaction]::AppActivate($edgeProc.Id)
        } catch { }
    }
}

if ($focused) {
    Write-Host "Browser window brought to foreground."
} else {
    Write-Warning "Browser opened; could not auto-focus (switch to the XPlayer tab manually)."
}
