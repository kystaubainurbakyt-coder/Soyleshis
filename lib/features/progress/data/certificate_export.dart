import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:soyle/core/localization/app_locale.dart';
import 'package:soyle/features/progress/domain/learning_progress.dart';

class CertificateExport {
  const CertificateExport();
  Future<Uint8List> create(LearningCertificate certificate) async {
    final language = AppLocale.instance.isEnglish ? 1 : 0;
    String text(String key) => messages[key]![language];
    final sans = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );
    final serif = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSerif.ttf'),
    );
    final navy = PdfColor.fromHex('#102E58'),
        gold = PdfColor.fromHex('#B29A70');
    final document = pw.Document(
      title: 'SOYLE ${certificate.level} ${text('certificate')}',
      author: 'SOYLE',
    );
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(30),
        theme: pw.ThemeData.withFont(base: sans, bold: sans),
        build: (_) => pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#FFFDF8'),
            border: pw.Border.all(color: gold, width: 1),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Container(
                width: 135,
                padding: const pw.EdgeInsets.all(22),
                color: navy,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'S O Y L E',
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 13,
                      ),
                    ),
                    pw.Spacer(),
                    pw.Text(
                      certificate.level,
                      style: pw.TextStyle(
                        color: gold,
                        font: serif,
                        fontSize: 48,
                      ),
                    ),
                    pw.SizedBox(height: 18),
                    pw.Text(
                      text(certificate.level),
                      style: const pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 11,
                      ),
                    ),
                    pw.Spacer(),
                    pw.Container(height: 1, color: gold),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      language == 1 ? 'KAZAKH\nLANGUAGE' : 'КАЗАХСКИЙ\nЯЗЫК',
                      style: pw.TextStyle(
                        color: gold,
                        fontSize: 9,
                        lineSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(35),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        text('certificate').toUpperCase(),
                        style: pw.TextStyle(
                          font: serif,
                          fontSize: 30,
                          color: navy,
                        ),
                      ),
                      pw.SizedBox(height: 9),
                      pw.Container(width: 55, height: 2, color: gold),
                      pw.Spacer(),
                      pw.Text(
                        certificate.name,
                        maxLines: 2,
                        style: pw.TextStyle(
                          font: serif,
                          fontSize: 28,
                          color: navy,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        text('certCompletion'),
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: navy,
                          lineSpacing: 5,
                        ),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text(
                        '${certificate.level}  ·  ${certificate.lessonCount} ${lessonNoun(certificate.lessonCount, language == 1)}  ·  ${text('average')}: ${certificate.average}%',
                        style: pw.TextStyle(fontSize: 11, color: navy),
                      ),
                      pw.Spacer(),
                      pw.Divider(color: gold),
                      pw.SizedBox(height: 10),
                      pw.Text(
                        '${text('issued')}: ${certificate.issuedAt}',
                        style: pw.TextStyle(fontSize: 9, color: navy),
                      ),
                      pw.SizedBox(height: 7),
                      pw.Text(
                        certificate.id,
                        style: pw.TextStyle(fontSize: 9, color: navy),
                      ),
                      pw.SizedBox(height: 13),
                      pw.Text(
                        text('certNote'),
                        style: pw.TextStyle(fontSize: 8, color: gold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return document.save();
  }
}
