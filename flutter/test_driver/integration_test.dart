import 'package:integration_test/integration_test_driver.dart';

/// Host side of `flutter drive` for integration tests (used for the
/// profile-mode, AOT-compiled device baseline).
Future<void> main() => integrationDriver();
