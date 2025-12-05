import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/trip_model.dart';

/// Service to generate PDF itineraries with map screenshots and route details
class PdfService {
  /// Generate PDF for a trip
  static Future<void> generateTripPDF(Trip trip) async {
    final pdf = pw.Document();

    // Add pages to PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          _buildHeader(trip),
          pw.SizedBox(height: 20),

          // Trip Summary
          _buildSummary(trip),
          pw.SizedBox(height: 20),

          // Map Placeholder
          _buildMapPlaceholder(trip),
          pw.SizedBox(height: 20),

          // Route Details
          _buildRouteDetails(trip),
          pw.SizedBox(height: 20),

          // Visa Information
          if (trip.visaRequired) ...[
            _buildVisaSection(trip),
            pw.SizedBox(height: 20),
          ],

          // Itinerary
          _buildItinerary(trip),

          // Footer
          pw.SizedBox(height: 30),
          _buildFooter(),
        ],
      ),
    );

    // Share or save the PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Trip_${trip.destination.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  /// Build PDF header
  static pw.Widget _buildHeader(Trip trip) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.green700,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Road Trip to ${trip.destination}',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Your Complete Travel Itinerary & Route Guide',
            style: const pw.TextStyle(
              fontSize: 14,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Build trip summary section
  static pw.Widget _buildSummary(Trip trip) {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final duration = trip.durationDays;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Trip Summary',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green700,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildInfoRow('Destination:', trip.destination),
          _buildInfoRow('Start Date:', dateFormat.format(trip.startDate)),
          _buildInfoRow('End Date:', dateFormat.format(trip.endDate)),
          _buildInfoRow('Duration:', '$duration day${duration > 1 ? 's' : ''}'),
          _buildInfoRow('Total Activities:', '${trip.totalActivities}'),
          _buildInfoRow(
            'Visa Required:',
            trip.visaRequired ? 'Yes' : 'No',
            valueColor: trip.visaRequired ? PdfColors.red : PdfColors.green,
          ),
        ],
      ),
    );
  }

  /// Build map placeholder section (Student A #2 requirement)
  static pw.Widget _buildMapPlaceholder(Trip trip) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            '📍 Route Map',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Container(
            height: 200,
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    '🗺️',
                    style: const pw.TextStyle(fontSize: 48),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Map Screenshot',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Route to ${trip.destination}',
                    style: pw.TextStyle(
                      fontSize: 12,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Note: In production, this would show actual map with route',
            style: pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  /// Build route details section (Student A #2 requirement)
  static pw.Widget _buildRouteDetails(Trip trip) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue300),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColors.blue50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '🚗 Route Details',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          _buildRouteInfo('Starting Point:', 'Muscat, Oman'),
          _buildRouteInfo('Destination:', trip.destination),
          _buildRouteInfo('Estimated Distance:', 'To be calculated'),
          _buildRouteInfo('Estimated Duration:', 'Based on route'),
          pw.SizedBox(height: 12),
          if (trip.waypoints.isNotEmpty) ...[
            pw.Text(
              'Waypoints:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
            pw.SizedBox(height: 8),
            ...trip.waypoints.map((wp) => pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
                  child: pw.Row(
                    children: [
                      pw.Text('• ', style: const pw.TextStyle(fontSize: 12)),
                      pw.Text(
                        '${wp.name} (${wp.type})',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  /// Build route info row
  static pw.Widget _buildRouteInfo(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 130,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  /// Build visa information section
  static pw.Widget _buildVisaSection(Trip trip) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.red50,
        border: pw.Border.all(color: PdfColors.red200),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(6),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.red,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Text(
                  '!',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'Visa Required',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            trip.visaInfo ?? 'Please check visa requirements before traveling.',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Build itinerary section
  static pw.Widget _buildItinerary(Trip trip) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Daily Itinerary',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green700,
          ),
        ),
        pw.SizedBox(height: 16),
        ...trip.itinerary.map((day) => _buildDayCard(day)),
      ],
    );
  }

  /// Build individual day card
  static pw.Widget _buildDayCard(DayItinerary day) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green700,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  'Day ${day.dayNumber}',
                  style: pw.TextStyle(
                    color: PdfColors.white,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                dateFormat.format(day.date),
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Activities:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
          pw.SizedBox(height: 8),
          ...day.activities.map(
            (activity) => pw.Padding(
              padding: const pw.EdgeInsets.only(left: 16, bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('• ', style: const pw.TextStyle(fontSize: 12)),
                  pw.Expanded(
                    child: pw.Text(
                      activity,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (day.directions != null && day.directions!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '🧭 Directions:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    day.directions!,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
          if (day.notes != null && day.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '📝 Notes:',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    day.notes!,
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build info row helper
  static pw.Widget _buildInfoRow(
    String label,
    String value, {
    PdfColor? valueColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 12,
              color: valueColor ?? PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// Build footer
  static pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400),
        ),
      ),
      child: pw.Center(
        child: pw.Text(
          'Generated by Road Trip Buddy | ${DateFormat('MMMM dd, yyyy').format(DateTime.now())}',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      ),
    );
  }
}