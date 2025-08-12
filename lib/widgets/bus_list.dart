import 'package:flutter/material.dart';
import 'package:ksrtc_users/theme/app_theme.dart';
import 'package:ksrtc_users/services/bus_service.dart';

class BusRoute {
  final String id;
  final String name;
  final String startPoint;
  final String endPoint;
  final String estimatedTime;
  final double distance;
  final bool isFavorite;

  BusRoute({
    required this.id,
    required this.name,
    required this.startPoint,
    required this.endPoint,
    required this.estimatedTime,
    required this.distance,
    this.isFavorite = false,
  });

  // Copy with method to create a new instance with some properties changed
  BusRoute copyWith({
    String? id,
    String? name,
    String? startPoint,
    String? endPoint,
    String? estimatedTime,
    double? distance,
    bool? isFavorite,
  }) {
    return BusRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      distance: distance ?? this.distance,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

class BusList extends StatefulWidget {
  const BusList({super.key});

  @override
  State<BusList> createState() => _BusListState();
}

class _BusListState extends State<BusList> {
  // List to store bus routes
  List<BusRoute> _busRoutes = [];
  // Filtered bus routes for display
  List<BusRoute> _filteredBusRoutes = [];
  // Bus service instance for API calls and favorite management
  final BusService _busService = BusService();
  // Loading state
  bool _isLoading = true;
  // Error state
  String? _error;
  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Fetch favorite bus routes from the API
  Future<void> _fetchBusRoutes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Fetch only favorite bus routes
      final routes = await _busService.fetchFavoriteBusRoutes();
      setState(() {
        _busRoutes = routes;
        _filteredBusRoutes = List.from(routes);
        _isLoading = false;
      });

      // Apply any existing search filter
      if (_searchController.text.isNotEmpty) {
        _filterBuses();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load bus routes: $e';
        _isLoading = false;
      });
    }
  }

  // Filter buses based on search query
  void _filterBuses() {
    final query = _searchController.text.toLowerCase().trim();

    setState(() {
      if (query.isEmpty) {
        _filteredBusRoutes = List.from(_busRoutes);
      } else {
        // Improved search algorithm - prioritize matches at the beginning of words
        _filteredBusRoutes =
            _busRoutes.where((route) {
              // Check if any word in the route name starts with the query
              final nameMatch = _checkStartsWithMatch(route.name, query);
              if (nameMatch) return true;

              // Check if any word in the start point starts with the query
              final startPointMatch = _checkStartsWithMatch(
                route.startPoint,
                query,
              );
              if (startPointMatch) return true;

              // Check if any word in the end point starts with the query
              final endPointMatch = _checkStartsWithMatch(
                route.endPoint,
                query,
              );
              if (endPointMatch) return true;

              // If no starts-with matches, fall back to contains
              return route.name.toLowerCase().contains(query) ||
                  route.startPoint.toLowerCase().contains(query) ||
                  route.endPoint.toLowerCase().contains(query);
            }).toList();
      }
    });
  }

  // Helper method to check if any word in text starts with query
  bool _checkStartsWithMatch(String text, String query) {
    final words = text.toLowerCase().split(' ');
    for (final word in words) {
      if (word.startsWith(query)) {
        return true;
      }
    }
    return false;
  }

  // Toggle favorite status for a bus route
  Future<void> _toggleFavorite(BusRoute route) async {
    final isFavorite = await _busService.toggleFavorite(route.id);
    setState(() {
      // Update the route in the list
      final index = _busRoutes.indexWhere((r) => r.id == route.id);
      if (index >= 0) {
        _busRoutes[index] = route.copyWith(isFavorite: isFavorite);
      }

      // If it's no longer a favorite, remove it from this list
      if (!isFavorite) {
        _busRoutes.removeWhere((r) => r.id == route.id);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialize the bus service first, then fetch routes
    _busService.init().then((_) {
      // Call the fetch method when the widget initializes
      _fetchBusRoutes();
    });

    // Add listener for search controller
    _searchController.addListener(_filterBuses);
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search favorite routes',
              prefixIcon: const Icon(Icons.search),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                      : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (_) => _filterBuses(),
          ),
        ),
        // Search status indicator
        if (_searchController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Results for "${_searchController.text}"',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_filteredBusRoutes.length} found',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 12),
                ),
              ],
            ),
          ),
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _buildErrorState()
                  : _filteredBusRoutes.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                    onRefresh: _fetchBusRoutes,
                    child: ListView.builder(
                      itemCount: _filteredBusRoutes.length,
                      itemBuilder: (context, index) {
                        final route = _filteredBusRoutes[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryYellow,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        route.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryDark,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        transitionBuilder: (
                                          Widget child,
                                          Animation<double> animation,
                                        ) {
                                          return ScaleTransition(
                                            scale: animation,
                                            child: child,
                                          );
                                        },
                                        child: Icon(
                                          route.isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          key: ValueKey<bool>(route.isFavorite),
                                          color:
                                              route.isFavorite
                                                  ? AppTheme.accentRed
                                                  : AppTheme.textGrey,
                                        ),
                                      ),
                                      onPressed: () => _toggleFavorite(route),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: AppTheme.primaryDark,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'From: ${route.startPoint}',
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                          ),
                                          Text(
                                            'To: ${route.endPoint}',
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Make the time and distance info responsive
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.access_time,
                                          color: AppTheme.primaryDark,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Est. Time: ${route.estimatedTime}',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.straighten,
                                          color: AppTheme.primaryDark,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Distance: ${route.distance} km',
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    // TODO: Implement view route details
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.accentBlue,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('View Route'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    // Show different messages based on whether there's a search query or not
    final bool isSearching = _searchController.text.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearching ? Icons.search_off : Icons.favorite_border,
            size: 80,
            color: AppTheme.textGrey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No Search Results' : 'No Favorite Routes',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try a different search term'
                : 'Add favorites from the All Bus Routes section',
            style: const TextStyle(color: AppTheme.textGrey),
          ),
          const SizedBox(height: 16),
          if (isSearching)
            ElevatedButton(
              onPressed: () => _searchController.clear(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Search'),
            )
          else
            ElevatedButton.icon(
              onPressed: _fetchBusRoutes,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentBlue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: AppTheme.accentRed.withOpacity(0.7),
          ),
          const SizedBox(height: 16),
          const Text(
            'Something Went Wrong',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? 'Failed to load bus routes',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textGrey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchBusRoutes,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
