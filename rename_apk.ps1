# rename_apk.ps1 - Windows safe

$AppName = "vintage-ledger"

# Lấy version từ pubspec.yaml
$pubspec = Get-Content pubspec.yaml
$versionLine = $pubspec | Where-Object { $_ -match "^version:" }
$Version = ($versionLine -split " ")[1]

# Thay + bằng _ để hợp lệ trên Windows
$VersionSafe = $Version -replace "\+", "_"

# Folder chứa APK
$APKDir = "build\app\outputs\flutter-apk"

# Chuyển vào folder APK
Set-Location $APKDir

# Danh sách ABI
$abis = @("arm64-v8a", "armeabi-v7a", "x86_64")

# Rename file chỉ dùng tên file
foreach ($abi in $abis) {
    $Old = "app-$abi-release.apk"
    $New = "app-$AppName-$abi-release-v$VersionSafe.apk"
    if (Test-Path $Old) {
        Rename-Item -Path $Old -NewName $New
        Write-Host "Renamed $Old → $New"
    } else {
        Write-Host "File $Old not found"
    }
}