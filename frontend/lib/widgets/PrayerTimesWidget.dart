import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/UserProvider.dart';
import 'CitySelectionDialog.dart';
import '../constants/colors.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class PrayerTimesWidget extends StatefulWidget {
  const PrayerTimesWidget({Key? key}) : super(key: key);

  @override
  State<PrayerTimesWidget> createState() => _PrayerTimesWidgetState();
}

class _PrayerTimesWidgetState extends State<PrayerTimesWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _dropAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _dropScaleAnimation;
  late Animation<double> _dropOpacityAnimation;
  late Animation<Offset> _dropOffsetAnimation;
  late Animation<double> _dropShapeAnimation;

  bool _isDropExpanding = false;

  // Prayer times data (placeholder static values)
  List<PrayerTime> prayerTimes = [];
  String hijriDate = '';
  String gregorianDate = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _dropAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Water drop animations
    _dropScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _dropAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _dropOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dropAnimationController, curve: Curves.easeIn),
    );

    _dropOffsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.0),
      end: const Offset(0.0, -0.3),
    ).animate(
      CurvedAnimation(
        parent: _dropAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _dropShapeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _dropAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start a subtle pulsing animation
    _startPulseAnimation();
    _fetchPrayerTimes();
  }

  Future<void> _fetchPrayerTimes() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final fallbackCity = userProvider.city ?? 'Riyadh';
    final fallbackCountry = userProvider.country ?? 'Saudi Arabia';

    try {
      // Step 1: check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Location services are disabled.");
      }

      // Step 2: request permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Step 3: if permanently denied → fallback to city/country
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        print("Location permissions are denied. Falling back to city.");
        await _fetchPrayerTimesByCity(fallbackCity, fallbackCountry);
        return;
      }

      // Step 4: get position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Step 5: call API with lat/lon
      final url =
          'https://api.aladhan.com/v1/timings?latitude=${position.latitude}&longitude=${position.longitude}&method=2';

      final response = await http.get(Uri.parse(url));
      print("Fetching prayer times from: $url");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final timings = data['data']['timings'];
        final hijri = data['data']['date']['hijri']['date'];
        final gregorian = data['data']['date']['gregorian']['date'];

        if (!mounted) return;
        setState(() {
          prayerTimes = [
            PrayerTime(name: 'Fajr', time: timings['Fajr'], arabic: 'الفجر'),
            PrayerTime(name: 'Dhuhr', time: timings['Dhuhr'], arabic: 'الظهر'),
            PrayerTime(name: 'Asr', time: timings['Asr'], arabic: 'العصر'),
            PrayerTime(
              name: 'Maghrib',
              time: timings['Maghrib'],
              arabic: 'المغرب',
            ),
            PrayerTime(name: 'Isha', time: timings['Isha'], arabic: 'العشاء'),
          ];
          hijriDate = hijri;
          gregorianDate = gregorian;
        });
      } else {
        throw Exception("Failed to fetch prayer times by location");
      }
    } catch (e) {
      // Any error (like GPS off, API error) → fallback
      print("Error fetching prayer times by location: $e");
      await _fetchPrayerTimesByCity(fallbackCity, fallbackCountry);
    }
  }

  Future<void> _fetchPrayerTimesByCity(String city, String country) async {
    final url =
        'https://api.aladhan.com/v1/timingsByCity?city=${Uri.encodeComponent(city)}&country=${Uri.encodeComponent(country)}&method=2';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final timings = data['data']['timings'];
        final hijri = data['data']['date']['hijri']['date'];
        final gregorian = data['data']['date']['gregorian']['date'];

        if (!mounted) return;
        setState(() {
          prayerTimes = [
            PrayerTime(name: 'Fajr', time: timings['Fajr'], arabic: 'الفجر'),
            PrayerTime(name: 'Dhuhr', time: timings['Dhuhr'], arabic: 'الظهر'),
            PrayerTime(name: 'Asr', time: timings['Asr'], arabic: 'العصر'),
            PrayerTime(
              name: 'Maghrib',
              time: timings['Maghrib'],
              arabic: 'المغرب',
            ),
            PrayerTime(name: 'Isha', time: timings['Isha'], arabic: 'العشاء'),
          ];
          hijriDate = hijri;
          gregorianDate = gregorian;
        });
      } else {
        throw Exception("Failed to fetch prayer times by city");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        // Last fallback → static times
        prayerTimes = [
          PrayerTime(name: 'Fajr', time: '05:12 AM', arabic: 'الفجر'),
          PrayerTime(name: 'Dhuhr', time: '12:45 PM', arabic: 'الظهر'),
          PrayerTime(name: 'Asr', time: '04:23 PM', arabic: 'العصر'),
          PrayerTime(name: 'Maghrib', time: '07:18 PM', arabic: 'المغرب'),
          PrayerTime(name: 'Isha', time: '08:45 PM', arabic: 'العشاء'),
        ];
        hijriDate = '';
        gregorianDate = '';
      });
    }
  }

  void _startPulseAnimation() {
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _dropAnimationController.dispose();
    super.dispose();
  }

  void _showPrayerTimesModal() {
    // Check if user has a city set
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (userProvider.city == null || userProvider.city!.isEmpty) {
      // User doesn't have a city, show city selection dialog
      if (userProvider.country != null && userProvider.country!.isNotEmpty) {
        _showCitySelectionDialog();
      } else {
        // User doesn't have a country either, show error
        _showCountryMissingDialog();
      }
      return;
    }

    // User has a city, proceed with prayer times modal
    // Stop the pulse animation when modal opens
    _animationController.stop();
    _animationController.reset();

    if (!mounted) return;
    setState(() {
      _isDropExpanding = true;
    });

    // Start the water drop animation
    _dropAnimationController.forward().then((_) {
      if (!mounted) return;
      // Show the modal after the drop animation completes
      _showModal();
    });
  }

  void _showCitySelectionDialog() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => CitySelectionDialog(
            country: userProvider.country!,
            onCitySelected: (String city) async {
              // Update the user's city in the backend
              await userProvider.updateUserCity(context, city);
              print("City updated to: ${userProvider.city}");
              // Now show the prayer times modal
              _showPrayerTimesModal();
            },
          ),
    );
  }

  void _showCountryMissingDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.location_off,
                  color: AppColors.islamicGreen600,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Location Required',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              'To provide accurate prayer times, we need to know your location. '
              'Please update your profile with your country and city information.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPrayerTimesModal(),
    ).then((_) {
      if (!mounted) return;
      // Reset drop animation when modal closes
      _dropAnimationController.reset();
      setState(() {
        _isDropExpanding = false;
      });
      // Resume pulse animation when modal closes
      _startPulseAnimation();
    });
  }

  Widget _buildWaterDrop() {
    if (!_isDropExpanding) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _dropAnimationController,
      builder: (context, child) {
        return SlideTransition(
          position: _dropOffsetAnimation,
          child: FadeTransition(
            opacity: _dropOpacityAnimation,
            child: ScaleTransition(
              scale: _dropScaleAnimation,
              child: Container(
                width: 200 * _dropScaleAnimation.value,
                height: 200 * _dropScaleAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.islamicGreen600.withOpacity(
                        0.8 * _dropOpacityAnimation.value,
                      ),
                      AppColors.islamicGreen400.withOpacity(
                        0.6 * _dropOpacityAnimation.value,
                      ),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.islamicGreen600.withOpacity(
                        0.3 * _dropOpacityAnimation.value,
                      ),
                      blurRadius: 20 * _dropScaleAnimation.value,
                      spreadRadius: 5 * _dropScaleAnimation.value,
                    ),
                  ],
                ),
                child: CustomPaint(
                  painter: MosquePainter(
                    progress: _dropShapeAnimation.value,
                    color: AppColors.islamicGreen600.withOpacity(
                      0.9 * _dropOpacityAnimation.value,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationRow(
    String city,
    String country, {
    bool isFallback = false,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFallback ? Icons.location_off : Icons.location_on_outlined,
              color:
                  isFallback
                      ? AppColors.islamicGreen400
                      : AppColors.islamicGreen500,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              '$city, $country',
              style: TextStyle(
                fontSize: 14,
                color:
                    isFallback
                        ? AppColors.islamicGreen400
                        : AppColors.islamicGreen600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (isFallback) ...[
          const SizedBox(height: 4),
          Text(
            'Using saved location',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.islamicGreen400,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrayerTimesModal() {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 600 || screenWidth < 400;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
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
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: isSmallScreen ? screenHeight * 0.8 : screenHeight * 0.6,
          minHeight: 400,
        ),
        child: Column(
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.adminGreen100, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.prayerGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                '🕌',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Prayer Times',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.islamicGreen800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hijriDate.isNotEmpty && gregorianDate.isNotEmpty
                              ? 'Today • $gregorianDate • Hijri: $hijriDate'
                              : 'Today • ${_getCurrentDate()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.islamicGreen600,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.islamicGreen50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.islamicGreen600,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Prayer times list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: prayerTimes.length,
                itemBuilder: (context, index) {
                  final prayer = prayerTimes[index];
                  final isCurrentPrayer = _isCurrentPrayer(prayer);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300 + (index * 100)),
                      curve: Curves.easeOutBack,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isCurrentPrayer
                                  ? AppColors.islamicGreen50
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                isCurrentPrayer
                                    ? AppColors.islamicGreen200
                                    : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Prayer icon and name
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color:
                                          isCurrentPrayer
                                              ? AppColors.islamicGreen500
                                              : AppColors.islamicGreen100,
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Icon(
                                      _getPrayerIcon(prayer.name),
                                      color:
                                          isCurrentPrayer
                                              ? AppColors.islamicWhite
                                              : AppColors.islamicGreen600,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          prayer.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                                isCurrentPrayer
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                            color:
                                                isCurrentPrayer
                                                    ? AppColors.islamicGreen800
                                                    : AppColors.islamicGreen700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          prayer.arabic,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.islamicGreen500,
                                            fontFamily: 'Arabic',
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Prayer time
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isCurrentPrayer
                                        ? AppColors.islamicGreen500
                                        : AppColors.islamicGreen50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                prayer.time,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isCurrentPrayer
                                          ? AppColors.islamicWhite
                                          : AppColors.islamicGreen700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer with location info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.islamicGreen100, width: 1),
                ),
              ),
              child: FutureBuilder<Position?>(
                future: _getCurrentLocation(),
                builder: (context, snapshot) {
                  final userProvider = Provider.of<UserProvider>(
                    context,
                    listen: false,
                  );

                  // Default fallback values
                  String city = userProvider.city ?? 'Unknown City';
                  String country = userProvider.country ?? 'Unknown Country';
                  bool isUsingFallback =
                      true; // Track if we're using fallback data

                  if (snapshot.hasData && snapshot.data != null) {
                    final position = snapshot.data!;

                    return FutureBuilder<List<Placemark>>(
                      future: _getPlacemarkFromCoordinates(position),
                      builder: (context, placeSnapshot) {
                        if (placeSnapshot.hasData &&
                            placeSnapshot.data != null &&
                            placeSnapshot.data!.isNotEmpty) {
                          final place = placeSnapshot.data!.first;

                          // Try to get city name from multiple sources
                          String? detectedCity =
                              place.locality ??
                              place.subLocality ??
                              place.administrativeArea;

                          // Try to get country name
                          String? detectedCountry = place.country;

                          // Only update if we got valid data
                          if (detectedCity != null && detectedCity.isNotEmpty) {
                            city = detectedCity;
                            isUsingFallback = false; // We got real GPS data
                          }
                          if (detectedCountry != null &&
                              detectedCountry.isNotEmpty) {
                            country = detectedCountry;
                            isUsingFallback = false; // We got real GPS data
                          }

                          print(
                            "Detected location - City: $city, Country: $country, Using Fallback: $isUsingFallback",
                          );
                        }

                        return _buildLocationRow(
                          city,
                          country,
                          isFallback: isUsingFallback,
                        );
                      },
                    );
                  }

                  return _buildLocationRow(
                    city,
                    country,
                    isFallback: isUsingFallback,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName.toLowerCase()) {
      case 'fajr':
        return Icons.wb_twilight;
      case 'dhuhr':
        return Icons.wb_sunny;
      case 'asr':
        return Icons.wb_sunny_outlined;
      case 'maghrib':
        return Icons.wb_twilight;
      case 'isha':
        return Icons.nights_stay;
      default:
        return Icons.access_time;
    }
  }

  bool _isCurrentPrayer(PrayerTime prayer) {
    // For demo purposes, highlight Dhuhr as current prayer
    return prayer.name == 'Dhuhr';
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
    } catch (e) {
      print("Error getting current location: $e");
      return null;
    }
  }

  Future<List<Placemark>> _getPlacemarkFromCoordinates(
    Position position,
  ) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // Filter out null placemarks and validate data
      final validPlacemarks =
          placemarks.where((placemark) {
            return placemark != null &&
                (placemark.locality != null ||
                    placemark.subLocality != null ||
                    placemark.country != null);
          }).toList();

      print("Found ${validPlacemarks.length} valid placemarks");
      if (validPlacemarks.isNotEmpty) {
        final firstPlace = validPlacemarks.first;
        print(
          "First placemark - Locality: ${firstPlace.locality}, SubLocality: ${firstPlace.subLocality}, Country: ${firstPlace.country}",
        );
      }

      // If no valid placemarks found, try with a more lenient approach
      if (validPlacemarks.isEmpty && placemarks.isNotEmpty) {
        print("No valid placemarks found, trying more lenient approach...");
        // Accept any placemark that exists (even if fields are null)
        final lenientPlacemarks =
            placemarks.where((placemark) {
              return placemark != null;
            }).toList();

        print("Lenient approach found ${lenientPlacemarks.length} placemarks");
        if (lenientPlacemarks.isNotEmpty) {
          final firstPlace = lenientPlacemarks.first;
          print(
            "Lenient placemark - Locality: ${firstPlace.locality}, SubLocality: ${firstPlace.subLocality}, Country: ${firstPlace.country}",
          );
        }

        return lenientPlacemarks;
      }

      return validPlacemarks;
    } catch (e) {
      print("Error getting placemark: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Stack(
        children: [
          // Water drop animation
          _buildWaterDrop(),

          // Main icon
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: GestureDetector(
                    onTap: _showPrayerTimesModal,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.islamicGreen500,
                            AppColors.islamicGreen600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.islamicGreen500.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: AppColors.islamicGreen600.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.mosque,
                          size: 28,
                          color: AppColors.islamicWhite,
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
    );
  }
}

// Custom painter for mosque with minaret
class MosquePainter extends CustomPainter {
  final double progress;
  final Color color;

  MosquePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final baseSize = (size.width / 2) * progress;

    // Draw the mosque base (main building)
    final mosquePath = Path();
    final mosqueWidth = baseSize * 1.6;
    final mosqueHeight = baseSize * 0.8;

    // Main building rectangle with rounded top
    mosquePath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY + baseSize * 0.3),
          width: mosqueWidth,
          height: mosqueHeight,
        ),
        Radius.circular(baseSize * 0.1),
      ),
    );

    // Dome on top of the mosque
    final domePath = Path();
    final domeRadius = mosqueWidth * 0.3;
    domePath.addOval(
      Rect.fromCenter(
        center: Offset(centerX, centerY + baseSize * 0.3 - mosqueHeight / 2),
        width: domeRadius * 2,
        height: domeRadius,
      ),
    );

    // Draw mosque base
    canvas.drawPath(mosquePath, paint);
    canvas.drawPath(domePath, paint);

    // Draw the minaret (tower)
    if (progress > 0.3) {
      final minaretPath = Path();
      final minaretWidth = baseSize * 0.15;
      final minaretHeight = baseSize * 1.2;

      // Minaret base
      minaretPath.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              centerX + mosqueWidth * 0.35,
              centerY - baseSize * 0.2,
            ),
            width: minaretWidth,
            height: minaretHeight,
          ),
          Radius.circular(minaretWidth * 0.3),
        ),
      );

      // Minaret top (cone)
      final minaretTopPath = Path();
      final topRadius = minaretWidth * 0.8;
      minaretTopPath.moveTo(
        centerX + mosqueWidth * 0.35,
        centerY - baseSize * 0.2 - minaretHeight / 2,
      );
      minaretTopPath.lineTo(
        centerX + mosqueWidth * 0.35 - topRadius,
        centerY - baseSize * 0.2 - minaretHeight / 2 - baseSize * 0.3,
      );
      minaretTopPath.lineTo(
        centerX + mosqueWidth * 0.35 + topRadius,
        centerY - baseSize * 0.2 - minaretHeight / 2 - baseSize * 0.3,
      );
      minaretTopPath.close();

      // Draw minaret
      canvas.drawPath(minaretPath, paint);
      canvas.drawPath(minaretTopPath, paint);

      // Crescent on top of minaret
      if (progress > 0.7) {
        final crescentPaint =
            Paint()
              ..color = color.withOpacity(0.9)
              ..style = PaintingStyle.fill;

        final crescentPath = Path();
        final crescentRadius = minaretWidth * 0.4;
        final crescentCenter = Offset(
          centerX + mosqueWidth * 0.35,
          centerY -
              baseSize * 0.2 -
              minaretHeight / 2 -
              baseSize * 0.3 -
              crescentRadius * 0.3,
        );

        // Draw crescent using two circles
        crescentPath.addOval(
          Rect.fromCenter(
            center: Offset(
              crescentCenter.dx - crescentRadius * 0.3,
              crescentCenter.dy,
            ),
            width: crescentRadius * 2,
            height: crescentRadius * 2,
          ),
        );

        crescentPath.addOval(
          Rect.fromCenter(
            center: Offset(
              crescentCenter.dx + crescentRadius * 0.3,
              crescentCenter.dy,
            ),
            width: crescentRadius * 2,
            height: crescentRadius * 2,
          ),
        );

        // Use difference to create crescent shape
        final crescentClipPath =
            Path()..addOval(
              Rect.fromCenter(
                center: Offset(
                  crescentCenter.dx + crescentRadius * 0.3,
                  crescentCenter.dy,
                ),
                width: crescentRadius * 2,
                height: crescentRadius * 2,
              ),
            );

        canvas.drawPath(crescentPath, Paint()..color = Colors.transparent);
        canvas.drawPath(crescentClipPath, Paint()..color = Colors.transparent);

        // Draw the actual crescent
        final finalCrescentPath =
            Path()..addOval(
              Rect.fromCenter(
                center: Offset(
                  crescentCenter.dx - crescentRadius * 0.3,
                  crescentCenter.dy,
                ),
                width: crescentRadius * 2,
                height: crescentRadius * 2,
              ),
            );

        canvas.drawPath(finalCrescentPath, crescentPaint);
      }
    }

    // Draw entrance arch
    if (progress > 0.5) {
      final entrancePaint =
          Paint()
            ..color = color.withOpacity(0.7)
            ..style = PaintingStyle.fill;

      final entrancePath = Path();
      final entranceWidth = mosqueWidth * 0.3;
      final entranceHeight = mosqueHeight * 0.6;

      // Arch entrance
      entrancePath.addArc(
        Rect.fromCenter(
          center: Offset(
            centerX,
            centerY + baseSize * 0.3 + mosqueHeight / 2 - entranceHeight,
          ),
          width: entranceWidth,
          height: entranceHeight * 2,
        ),
        0,
        3.14159, // π radians
      );

      canvas.drawPath(entrancePath, entrancePaint);
    }

    // Draw windows
    if (progress > 0.6) {
      final windowPaint =
          Paint()
            ..color = color.withOpacity(0.6)
            ..style = PaintingStyle.fill;

      // Left window
      final leftWindowPath = Path();
      leftWindowPath.addOval(
        Rect.fromCenter(
          center: Offset(
            centerX - mosqueWidth * 0.25,
            centerY + baseSize * 0.3,
          ),
          width: baseSize * 0.2,
          height: baseSize * 0.2,
        ),
      );

      // Right window
      final rightWindowPath = Path();
      rightWindowPath.addOval(
        Rect.fromCenter(
          center: Offset(
            centerX + mosqueWidth * 0.25,
            centerY + baseSize * 0.3,
          ),
          width: baseSize * 0.2,
          height: baseSize * 0.2,
        ),
      );

      canvas.drawPath(leftWindowPath, windowPaint);
      canvas.drawPath(rightWindowPath, windowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PrayerTime {
  final String name;
  final String time;
  final String arabic;

  PrayerTime({required this.name, required this.time, required this.arabic});
}

// Usage example widget showing how to integrate the prayer times widget
class HidayaAppWithPrayerTimes extends StatelessWidget {
  const HidayaAppWithPrayerTimes({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hidaya'),
        backgroundColor: AppColors.prayerGreen, // AppColors.islamicGreen500
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Your main app content goes here
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF4FBF7), // AppColors.islamicGreen50
                  Color(0xFFFDF8F0), // AppColors.islamicCream
                  Color(0xFFFEF9E6), // AppColors.islamicGold50
                ],
              ),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hidaya App',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF142E1C),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'هداية - Guidance in Faith',
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF235831),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Prayer times widget overlay
          const PrayerTimesWidget(),
        ],
      ),
    );
  }
}
