import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Servicio de generación de PDFs — portado de Anny.
/// Genera PDFs para tickets individuales y reportes de eventos.
class PdfService {
  /// Imprimir/exportar ticket individual como PDF.
  static Future<void> printTicket({
    required String eventTitle,
    required String organizer,
    required String location,
    required String date,
    required String ticketCode,
    required String userName,
    required String typeName,
    required double price,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue700, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(16)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Cabecera
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TICKET DE INGRESO',
                            style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.blue800)),
                        pw.Text(organizer,
                            style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Text('TicketPotosí',
                        style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900)),
                  ],
                ),
                pw.Divider(color: PdfColors.blue100, thickness: 1.5, height: 32),

                // Información del evento
                pw.Text('INFORMACIÓN DEL EVENTO',
                    style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800)),
                pw.SizedBox(height: 8),
                pw.Text(eventTitle,
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.black)),
                pw.SizedBox(height: 12),

                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('LUGAR:',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey600)),
                          pw.Text(location,
                              style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('FECHA:',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.grey600)),
                          pw.Text(date,
                              style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Divider(color: PdfColors.grey200, thickness: 1, height: 32),

                // Detalles del ticket
                pw.Text('DETALLES DEL TICKET',
                    style: pw.TextStyle(
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800)),
                pw.SizedBox(height: 8),

                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('TITULAR:',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                          pw.Text(userName, style: const pw.TextStyle(fontSize: 12)),
                          pw.SizedBox(height: 12),
                          pw.Text('TIPO DE ENTRADA:',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                          pw.Text(typeName,
                              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('CÓDIGO DE TICKET:',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                          pw.Text(ticketCode,
                              style: pw.TextStyle(fontSize: 12, font: pw.Font.courier(), fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 12),
                          pw.Text('PRECIO:',
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey600)),
                          pw.Text('Bs. ${price.toStringAsFixed(2)}',
                              style: const pw.TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),

                // Pie de página
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text('Presenta este ticket impreso o digital al ingresar al evento.',
                          style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700, fontStyle: pw.FontStyle.italic)),
                      pw.SizedBox(height: 4),
                      pw.Text('El código QR es único y personal. Su uso indebido anula el ingreso.',
                          style: pw.TextStyle(fontSize: 9, color: PdfColors.red800, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 16),
                      pw.Text('¡Gracias por usar TicketPotosí!',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'ticket_$ticketCode.pdf',
    );
  }

  /// Imprimir/exportar reporte de evento como PDF.
  static Future<void> printEventReport({
    required String eventTitle,
    required String organizer,
    required String location,
    required String date,
    required int sold,
    required int used,
    required double revenue,
    required List<Map<String, dynamic>> ticketDetails,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Cabecera
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('REPORTE OFICIAL DE EVENTO',
                            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text(organizer,
                            style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Text('TicketPotosí',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  ],
                ),
                pw.Divider(color: PdfColors.blue100, thickness: 1.5, height: 24),

                // Detalles del evento
                pw.Text('DETALLES DEL EVENTO',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                pw.SizedBox(height: 6),
                pw.Text(eventTitle, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Row(children: [
                  pw.Expanded(child: pw.Text('Lugar: $location', style: const pw.TextStyle(fontSize: 11))),
                  pw.Expanded(child: pw.Text('Fecha: $date', style: const pw.TextStyle(fontSize: 11))),
                ]),
                pw.Divider(color: PdfColors.grey200, thickness: 1, height: 24),

                // Resumen
                pw.Text('RESUMEN DE VENTAS Y ASISTENCIA',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                pw.SizedBox(height: 8),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Column(children: [
                    pw.Text('$sold', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue700)),
                    pw.Text('Vendidos', style: const pw.TextStyle(fontSize: 10)),
                  ]),
                  pw.Column(children: [
                    pw.Text('$used', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.green)),
                    pw.Text('Asistencias', style: const pw.TextStyle(fontSize: 10)),
                  ]),
                  pw.Column(children: [
                    pw.Text('Bs. ${revenue.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.orange900)),
                    pw.Text('Recaudación', style: const pw.TextStyle(fontSize: 10)),
                  ]),
                ]),
                pw.Divider(color: PdfColors.grey200, thickness: 1, height: 24),

                // Detalle de tickets
                pw.Text('DETALLE DE TICKETS EMITIDOS',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: ['Comprador', 'Tipo', 'Código', 'Estado'].map((h) =>
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(h, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        ),
                      ).toList(),
                    ),
                    ...ticketDetails.map((t) => pw.TableRow(
                      children: [
                        t['name'] ?? 'Sin nombre',
                        t['type'] ?? 'General',
                        t['code'] ?? '—',
                        t['status'] ?? 'Pendiente',
                      ].map((v) => pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(v, style: const pw.TextStyle(fontSize: 9)),
                      )).toList(),
                    )),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'reporte_evento.pdf',
    );
  }
}
