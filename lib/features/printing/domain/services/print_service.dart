import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

class PrintService {
  PrintService(this._generateThermal, this._generateA4);

  final Future<Uint8List> Function(int saleId) _generateThermal;
  final Future<Uint8List> Function(int saleId) _generateA4;

  /// Preview thermal receipt in a dialog.
  Future<void> previewThermalReceipt(BuildContext context, int saleId) async {
    try {
      final pdfBytes = await _generateThermal(saleId);
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'receipt-$saleId',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preview failed: $e')),
        );
      }
    }
  }

  /// Preview A4 invoice in a dialog.
  Future<void> previewA4Invoice(BuildContext context, int saleId) async {
    try {
      final pdfBytes = await _generateA4(saleId);
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'invoice-$saleId',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preview failed: $e')),
        );
      }
    }
  }

  /// Print thermal receipt directly.
  Future<void> printThermalReceipt(BuildContext context, int saleId) async {
    try {
      final pdfBytes = await _generateThermal(saleId);
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'receipt-$saleId',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }

  /// Print A4 invoice directly.
  Future<void> printA4Invoice(BuildContext context, int saleId) async {
    try {
      final pdfBytes = await _generateA4(saleId);
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: 'invoice-$saleId',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }

  /// Save PDF to file. Returns path or null on failure.
  Future<String?> savePdfToFile({
    required int saleId,
    required String invoiceNumber,
    required bool isThermal,
  }) async {
    try {
      final pdfBytes = isThermal
          ? await _generateThermal(saleId)
          : await _generateA4(saleId);
      final dir = await getApplicationDocumentsDirectory();
      final type = isThermal ? 'receipt' : 'invoice';
      final safeName = invoiceNumber.replaceAll(RegExp(r'[^\w\-]'), '_');
      final path = '${dir.path}/$type-$safeName.pdf';
      final file = File(path);
      await file.writeAsBytes(pdfBytes);
      return path;
    } catch (e) {
      return null;
    }
  }
}
