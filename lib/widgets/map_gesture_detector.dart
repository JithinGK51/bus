import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapGestureResult {
  final double scale;
  final double rotation;
  final Offset focalPoint;
  final bool isMultiTouch;
  final Offset? panDelta;

  MapGestureResult({
    required this.scale,
    required this.rotation,
    required this.focalPoint,
    required this.isMultiTouch,
    this.panDelta,
  });
}

class MapGestureDetector extends StatefulWidget {
  final Widget child;
  final Function(MapGestureResult) onGestureUpdate;
  final Function() onGestureEnd;

  const MapGestureDetector({
    super.key,
    required this.child,
    required this.onGestureUpdate,
    required this.onGestureEnd,
  });

  @override
  State<MapGestureDetector> createState() => _MapGestureDetectorState();
}

class _MapGestureDetectorState extends State<MapGestureDetector> {
  double _baseScaleFactor = 1.0;
  double _currentScaleFactor = 1.0;
  double _baseRotation = 0.0;
  double _currentRotation = 0.0;
  bool _isMultiTouch = false;

  // Single-finger pan tracking
  Offset _lastPanPosition = Offset.zero;
  Offset _currentPanDelta = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _handleScaleStart,
      onScaleUpdate: _handleScaleUpdate,
      onScaleEnd: _handleScaleEnd,
      child: widget.child,
    );
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScaleFactor = _currentScaleFactor;
    _baseRotation = _currentRotation;
    _lastPanPosition = details.focalPoint;
    _isMultiTouch = false;
    _currentPanDelta = Offset.zero;
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // Check if this is a multi-touch gesture (2+ fingers)
    _isMultiTouch = details.pointerCount >= 2;

    if (_isMultiTouch) {
      // Handle multi-touch gestures (pinch-to-zoom, rotation)
      setState(() {
        _currentScaleFactor = _baseScaleFactor * details.scale;
        _currentRotation = _baseRotation + details.rotation;
      });

      widget.onGestureUpdate(
        MapGestureResult(
          scale: details.scale,
          rotation: details.rotation,
          focalPoint: details.focalPoint,
          isMultiTouch: true,
        ),
      );
    } else {
      // Handle single-finger pan
      final currentPosition = details.focalPoint;
      _currentPanDelta = currentPosition - _lastPanPosition;
      _lastPanPosition = currentPosition;

      widget.onGestureUpdate(
        MapGestureResult(
          scale: 1.0,
          rotation: 0.0,
          focalPoint: currentPosition,
          isMultiTouch: false,
          panDelta: _currentPanDelta,
        ),
      );
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    widget.onGestureEnd();
  }
}

// Extension to convert screen coordinates to LatLng
extension ScreenCoordsToLatLng on GoogleMapController {
  Future<LatLng> getLatLngFromScreenCoordinate(Offset point) async {
    return await getLatLng(
      ScreenCoordinate(x: point.dx.toInt(), y: point.dy.toInt()),
    );
  }
}
