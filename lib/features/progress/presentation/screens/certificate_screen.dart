import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:soyle/app/router/app_routes.dart';
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/core/state/app_state.dart';
import 'package:soyle/core/theme/app_theme.dart';
import 'package:soyle/features/lessons/data/lesson_service.dart';
import 'package:soyle/features/progress/data/certificate_export.dart';
import 'package:soyle/features/progress/domain/learning_progress.dart';
import 'package:soyle/shared/widgets/adaptive_content.dart';
import 'package:soyle/shared/widgets/learning_ui.dart';
import 'package:soyle/shared/widgets/primary_button.dart';

class CertificateScreen extends StatefulWidget {
  const CertificateScreen({super.key});
  @override
  State<CertificateScreen> createState() => _CertificateScreenState();
}

class _CertificateScreenState extends State<CertificateScreen> {
  bool exporting = false;
  Future<void> export(LearningCertificate certificate) async {
    if (exporting) return;
    setState(() => exporting = true);
    final language = AppLocale.instance.language;
    try {
      final bytes = await const CertificateExport().create(certificate);
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${certificate.id}-$language.pdf',
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(tr('pdfError'))));
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: AppState.instance,
    builder: (context, _) {
      final state = AppState.instance;
      final arg = ModalRoute.of(context)?.settings.arguments;
      final level = LessonService.levels.contains(arg) ? arg as String : 'A1';
      final certificate = state.certificates[level];
      return Scaffold(
        appBar: AppBar(
          title: Text(tr('myCertificate')),
          actions: const [LanguageSwitch(), SizedBox(width: 18)],
        ),
        bottomNavigationBar: certificate == null
            ? null
            : SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  child: PrimaryButton(
                    label: tr('downloadPdf'),
                    icon: Icons.file_download_outlined,
                    loading: exporting,
                    onPressed: () => export(certificate),
                  ),
                ),
              ),
        body: AdaptiveContent(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (certificate == null) ...[
                const SizedBox(height: 24),
                const Icon(
                  Icons.workspace_premium_outlined,
                  size: 64,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 24),
                Text(
                  tr('certificateLocked'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 18),
                Text(
                  tr('certificateRequirements', {'level': level}),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 28),
                Text(
                  tr('completedCount', {
                    'done': state.levelPassed(level),
                    'total': state.levelLessons(level).length,
                  }),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value:
                      state.levelPassed(level) /
                      state.levelLessons(level).length,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: tr('journey'),
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.journey,
                    arguments: level,
                  ),
                ),
              ] else ...[
                Text(
                  tr('certificateCongrats'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  tr('certificateSubtitle'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 26),
                Reveal(child: CertificatePaper(certificate: certificate)),
                const SizedBox(height: 20),
                Text(
                  tr('certNote'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class CertificatePaper extends StatelessWidget {
  const CertificatePaper({super.key, required this.certificate});
  final LearningCertificate certificate;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: const Color(0xFFFFFDF8),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFD8C9AB)),
    ),
    child: Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          color: AppColors.primary,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'S O Y L E',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 3,
                  ),
                ),
              ),
              Text(
                certificate.level,
                style: const TextStyle(
                  color: Color(0xFFE2CFAB),
                  fontFamily: 'NotoSerif',
                  fontSize: 25,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
          child: Column(
            children: [
              Text(
                tr('certificate').toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'NotoSerif',
                  fontSize: 23,
                  letterSpacing: 1,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                certificate.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'NotoSerif',
                  fontSize: 26,
                  color: AppColors.primary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                tr('certCompletion'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD8C9AB)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${certificate.level}  ·  ${tr(certificate.level)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const Icon(
                Icons.workspace_premium_rounded,
                size: 54,
                color: Color(0xFFAB8A54),
              ),
              const SizedBox(height: 22),
              Text(
                '${tr('lessonsCount', {'n': certificate.lessonCount})}  ·  ${certificate.average}%',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFD8C9AB)),
              const SizedBox(height: 12),
              Text(
                '${tr('issued')}: ${certificate.issuedAt}',
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 8),
              Text(
                certificate.id,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
