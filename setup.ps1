<#
gta6-dlss5 setup
Checks your PC, installs Veyra (free, open source, GPL-3.0, github.com/Likely7/Veyra-NRVideo)
and prints the GTA 6 preset for your GPU. Nothing is uploaded anywhere.

one line:   irm https://raw.githubusercontent.com/phosphenq/gta6-dlss5/main/setup.ps1 | iex
from file:  powershell -ExecutionPolicy Bypass -File setup.ps1 [-InstallDir D:\Veyra] [-ZipPath .\Veyra.zip] [-CheckOnly]
#>
param(
  [string]$InstallDir = (Join-Path $env:LOCALAPPDATA 'gta6-dlss5'),
  [string]$ZipPath = '',
  [switch]$CheckOnly
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$Repo = 'Likely7/Veyra-NRVideo'

function Row([string]$k, [string]$v, [string]$state = 'ok') {
  $c = @{ ok = 'Green'; warn = 'Yellow'; bad = 'Red'; info = 'Gray' }[$state]
  $mark = @{ ok = '[ok]  '; warn = '[!]   '; bad = '[x]   '; info = '      ' }[$state]
  Write-Host ($mark + $k.PadRight(14)) -NoNewline -ForegroundColor $c
  Write-Host $v
}

Write-Host ''
Write-Host 'gta6-dlss5  |  PS5 -> your PC -> DLSS 5 + frame generation' -ForegroundColor Cyan
Write-Host ''

# 1. Windows 11 x64 (Veyra needs it, DirectX 12)
$inv = [Globalization.CultureInfo]::InvariantCulture
$build = [int](Get-CimInstance Win32_OperatingSystem).BuildNumber
$okOs = ($build -ge 22000) -and [Environment]::Is64BitOperatingSystem
$osName = if ($build -ge 22000) { 'Windows 11' } else { 'Windows 10 (Veyra needs 11)' }
Row 'windows' ("{0} x64, build {1}" -f $osName, $build) ($(if ($okOs) { 'ok' } else { 'bad' }))

# 2. GPU and driver
$gpu = $null; $driver = $null; $vram = 0
if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
  $line = (& nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader,nounits | Select-Object -First 1)
  $p = $line.Split(',')
  $gpu = $p[0].Trim(); $driver = $p[1].Trim(); $vram = [int]$p[2].Trim()
} else {
  $vc = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -notmatch 'Basic|Virtual|Parsec' } | Select-Object -First 1
  $gpu = $vc.Name; $driver = $vc.DriverVersion
}
$tier = 'NONE'
if ($gpu -match 'RTX\s*50\d\d') { $tier = 'RTX50' }
elseif ($gpu -match 'RTX\s*40\d\d') { $tier = 'RTX40' }
elseif ($gpu -match 'RTX\s*30\d\d') { $tier = 'RTX30' }
elseif ($gpu -match 'RTX\s*20\d\d') { $tier = 'RTX20' }
elseif ($gpu -match 'RX\s*(7|9)\d\d\d') { $tier = 'AMD' }
$gpuState = @{ RTX50 = 'ok'; RTX40 = 'ok'; RTX30 = 'warn'; RTX20 = 'warn'; AMD = 'warn'; NONE = 'bad' }[$tier]
$vramText = if ($vram) { ", {0} GB" -f [math]::Round($vram / 1024) } else { '' }
Row 'gpu' ("{0}{1}, driver {2}" -f $gpu, $vramText, $driver) $gpuState
$what = @{
  RTX50 = 'DLSS 5 neural rendering + 4x frame generation + RTX Video upscaling'
  RTX40 = 'neural rendering (community model) + frame generation + RTX Video upscaling'
  RTX30 = 'upscaling + community neural rendering, frame generation in compatibility mode'
  RTX20 = 'upscaling + community neural rendering (frame generation needs RTX 30 or newer)'
  AMD   = 'AMD build: FSR 4 / AMD frame generation, neural rendering experimental'
  NONE  = 'no supported GPU found: Veyra needs GeForce RTX 20-50 or Radeon RX 7000/9000'
}[$tier]
Row 'you get' $what ($(if ($tier -eq 'NONE') { 'bad' } else { 'info' }))

# 3. Disk
$drive = (Split-Path -Qualifier ([IO.Path]::GetFullPath($InstallDir))).TrimEnd(':')
$free = [math]::Round((Get-PSDrive $drive).Free / 1GB)
Row 'disk' ("{0}: {1} GB free, need 3 GB" -f $drive, $free.ToString($inv)) ($(if ($free -ge 3) { 'ok' } else { 'bad' }))

# 4. Network for PS5 Remote Play (cable beats Wi-Fi by a mile)
$up = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object Status -eq 'Up'
$wired = $up | Where-Object { $_.MediaType -eq '802.3' -and $_.InterfaceDescription -notmatch 'Wi-?Fi|Wireless|802\.11' }
if ($wired) { Row 'network' ("cable, {0}" -f $wired[0].LinkSpeed) 'ok' }
elseif ($up) { Row 'network' 'Wi-Fi only: plug the PC and the PS5 into the router for Remote Play' 'warn' }
else { Row 'network' 'no active adapter found' 'warn' }

