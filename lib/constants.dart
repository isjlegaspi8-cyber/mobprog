import 'package:flutter_dotenv/flutter_dotenv.dart';

// Loaded from assets/.env — add a line like: HOST=https://dummyjson.com
String get host {
  final configured = dotenv.env['HOST'] ?? '';
  final trimmed = configured.trim();
  return trimmed.isEmpty ? 'https://dummyjson.com' : trimmed;
}
