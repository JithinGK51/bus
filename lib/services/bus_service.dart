import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ksrtc_users/config/api_config.dart';
import 'package:ksrtc_users/widgets/bus_list.dart';
import 'package:ksrtc_users/utils/mock_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusService {
  // Singleton instance
  static final BusService _instance = BusService._internal();
  factory BusService() => _instance;
  BusService._internal();

  // Favorite bus routes stored in memory
  final List<String> _favoriteBusIds = [];

  // Getter for favorite bus IDs
  List<String> get favoriteBusIds => _favoriteBusIds;

  // Initialize the service and load favorites from storage
  Future<void> init() async {
    await _loadFavorites();
    await _loadApiConfig();
  }

  // Load API configuration from SharedPreferences
  Future<void> _loadApiConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('api_base_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        ApiConfig.updateBaseUrl(savedUrl);
        debugPrint('Loaded API URL from preferences: ${ApiConfig.baseUrl}');
      }
    } catch (e) {
      debugPrint('Error loading API config: $e');
    }
  }

  // Load favorites from SharedPreferences
  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList('favorite_bus_routes') ?? [];
      _favoriteBusIds.clear();
      _favoriteBusIds.addAll(favorites);
      debugPrint('Loaded ${_favoriteBusIds.length} favorites from storage');
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  // Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('favorite_bus_routes', _favoriteBusIds);
      debugPrint('Saved ${_favoriteBusIds.length} favorites to storage');
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  // Toggle favorite status for a bus route
  Future<bool> toggleFavorite(String busId) async {
    if (_favoriteBusIds.contains(busId)) {
      _favoriteBusIds.remove(busId);
      await _saveFavorites();
      return false; // Not favorite anymore
    } else {
      _favoriteBusIds.add(busId);
      await _saveFavorites();
      return true; // Now favorite
    }
  }

  // Check if a bus route is favorite
  bool isFavorite(String busId) {
    return _favoriteBusIds.contains(busId);
  }

  // Cache for bus routes to improve loading time
  List<BusRoute>? _cachedAllRoutes;
  DateTime? _lastFetchTime;

  // Fetch all bus routes from API
  Future<List<BusRoute>> fetchAllBusRoutes() async {
    // Return cached data if available and less than 30 seconds old
    final now = DateTime.now();
    if (_cachedAllRoutes != null &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!).inSeconds < 30) {
      debugPrint('Using cached bus routes data');
      return _updateFavoriteStatus(_cachedAllRoutes!);
    }

    try {
      try {
        // Show immediate response with mock data first
        if (_cachedAllRoutes == null) {
          _cachedAllRoutes = MockData.getMockBusRoutes();
          _lastFetchTime = now;
        }

        // Then fetch real data in background
        final response = await http
            .get(Uri.parse(ApiConfig.busRoutesEndpoint))
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          final routes =
              data.map((routeData) {
                return BusRoute(
                  id: routeData['id'],
                  name: routeData['name'],
                  startPoint: routeData['start_point'],
                  endPoint: routeData['end_point'],
                  estimatedTime: routeData['estimated_time'],
                  distance: routeData['distance'].toDouble(),
                );
              }).toList();

          // Update cache
          _cachedAllRoutes = routes;
          _lastFetchTime = now;

          // Return with favorite status
          return _updateFavoriteStatus(routes);
        } else {
          throw Exception('Failed to load bus routes: ${response.statusCode}');
        }
      } catch (e) {
        // If API call fails, use mock data
        debugPrint('Using mock data due to API error: $e');
        final mockRoutes = MockData.getMockBusRoutes();

        // Update cache with mock data
        _cachedAllRoutes = mockRoutes;
        _lastFetchTime = now;

        // Return with favorite status
        return _updateFavoriteStatus(mockRoutes);
      }
    } catch (e) {
      debugPrint('Error fetching bus routes: $e');
      return []; // Return empty list on error
    }
  }

  // Helper method to update favorite status for a list of routes
  List<BusRoute> _updateFavoriteStatus(List<BusRoute> routes) {
    return routes.map((route) {
      if (_favoriteBusIds.contains(route.id)) {
        return route.copyWith(isFavorite: true);
      }
      return route;
    }).toList();
  }

  // Fetch only favorite bus routes
  Future<List<BusRoute>> fetchFavoriteBusRoutes() async {
    try {
      // If we have cached routes, use them immediately for favorites
      if (_cachedAllRoutes != null) {
        return _cachedAllRoutes!
            .where((route) => _favoriteBusIds.contains(route.id))
            .map((route) => route.copyWith(isFavorite: true))
            .toList();
      }

      // Otherwise fetch all routes first
      final allRoutes = await fetchAllBusRoutes();

      // Then filter to only favorites
      return allRoutes
          .where((route) => _favoriteBusIds.contains(route.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching favorite bus routes: $e');

      // Use mock data if API fails
      try {
        final mockRoutes = MockData.getMockBusRoutes();
        return mockRoutes
            .where((route) => _favoriteBusIds.contains(route.id))
            .map((route) => route.copyWith(isFavorite: true))
            .toList();
      } catch (mockError) {
        debugPrint('Error using mock data: $mockError');
        return []; // Return empty list if all else fails
      }
    }
  }
}
