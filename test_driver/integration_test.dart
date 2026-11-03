// Driver for the profile-mode measurements in integration_test/*_perf_test.dart:
//
//   fvm flutter drive --profile --no-dds --flavor dev --driver=test_driver/integration_test.dart \
//     --target=integration_test/thumbnails_perf_test.dart
//
// Results land in build/integration_response_data.json.
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
