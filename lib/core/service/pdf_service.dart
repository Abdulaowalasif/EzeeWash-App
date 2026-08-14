// lib/core/service/pdf_service.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/orders/domain/entities/order_entity.dart';

class PdfService {
  static Future<Uint8List> generateOrderInvoice(OrderEntity order) async {
    final pdf = pw.Document();

    // Use Hind Siliguri or similar Bengali-supporting font to render the Taka symbol
    final font = await PdfGoogleFonts.hindSiliguriRegular();
    final boldFont = await PdfGoogleFonts.hindSiliguriBold();

    // Using EzeeWash Primary Color (Blue)
    const primaryBlue = PdfColor.fromInt(0xFF2196F3);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(order, boldFont, primaryBlue),
          pw.SizedBox(height: 30),
          _buildOrderInfo(order, font, boldFont),
          pw.SizedBox(height: 25),
          _buildItemsTable(order, boldFont, font, primaryBlue),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          _buildPriceSummary(order, boldFont, primaryBlue),
          pw.Spacer(),
          pw.Align(
            alignment: pw.Alignment.center,
            child: pw.Text(
              'Thank you for using EzeeWash Laundry Services!',
              style: pw.TextStyle(
                font: font,
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
    OrderEntity order,
    pw.Font boldFont,
    PdfColor color,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'RECEIPT',
              style: pw.TextStyle(font: boldFont, fontSize: 28, color: color),
            ),
            pw.Text(
              'No: ${order.orderNumber}',
              style: const pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'EzeeWash',
              style: pw.TextStyle(font: boldFont, fontSize: 16),
            ),
            pw.Text(
              'Official Order Invoice',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text('Date: ${order.createdAt.toString().split(' ')[0]}'),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildOrderInfo(
    OrderEntity order,
    pw.Font font,
    pw.Font boldFont,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Delivery Address:',
                style: pw.TextStyle(font: boldFont, fontSize: 12),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                order.deliveryAddress ?? order.pickupAddress,
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
            ],
          ),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Status:',
                style: pw.TextStyle(font: boldFont, fontSize: 12),
              ),
              pw.Text(
                order.status.toUpperCase(),
                style: pw.TextStyle(font: boldFont, color: PdfColors.green),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Payment:',
                style: pw.TextStyle(font: boldFont, fontSize: 12),
              ),
              pw.Text(
                order.paymentMethod.replaceAll('_', ' ').toUpperCase(),
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(
    OrderEntity order,
    pw.Font boldFont,
    pw.Font font,
    PdfColor color,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: ['Service Description', 'Qty', 'Unit Price', 'Subtotal'],
      data: [
        [
          order.serviceName,
          '${order.itemCount}',
          '৳${(order.totalPrice / order.itemCount).toStringAsFixed(2)}',
          '৳${order.totalPrice.toStringAsFixed(2)}',
        ],
      ],
      border: null,
      headerStyle: pw.TextStyle(
        font: boldFont,
        color: PdfColors.white,
        fontSize: 10,
      ),
      headerDecoration: pw.BoxDecoration(color: color),
      cellHeight: 30,
      cellStyle: pw.TextStyle(font: font, fontSize: 10),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
    );
  }

  static pw.Widget _buildPriceSummary(
    OrderEntity order,
    pw.Font boldFont,
    PdfColor color,
  ) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 180,
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Total Paid:',
                style: pw.TextStyle(font: boldFont, fontSize: 14),
              ),
              pw.Text(
                '৳${order.totalPrice.toStringAsFixed(2)}',
                style: pw.TextStyle(font: boldFont, fontSize: 16, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
