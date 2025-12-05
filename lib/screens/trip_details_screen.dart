import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/trip_model.dart';
import '../services/firestore_service.dart';
import '../services/pdf_service.dart';
import '../services/tts_service.dart';
import '../utils/constants.dart';
import '../widgets/trip_progress_widget.dart';
import 'plan_trip_screen.dart';

/// Screen to display trip details with progress widget and TTS
class TripDetailsScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailsScreen({super.key, required this.trip});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  final _firestoreService = FirestoreService();
  final _ttsService = TTSService();
  bool _isDeleting = false;
  bool _isGeneratingPDF = false;

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _deleteTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text(
            'Are you sure you want to delete this trip? This action cannot be undone.'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppConstants.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isDeleting = true);

      final success = await _firestoreService.deleteTrip(widget.trip.id!);

      if (!mounted) return;

      if (success) {
        AppHelpers.showSnackBar(context, 'Trip deleted successfully');
        Navigator.pop(context);
      } else {
        setState(() => _isDeleting = false);
        AppHelpers.showSnackBar(
          context,
          'Failed to delete trip',
          isError: true,
        );
      }
    }
  }

  Future<void> _generatePDF() async {
    setState(() => _isGeneratingPDF = true);

    try {
      await PdfService.generateTripPDF(widget.trip);
      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'PDF generated successfully!');
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showSnackBar(
        context,
        'Failed to generate PDF',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPDF = false);
    }
  }

  void _editTrip() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanTripScreen(trip: widget.trip),
      ),
    );
  }

  Future<void> _readTripSummary(bool inArabic) async {
    await _ttsService.readTripSummary(
      widget.trip.destination,
      widget.trip.durationDays,
      widget.trip.totalActivities,
      inArabic: inArabic,
    );
  }

  Future<void> _readDayDirections(DayItinerary day, bool inArabic) async {
    if (day.directions == null || day.directions!.isEmpty) {
      AppHelpers.showSnackBar(
        context,
        'No directions for this day',
        isError: true,
      );
      return;
    }

    await _ttsService.readTripDirections(
      day.dayNumber,
      day.directions!,
      inArabic: inArabic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final trip = widget.trip;
    final status = AppHelpers.getTripStatus(trip.startDate, trip.endDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editTrip,
            tooltip: 'Edit',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteTrip,
            tooltip: 'Delete',
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            children: [
              // Destination Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConstants.primaryColor,
                      AppConstants.secondaryColor,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            trip.destination,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${dateFormat.format(trip.startDate)} - ${dateFormat.format(trip.endDate)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${trip.durationDays} day${trip.durationDays > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 20),
                        const Icon(Icons.list_alt,
                            color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${trip.totalActivities} activities',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // TTS Summary Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _readTripSummary(false),
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Play English'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.infoColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _readTripSummary(true),
                      icon: const Text('🔊', style: TextStyle(fontSize: 18)),
                      label: const Text('عربي'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.successColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Trip Progress Widget (Student B #4)
              if (status == 'Ongoing') ...[
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Trip Progress',
                          style: AppConstants.subheadingStyle,
                        ),
                        const SizedBox(height: 20),
                        TripProgressWidget(trip: trip),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Visa Information
              _buildVisaCard(),
              const SizedBox(height: 20),

              // Itinerary
              Text(
                'Daily Itinerary',
                style: AppConstants.subheadingStyle,
              ),
              const SizedBox(height: 12),
              ...trip.itinerary.map((day) => _buildDayCard(day)),

              const SizedBox(height: 100),
            ],
          ),

          // Bottom PDF Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isGeneratingPDF ? null : _generatePDF,
                icon: _isGeneratingPDF
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_isGeneratingPDF ? 'Generating...' : 'Download PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
              ),
            ),
          ),

          if (_isDeleting)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVisaCard() {
    final trip = widget.trip;
    final color = trip.visaRequired ? AppConstants.errorColor : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                trip.visaRequired ? Icons.warning : Icons.check_circle,
                color: color,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                trip.visaRequired ? 'Visa Required' : 'No Visa Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          if (trip.visaInfo != null) ...[
            const SizedBox(height: 12),
            Text(
              trip.visaInfo!,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayCard(DayItinerary day) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Day ${day.dayNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    dateFormat.format(day.date),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (day.activities.isNotEmpty) ...[
              const Text(
                'Activities:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              ...day.activities.map(
                (activity) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontSize: 16)),
                      Expanded(
                        child: Text(
                          activity,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (day.directions != null && day.directions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🧭 Directions:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.volume_up, size: 20),
                              onPressed: () => _readDayDirections(day, false),
                              tooltip: 'English',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Text('ع',
                                  style: TextStyle(fontSize: 16)),
                              onPressed: () => _readDayDirections(day, true),
                              tooltip: 'Arabic',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.directions!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            if (day.notes != null && day.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📝 Notes:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      day.notes!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            if (day.activities.isEmpty &&
                (day.notes == null || day.notes!.isEmpty) &&
                (day.directions == null || day.directions!.isEmpty))
              Text(
                'No activities planned',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        ),
      ),
    );
  }
}