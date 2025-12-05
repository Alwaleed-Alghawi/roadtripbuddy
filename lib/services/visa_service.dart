/// Service to check visa requirements for Omani passport holders
/// Simulates calling Oman MFA visa API
class VisaService {

  /// Check visa requirement with mock API call
  static Future<VisaInfo> checkVisaRequirementWithAPI(String destination) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    // In real implementation, would call:
    // final response = await http.post(
    //   Uri.parse(_mockApiUrl),
    //   body: json.encode({'destination': destination, 'passport': 'OMN'}),
    // );

    // For now, return from local database
    return _getVisaInfoFromDatabase(destination);
  }

  /// Get visa info from local database (mock API response)
  static VisaInfo _getVisaInfoFromDatabase(String destination) {
    final normalizedDest = destination.trim().toLowerCase();

    for (var entry in _visaRequirements.entries) {
      if (entry.key.toLowerCase() == normalizedDest) {
        return entry.value;
      }
    }

    // Return default for unknown countries
    return VisaInfo(
      required: true,
      type: 'Unknown',
      stayDuration: 'N/A',
      notes: 'Please check with the embassy or consulate of $destination for visa requirements.',
      apiSource: 'Oman MFA Mock API',
    );
  }

  /// Map of countries and their visa requirements for Omani citizens
  static const Map<String, VisaInfo> _visaRequirements = {
    // GCC Countries - Visa Free
    'United Arab Emirates': VisaInfo(
      required: false,
      type: 'Visa Free',
      stayDuration: '90 days',
      notes: 'GCC citizens can enter freely with national ID',
      apiSource: 'Oman MFA API',
    ),
    'Saudi Arabia': VisaInfo(
      required: false,
      type: 'Visa Free',
      stayDuration: '90 days',
      notes: 'GCC citizens can enter freely',
      apiSource: 'Oman MFA API',
    ),
    'Kuwait': VisaInfo(
      required: false,
      type: 'Visa Free',
      stayDuration: '90 days',
      notes: 'GCC citizens can enter freely',
      apiSource: 'Oman MFA API',
    ),
    'Bahrain': VisaInfo(
      required: false,
      type: 'Visa Free',
      stayDuration: '90 days',
      notes: 'GCC citizens can enter freely',
      apiSource: 'Oman MFA API',
    ),
    'Qatar': VisaInfo(
      required: false,
      type: 'Visa Free',
      stayDuration: '90 days',
      notes: 'GCC citizens can enter freely',
      apiSource: 'Oman MFA API',
    ),
    'Dubai': VisaInfo(
      required: false,
      type: 'Visa Free',
      stayDuration: '90 days',
      notes: 'GCC citizens can enter freely with national ID',
      apiSource: 'Oman MFA API',
    ),

    // Visa Free Countries
    'Malaysia': VisaInfo(
      required: false,
      type: 'Visa Free',
      stayDuration: '90 days',
      notes: 'No visa required for tourism',
      apiSource: 'Oman MFA API',
    ),
    'Singapore': VisaInfo(
      required: false,
      type: 'Visa Free',
      stayDuration: '30 days',
      notes: 'No visa required for tourism',
      apiSource: 'Oman MFA API',
    ),
    'Turkey': VisaInfo(
      required: false,
      type: 'Visa Free',
      stayDuration: '90 days',
      notes: 'No visa required for tourism',
      apiSource: 'Oman MFA API',
    ),
    'Egypt': VisaInfo(
      required: false,
      type: 'Visa on Arrival',
      stayDuration: '30 days',
      notes: 'Visa available on arrival at airport',
      cost: '25 USD',
      processingTime: 'On arrival',
      apiSource: 'Oman MFA API',
    ),
    'Jordan': VisaInfo(
      required: false,
      type: 'Visa on Arrival',
      stayDuration: '30 days',
      notes: 'Visa available on arrival',
      cost: '40 JOD',
      processingTime: 'On arrival',
      apiSource: 'Oman MFA API',
    ),
    'Morocco': VisaInfo(
      required: false,
      type: 'Visa Free',
      stayDuration: '90 days',
      notes: 'No visa required',
      apiSource: 'Oman MFA API',
    ),
    'Tunisia': VisaInfo(
      required: false,
      type: 'Visa Free',
      stayDuration: '90 days',
      notes: 'No visa required',
      apiSource: 'Oman MFA API',
    ),

    // Visa Required Countries
    'United States': VisaInfo(
      required: true,
      type: 'B1/B2 Tourist Visa',
      stayDuration: 'Up to 6 months',
      notes: 'Must apply at US Embassy. Interview required',
      cost: '160 USD',
      processingTime: '2-4 weeks',
      apiSource: 'Oman MFA API',
    ),
    'United Kingdom': VisaInfo(
      required: true,
      type: 'Standard Visitor Visa',
      stayDuration: 'Up to 6 months',
      notes: 'Apply online before travel',
      cost: '100 GBP',
      processingTime: '3 weeks',
      apiSource: 'Oman MFA API',
    ),
    'Canada': VisaInfo(
      required: true,
      type: 'Visitor Visa (TRV)',
      stayDuration: 'Up to 6 months',
      notes: 'Apply online or at visa center',
      cost: '100 CAD',
      processingTime: '2-3 weeks',
      apiSource: 'Oman MFA API',
    ),
    'Australia': VisaInfo(
      required: true,
      type: 'Visitor Visa (subclass 600)',
      stayDuration: 'Up to 3 months',
      notes: 'Apply online',
      cost: '145 AUD',
      processingTime: '2-4 weeks',
      apiSource: 'Oman MFA API',
    ),
    'India': VisaInfo(
      required: true,
      type: 'e-Visa',
      stayDuration: '30 days',
      notes: 'Apply online 4 days before travel',
      cost: '25 USD',
      processingTime: '3-5 days',
      apiSource: 'Oman MFA API',
    ),
    'China': VisaInfo(
      required: true,
      type: 'Tourist Visa (L)',
      stayDuration: '30 days',
      notes: 'Apply at Chinese Embassy',
      cost: '140 USD',
      processingTime: '4-7 days',
      apiSource: 'Oman MFA API',
    ),
    'Japan': VisaInfo(
      required: true,
      type: 'Temporary Visitor Visa',
      stayDuration: '15-90 days',
      notes: 'Apply at Japanese Embassy',
      cost: 'Free',
      processingTime: '5-7 days',
      apiSource: 'Oman MFA API',
    ),
    'South Korea': VisaInfo(
      required: true,
      type: 'Tourist Visa',
      stayDuration: '90 days',
      notes: 'Apply at Korean Embassy',
      cost: '40 USD',
      processingTime: '5-7 days',
      apiSource: 'Oman MFA API',
    ),
    'Thailand': VisaInfo(
      required: false,
      type: 'Visa on Arrival',
      stayDuration: '15 days',
      notes: 'Visa available on arrival for 15 days',
      cost: '2,000 THB',
      processingTime: 'On arrival',
      apiSource: 'Oman MFA API',
    ),
    'Indonesia': VisaInfo(
      required: false,
      type: 'Visa Free',
      stayDuration: '30 days',
      notes: 'Visa-free for tourism',
      apiSource: 'Oman MFA API',
    ),
  };

  /// Get list of all countries in database
  static List<String> getAllCountries() {
    return _visaRequirements.keys.toList()..sort();
  }
}

/// Model for visa information
class VisaInfo {
  final bool required;
  final String type;
  final String stayDuration;
  final String notes;
  final String? cost;
  final String? processingTime;
  final String apiSource;

  const VisaInfo({
    required this.required,
    required this.type,
    required this.stayDuration,
    required this.notes,
    this.cost,
    this.processingTime,
    this.apiSource = 'Oman MFA API',
  });
}