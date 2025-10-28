import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../constants/colors.dart';

class NearbyMosquesPage extends StatefulWidget {
  const NearbyMosquesPage({Key? key}) : super(key: key);

  @override
  State<NearbyMosquesPage> createState() => _NearbyMosquesPageState();
}

class _NearbyMosquesPageState extends State<NearbyMosquesPage>
    with TickerProviderStateMixin {
  MapController? _mapController;
  late AnimationController _animationController;
  late AnimationController _bottomSheetController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  ScrollController _scrollController = ScrollController();
  Mosque? _hoveredMosque;

  LatLng _currentLocation = const LatLng(21.4225, 39.8262); // Makkah default
  Set<Marker> _markers = {};
  Mosque? _selectedMosque;
  bool _showBottomSheet = false;
  bool _isLoading = true;

  // Mock mosque data - in real app, this would come from API
  List<Mosque> _mosques = [];

  // Method to fetch nearby mosques from Overpass API
  Future<void> _fetchNearbyMosques() async {
    try {
      if (!mounted) return;

      // Create the Overpass query
      final query = '''
[out:json];
node["amenity"="place_of_worship"]["religion"="muslim"](around:10000,${_currentLocation.latitude}, ${_currentLocation.longitude});
out;
''';

      print(
        'Fetching mosques for location: ${_currentLocation.latitude}, ${_currentLocation.longitude}',
      );
      print('Query: $query');

      // Make the API request
      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: query,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List<dynamic>? ?? [];

        print('Found ${elements.length} mosques');
        print('Elements: $elements');
        if (mounted) {
          setState(() {
            _mosques =
                elements.map((element) {
                  return Mosque.fromOverpassElement(element, _currentLocation);
                }).toList();

            // Sort by distance
            _mosques.sort((a, b) => a.distance.compareTo(b.distance));
          });

          print('Created ${_mosques.length} mosque objects');
          print(
            'Mosques: ${_mosques.map((m) => '${m.name} at ${m.location.latitude}, ${m.location.longitude}').toList()}',
          );

          // Update markers
          _createMarkers();
        }
      } else {
        print('Failed to fetch mosques: ${response.statusCode}');
        // Fallback to default mosques if API fails
        _setDefaultMosques();
      }
    } catch (e) {
      print('Error fetching nearby mosques: $e');
      // Fallback to default mosques if API fails
      _setDefaultMosques();
    }
  }

  void _setDefaultMosques() {
    if (!mounted) return;

    setState(() {
      _mosques = [
        Mosque(
          id: '1',
          name: 'Masjid Al-Haram',
          address: 'Makkah Al Mukarramah, Saudi Arabia',
          location: const LatLng(21.4225, 39.8262),
          distance: 0.0,
        ),
        Mosque(
          id: '2',
          name: 'Masjid An-Nabawi',
          address: 'Medina, Saudi Arabia',
          location: const LatLng(24.4672, 39.6142),
          distance: 358.2,
        ),
        Mosque(
          id: '3',
          name: 'Al-Quba Mosque',
          address: 'Medina, Saudi Arabia',
          location: const LatLng(24.4370, 39.6184),
          distance: 362.1,
        ),
        Mosque(
          id: '4',
          name: 'Masjid Al-Qiblatayn',
          address: 'Medina, Saudi Arabia',
          location: const LatLng(24.4819, 39.5951),
          distance: 365.8,
        ),
        Mosque(
          id: '5',
          name: 'King Fahd Mosque',
          address: 'Jeddah, Saudi Arabia',
          location: const LatLng(21.5433, 39.1728),
          distance: 65.3,
        ),
      ];
    });
    _createMarkers();
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeAnimations();
    _getCurrentLocation();
    _createMarkers();
    _checkPlatform();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _bottomSheetController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _bottomSheetController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bottomSheetController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  void _checkPlatform() {
    // Google Maps is supported on web, so we don't need to show an error
    // Just set loading to false to allow the map to initialize
    if (kIsWeb) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      if (kIsWeb) {
        // For web, try to get location using browser's geolocation API
        await _getWebLocation();
      } else {
        // For mobile, use geolocator package
        await _getMobileLocation();
      }

      // After getting location, fetch nearby mosques
      await _fetchNearbyMosques();
    } catch (e) {
      print('Error getting location: $e');
      // Fallback to default location
      if (mounted) {
        setState(() {
          _currentLocation = const LatLng(21.4225, 39.8262); // Makkah default
          _isLoading = false;
        });
        _updateDistances();
        _createMarkers();
        // Fetch mosques for default location
        _fetchNearbyMosques();
      }
    }
  }

  Future<void> _getMobileLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        if (mounted) {
          _showLocationServiceDisabledDialog();
        }
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permission denied
          if (mounted) {
            _showPermissionDeniedDialog();
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permission denied forever
        if (mounted) {
          _showPermissionDeniedForeverDialog();
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });

        _updateDistances();
        _createMarkers();

        // Move map to current location
        if (_mapController != null) {
          _mapController!.move(_currentLocation, 14.0);
        }
      }
    } catch (e) {
      print('Error getting mobile location: $e');
      // Check if widget is still mounted before calling setState
      if (mounted) {
        // Fallback to default location
        setState(() {
          _currentLocation = const LatLng(21.4225, 39.8262); // Makkah default
          _isLoading = false;
        });
        _updateDistances();
        _createMarkers();
      }
    }
  }

  Future<void> _getWebLocation() async {
    // For web, use geolocator package to get real location
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled
        if (mounted) {
          _showLocationServiceDisabledDialog();
        }
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Permission denied
          if (mounted) {
            _showPermissionDeniedDialog();
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permission denied forever
        if (mounted) {
          _showPermissionDeniedForeverDialog();
        }
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Check if widget is still mounted before calling setState
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });

        _updateDistances();
        _createMarkers();

        // Move map to current location
        if (_mapController != null) {
          _mapController!.move(_currentLocation, 14.0);
        }
      }
    } catch (e) {
      print('Error getting web location: $e');
      // Check if widget is still mounted before calling setState
      if (mounted) {
        // Fallback to default location
        setState(() {
          _currentLocation = const LatLng(21.4225, 39.8262); // Makkah default
          _isLoading = false;
        });
        _updateDistances();
        _createMarkers();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not get your location. Using default location.',
            ),
            duration: Duration(seconds: 3),
            backgroundColor: AppColors.islamicGreen600,
          ),
        );
      }
    }
  }

  void _showLocationServiceDisabledDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Location Services Disabled'),
          content: const Text(
            'Location services are disabled on your device. Please enable them in your device settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Denied'),
          content: const Text(
            'Location permission was denied. Please enable it in your device settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDeniedForeverDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Denied Forever'),
          content: const Text(
            'Location permission was denied forever. Please enable it in your device settings.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _updateDistances() {
    for (var mosque in _mosques) {
      // Calculate distance using Haversine formula
      double distance = _calculateDistance(
        _currentLocation.latitude,
        _currentLocation.longitude,
        mosque.location.latitude,
        mosque.location.longitude,
      );
      mosque.distance = distance;
    }

    // Sort mosques by distance
    _mosques.sort((a, b) => a.distance.compareTo(b.distance));
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  void _createMarkers() {
    if (!mounted) return;

    print('Creating markers for ${_mosques.length} mosques');

    _markers.clear();

    // Add current location marker
    _markers.add(
      Marker(
        point: _currentLocation,
        width: 80,
        height: 80,
        child: Icon(
          Icons.my_location,
          color: AppColors.islamicGreen600,
          size: 40,
        ),
      ),
    );

    print(
      'Added current location marker at ${_currentLocation.latitude}, ${_currentLocation.longitude}',
    );

    // Add mosque markers
    for (var mosque in _mosques) {
      print(
        'Adding marker for mosque: ${mosque.name} at ${mosque.location.latitude}, ${mosque.location.longitude}',
      );
      _markers.add(
        Marker(
          point: mosque.location,
          width: 80,
          height: 80,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoveredMosque = mosque),
            onExit: (_) => setState(() => _hoveredMosque = null),
            child: GestureDetector(
              onTap: () => _onMosqueMarkerTapped(mosque),
              child: Icon(
                Icons.location_on,
                color:
                    _hoveredMosque?.id == mosque.id
                        ? AppColors.islamicGreen600
                        : AppColors.islamicGreen500,
                size: _hoveredMosque?.id == mosque.id ? 45 : 40,
              ),
            ),
          ),
        ),
      );
    }

    print('Total markers created: ${_markers.length}');

    if (mounted) {
      setState(() {});
      print('setState called to update markers');
    }
  }

  void _onMosqueMarkerTapped(Mosque mosque) {
    if (!mounted) return;

    setState(() {
      _showBottomSheet = true;
    });
    _bottomSheetController.forward();

    // Scroll to the selected mosque in the list
    _scrollToMosque(mosque);
  }

  void _scrollToMosque(Mosque mosque) {
    final index = _mosques.indexWhere((m) => m.id == mosque.id);
    if (index != -1 && _scrollController.hasClients) {
      _scrollController.animateTo(
        index * 120.0, // Approximate height of each mosque card
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _hideBottomSheet() {
    _bottomSheetController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showBottomSheet = false;
        });
      }
    });
  }

  void _recenterMap() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    await _getCurrentLocation();

    // Check if still mounted before updating UI
    if (mounted) {
      // Move map to current location with animation
      if (_mapController != null) {
        _mapController!.move(_currentLocation, 14.0);
      }

      // Fetch nearby mosques for the new location
      await _fetchNearbyMosques();

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _openDirections(Mosque mosque) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${mosque.location.latitude},${mosque.location.longitude}&travelmode=driving';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bottomSheetController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.islamicCream,
      /*   appBar: AppBar(
        title: const Text(
          'Nearby Mosques',
          style: TextStyle(fontWeight: FontWeight.bold, color: islamicWhite),
        ),
        backgroundColor: AppColors.islamicGreen600,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: islamicWhite),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: islamicWhite),
            onPressed: () {
              print('Manual refresh triggered');
              _fetchNearbyMosques();
            },
            tooltip: 'Refresh Mosques',
          ),
        ],
      ), */
      body: Stack(
        children: [
          // Google Map
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _animationController.value,
                child:
                    _isLoading
                        ? _buildLoadingIndicator()
                        : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _currentLocation,
                            initialZoom: 14.0,
                            onMapReady: () {
                              print('Map is ready');
                              print(
                                'Current markers count: ${_markers.length}',
                              );
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              tileProvider: CancellableNetworkTileProvider(),
                            ),
                            MarkerLayer(markers: _markers.toList()),
                          ],
                        ),
              );
            },
          ),

          // GPS Re-center Button
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                // Debug info
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: AppColors.islamicWhite.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Mosques: ${_mosques.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.islamicGreen700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Lat: ${_currentLocation.latitude.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.islamicGreen600,
                        ),
                      ),
                      Text(
                        'Lon: ${_currentLocation.longitude.toStringAsFixed(4)}',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.islamicGreen600,
                        ),
                      ),
                    ],
                  ),
                ),
                // GPS button
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _animationController.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.islamicWhite,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(25),
                            onTap: _recenterMap,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                              ),

                              child: Icon(
                                Icons.my_location,
                                color: AppColors.islamicGreen600,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // Hover Tooltip
          if (_hoveredMosque != null)
            Positioned(
              left: 16,
              top: 100,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.islamicWhite,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _hoveredMosque!.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.islamicGreen800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_hoveredMosque!.distance.toStringAsFixed(1)} km away',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.islamicGreen600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Bottom Sheet
          if (_showBottomSheet)
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    MediaQuery.of(context).size.height *
                        0.4 *
                        _slideAnimation.value,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      decoration: const BoxDecoration(
                        color: AppColors.islamicWhite,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 20,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      child: _buildBottomSheetContent(),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      /* floatingActionButton: FloatingActionButton(
        onPressed: _recenterMap,
        backgroundColor: AppColors.islamicGreen600,
        child: Icon(Icons.my_location, color: islamicWhite),
        tooltip: 'Get Current Location',
      ), */
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      color: AppColors.islamicCream,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.islamicGreen500,
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Text('🕌', style: TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.islamicGreen500,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Finding nearby mosques...',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.islamicGreen700,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current Location: ${_currentLocation.latitude.toStringAsFixed(4)}, ${_currentLocation.longitude.toStringAsFixed(4)}',
              style: TextStyle(fontSize: 12, color: AppColors.islamicGreen600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetContent() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.islamicGreen200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header with close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.islamicGreen500,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '🕌',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Nearby Mosques',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.islamicGreen800,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _hideBottomSheet,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.islamicGreen50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.close,
                          color: AppColors.islamicGreen600,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Mosque List
              Expanded(
                child:
                    _mosques.isEmpty
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.islamicGreen500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Finding nearby mosques...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.islamicGreen700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _mosques.length,
                          itemBuilder: (context, index) {
                            final mosque = _mosques[index];
                            return _buildMosqueCard(mosque);
                          },
                        ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMosqueCard(Mosque mosque) {
    print("building mosque card for ${mosque.name}");
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.islamicWhite,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mosque Name
            Row(
              children: [
                Expanded(
                  child: Text(
                    mosque.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.islamicGreen800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.islamicGreen50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${mosque.distance.toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.islamicGreen700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Arabic name if available
            if (mosque.nameAr != null && mosque.nameAr != mosque.name)
              Text(
                mosque.nameAr!,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.islamicGreen600,
                  fontStyle: FontStyle.italic,
                ),
              ),

            const SizedBox(height: 8),

            // Address
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: AppColors.islamicGreen500,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mosque.address,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.islamicGreen600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Get Directions Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openDirections(mosque),
                icon: const Icon(Icons.directions, size: 20),
                label: const Text(
                  'Get Directions',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.islamicGreen600,
                  foregroundColor: AppColors.islamicWhite,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Mosque {
  final String id;
  final String name;
  final String? nameAr;
  final String? nameEn;
  final String address;
  final LatLng location;
  double distance;
  final String? religion;
  final String? amenity;

  Mosque({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    required this.address,
    required this.location,
    required this.distance,
    this.religion,
    this.amenity,
  });

  factory Mosque.fromOverpassElement(
    Map<String, dynamic> element,
    LatLng currentLocation,
  ) {
    final tags = element['tags'] as Map<String, dynamic>? ?? {};
    final lat = element['lat'] as double;
    final lon = element['lon'] as double;

    // Calculate distance from current location
    final mosqueLocation = LatLng(lat, lon);
    final distance = _calculateDistanceFromLatLng(
      currentLocation,
      mosqueLocation,
    );

    // Get the best available name
    String name =
        tags['name:en'] ?? tags['name:ar'] ?? tags['name'] ?? 'Unnamed Mosque';

    // Create a simple address from coordinates
    String address = '${lat.toStringAsFixed(6)}, ${lon.toStringAsFixed(6)}';

    return Mosque(
      id: element['id'].toString(),
      name: name,
      nameAr: tags['name:ar'],
      nameEn: tags['name:en'],
      address: address,
      location: mosqueLocation,
      distance: distance,
      religion: tags['religion'],
      amenity: tags['amenity'],
    );
  }

  static double _calculateDistanceFromLatLng(LatLng from, LatLng to) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _degreesToRadians(to.latitude - from.latitude);
    double dLon = _degreesToRadians(to.longitude - from.longitude);

    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(from.latitude)) *
            math.cos(_degreesToRadians(to.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}
