import 'package:ksrtc_users/widgets/bus_list.dart';

/// This class provides mock data for testing purposes
/// It can be used when the API is not available
class MockData {
  /// Returns a list of mock bus routes
  static List<BusRoute> getMockBusRoutes() {
    return [
      BusRoute(
        id: '1',
        name: 'Route 101',
        startPoint: 'Tumkuru Bus Station',
        endPoint: 'Bengaluru Majestic',
        estimatedTime: '2h 30m',
        distance: 70.5,
      ),
      BusRoute(
        id: '2',
        name: 'Route 102',
        startPoint: 'Tumkuru Bus Station',
        endPoint: 'Mysuru Bus Stand',
        estimatedTime: '3h 45m',
        distance: 145.2,
      ),
      BusRoute(
        id: '3',
        name: 'Route 103',
        startPoint: 'Tumkuru Bus Station',
        endPoint: 'Hassan Bus Terminal',
        estimatedTime: '2h 15m',
        distance: 118.7,
      ),
      BusRoute(
        id: '4',
        name: 'Route 104',
        startPoint: 'Tumkuru Bus Station',
        endPoint: 'Davangere Bus Stand',
        estimatedTime: '1h 50m',
        distance: 110.3,
      ),
      BusRoute(
        id: '5',
        name: 'Route 105',
        startPoint: 'Tumkuru Bus Station',
        endPoint: 'Chitradurga Bus Terminal',
        estimatedTime: '1h 30m',
        distance: 85.6,
      ),
    ];
  }
}
