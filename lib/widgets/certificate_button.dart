import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../app_services.dart';
import '../certificates/certificate_pdf.dart';
import '../data/progress_store.dart';

/// Erzeugt das PDF-Zertifikat und öffnet den Teilen-/Speichern-Dialog.
/// Fragt beim ersten Mal nach dem Namen für das Zertifikat.
class CertificateButton extends StatelessWidget {
  const CertificateButton({super.key, required this.result, this.compact = false});

  final ExamResult result;
  final bool compact;

  Future<void> _download(BuildContext context) async {
    final progress = AppServices.of(context).progress;
    var name = progress.userName;
    if (name.isEmpty) {
      final entered = await askForName(context);
      if (entered == null || entered.isEmpty) return;
      await progress.setUserName(entered);
      name = entered;
    }
    final bytes = await buildCertificate(
      name: name,
      trackTitle: result.trackTitle,
      levelTitle: result.levelTitle,
      chapterTitle: result.chapterTitle,
      percent: result.percent,
      date: result.date,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: certificateFileName(result.trackTitle, result.chapterTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: 'Zertifikat herunterladen',
        icon: const Icon(Icons.download),
        onPressed: () => _download(context),
      );
    }
    return OutlinedButton.icon(
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text('Zertifikat herunterladen (PDF)'),
      onPressed: () => _download(context),
    );
  }
}

Future<String?> askForName(BuildContext context) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Dein Name'),
      content: TextField(
        controller: controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Vor- und Nachname',
          helperText: 'Erscheint auf deinen Zertifikaten.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Speichern'),
        ),
      ],
    ),
  );
}
