import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/trip_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/visa_service.dart';
import '../services/pdf_service.dart';
import '../services/tts_service.dart';
import '../utils/constants.dart';

/// Screen for planning a new trip with TTS support (Student A #1, #2, #4)
class PlanTripScreen extends StatefulWidget {
  final Trip? trip;

  const PlanTripScreen({super.key, this.trip});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _destinationController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _ttsService = TTSService();

  DateTime? _startDate;
  DateTime? _endDate;
  VisaInfo? _visaInfo;
  bool _isLoading = false;
  bool _showVisaInfo = false;
  bool _checkingVisa = false;

  List<DayItinerary> _itinerary = [];
  Map<int, List<TextEditingController>> _activityControllers = {};
  Map<int, TextEditingController> _notesControllers = {};
  Map<int, TextEditingController> _directionsControllers = {};

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
    if (widget.trip != null) {
      _loadExistingTrip();
    }
  }

  void _loadExistingTrip() {
    final trip = widget.trip!;
    _destinationController.text = trip.destination;
    _startDate = trip.startDate;
    _endDate = trip.endDate;
    _itinerary = List.from(trip.itinerary);
    _showVisaInfo = true;

    for (var day in _itinerary) {
      _activityControllers[day.dayNumber] = day.activities
          .map((activity) => TextEditingController(text: activity))
          .toList();
      _notesControllers[day.dayNumber] =
          TextEditingController(text: day.notes ?? '');
      _directionsControllers[day.dayNumber] =
          TextEditingController(text: day.directions ?? '');
    }

    _checkVisaWithAPI();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    for (var controllers in _activityControllers.values) {
      for (var controller in controllers) {
        controller.dispose();
      }
    }
    for (var controller in _notesControllers.values) {
      controller.dispose();
    }
    for (var controller in _directionsControllers.values) {
      controller.dispose();
    }
    _ttsService.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      AppHelpers.showSnackBar(
        context,
        'Please select start date first',
        isError: true,
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate!.add(const Duration(days: 1)),
      firstDate: _startDate!,
      lastDate: _startDate!.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _endDate = picked);
      _generateItinerary();
    }
  }

  /// Check visa with mock API (Student A #1)
  Future<void> _checkVisaWithAPI() async {
    final destination = _destinationController.text.trim();
    
    if (destination.isEmpty) {
      AppHelpers.showSnackBar(
        context,
        'Please enter a destination first',
        isError: true,
      );
      return;
    }

    setState(() => _checkingVisa = true);

    try {
      _visaInfo = await VisaService.checkVisaRequirementWithAPI(destination);
      setState(() {
        _showVisaInfo = true;
        _checkingVisa = false;
      });
    } catch (e) {
      setState(() => _checkingVisa = false);
      if (mounted) {
        AppHelpers.showSnackBar(
          context,
          'Error checking visa requirements',
          isError: true,
        );
      }
    }
  }

  void _generateItinerary() {
    if (_startDate == null || _endDate == null) return;

    final days = _endDate!.difference(_startDate!).inDays + 1;
    _itinerary.clear();
    _activityControllers.clear();
    _notesControllers.clear();
    _directionsControllers.clear();

    for (int i = 0; i < days; i++) {
      final dayNumber = i + 1;
      final date = _startDate!.add(Duration(days: i));

      _itinerary.add(DayItinerary(
        dayNumber: dayNumber,
        date: date,
        activities: [],
        notes: null,
        directions: null,
      ));

      _activityControllers[dayNumber] = [TextEditingController()];
      _notesControllers[dayNumber] = TextEditingController();
      _directionsControllers[dayNumber] = TextEditingController();
    }

    setState(() {});
  }

  void _addActivityField(int dayNumber) {
    setState(() {
      _activityControllers[dayNumber]!.add(TextEditingController());
    });
  }

  void _removeActivityField(int dayNumber, int index) {
    setState(() {
      _activityControllers[dayNumber]![index].dispose();
      _activityControllers[dayNumber]!.removeAt(index);
    });
  }

  List<DayItinerary> _buildItineraryFromInput() {
    return _itinerary.map((day) {
      final activities = _activityControllers[day.dayNumber]!
          .map((controller) => controller.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      final notes = _notesControllers[day.dayNumber]!.text.trim();
      final directions = _directionsControllers[day.dayNumber]!.text.trim();

      return DayItinerary(
        dayNumber: day.dayNumber,
        date: day.date,
        activities: activities,
        notes: notes.isEmpty ? null : notes,
        directions: directions.isEmpty ? null : directions,
      );
    }).toList();
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) return;

    if (_startDate == null || _endDate == null) {
      AppHelpers.showSnackBar(
        context,
        'Please select trip dates',
        isError: true,
      );
      return;
    }

    final userId = _authService.currentUserId;
    if (userId == null) return;

    setState(() => _isLoading = true);

    final destination = _destinationController.text.trim();
    final visaInfo = _visaInfo ?? await VisaService.checkVisaRequirementWithAPI(destination);
    final itinerary = _buildItineraryFromInput();

    final trip = Trip(
      id: widget.trip?.id,
      userId: userId,
      destination: destination,
      startDate: _startDate!,
      endDate: _endDate!,
      visaRequired: visaInfo.required,
      visaInfo: visaInfo.notes,
      itinerary: itinerary,
      createdAt: widget.trip?.createdAt ?? DateTime.now(),
    );

    String? result;
    if (widget.trip != null) {
      final success = await _firestoreService.updateTrip(trip);
      result = success ? null : 'failed';
    } else {
      result = await _firestoreService.createTrip(trip);
    }

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result != null && (widget.trip != null || result != 'failed')) {
      AppHelpers.showSnackBar(
        context,
        'Trip saved successfully!',
      );
      Navigator.pop(context);
    } else {
      AppHelpers.showSnackBar(
        context,
        'Failed to save trip. Please try again.',
        isError: true,
      );
    }
  }

  Future<void> _generatePDF() async {
    if (_startDate == null || _endDate == null) {
      AppHelpers.showSnackBar(
        context,
        'Please complete trip details first',
        isError: true,
      );
      return;
    }

    final destination = _destinationController.text.trim();
    if (destination.isEmpty) {
      AppHelpers.showSnackBar(
        context,
        'Please enter a destination',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userId = _authService.currentUserId;
      final visaInfo = _visaInfo ?? await VisaService.checkVisaRequirementWithAPI(destination);
      final itinerary = _buildItineraryFromInput();

      final trip = Trip(
        userId: userId ?? '',
        destination: destination,
        startDate: _startDate!,
        endDate: _endDate!,
        visaRequired: visaInfo.required,
        visaInfo: visaInfo.notes,
        itinerary: itinerary,
        createdAt: DateTime.now(),
      );

      await PdfService.generateTripPDF(trip);

      if (!mounted) return;
      AppHelpers.showSnackBar(context, 'PDF generated successfully!');
    } catch (e) {
      if (!mounted) return;
      AppHelpers.showSnackBar(
        context,
        'Failed to generate PDF: $e',
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Read directions with TTS (Student A #4)
  Future<void> _readDirections(int dayNumber, bool inArabic) async {
    final directions = _directionsControllers[dayNumber]!.text.trim();
    
    if (directions.isEmpty) {
      AppHelpers.showSnackBar(
        context,
        'No directions to read for this day',
        isError: true,
      );
      return;
    }

    await _ttsService.readTripDirections(
      dayNumber,
      directions,
      inArabic: inArabic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip != null ? 'Edit Trip' : 'Plan New Trip'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              children: [
                TextFormField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    labelText: 'Destination',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                    hintText: 'e.g., Dubai, Turkey, Egypt',
                  ),
                  validator: AppHelpers.validateDestination,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectStartDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _startDate != null
                                    ? dateFormat.format(_startDate!)
                                    : 'Select',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _selectEndDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Date',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _endDate != null
                                    ? dateFormat.format(_endDate!)
                                    : 'Select',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _checkingVisa ? null : _checkVisaWithAPI,
                  icon: _checkingVisa
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.card_travel),
                  label: Text(_checkingVisa
                      ? 'Checking Visa...'
                      : 'Check Visa Requirements'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.secondaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                ),

                if (_showVisaInfo && _visaInfo != null) ...[
                  const SizedBox(height: 16),
                  _buildVisaInfoCard(),
                ],

                if (_itinerary.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Daily Itinerary',
                    style: AppConstants.subheadingStyle,
                  ),
                  const SizedBox(height: 16),
                  ..._itinerary.map((day) => _buildDayCard(day)),
                ],

                const SizedBox(height: 100),
              ],
            ),
          ),

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
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveTrip,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Trip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _generatePDF,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text('PDF'),
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
                ],
              ),
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: SpinKitFadingCircle(
                  color: AppConstants.primaryColor,
                  size: 50,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVisaInfoCard() {
    final visaInfo = _visaInfo!;
    final color = visaInfo.required ? AppConstants.errorColor : Colors.green;

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
                visaInfo.required ? Icons.warning : Icons.check_circle,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                visaInfo.required ? 'Visa Required' : 'No Visa Required',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Type:', visaInfo.type),
          _buildInfoRow('Stay Duration:', visaInfo.stayDuration),
          if (visaInfo.cost != null) _buildInfoRow('Cost:', visaInfo.cost!),
          if (visaInfo.processingTime != null)
            _buildInfoRow('Processing:', visaInfo.processingTime!),
          _buildInfoRow('Source:', visaInfo.apiSource),
          const SizedBox(height: 8),
          Text(
            visaInfo.notes,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(DayItinerary day) {
    final dateFormat = DateFormat('EEEE, MMM dd');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                Text(
                  dateFormat.format(day.date),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Activities:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(
              _activityControllers[day.dayNumber]!.length,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _activityControllers[day.dayNumber]![index],
                        decoration: InputDecoration(
                          hintText: 'Add activity',
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (_activityControllers[day.dayNumber]!.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeActivityField(day.dayNumber, index),
                      ),
                  ],
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _addActivityField(day.dayNumber),
              icon: const Icon(Icons.add),
              label: const Text('Add Activity'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesControllers[day.dayNumber],
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _directionsControllers[day.dayNumber],
              decoration: InputDecoration(
                labelText: 'Directions (for TTS)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: () => _readDirections(day.dayNumber, false),
                      tooltip: 'Read in English',
                    ),
                    IconButton(
                      icon: const Text('ع', style: TextStyle(fontSize: 18)),
                      onPressed: () => _readDirections(day.dayNumber, true),
                      tooltip: 'Read in Arabic',
                    ),
                  ],
                ),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}