# Towers Philippine Coverage Dashboard

Single-page Towers Philippine Coverage Dashboard built for the GeneXus Trial CloudNET deployment.

Live deployment:

https://trialapps3.genexus.com/towers2026042301/general.security.towersoverview.aspx

## Contents

- `src/towers-dashboard.html` - standalone responsive dashboard source.
- `genexus/towers-overview.xpz` - GeneXus object package used for the trial cloud deployment.
- `android-wrapper/` - Android WebView wrapper that opens the deployed dashboard.

## Android Wrapper

The Android wrapper uses the deployed GeneXus URL:

`https://trialapps3.genexus.com/towers2026042301/general.security.towersoverview.aspx`

Build, install, and launch from PowerShell:

```powershell
cd android-wrapper
.\build-android.ps1
```

The script expects Android SDK build tools and Android Studio's bundled JBR at the local paths defined at the top of `build-android.ps1`.
