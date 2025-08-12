import 'package:flutter/material.dart';
import 'package:ksrtc_users/theme/app_theme.dart';
import 'package:ksrtc_users/widgets/bus_list.dart';
import 'package:ksrtc_users/services/bus_service.dart';
import 'package:ksrtc_users/utils/mock_data.dart';

class AllBusList extends StatefulWidget {
  final TextEditingController? externalSearchController;

  const AllBusList({super.key, this.externalSearchController});

  @override
  State<AllBusList> createState() => _AllBusListState();
}

class _AllBusListState extends State<AllBusList>
    with SingleTickerProviderStateMixin {
  // List to store all bus routes
  List<BusRoute> _allBusRoutes = [];
  // Bus service instance for API calls and favorite management
  final BusService _busService = BusService();
  // Loading state
  bool _isLoading = true;
  // Error state
  String? _error;
  // Placeholder data loaded flag
  bool _placeholderLoaded = false;

  // Filtered bus routes for display
  List<BusRoute> _filteredBusRoutes = [];
  late TextEditingController _searchController;
  bool _isUsingExternalController = false;

  // Fetch all bus routes from the API
  Future<void> _fetchAllBusRoutes() async {
    // If we already have placeholder data, don't show loading indicator again
    if (!_placeholderLoaded) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      // Fetch all bus routes
      final routes = await _busService.fetchAllBusRoutes();

      // Only update UI if the widget is still mounted
      if (mounted) {
        setState(() {
          // Keep favorite status from placeholder data
          if (_placeholderLoaded) {
            // Create a map of favorite status from current data
            final Map<String, bool> favoriteStatus = {};
            for (final route in _allBusRoutes) {
              if (route.isFavorite) {
                favoriteStatus[route.id] = true;
              }
            }

            // Apply favorite status to new data
            _allBusRoutes =
                routes.map((route) {
                  if (favoriteStatus.containsKey(route.id)) {
                    return route.copyWith(isFavorite: true);
                  }
                  return route;
                }).toList();
          } else {
            _allBusRoutes = routes;
          }

          // Update filtered routes
          if (_searchController.text.isEmpty) {
            _filteredBusRoutes = List.from(_allBusRoutes);
          } else {
            // Re-apply current filter
            _filterBuses();
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      // Only update UI if the widget is still mounted and we don't have placeholder data
      if (mounted && !_placeholderLoaded) {
        setState(() {
          _error = 'Failed to load bus routes: $e';
          _isLoading = false;
        });
      } else if (mounted) {
        // Just log the error if we have placeholder data
        print('Error fetching bus routes: $e');
      }
    }
  }

  // Toggle favorite status for a bus route
  Future<void> _toggleFavorite(BusRoute route) async {
    final isFavorite = await _busService.toggleFavorite(route.id);
    setState(() {
      // Update the route in both lists
      final allIndex = _allBusRoutes.indexWhere((r) => r.id == route.id);
      if (allIndex >= 0) {
        _allBusRoutes[allIndex] = route.copyWith(isFavorite: isFavorite);
      }

      final filteredIndex = _filteredBusRoutes.indexWhere(
        (r) => r.id == route.id,
      );
      if (filteredIndex >= 0) {
        _filteredBusRoutes[filteredIndex] = route.copyWith(
          isFavorite: isFavorite,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();

    // Use external controller if provided, otherwise create a local one
    if (widget.externalSearchController != null) {
      _searchController = widget.externalSearchController!;
      _isUsingExternalController = true;
    } else {
      _searchController = TextEditingController();
    }

    _searchController.addListener(_filterBuses);

    // Load placeholder data immediately
    _loadPlaceholderData();

    // Initialize the bus service and fetch real data
    _busService.init().then((_) {
      // Fetch bus routes data in the background
      _fetchAllBusRoutes();
    });
  }

  // Load placeholder data immediately for better UX
  void _loadPlaceholderData() {
    // Use mock data as placeholder
    final mockRoutes = MockData.getMockBusRoutes();
    setState(() {
      _allBusRoutes = mockRoutes;
      _filteredBusRoutes = List.from(mockRoutes);
      _placeholderLoaded = true;
      _isLoading = false;

      // Apply any existing search term if needed
      if (_searchController.text.isNotEmpty) {
        _filterBuses();
      }
    });
  }

  @override
  void dispose() {
    // Only dispose the controller if we created it internally
    if (!_isUsingExternalController) {
      _searchController.dispose();
    }
    super.dispose();
  }

  void _filterBuses() {
    final query = _searchController.text.toLowerCase().trim();

    // Immediately update UI for better responsiveness
    setState(() {
      if (query.isEmpty) {
        _filteredBusRoutes = List.from(_allBusRoutes);
      } else {
        // Improved search algorithm - prioritize matches at the beginning of words
        _filteredBusRoutes =
            _allBusRoutes.where((route) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Only show the search field if not using an external controller
        if (!_isUsingExternalController)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search all buses',
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
                    onRefresh: _fetchAllBusRoutes,
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
                                    Text(
                                      'Bus #${route.id}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textGrey,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
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
                                // Make buttons more responsive with Row
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          // TODO: Implement track bus functionality
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppTheme.primaryYellow,
                                          foregroundColor: AppTheme.primaryDark,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 12,
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.location_on,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Track',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          // TODO: Implement view details functionality
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.accentBlue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                            horizontal: 12,
                                          ),
                                        ),
                                        icon: const Icon(
                                          Icons.info_outline,
                                          size: 16,
                                        ),
                                        label: const Text(
                                          'Details',
                                          style: TextStyle(fontSize: 13),
                                        ),
                                      ),
                                    ),
                                  ],
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
            isSearching ? Icons.search_off : Icons.directions_bus_outlined,
            size: 80,
            color: AppTheme.textGrey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No Results Found' : 'No Bus Routes Available',
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
                : 'Bus routes will appear here when available',
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
              onPressed: _fetchAllBusRoutes,
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
            onPressed: _fetchAllBusRoutes,
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
