import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Die eingebauten PDF-Schriften können nur Latin-1 (inkl. ä, ö, ü, ß).
/// Andere Zeichen werden ersetzt, damit die Erzeugung nie fehlschlägt.
String _latin1(String s) {
  const replacements = {'–': '-', '—': '-', '„': '"', '“': '"', '”': '"', '’': "'", '…': '...'};
  final buffer = StringBuffer();
  for (final rune in s.runes) {
    final ch = String.fromCharCode(rune);
    if (replacements.containsKey(ch)) {
      buffer.write(replacements[ch]);
    } else {
      buffer.write(rune <= 0xFF ? ch : '?');
    }
  }
  return buffer.toString();
}

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

/// Erzeugt ein Zertifikat für eine bestandene Kapitel-Abschlussprüfung.
Future<Uint8List> buildCertificate({
  required String name,
  required String trackTitle,
  required String levelTitle,
  required String chapterTitle,
  required int percent,
  required DateTime date,
}) {
  final doc = pw.Document(
    title: _latin1('Zertifikat $trackTitle - $chapterTitle'),
    author: 'Prog Trainer',
  );
  const accent = PdfColors.indigo;

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: accent, width: 6),
        ),
        padding: const pw.EdgeInsets.all(6),
        child: pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.indigo200, width: 1.5),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 48, vertical: 32),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('PROG TRAINER',
                  style: pw.TextStyle(
                      fontSize: 14, color: accent, letterSpacing: 4)),
              pw.SizedBox(height: 18),
              pw.Text('Zertifikat',
                  style: pw.TextStyle(
                      fontSize: 48, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 24),
              pw.Text('Hiermit wird bestätigt, dass',
                  style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 12),
              pw.Text(_latin1(name),
                  style: pw.TextStyle(
                      fontSize: 32,
                      fontWeight: pw.FontWeight.bold,
                      color: accent)),
              pw.SizedBox(height: 12),
              pw.Text('die Abschlussprüfung des Kapitels',
                  style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 8),
              pw.Text(_latin1('„$chapterTitle“'),
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(_latin1('$trackTitle · $levelTitle'),
                  style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 8),
              pw.Text('mit $percent % erfolgreich bestanden hat.',
                  style: const pw.TextStyle(fontSize: 16)),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Datum: ${formatDate(date)}',
                      style: const pw.TextStyle(fontSize: 12)),
                  pw.Text('Prog Trainer Lern-App',
                      style: const pw.TextStyle(
                          fontSize: 12, color: PdfColors.grey700)),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return doc.save();
}

String certificateFileName(String trackTitle, String chapterTitle) {
  final slug = '$trackTitle-$chapterTitle'
      .toLowerCase()
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('ß', 'ss')
      .replaceAll('#', 'sharp')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return 'zertifikat_$slug.pdf';
}
