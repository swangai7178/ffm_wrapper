# ffm_wrapper

A lightweight Flutter wrapper that exposes FFmpeg capabilities for common audio and video processing tasks. Designed to make command-based media transformations easier to integrate into Flutter apps while keeping platform differences transparent.

## Key features

- Simple API for running FFmpeg commands and streaming output
- Helpers for common tasks: trimming, transcoding, extracting audio, generating thumbnails
- Cross-platform support: Android, iOS, Web (where supported by FFmpeg/WASM builds)
- Progress callbacks and error handling
- Optional bundled binaries or use system FFmpeg

## Quick start

### Prerequisites

- Flutter SDK (stable)
- Platform toolchains (Android Studio / Xcode) for mobile builds
- FFmpeg binary or WASM build available for your target platforms

### Install

In your pubspec.yaml:

```yaml
dependencies:
    ffm_wrapper: ^1.0.0
```

Then:

```bash
flutter pub get
```

If you plan to bundle native FFmpeg binaries, follow platform packaging instructions below.

## Usage

Basic example:

```dart
import 'package:ffm_wrapper/ffm_wrapper.dart';

final wrapper = FfmWrapper();

final result = await wrapper.run(
    ['-i', '/path/input.mp4', '-ss', '00:00:10', '-t', '00:00:30', '-c', 'copy', '/path/output.mp4'],
    onProgress: (progress) => print('Progress: $progress'),
);

if (result.success) {
    print('Output: ${result.outputPath}');
} else {
    print('Error: ${result.errorMessage}');
}
```

Helper examples:

- Extract audio:
    wrapper.run(['-i', 'in.mp4', '-vn', '-acodec', 'copy', 'out.aac']);

- Generate thumbnail:
    wrapper.run(['-i', 'in.mp4', '-ss', '00:00:01', '-vframes', '1', 'thumb.jpg']);

## Configuration & API

- FfmWrapper(options): configure binary path, logging, and timeout
- run(command, {onProgress, onLog}): execute a command array or string
- stream(command): obtain stdout/stderr as a stream for long-running tasks

Check the inline docs for full method signatures and return types.

## Platform notes

- Android: include binary in APK or use JNI-based integration; ensure storage and file URI permissions.
- iOS: embed static frameworks or use WASM; entitlements and file access require configuration.
- Web: use FFmpeg WASM; performance and file I/O differ from native platforms.

## Troubleshooting

- Common failure: incorrect input paths — ensure files are accessible to the app sandbox.
- Permission errors: request runtime storage/media permissions on Android.
- Performance: prefer transcoding with hardware codecs where available.

## Contributing

Contributions welcome. Please:
- Open issues with reproducible steps
- Follow the repo's code style and tests
- Submit PRs against main with a descriptive title and tests where appropriate

## License

MIT License — see LICENSE file for details.

## Resources

- FFmpeg docs: https://ffmpeg.org/documentation.html
- Flutter docs: https://docs.flutter.dev/

