// lib/core/service/pdf_service.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/orders/domain/entities/order_entity.dart';

class PdfService {
  static double _calculateServiceCharge(int count) {
    if (count <= 1) return 30.0;
    double charge = 30.0;
    if (count >= 2) charge += 20.0;
    if (count >= 3) charge += 15.0;
    if (count >= 4) charge += 10.0;
    if (count >= 5) charge += (count - 4) * 5.0;
    return charge;
  }

  static Future<Uint8List> generateOrderInvoice(OrderEntity order) async {
    final pdf = pw.Document();

    // Use Hind Siliguri or similar Bengali-supporting font to render the Taka symbol
    final font = await PdfGoogleFonts.hindSiliguriRegular();
    final boldFont = await PdfGoogleFonts.hindSiliguriBold();

    // Using EzeeWash Primary Color (Blue)
    const primaryBlue = PdfColor.fromInt(0xFF2196F3);
    final double serviceCharge = _calculateServiceCharge(1);
    final double discount = order.discountAmount;
    final double totalPaid = order.totalPrice;
    final double subtotal = totalPaid - serviceCharge + discount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(order, boldFont, primaryBlue),
          pw.SizedBox(height: 30),
          _buildOrderInfo(order, font, boldFont),
          pw.SizedBox(height: 25),
          _buildItemsTable(order, subtotal, boldFont, font, primaryBlue),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          _buildPriceSummary(
            subtotal,
            serviceCharge,
            discount,
            totalPaid,
            boldFont,
            font,
            primaryBlue,
          ),
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
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'INVOICE',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 32,
                color: color,
                letterSpacing: 1.5,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Order #: ${order.orderNumber}',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 12,
                color: PdfColors.grey800,
              ),
            ),
            pw.Text(
              'Date: ${order.createdAt.toString().split(' ')[0]}',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 10,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'EZEEWASH',
              style: pw.TextStyle(font: boldFont, fontSize: 24, color: color),
            ),
            pw.Text(
              'Premium Laundry & Dry Cleaning',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
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
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FAFF),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.blueGrey100, width: 1),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Delivery Address:',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 12,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  order.deliveryAddress ?? order.pickupAddress,
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
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
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 12,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  order.status.toUpperCase(),
                  style: pw.TextStyle(
                    font: boldFont,
                    color: PdfColors.green,
                    fontSize: 10,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Payment:',
                  style: pw.TextStyle(
                    font: boldFont,
                    fontSize: 12,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  order.paymentMethod.replaceAll('_', ' ').toUpperCase(),
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(
    OrderEntity order,
    double subtotal,
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
          '৳${(subtotal / (order.itemCount > 0 ? order.itemCount : 1)).toStringAsFixed(0)}',
          '৳${subtotal.toStringAsFixed(0)}',
        ],
      ],
      border: pw.TableBorder(
        horizontalInside: const pw.BorderSide(
          color: PdfColors.grey200,
          width: 0.5,
        ),
        bottom: const pw.BorderSide(color: PdfColors.grey300, width: 1),
      ),
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
    double subtotal,
    double serviceCharge,
    double discount,
    double totalPaid,
    pw.Font boldFont,
    pw.Font font,
    PdfColor color,
  ) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.SizedBox(
        width: 200,
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 10),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _buildSummaryRow('Subtotal:', subtotal, font),
              _buildSummaryRow('Delivery Charge:', serviceCharge, font),
              if (discount > 0)
                _buildSummaryRow(
                  'Discount:',
                  -discount,
                  font,
                  color: PdfColors.green,
                ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1, color: PdfColors.grey300),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Total Paid:',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 14,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.Text(
                    '৳${totalPaid.toStringAsFixed(0)}',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 16,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    double amount,
    pw.Font font, {
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: 12,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            amount < 0
                ? '-৳${amount.abs().toStringAsFixed(0)}'
                : '৳${amount.toStringAsFixed(0)}',
            style: pw.TextStyle(
              font: font,
              fontSize: 12,
              color: color ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Multi-Order Invoice ───

  static Future<Uint8List> generateMultiOrderInvoice(
    List<OrderEntity> orders,
  ) async {
    if (orders.isEmpty) throw Exception('No orders provided');
    if (orders.length == 1) return generateOrderInvoice(orders.first);

    final pdf = pw.Document();

    final font = await PdfGoogleFonts.hindSiliguriRegular();
    final boldFont = await PdfGoogleFonts.hindSiliguriBold();
    const primaryBlue = PdfColor.fromInt(0xFF2196F3);

    final firstOrder = orders.first;
    final orderNumbers = orders.map((e) => '#${e.orderNumber}').join(', ');
    final double serviceCharge = _calculateServiceCharge(orders.length);
    final double totalPaid = orders.fold<double>(
      0.0,
      (sum, order) => sum + order.totalPrice,
    );
    final double totalDiscount = orders.fold<double>(
      0.0,
      (sum, order) => sum + order.discountAmount,
    );
    final double subtotal = totalPaid - serviceCharge + totalDiscount;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildMultiHeader(firstOrder, orderNumbers, boldFont, primaryBlue),
          pw.SizedBox(height: 30),
          _buildOrderInfo(
            firstOrder,
            font,
            boldFont,
          ), // Same address/status for all
          pw.SizedBox(height: 25),
          _buildMultiItemsTable(orders, boldFont, font, primaryBlue),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          _buildPriceSummary(
            subtotal,
            serviceCharge,
            totalDiscount,
            totalPaid,
            boldFont,
            font,
            primaryBlue,
          ),
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

  static pw.Widget _buildMultiHeader(
    OrderEntity firstOrder,
    String orderNumbers,
    pw.Font boldFont,
    PdfColor color,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INVOICE (MULTI-ORDER)',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 26,
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Orders: $orderNumbers',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 10,
                  color: PdfColors.grey800,
                ),
                maxLines: 2,
              ),
              pw.Text(
                'Date: ${firstOrder.createdAt.toString().split(' ')[0]}',
                style: pw.TextStyle(
                  font: boldFont,
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'EZEEWASH',
              style: pw.TextStyle(font: boldFont, fontSize: 24, color: color),
            ),
            pw.Text(
              'Premium Laundry & Dry Cleaning',
              style: pw.TextStyle(
                font: boldFont,
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildMultiItemsTable(
    List<OrderEntity> orders,
    pw.Font boldFont,
    pw.Font font,
    PdfColor color,
  ) {
    final double totalServiceCharge = _calculateServiceCharge(orders.length);
    final double serviceChargePerOrder = totalServiceCharge / orders.length;
    final data = orders.map((order) {
      final double itemSubtotal =
          order.totalPrice - serviceChargePerOrder + order.discountAmount;
      return [
        order.serviceName,
        '${order.itemCount}',
        '৳${(itemSubtotal / (order.itemCount > 0 ? order.itemCount : 1)).toStringAsFixed(0)}',
        '৳${itemSubtotal.toStringAsFixed(0)}',
      ];
    }).toList();

    return pw.TableHelper.fromTextArray(
      headers: ['Service Description', 'Qty', 'Unit Price', 'Subtotal'],
      data: data,
      border: pw.TableBorder(
        horizontalInside: const pw.BorderSide(
          color: PdfColors.grey200,
          width: 0.5,
        ),
        bottom: const pw.BorderSide(color: PdfColors.grey300, width: 1),
      ),
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
}
