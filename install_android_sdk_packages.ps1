$ErrorActionPreference = 'Stop'
$sdkRoot = 'C:\Users\Paola\AppData\Local\Android\Sdk'
$javaHome = 'C:\Program Files\Android\Android Studio\jbr'
$env:JAVA_HOME = $javaHome
$env:Path = "$javaHome\bin;$env:Path"
$sdkmanager = Join-Path $sdkRoot 'cmdline-tools\latest\bin\sdkmanager.bat'

& $javaHome\bin\java.exe -version
& $sdkmanager --sdk_root=$sdkRoot 'platform-tools' 'platforms;android-35' 'build-tools;35.0.0' 'cmdline-tools;latest'

1..20 | ForEach-Object { 'y' } | & $sdkmanager --sdk_root=$sdkRoot --licenses

& 'C:\flutter_windows_3.44.4-stable\flutter\bin\flutter.bat' config --android-sdk $sdkRoot
& 'C:\flutter_windows_3.44.4-stable\flutter\bin\flutter.bat' doctor -v
