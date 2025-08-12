import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:ksrtc_users/theme/app_theme.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:ksrtc_users/widgets/map_gesture_detector.dart';

class BusMap extends StatefulWidget {
  const BusMap({super.key});

  @override
  BusMapState createState() => BusMapState();
}

class BusMapState extends State<BusMap> {
  GoogleMapController? _mapController;
  final Location _location = Location();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};
  LocationData? _currentLocation;
  // Default to Tumkuru, Karnataka, India coordinates if user location is not available
  final LatLng _initialPosition = const LatLng(13.3379, 77.1173);
  bool _isLoading = true;
  double _currentZoom = 13.0;
  MapType _currentMapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _initLocationService();
  }

  Future<void> _initLocationService() async {
    // Show map immediately while fetching location in the background
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    _fetchLocationInBackground();
  }

  Future<void> _fetchLocationInBackground() async {
    try {
      bool serviceEnabled;
      PermissionStatus permissionGranted;

      // Check if location services are enabled
      serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          // Show a message to the user that location services are disabled
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location services are disabled. Some features may not work properly.',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      // Check location permission
      permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          // Show a message to the user that location permission is denied
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Location permission denied. Some features may not work properly.',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      // Get current location
      if (permissionGranted == PermissionStatus.granted) {
        _currentLocation = await _location.getLocation();

        // Update map camera to current location if available
        if (_currentLocation != null && _mapController != null && mounted) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
              15.0,
            ),
          );
        }

        // Set up location change listener
        _location.onLocationChanged.listen((LocationData currentLocation) {
          if (mounted) {
            setState(() {
              _currentLocation = currentLocation;
            });
          }
        });
      }
    } catch (e) {
      // Handle any exceptions that might occur
      debugPrint('Error initializing location service: $e');
    }
  }

  // Move camera to current location
  Future<void> goToCurrentLocation() async {
    if (_currentLocation != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!),
          15.0,
        ),
      );
    }
  }

  // Store the current camera position for panning
  late CameraPosition _lastCameraPosition = CameraPosition(
    target: _initialPosition,
    zoom: 13.0,
  );

  // Multi-touch gesture variables
  bool _isMultiTouchActive = false;
  double _startZoom = 13.0;
  late LatLng _gestureCenter = _initialPosition;
  Offset _gesturePosition = Offset.zero;
  double _gestureScale = 1.0;

  // Removed unused variable

  // Handle single-finger panning
  Future<void> _handleSingleFingerPan(Offset panDelta) async {
    if (_mapController == null) return;

    final LatLng currentTarget = _lastCameraPosition.target;

    // Calculate new position based on pan delta
    // Scale factor determines how responsive the panning feels
    const scaleFactor = 0.000005;
    final newLat =
        currentTarget.latitude + (panDelta.dy * scaleFactor * _currentZoom);
    final newLng =
        currentTarget.longitude - (panDelta.dx * scaleFactor * _currentZoom);

    final newTarget = LatLng(newLat, newLng);

    // Use moveCamera for smooth movement
    await _mapController!.moveCamera(CameraUpdate.newLatLng(newTarget));
  }

  // Show all markers on the map
  Future<void> showAllMarkers() async {
    if (_mapController != null && _markers.isNotEmpty) {
      // Create a bounds that includes all markers
      final bounds = _createBoundsFromMarkers();

      // Animate camera to show all markers with padding
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0), // 50.0 is padding
      );
    }
  }

  // Create bounds from all markers
  LatLngBounds _createBoundsFromMarkers() {
    double? minLat, maxLat, minLng, maxLng;

    // Include markers
    for (final marker in _markers) {
      if (minLat == null || marker.position.latitude < minLat) {
        minLat = marker.position.latitude;
      }
      if (maxLat == null || marker.position.latitude > maxLat) {
        maxLat = marker.position.latitude;
      }
      if (minLng == null || marker.position.longitude < minLng) {
        minLng = marker.position.longitude;
      }
      if (maxLng == null || marker.position.longitude > maxLng) {
        maxLng = marker.position.longitude;
      }
    }

    // Include polyline points
    for (final polyline in _polylines) {
      for (final point in polyline.points) {
        if (minLat == null || point.latitude < minLat) {
          minLat = point.latitude;
        }
        if (maxLat == null || point.latitude > maxLat) {
          maxLat = point.latitude;
        }
        if (minLng == null || point.longitude < minLng) {
          minLng = point.longitude;
        }
        if (maxLng == null || point.longitude > maxLng) {
          maxLng = point.longitude;
        }
      }
    }

    // Include circle centers
    for (final circle in _circles) {
      final LatLng center = circle.center;
      final double radius =
          circle.radius / 111000; // Convert meters to degrees (approx)

      if (minLat == null || center.latitude - radius < minLat) {
        minLat = center.latitude - radius;
      }
      if (maxLat == null || center.latitude + radius > maxLat) {
        maxLat = center.latitude + radius;
      }
      if (minLng == null || center.longitude - radius < minLng) {
        minLng = center.longitude - radius;
      }
      if (maxLng == null || center.longitude + radius > maxLng) {
        maxLng = center.longitude + radius;
      }
    }

    // Create bounds with some padding
    return LatLngBounds(
      southwest: LatLng(minLat! - 0.01, minLng! - 0.01),
      northeast: LatLng(maxLat! + 0.01, maxLng! + 0.01),
    );
  }

  // Zoom in function
  Future<void> _zoomIn() async {
    if (_mapController != null) {
      _currentZoom += 1.0;
      await _mapController!.animateCamera(CameraUpdate.zoomTo(_currentZoom));
    }
  }

  // Zoom out function
  Future<void> _zoomOut() async {
    if (_mapController != null) {
      _currentZoom -= 1.0;
      if (_currentZoom < 1.0) _currentZoom = 1.0;
      await _mapController!.animateCamera(CameraUpdate.zoomTo(_currentZoom));
    }
  }

  // Handle map gestures (single-finger pan and multi-touch pinch-to-zoom)
  void _handleMapGesture(MapGestureResult result) async {
    if (result.isMultiTouch) {
      // Handle multi-touch gestures
      setState(() {
        _gesturePosition = result.focalPoint;
        _gestureScale = result.scale;
      });

      if (!_isMultiTouchActive) {
        // First time detecting multi-touch
        _isMultiTouchActive = true;
        _startZoom = _currentZoom;

        // Try to convert screen coordinates to map coordinates
        if (_mapController != null) {
          try {
            _gestureCenter = await _mapController!
                .getLatLngFromScreenCoordinate(result.focalPoint);
          } catch (e) {
            // Fallback to current center if conversion fails
            _gestureCenter = _lastCameraPosition.target;
          }
        }
      }

      if (_mapController != null) {
        // Calculate new zoom based on pinch scale
        final newZoom = math.max(1.0, _startZoom * result.scale);

        // Apply the zoom centered on the focal point
        await _mapController!.moveCamera(
          CameraUpdate.newLatLngZoom(_gestureCenter, newZoom),
        );
      }
    } else if (result.panDelta != null) {
      // Handle single-finger pan
      setState(() {
        _isMultiTouchActive = false;
      });

      // Process the pan movement
      await _handleSingleFingerPan(result.panDelta!);
    }
  }

  // Reset gesture state when gesture ends
  void _handleMapGestureEnd() {
    setState(() {
      _isMultiTouchActive = false;
      _gestureScale = 1.0;
    });
  }

  // Toggle map type
  void _toggleMapType() {
    setState(() {
      _currentMapType =
          _currentMapType == MapType.normal
              ? MapType.satellite
              : MapType.normal;
    });
  }

  // This method is used by the HomePage to navigate to specific locations
  Future<void> goToLocation(LatLng location, double zoom) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(location, zoom),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Stack(
          children: [
            MapGestureDetector(
              onGestureUpdate: _handleMapGesture,
              onGestureEnd: _handleMapGestureEnd,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _initialPosition,
                  zoom: _currentZoom,
                ),
                markers: _markers,
                polylines: _polylines,
                circles: _circles,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                mapType: _currentMapType,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  // Go to user's location immediately when map is created
                  if (_currentLocation != null) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(
                          _currentLocation!.latitude!,
                          _currentLocation!.longitude!,
                        ),
                        15.0,
                      ),
                    );
                  }
                },
                onCameraMove: (CameraPosition position) {
                  _currentZoom = position.zoom;
                  _lastCameraPosition = position;
                },
                // Enable built-in gesture recognition for two-finger gestures
                zoomGesturesEnabled: true,
                rotateGesturesEnabled: true,
                tiltGesturesEnabled: true,
                scrollGesturesEnabled: true,
              ),
            ),
            // Map gesture instructions tooltip
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Use one finger to pan and two fingers to zoom',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),

            // Map control buttons - right side
            Positioned(
              right: 16,
              bottom: 120,
              child: Column(
                children: [
                  // Zoom in button
                  FloatingActionButton.small(
                    heroTag: 'zoomIn',
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryDark,
                    onPressed: _zoomIn,
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  // Zoom out button
                  FloatingActionButton.small(
                    heroTag: 'zoomOut',
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryDark,
                    onPressed: _zoomOut,
                    child: const Icon(Icons.remove),
                  ),
                  const SizedBox(height: 8),
                  // Map type toggle button
                  FloatingActionButton.small(
                    heroTag: 'mapType',
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryDark,
                    onPressed: _toggleMapType,
                    child: const Icon(Icons.layers),
                  ),
                  const SizedBox(height: 8),
                  // Current location button
                  FloatingActionButton.small(
                    heroTag: 'myLocation',
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryDark,
                    onPressed: goToCurrentLocation,
                    child: const Icon(Icons.my_location),
                  ),
                  const SizedBox(height: 8),
                  // Show all markers/routes button
                  FloatingActionButton.small(
                    heroTag: 'showAll',
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.primaryDark,
                    onPressed: showAllMarkers,
                    child: const Icon(Icons.map),
                  ),
                ],
              ),
            ),

            // Multi-touch gesture indicator
            if (_isMultiTouchActive)
              Positioned(
                left: _gesturePosition.dx - 50,
                top: _gesturePosition.dy - 50,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryYellow.withOpacity(0.2),
                    border: Border.all(color: AppTheme.primaryYellow, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      '${(_gestureScale).toStringAsFixed(1)}x',
                      style: const TextStyle(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
  }
}