$fg = @{ RTX50 = 'DLSS Frame Generation 4X (30 -> 120) on a 120 Hz screen, 2X on 60 Hz'; RTX40 = 'DLSS Frame Generation 2X, 4X if your screen is 120 Hz'; RTX30 = '2X (compatibility mode)'; RTX20 = 'off'; AMD = '2X'; NONE = '-' }[$tier]
$nr = @{ RTX50 = 'RTX 50 - NVIDIA original, 2 layers, output stabilizer on'; RTX40 = 'RTX 20-50 - SF performance model, 1 layer, output stabilizer on'; RTX30 = 'RTX 20-50 - SF performance model, 1 layer'; RTX20 = 'RTX 20-50 - SF performance model, 1 layer'; AMD = 'RX 7000 / 9000 - AMD NR (experimental)'; NONE = '-' }[$tier]

function Show-Preset {
  Write-Host ''
  Write-Host 'GTA 6 preset (Veyra -> Pro mode)' -ForegroundColor Cyan
  Row 'source' 'PS5 streaming 1080p / 60 fps, codec H.265 (Settings -> PS5 streaming) or a capture card at 60 fps' 'info'
  Row 'copies' 'GTA 6 is 30 fps inside a 60 fps stream; Veyra drops the copies itself (auto dedup)' 'info'
  Row 'NR' $nr 'info'
  Row 'SR' 'RTX Video SR, target = your screen (4K TV: x2 from 1080p)' 'info'
  Row 'frame gen' $fg 'info'
  Row 'display' 'Display sync Auto (lowest latency), Output cap: Follow the display' 'info'
  Row 'compare' 'hold V to see the original picture' 'info'
  Write-Host ''
  Write-Host 'PS5 pairing (no capture card needed)' -ForegroundColor Cyan
  Row '1' 'PS5: Settings -> System -> Remote Play -> Enable Remote Play' 'info'
  Row '2' 'PS5: same menu -> Link Device (or Pair Device), it shows an 8-digit code' 'info'
  Row '3' 'Veyra: Home -> PS5 streaming -> Get Account ID -> paste it, enter the code' 'info'
  Write-Host ''
}

if ($CheckOnly -or $tier -eq 'NONE' -or -not $okOs) { Show-Preset; return }

# 5. Download the latest Veyra build from GitHub and check its SHA-256
$flavor = if ($tier -eq 'AMD') { 'AMD' } else { 'NVIDIA' }
$rel = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest" -Headers @{ 'User-Agent' = 'gta6-dlss5' }
$asset = $rel.assets | Where-Object { $_.name -match "^Veyra-[\d.]+-$flavor-win64-portable\.zip$" } | Select-Object -First 1
$sums = $rel.assets | Where-Object { $_.name -eq 'SHA256SUMS.txt' } | Select-Object -First 1
if (-not $asset) { throw "no $flavor package in $($rel.tag_name)" }
New-Item -ItemType Directory -Force $InstallDir | Out-Null
$zip = if ($ZipPath) { (Resolve-Path $ZipPath).Path } else { Join-Path $InstallDir $asset.name }
if (-not $ZipPath -and -not (Test-Path $zip)) {
  Row 'download' ("{0}, {1} MB" -f $asset.name, [math]::Round($asset.size / 1MB)) 'info'
  if (Get-Command curl.exe -ErrorAction SilentlyContinue) { & curl.exe -L --retry 3 -# -o $zip $asset.browser_download_url; if ($LASTEXITCODE) { throw 'download failed' } }
  else { Invoke-WebRequest $asset.browser_download_url -OutFile $zip }
}
$hash = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
$want = ((Invoke-RestMethod $sums.browser_download_url -Headers @{ 'User-Agent' = 'gta6-dlss5' }) -split "`n" |
  Where-Object { $_ -match [regex]::Escape($asset.name) } | ForEach-Object { ($_ -split '\s+')[0].ToLower() }) | Select-Object -First 1
$gh = if ($asset.digest) { ($asset.digest -replace '^sha256:', '').ToLower() } else { $want }
if ($hash -ne $want -or $hash -ne $gh) { throw "SHA-256 mismatch for $($asset.name): $hash" }
Row 'sha256' ("{0}... matches the release" -f $hash.Substring(0, 16))

# 6. Unpack and add a desktop shortcut
$dest = Join-Path $InstallDir ($asset.name -replace '\.zip$', '')   # the zip already has this top folder
if (-not (Test-Path $dest)) {
  & tar.exe -xf $zip -C $InstallDir
  if ($LASTEXITCODE) { Expand-Archive $zip $InstallDir -Force }
}
$exe = Get-ChildItem $InstallDir -Recurse -Filter 'veyra_qml_ui.exe' | Sort-Object FullName | Select-Object -First 1
if (-not $exe) { throw "veyra_qml_ui.exe not found in $InstallDir" }
$lnk = Join-Path ([Environment]::GetFolderPath('Desktop')) 'GTA 6 DLSS 5 (Veyra).lnk'
$sh = (New-Object -ComObject WScript.Shell).CreateShortcut($lnk)
$sh.TargetPath = $exe.FullName; $sh.WorkingDirectory = $exe.DirectoryName; $sh.Save()
Row 'installed' ("Veyra {0}, {1}" -f $rel.tag_name, (Split-Path $exe.DirectoryName -Leaf))
Row 'shortcut' 'Desktop\GTA 6 DLSS 5 (Veyra)'

Show-Preset
Write-Host 'Windows may warn "unknown publisher": Veyra is not code-signed. Source: github.com/Likely7/Veyra-NRVideo' -ForegroundColor DarkGray
