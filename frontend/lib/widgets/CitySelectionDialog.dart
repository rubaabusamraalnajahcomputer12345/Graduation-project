import 'dart:convert';
import 'package:frontend/providers/UserProvider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';

class CitySelectionDialog extends StatefulWidget {
  final String country;
  final Function(String) onCitySelected;

  const CitySelectionDialog({
    Key? key,
    required this.country,
    required this.onCitySelected,
  }) : super(key: key);

  @override
  State<CitySelectionDialog> createState() => _CitySelectionDialogState();
}

class _CitySelectionDialogState extends State<CitySelectionDialog> {
  String? selectedCity;
  final TextEditingController _searchController = TextEditingController();
  List<String> filteredCities = [];
  List<String> allCities = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCities();
    _searchController.addListener(() {
      _filterCities(_searchController.text);
    });
  }

  Future<void> _fetchCities() async {
    setState(() {
      isLoading = true;
    });
    final response = await http.post(
      Uri.parse('https://countriesnow.space/api/v0.1/countries/cities'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "country": Provider.of<UserProvider>(context, listen: false).country,
      }),
    );
    print(
      "body of request : ${Provider.of<UserProvider>(context, listen: false).country}",
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final cities = List<String>.from(data['data'] ?? []);
      setState(() {
        allCities = cities;
        filteredCities = cities;
        isLoading = false;
      });
    } else {
      setState(() {
        allCities = [];
        filteredCities = [];
        isLoading = false;
      });
    }
  }

  void _filterCities(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredCities = allCities;
      });
    } else {
      setState(() {
        filteredCities =
            allCities
                .where(
                  (city) => city.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.islamicGreen500,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.location_city,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Your City',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.islamicGreen800,
                        ),
                      ),
                      Text(
                        'Choose the nearest city in ${widget.country}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.islamicGreen600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.islamicGreen600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Search bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.islamicGreen50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.islamicGreen200),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for a city...',
                  hintStyle: TextStyle(color: AppColors.islamicGreen400),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppColors.islamicGreen500,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Cities list
            Expanded(
              child:
                  isLoading
                      ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.islamicGreen500,
                        ),
                      )
                      : allCities.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 64,
                              color: AppColors.islamicGreen300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No cities found for ${widget.country}',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.islamicGreen600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Please contact support to add cities for your country',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.islamicGreen400,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: filteredCities.length,
                        itemBuilder: (context, index) {
                          final city = filteredCities[index];
                          final isSelected = selectedCity == city;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    selectedCity = city;
                                  });
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? AppColors.islamicGreen100
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? AppColors.islamicGreen500
                                              : AppColors.islamicGreen200,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color:
                                            isSelected
                                                ? AppColors.islamicGreen600
                                                : AppColors.islamicGreen400,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          city,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight:
                                                isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.w500,
                                            color:
                                                isSelected
                                                    ? AppColors.islamicGreen800
                                                    : AppColors.islamicGreen700,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: AppColors.islamicGreen600,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            ),

            const SizedBox(height: 20),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    selectedCity != null
                        ? () {
                          widget.onCitySelected(selectedCity!);
                          Navigator.of(context).pop();
                        }
                        : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.islamicGreen500,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'Confirm City Selection',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
