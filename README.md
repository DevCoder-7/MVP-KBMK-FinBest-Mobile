# FinBest Mobile

Flutter MVP for FinBest. The app uses the existing Next.js API and therefore
the same Neon database as the web app. Database credentials must never be put
in this project.

## Requirements

- Flutter stable with Dart 3.4 or newer
- Android Studio or Xcode for the target device
- A reachable FinBest web API

Official setup references:

- [Install Flutter on Windows](https://docs.flutter.dev/install/manual)
- [Set up Android development](https://docs.flutter.dev/platform-integration/android/setup)
- [Install Android Studio](https://developer.android.com/studio/install)

## Setup

The Android and iOS wrappers are already included. Install Flutter, then fetch
the SDK packages from this directory:

```bash
flutter pub get
```

## Run

Production API is the default:

```bash
flutter run
```

Use the local web backend from an Android emulator:

```bash
flutter run --dart-define=FINBEST_API_BASE_URL=http://10.0.2.2:3002
```

Use a physical device by replacing `10.0.2.2` with the computer's LAN IP.
The phone and computer must be on the same network.

## Verification

```bash
flutter analyze
flutter test
```

Android builds also require Android SDK command-line tools, a platform SDK, and
build-tools installed through Android Studio's SDK Manager.

## Run on this Windows laptop

Flutter is already available locally at:

```text
D:\Data_Glenn\04_Organisasi-Karier\Competitions\KBMK-2026\.tools\flutter
```

1. Open Android Studio.
2. Open **More Actions > SDK Manager**.
3. Under **SDK Platforms**, install the latest stable Android SDK Platform.
4. Under **SDK Tools**, install **Android SDK Command-line Tools (latest)**,
   **Android SDK Build-Tools**, **Android SDK Platform-Tools**, and
   **Android Emulator**.
5. Open **More Actions > Virtual Device Manager**, create a phone emulator,
   then start it.
6. Open PowerShell in this project folder.
7. Verify the toolchain:

```powershell
& "D:\Data_Glenn\04_Organisasi-Karier\Competitions\KBMK-2026\.tools\flutter\bin\flutter.bat" doctor -v
```

8. Accept Android licenses if requested:

```powershell
& "D:\Data_Glenn\04_Organisasi-Karier\Competitions\KBMK-2026\.tools\flutter\bin\flutter.bat" doctor --android-licenses
```

9. Fetch packages and check the connected emulator:

```powershell
& "D:\Data_Glenn\04_Organisasi-Karier\Competitions\KBMK-2026\.tools\flutter\bin\flutter.bat" pub get
& "D:\Data_Glenn\04_Organisasi-Karier\Competitions\KBMK-2026\.tools\flutter\bin\flutter.bat" devices
```

10. Run FinBest using the deployed backend and Neon database:

```powershell
& "D:\Data_Glenn\04_Organisasi-Karier\Competitions\KBMK-2026\.tools\flutter\bin\flutter.bat" run
```

Sign in with `demo` / `demo`. Stop the app with `q` in the terminal.

To build an installable debug APK after the Android toolchain is ready:

```powershell
& "D:\Data_Glenn\04_Organisasi-Karier\Competitions\KBMK-2026\.tools\flutter\bin\flutter.bat" build apk --debug
```

The APK will be written to `build/app/outputs/flutter-apk/app-debug.apk`.
Building or running the iOS wrapper requires macOS with Xcode.

## Architecture

```text
Flutter app -> HTTPS -> Next.js API -> Prisma -> Neon PostgreSQL
```

Authentication uses the existing signed `finbest-session` HttpOnly cookie. The
cookie is kept only for the current app process in this MVP. The API base URL is
configured at build time; secrets remain in Vercel and the web app's local
`.env` file.
