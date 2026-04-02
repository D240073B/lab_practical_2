import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '/services/location_service.dart';
import '/services/checkin_service.dart';
import '/screens/history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String locationText = 'No location.';
  String? currentAddress;

  double? currentLatitude;
  double? currentLongitude;

  Fair? nearestFair;
  double? distanceToFair;
  bool isAtFair = false;
  int totalPoints = 0;

  late MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _loadTotalPoints();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadTotalPoints() async {
    final points = await CheckInService.getTotalPoints();
    setState(() {
      totalPoints = points;
    });
  }

  Future<void> _joinFair() async {
    if (nearestFair == null || !isAtFair) {
      _showSnackBar('You are not within any fair location.');
      return;
    }

    await CheckInService.addCheckIn(nearestFair!.name, nearestFair!.points);
    await _loadTotalPoints();
    _showSnackBar(
        'Joined "${nearestFair!.name}" — earned ${nearestFair!.points} points!');
  }

  Future<void> _viewHistory() async {
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HistoryScreen()),
    );
    // Refresh points when returning from history
    _loadTotalPoints();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _getLocation() async {
    try {
      final locationService = LocationService();

      final position = await locationService.getCurrentLocation();
      final address =
          await locationService.getAddressFromCoordinates(position);

      final result =
          locationService.getNearestFair(position.latitude, position.longitude);

      setState(() {
        currentLatitude = position.latitude;
        currentLongitude = position.longitude;
        currentAddress =
            address.startsWith('Address unavailable:') ? null : address;
        locationText =
            'Latitude: ${position.latitude.toStringAsFixed(6)}\n'
            'Longitude: ${position.longitude.toStringAsFixed(6)}\n\n'
            'Address: $address';

        nearestFair = result.fair;
        distanceToFair = result.distance;
        isAtFair = result.distance <= result.fair.radius;
      });

      // Animate map to user location
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15,
      );
    } catch (e) {
      setState(() {
        locationText = 'Error getting location: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasLocation =
        currentLatitude != null && currentLongitude != null;

    // Default to first fair if no nearest fair determined yet
    final displayFair = nearestFair ?? LocationService.fairs.first;
    final LatLng fairLocation =
        LatLng(displayFair.latitude, displayFair.longitude);
    final LatLng userLocation = hasLocation
        ? LatLng(currentLatitude!, currentLongitude!)
        : fairLocation;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          // ── Map background ──
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: fairLocation,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              // Circle layer for nearest fair radius
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: fairLocation,
                    radius: displayFair.radius,
                    useRadiusInMeter: true,
                    color: Colors.green.withValues(alpha: 0.2),
                    borderColor: Colors.green,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              // Markers
              MarkerLayer(
                markers: [
                  // Fair marker
                  Marker(
                    point: fairLocation,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on,
                          color: Colors.white, size: 24),
                    ),
                  ),
                  // User marker
                  if (hasLocation)
                    Marker(
                      point: userLocation,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_pin_circle,
                            color: Colors.white, size: 24),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Bottom overlay panel ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Address ──
                  Row(
                    children: [
                      const Icon(Icons.place, color: Color(0xFF2E7D32), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentAddress ?? 'Tap "Refresh Location" to start',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4A4A4A),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // ── Fair Info ──
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayFair.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E20),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Location: (${displayFair.latitude.toStringAsFixed(5)}, '
                              '${displayFair.longitude.toStringAsFixed(5)})',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              distanceToFair != null
                                  ? 'Distance: ${distanceToFair!.toStringAsFixed(0)} m'
                                  : 'Distance: —',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      // Points badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFD54F)),
                        ),
                        child: Text(
                          '${displayFair.points} pts',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF57F17),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Status indicator + Total Points ──
                  Row(
                    children: [
                      // Status chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isAtFair
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAtFair ? Icons.check_circle : Icons.cancel,
                              size: 16,
                              color: isAtFair ? Colors.green : Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isAtFair ? 'At Fair' : 'Not At Fair',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isAtFair
                                    ? const Color(0xFF2E7D32)
                                    : const Color(0xFFC62828),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Total points
                      Row(
                        children: [
                          const Icon(Icons.stars,
                              color: Color(0xFFFFA000), size: 20),
                          const SizedBox(width: 4),
                          Text(
                            'Total: $totalPoints pts',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A4A4A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Buttons ──
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _getLocation,
                            icon: const Icon(Icons.my_location, size: 18),
                            label: const Text('Refresh Location'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: isAtFair ? _joinFair : null,
                            icon: const Icon(Icons.event_available, size: 18),
                            label: const Text('Join Fair'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _viewHistory,
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('View Participation History'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: const BorderSide(color: Color(0xFF2E7D32)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
