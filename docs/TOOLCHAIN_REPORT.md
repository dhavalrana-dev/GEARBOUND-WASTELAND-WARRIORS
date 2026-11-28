# Toolchain report (Phase 01, GB-038)

## Current state (2026-11-28, sessions 18 and 20)

| Tool | Status | Evidence |
|---|---|---|
| Flutter | 3.47.7 stable, Dart 3.13.5 | `flutter --version` |
| Android SDK | **Usable:** the owner's Android Studio SDK at `F:\Android\Sdk` (license accepted by the owner) | `flutter config --android-sdk F:\Android\Sdk`; `flutter/android/local.properties` `sdk.dir` |
| Android build | **Debug APK built**, plus a profile APK (29.1 MB) | `flutter build apk --debug` (log `artifacts/android-debug-build.log`) |
| Emulator | Pixel 10 Pro XL AVD, Android 17 (API 37), x86_64 | `adb devices` → `emulator-5554` |
| On-device checks | App launches to the campaign route; `baseline_device_test.dart` passes in debug and profile (AOT) | `artifacts/device-baseline-debug.log`, `artifacts/device-baseline-profile.log` |
| `flutter doctor` Android | Warnings remain: `cmdline-tools` missing, license status unknown | `flutter doctor` |
| Physical phone | Not tested (no ARM64 device connected) | — |
| Unity Android build | **IL2CPP APK built** (ARM64 + x86_64, 184 MB, about 6 min cold) with Unity's bundled SDK, NDK and JDK; the baseline scene passes on the emulator | `artifacts/unity-android-build.log`, `artifacts/unity-device-baseline.log` |
| iOS | Not possible on Windows | Needs macOS and Xcode |

**What the first build installed (the owner approved the downloads):** Gradle 9.3.1, the Android Gradle plugin 9.1.0 and Kotlin 2.4.0 with their libraries, NDK 28.2.13676358, and Android SDK Platform 35, all into `F:\Android\Sdk` and the user Gradle cache.

**Fix applied:** `flutter/android/gradle.properties` sets `kotlin.incremental=false`. Plugins live in the pub cache on drive C: while the project builds on F:, and Kotlin's incremental caches cannot span drive roots on Windows; the build failed with "Could not close incremental caches" until this was set.

**Unity Android build (session 20):** run from the repository root (PowerShell)

```
& "C:\Program Files\Unity\Hub\Editor\6000.3.27f1\Editor\Unity.exe" -batchmode -nographics -quit -projectPath unity -buildTarget Android -executeMethod Gearbound.Baseline.Editor.AndroidBaselineBuild.Build -logFile artifacts/unity-android-build.log
adb install -r unity/Builds/android/gearbound-unity-baseline.apk
adb shell monkey -p com.gearbound.unitybaseline -c android.intent.category.LAUNCHER 1
adb logcat -s Unity   # look for "UNITY DEVICE BASELINE OK"
```

The build copies the shared fixtures into `unity/Assets/Generated/` (not committed) and writes the APK to `unity/Builds/android/` (not committed). It uses Unity's own Android SDK, NDK and OpenJDK installed by Unity Hub. The project's Android player settings are now IL2CPP, ARM64 + x86_64 and the application ID `com.gearbound.unitybaseline`; a real game ID comes with the Unity client (GB-046).

**Owner follow-ups:** install the Android SDK Command-line Tools from Android Studio's SDK Manager to clear the `flutter doctor` warnings, and connect a physical ARM64 phone with USB debugging for the Phase 15 device check.

## Earlier diagnosis (2026-11-27)

The section below records the state before the owner's Android Studio SDK was found; it is kept for history.

Checked 2026-11-27 on the development machine (Windows 11, build 26300).

| Tool | Status | Evidence |
|---|---|---|
| Flutter | 3.47.7 stable, Dart 3.13.5 | `flutter doctor -v` |
| Windows desktop toolchain | OK (VS Build Tools 2026 18.7.1) | `flutter doctor` |
| Unity | 6000.3.27f1; EditMode tests run in batchmode | `artifacts/unity-editmode.xml` |
| **Android toolchain** | **Not usable** | `flutter doctor`: "Unable to locate Android SDK" |
| iOS | Not possible on Windows | Needs macOS and Xcode |

## Android diagnosis

- **No standalone Android SDK.** `ANDROID_HOME` and `ANDROID_SDK_ROOT` are unset, and `%LOCALAPPDATA%\Android\Sdk` does not exist.
- **Gradle uses Unity's SDK.** The only SDK is the one bundled with Unity: `C:\Program Files\Unity\Hub\Editor\6000.3.27f1\Editor\Data\PlaybackEngines\AndroidPlayer\SDK`. `flutter/android/local.properties` points Gradle there, but `flutter doctor` is not configured to use it, hence the "unable to locate" message.
- **That SDK contents:**
  - platforms android-34 through 37.0, build-tools 36.0.0, cmdline-tools, platform-tools and cmake;
  - **no `licenses/` folder**;
  - the NDK sits outside the SDK, at `AndroidPlayer\NDK`, version **27.2.12479018 (r27c)**.
- **NDK mismatch.** Flutter's Android template asks for `ndkVersion = flutter.ndkVersion`, recorded earlier as **28.2.13676358**. Gradle would try to install it into the Unity SDK under `Program Files`. That needs (a) accepting Google's Android SDK license and (b) write access to `Program Files`. Neither may be done by the agent.
- **No build attempted.** No build was run this session, because it would only trigger that download and license prompt.

## What you need to do (choose one)

**Option A — recommended: a separate SDK for Flutter.** This keeps Unity's SDK untouched.

1. Install Android Studio, or the Android command-line tools, into your user profile, for example `%LOCALAPPDATA%\Android\Sdk`.
2. Review and accept the licenses yourself:

   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat" --licenses
   ```

3. Install the platform and NDK the Flutter template needs (the `ndk;` version must match the one Gradle reports):

   ```powershell
   & "$env:LOCALAPPDATA\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat" "platform-tools" "platforms;android-36" "ndk;28.2.13676358"
   ```

4. Point Flutter at the new SDK:

   ```powershell
   E:\flutter\bin\flutter.bat config --android-sdk "$env:LOCALAPPDATA\Android\Sdk"
   ```

5. Delete `flutter/android/local.properties`; Flutter regenerates it with the new SDK path. Then run `flutter doctor --android-licenses` and `flutter doctor`.

**Option B: build against Unity's SDK and NDK 27.2.** Pin `ndkVersion = "27.2.12479018"` and point `ndk.dir` at Unity's NDK. This is untested with Flutter 3.47.7's plugins, and it still needs the SDK license accepted (the SDK has no `licenses/` folder). Option A is the safer route.

After either option, the agent can run `flutter build apk --debug` and record the result here.
