import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/features/lessons/domain/models/lesson.dart';

/// Scans SOYLE lesson links in the form `soyle://lesson/<lesson-id>`.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final controller = MobileScannerController(
    autoStart: true,
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool handled = false;
  String? error;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (handled) return;
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstOrNull;
    final uri = value == null ? null : Uri.tryParse(value);
    final id =
        uri != null &&
            uri.scheme == 'soyle' &&
            uri.host == 'lesson' &&
            uri.pathSegments.length == 1
        ? int.tryParse(uri.pathSegments.single)
        : null;
    Lesson? lesson;
    for (final candidate in AppState.instance.lessons) {
      if (candidate.id == id) lesson = candidate;
    }
    if (lesson == null) {
      if (mounted) setState(() => error = tr('invalidLessonQr'));
      return;
    }
    handled = true;
    await controller.stop();
    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.lessonDetail,
      arguments: lesson,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(tr('scanLessonQr'))),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(tr('scanLessonQrHint'), textAlign: TextAlign.center),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: MobileScanner(
              controller: controller,
              onDetect: _onDetect,
              errorBuilder: (context, exception) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        exception.errorCode ==
                                MobileScannerErrorCode.permissionDenied
                            ? Icons.no_photography_outlined
                            : Icons.camera_alt_outlined,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tr(
                          exception.errorCode ==
                                  MobileScannerErrorCode.permissionDenied
                              ? 'cameraPermissionDenied'
                              : 'cameraUnavailable',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () async {
                          try {
                            await controller.start();
                          } catch (_) {
                            if (mounted) {
                              setState(
                                () => error = tr('cameraPermissionDenied'),
                              );
                            }
                          }
                        },
                        child: Text(tr('retry')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    ),
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
