import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../database/app_database.dart';
import '../models/sale_print_data.dart';

class ReceiptPdfService {
  ReceiptPdfService(this._getPrintData);

  final Future<SalePrintData> Function(int saleId) _getPrintData;

  /// Generate thermal receipt PDF (58mm/80mm style, narrow width).
  Future<Uint8List> generateThermalReceiptPdf(int saleId) async {
    final data = await _getPrintData(saleId);
    return _buildThermalReceipt(data);
  }

  /// Generate A4 invoice PDF.
  Future<Uint8List> generateA4InvoicePdf(int saleId) async {
    final data = await _getPrintData(saleId);
    return _buildA4Invoice(data);
  }

  Future<Uint8List> _buildThermalReceipt(SalePrintData data) async {
    const pageFormat = PdfPageFormat(80 * PdfPageFormat.mm, 297 * PdfPageFormat.mm);
    final pdf = pw.Document(pageMode: PdfPageMode.none);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(8),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            _buildBusinessHeader(data.businessSettings, isThermal: true),
            pw.SizedBox(height: 8),
            _buildReceiptMeta(data, isThermal: true),
            pw.Divider(),
            ...data.items.map((i) => _buildThermalItemLine(i, data)),
            pw.Divider(),
            _buildThermalTotals(data),
            pw.SizedBox(height: 8),
            pw.Text(
              data.businessSettings.receiptFooter,
              style: pw.TextStyle(fontSize: 8),
              textAlign: pw.TextAlign.center,
            ),
            if (data.receipt != null && data.receipt!.printedCount > 0)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(
                  'Reprint #${data.receipt!.printedCount}',
                  style: pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
                ),
              ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildBusinessHeader(BusinessSettingsMap s, {bool isThermal = false}) {
    final fontSize = isThermal ? 12.0 : 14.0;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(s.businessName, style: pw.TextStyle(fontSize: fontSize, fontWeight: pw.FontWeight.bold)),
        if (s.address.isNotEmpty) pw.Text(s.address, style: pw.TextStyle(fontSize: 8)),
        if (s.phone.isNotEmpty) pw.Text(s.phone, style: pw.TextStyle(fontSize: 8)),
        if (s.ntmOrTaxNumber.isNotEmpty) pw.Text('Tax: ${s.ntmOrTaxNumber}', style: pw.TextStyle(fontSize: 7)),
      ],
    );
  }

  pw.Widget _buildReceiptMeta(SalePrintData data, {bool isThermal = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Invoice: ${data.sale.invoiceNumber}', style: pw.TextStyle(fontSize: 9)),
        pw.Text('Date: ${_formatDateTime(data.sale.saleDate)}', style: pw.TextStyle(fontSize: 8)),
        pw.Text('Cashier: ${data.cashier?.fullName ?? '-'}', style: pw.TextStyle(fontSize: 8)),
        if (data.customer != null)
          pw.Text('Customer: ${data.customer!.name}', style: pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  pw.Widget _buildThermalItemLine(SaleItem item, SalePrintData data) {
    final name = data.itemProductNames[item.productId] ?? 'Item';
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              '$name x${item.quantity.toStringAsFixed(0)}',
              style: const pw.TextStyle(fontSize: 9),
              maxLines: 2,
            ),
          ),
          pw.Text(
            '${data.businessSettings.currencySymbol}${item.totalAmount.toStringAsFixed(2)}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildThermalTotals(SalePrintData data) {
    final s = data.businessSettings;
    final sale = data.sale;
    return pw.Column(
      children: [
        _totalRow('Subtotal', sale.subtotal, s),
        if (sale.discountAmount > 0) _totalRow('Discount', -sale.discountAmount, s),
        _totalRow('Tax', sale.taxAmount, s),
        pw.Divider(thickness: 1),
        _totalRow('Total', sale.totalAmount, s, bold: true),
        _totalRow('Paid', sale.paidAmount, s),
        if (sale.paidAmount > sale.totalAmount)
          _totalRow('Change', sale.paidAmount - sale.totalAmount, s),
        if (sale.dueAmount > 0) _totalRow('Due', sale.dueAmount, s),
      ],
    );
  }

  pw.Widget _totalRow(String label, double value, BusinessSettingsMap s, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : null)),
          pw.Text('${s.currencySymbol}${value.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 9, fontWeight: bold ? pw.FontWeight.bold : null)),
        ],
      ),
    );
  }

  Future<Uint8List> _buildA4Invoice(SalePrintData data) async {
    final pdf = pw.Document();
    final s = data.businessSettings;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildBusinessHeader(data.businessSettings, isThermal: false),
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Invoice', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 8),
                    pw.Text('Invoice #: ${data.sale.invoiceNumber}'),
                    pw.Text('Date: ${_formatDateTime(data.sale.saleDate)}'),
                    pw.Text('Cashier: ${data.cashier?.fullName ?? '-'}'),
                  ],
                ),
                if (data.customer != null)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Bill To', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(data.customer!.name),
                        if (data.customer!.phone != null) pw.Text(data.customer!.phone!),
                        if (data.customer!.address != null) pw.Text(data.customer!.address!),
                      ],
                    ),
                  ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1),
                4: const pw.FlexColumnWidth(1),
                5: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    _tableCell('Item', bold: true),
                    _tableCell('Qty', bold: true),
                    _tableCell('Unit Price', bold: true),
                    _tableCell('Discount', bold: true),
                    _tableCell('Tax', bold: true),
                    _tableCell('Total', bold: true),
                  ],
                ),
                ...data.items.map((i) {
                  final name = data.itemProductNames[i.productId] ?? 'Item';
                  return pw.TableRow(
                    children: [
                      _tableCell(name),
                      _tableCell(i.quantity.toStringAsFixed(0)),
                      _tableCell('${s.currencySymbol}${i.unitPrice.toStringAsFixed(2)}'),
                      _tableCell('${s.currencySymbol}${i.itemDiscount.toStringAsFixed(2)}'),
                      _tableCell('${s.currencySymbol}${i.itemTax.toStringAsFixed(2)}'),
                      _tableCell('${s.currencySymbol}${i.totalAmount.toStringAsFixed(2)}'),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Container(
                width: 200,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey400),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _totalRow('Subtotal', data.sale.subtotal, s),
                    if (data.sale.discountAmount > 0) _totalRow('Discount', -data.sale.discountAmount, s),
                    _totalRow('Tax', data.sale.taxAmount, s),
                    pw.Divider(),
                    _totalRow('Total', data.sale.totalAmount, s, bold: true),
                    _totalRow('Paid', data.sale.paidAmount, s),
                    if (data.sale.paidAmount > data.sale.totalAmount)
                      _totalRow('Change', data.sale.paidAmount - data.sale.totalAmount, s),
                    if (data.sale.dueAmount > 0) _totalRow('Due', data.sale.dueAmount, s),
                  ],
                ),
              ),
            ),
            pw.Spacer(),
            pw.Center(
              child: pw.Text(
                data.businessSettings.receiptFooter,
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            if (data.receipt != null && data.receipt!.printedCount > 0)
              pw.Center(
                child: pw.Text(
                  'Reprint #${data.receipt!.printedCount}',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  pw.Widget _tableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : null)),
    );
  }

  String _formatDateTime(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
