param(
    [string]$SdkRoot = "C:\Users\raymo\AppData\Local\Android\Sdk",
    [string]$BuildToolsVersion = "36.1.0",
    [string]$PlatformVersion = "android-36.1",
    [string]$PackageName = "com.openai.towers",
    [string]$ActivityName = "com.openai.towers.MainActivity",
    [string]$OutputApk = "build\Towers-debug.apk",
    [switch]$SkipInstall
)

$ErrorActionPreference = "Stop"
$PSNativeCommandUseErrorActionPreference = $false

function Invoke-Native {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string[]]$ArgumentList = @()
    )

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $output = & $FilePath @ArgumentList 2>&1
        $exitCode = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }
    if ($output) {
        $output | ForEach-Object { Write-Output $_ }
    }
    if ($exitCode -ne 0) {
        throw "Command failed ($exitCode): $FilePath $($ArgumentList -join ' ')"
    }
}

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$buildRoot = Join-Path $projectRoot "build"
$classesDir = Join-Path $buildRoot "classes"
$dexDir = Join-Path $buildRoot "dex"
$classesJar = Join-Path $buildRoot "classes.jar"
$unsignedApk = Join-Path $buildRoot "Towers-unsigned.apk"
$alignedApk = Join-Path $buildRoot "Towers-aligned.apk"
$signedApk = Join-Path $projectRoot $OutputApk

$javac = "C:\Program Files\Android\Android Studio\jbr\bin\javac.exe"
$jar = "C:\Program Files\Android\Android Studio\jbr\bin\jar.exe"
$androidJar = Join-Path $SdkRoot "platforms\$PlatformVersion\android.jar"
$aapt2 = Join-Path $SdkRoot "build-tools\$BuildToolsVersion\aapt2.exe"
$aapt = Join-Path $SdkRoot "build-tools\$BuildToolsVersion\aapt.exe"
$d8 = Join-Path $SdkRoot "build-tools\$BuildToolsVersion\d8.bat"
$zipalign = Join-Path $SdkRoot "build-tools\$BuildToolsVersion\zipalign.exe"
$apksigner = Join-Path $SdkRoot "build-tools\$BuildToolsVersion\apksigner.bat"
$adb = Join-Path $SdkRoot "platform-tools\adb.exe"
$manifest = Join-Path $projectRoot "AndroidManifest.xml"
$sources = Get-ChildItem -Path (Join-Path $projectRoot "src") -Recurse -Filter *.java | Select-Object -ExpandProperty FullName
$keystore = "C:\Users\raymo\.android\debug.keystore"

Remove-Item $buildRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $classesDir -Force | Out-Null
New-Item -ItemType Directory -Path $dexDir -Force | Out-Null

$javacArgs = @("-encoding", "UTF-8", "--release", "8", "-cp", $androidJar, "-d", $classesDir) + $sources
Invoke-Native $javac $javacArgs
Push-Location $classesDir
try {
    Invoke-Native $jar @("--create", "--file", $classesJar, ".")
} finally {
    Pop-Location
}
Invoke-Native $aapt2 @("link", "--manifest", $manifest, "-I", $androidJar, "-o", $unsignedApk)
Invoke-Native "cmd.exe" @("/c", """$d8"" --lib ""$androidJar"" --output ""$dexDir"" ""$classesJar""")
Push-Location $dexDir
try {
    Invoke-Native $aapt @("add", $unsignedApk, "classes.dex")
} finally {
    Pop-Location
}
Invoke-Native $zipalign @("-f", "4", $unsignedApk, $alignedApk)
Invoke-Native "cmd.exe" @("/c", """$apksigner"" sign --ks ""$keystore"" --ks-key-alias androiddebugkey --ks-pass pass:android --key-pass pass:android --out ""$signedApk"" ""$alignedApk""")

if (-not $SkipInstall) {
    Invoke-Native $adb @("install", "-r", $signedApk)
    Invoke-Native $adb @("shell", "am", "start", "-n", "$PackageName/$ActivityName")
}

if ($SkipInstall) {
    Write-Output "APK built: $signedApk"
} else {
    Write-Output "APK built and launched: $signedApk"
}
