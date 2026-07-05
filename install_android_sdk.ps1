$ErrorActionPreference = 'Stop'
$sdkRoot = 'C:\Users\Paola\AppData\Local\Android\Sdk'
$zip = Join-Path $env:TEMP 'commandlinetools-win.zip'
$cmdLineToolsRoot = Join-Path $sdkRoot 'cmdline-tools'
$extract = Join-Path $cmdLineToolsRoot '_tmp'

New-Item -ItemType Directory -Force -Path $cmdLineToolsRoot | Out-Null
Remove-Item $extract -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $zip -Force -ErrorAction SilentlyContinue

curl.exe -L 'https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip' -o $zip
Expand-Archive -Path $zip -DestinationPath $extract -Force

$latestDir = Join-Path $cmdLineToolsRoot 'latest'
New-Item -ItemType Directory -Force -Path $latestDir | Out-Null

if (Test-Path (Join-Path $extract 'cmdline-tools')) {
    Copy-Item (Join-Path $extract 'cmdline-tools\*') $latestDir -Recurse -Force
} else {
    Copy-Item (Join-Path $extract '*') $latestDir -Recurse -Force
}

Remove-Item $extract -Recurse -Force
Remove-Item $zip -Force -ErrorAction SilentlyContinue

$javaHome = 'C:\Program Files\Android\Android Studio\jbr'
$javaExe = Join-Path $javaHome 'bin\java.exe'
$env:JAVA_HOME = $javaHome
$env:Path = "$javaHome\bin;$env:Path"
$sdkmanager = Join-Path $latestDir 'bin\sdkmanager.bat'

& $javaExe -version
& $sdkmanager --sdk_root=$sdkRoot "platform-tools" "platforms;android-35" "build-tools;35.0.0" "cmdline-tools;latest"

$licensesInput = "y`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny`ny"
$licensesInput | & $sdkmanager --sdk_root=$sdkRoot --licenses

& 'C:\flutter_windows_3.44.4-stable\flutter\bin\flutter.bat' config --android-sdk $sdkRoot
& 'C:\flutter_windows_3.44.4-stable\flutter\bin\flutter.bat' doctor -v
