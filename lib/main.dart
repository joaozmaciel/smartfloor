import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/supabase_config.dart';
import 'features/home/data/repositories/supabase_project_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ensureConfigured();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabasePublishableKey);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(SmartFloorApp(projectRepository: SupabaseProjectRepository()));
}
