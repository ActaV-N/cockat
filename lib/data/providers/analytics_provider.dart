import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/analytics_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});
