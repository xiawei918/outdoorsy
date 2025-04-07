import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/geocoding_service.dart';

final geocodingServiceProvider = Provider((ref) => GeocodingService()); 