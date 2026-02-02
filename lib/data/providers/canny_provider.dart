import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/canny_service.dart';

/// Canny 서비스 Provider
final cannyServiceProvider = Provider<CannyService>((ref) {
  return CannyService(Supabase.instance.client);
});
