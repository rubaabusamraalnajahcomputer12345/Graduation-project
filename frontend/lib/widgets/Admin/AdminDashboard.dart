import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:frontend/config.dart';
import 'package:frontend/constants/colors.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Add these dependencies to pubspec.yaml:
// dependencies:
//   fl_chart: ^0.68.0
//   intl: ^0.19.0

// Islamic Theme Colors
class IslamicColors {}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<Map<String, dynamic>> userGrowthData = [];
  bool isLoadingUserGrowth = true;
  String? userGrowthError;

  List<Map<String, dynamic>> genderData = [];
  bool isLoadingGenderData = true;
  String? genderDataError;

  Map<String, dynamic> dashboardStats = {};
  bool isLoadingDashboardStats = true;
  String? dashboardStatsError;

  List<Map<String, dynamic>> questionCategoriesData = [];
  bool isLoadingQuestionCategories = true;
  String? questionCategoriesError;

  Map<String, dynamic> todayActivity = {};
  bool isLoadingTodayActivity = true;
  String? todayActivityError;

  Map<String, dynamic> topContent = {};
  bool isLoadingTopContent = true;
  String? topContentError;

  @override
  void initState() {
    super.initState();
    fetchUserGrowthData();
    fetchGenderData();
    fetchDashboardStats();
    fetchQuestionCategories();
    fetchTodayActivity();
    fetchTopContent();
  }

  Future<void> fetchUserGrowthData() async {
    try {
      final uri = Uri.parse(userGrowth);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            userGrowthData =
                data
                    .map<Map<String, dynamic>>(
                      (e) => {'month': e['month'], 'users': e['users']},
                    )
                    .toList();
            isLoadingUserGrowth = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            userGrowthError = 'Failed to load data: ${response.statusCode}';
            isLoadingUserGrowth = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          userGrowthError = e.toString();
          isLoadingUserGrowth = false;
        });
      }
    }
  }

  Future<void> fetchGenderData() async {
    try {
      final uri = Uri.parse(gender);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            int female = data['female'] ?? 0;
            int male = data['male'] ?? 0;
            int other = data['other'] ?? 0;
            int total = female + male + other;
            int femalePercent =
                total > 0 ? ((female / total) * 100).round() : 0;

            genderData = [
              {"name": "Female", "value": femalePercent, "color": 0xFF059669},
              {
                "name": "Male",
                "value": total > 0 ? ((male / total) * 100).round() : 0,
                "color": 0xFF0891b2,
              },
              {
                "name": "Other",
                "value": total > 0 ? ((other / total) * 100).round() : 0,
                "color": 0xFF7c3aed,
              },
            ];
            isLoadingGenderData = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            genderDataError =
                'Failed to load gender data: ${response.statusCode}';
            isLoadingGenderData = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          genderDataError = e.toString();
          isLoadingGenderData = false;
        });
      }
    }
  }

  Future<void> fetchQuestionCategories() async {
    try {
      final uri = Uri.parse(questionCategories);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            questionCategoriesData =
                data
                    .map<Map<String, dynamic>>(
                      (e) => {'category': e['category'], 'count': e['count']},
                    )
                    .toList();
            isLoadingQuestionCategories = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            questionCategoriesError =
                'Failed to load question categories: ${response.statusCode}';
            isLoadingQuestionCategories = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          questionCategoriesError = e.toString();
          isLoadingQuestionCategories = false;
        });
      }
    }
  }

  Future<void> fetchDashboardStats() async {
    try {
      final uri = Uri.parse(dashboardStatsUrl);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            dashboardStats = data;
            isLoadingDashboardStats = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            dashboardStatsError =
                'Failed to load dashboard stats: ${response.statusCode}';
            isLoadingDashboardStats = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          dashboardStatsError = e.toString();
          isLoadingDashboardStats = false;
        });
      }
    }
  }

  Future<void> fetchTodayActivity() async {
    try {
      final uri = Uri.parse(todayActivityUrl);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            todayActivity = data;
            isLoadingTodayActivity = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            todayActivityError =
                'Failed to load today activity: ${response.statusCode}';
            isLoadingTodayActivity = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          todayActivityError = e.toString();
          isLoadingTodayActivity = false;
        });
      }
    }
  }

  Future<void> fetchTopContent() async {
    try {
      final uri = Uri.parse(topContentUrl);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            topContent = data;
            isLoadingTopContent = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            topContentError =
                'Failed to load top content: ${response.statusCode}';
            isLoadingTopContent = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          topContentError = e.toString();
          isLoadingTopContent = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminPanelGreen50,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.adminPanelGreen50,
              AppColors.adminPanelCream,
              AppColors.adminPanelGold50,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildMainStatsGrid(context),
              const SizedBox(height: 32),
              _buildSecondaryStatsGrid(context),
              const SizedBox(height: 32),
              _buildChartsSection(context),
              const SizedBox(height: 32),
              _buildQuestionCategoriesChart(context),
              const SizedBox(height: 32),
              _buildTodayHighlightsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.adminPanelGreen800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Welcome back! Here\'s what\'s happening with your platform.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.adminPanelGreen600,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.adminPanelGreen300),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
            style: const TextStyle(
              color: AppColors.adminPanelGreen700,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainStatsGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount =
        screenWidth > 1200
            ? 4
            : screenWidth > 800
            ? 2
            : 1;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: 1.6,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Total Users',
          isLoadingDashboardStats
              ? '...'
              : '${dashboardStats['totalusers'] ?? 0}',
          Icons.people,
          dashboardStats['monthlyincreaseinusers'] != null
              ? '${dashboardStats['monthlyincreaseinusers'] < 0 ? '' : '+'}${dashboardStats['monthlyincreaseinusers']} this month'
              : null,
          AppColors.adminPanelGreen600,
          dashboardStats['monthlyincreaseinusers'] != null,
        ),
        _buildStatCard(
          'Certified Volunteers',
          isLoadingDashboardStats
              ? '...'
              : '${dashboardStats['totalcertifiedvolunteers'] ?? 0}',
          Icons.verified_user,
          dashboardStats['weeklyincreaseincertifiedvolunteers'] != null
              ? '${dashboardStats['weeklyincreaseincertifiedvolunteers'] < 0 ? '' : '+'}${dashboardStats['weeklyincreaseincertifiedvolunteers']} this week'
              : null,
          AppColors.adminPanelGreen600,
          dashboardStats['weeklyincreaseincertifiedvolunteers'] != null,
        ),
        _buildStatCard(
          'Pending Applications',
          isLoadingDashboardStats
              ? '...'
              : '${dashboardStats['totalpendingvolunteers'] ?? 0}',
          Icons.person_add,
          dashboardStats['dailyincreaseinpendingvolunteers'] != null
              ? '${dashboardStats['dailyincreaseinpendingvolunteers'] < 0 ? '' : '+'}${dashboardStats['dailyincreaseinpendingvolunteers']} new today'
              : null,
          Colors.orange.shade600,
          dashboardStats['dailyincreaseinpendingvolunteers'] != null,
        ),
        _buildStatCard(
          'Total Questions',
          isLoadingDashboardStats
              ? '...'
              : '${dashboardStats['totalquestions'] ?? 0}',
          Icons.help_outline,
          dashboardStats['dailyincreaseinquestions'] != null
              ? '${dashboardStats['dailyincreaseinquestions'] < 0 ? '' : '+'}${dashboardStats['dailyincreaseinquestions']} today'
              : null,
          AppColors.adminPanelGreen600,
          dashboardStats['dailyincreaseinquestions'] != null,
        ),
      ],
    );
  }

  Widget _buildSecondaryStatsGrid(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount =
        screenWidth > 1200
            ? 5
            : screenWidth > 800
            ? 3
            : 2;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      childAspectRatio: 1.8,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Answered Questions',
          isLoadingDashboardStats
              ? '...'
              : '${dashboardStats['totalansweredquestions'] ?? 0}',
          Icons.check_circle,
          null,
          Colors.green.shade600,
          false,
        ),
        _buildStatCard(
          'Unanswered',
          isLoadingDashboardStats
              ? '...'
              : '${dashboardStats['totalunansweredquestions'] ?? 0}',
          Icons.cancel,
          null,
          Colors.red.shade600,
          false,
        ),
        _buildStatCard(
          'Flagged Content',
          isLoadingDashboardStats
              ? '...'
              : '${dashboardStats['totalflags'] ?? 0}',
          Icons.flag,
          null,
          Colors.red.shade600,
          false,
        ),
        _buildStatCard(
          'Stories',
          isLoadingDashboardStats
              ? '...'
              : '${dashboardStats['totalstories'] ?? 0}',
          Icons.brightness_6_outlined,
          null,
          AppColors.adminPanelGreen600,
          false,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    String? change,
    Color iconColor,
    bool showChange,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminPanelGreen100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, color: iconColor, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.adminPanelGreen800,
              height: 1.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (showChange && change != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.trending_up, size: 12, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    change,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1024;

    return Column(
      children: [
        if (isMobile) ...[
          _buildUserGrowthChart(),
          const SizedBox(height: 24),
          _buildGenderChart(),
        ] else ...[
          Row(
            children: [
              Expanded(child: _buildUserGrowthChart()),
              const SizedBox(width: 24),
              Expanded(child: _buildGenderChart()),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildUserGrowthChart() {
    if (isLoadingUserGrowth) {
      return const Center(child: CircularProgressIndicator());
    }
    if (userGrowthError != null) {
      return Center(child: Text('Error: ' + userGrowthError!));
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminPanelGreen100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Growth',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.adminPanelGreen800,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor:
                        (touchedSpots) => AppColors.adminPanelGreen600,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '${spot.y.toInt()}',
                          const TextStyle(
                            color: Colors.white, // Change text color to white
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: 5,
                  verticalInterval: 1,
                  getDrawingHorizontalLine:
                      (value) => FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                        dashArray: [3, 3],
                      ),
                  getDrawingVerticalLine:
                      (value) => FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                        dashArray: [3, 3],
                      ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < userGrowthData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              userGrowthData[value.toInt()]['month'],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (userGrowthData.length - 1).toDouble(),
                minY:
                    userGrowthData.isNotEmpty
                        ? userGrowthData
                            .map((e) => e['users'] as int)
                            .reduce((a, b) => a < b ? a : b)
                            .toDouble()
                        : 0,
                maxY:
                    userGrowthData.isNotEmpty
                        ? userGrowthData
                            .map((e) => e['users'] as int)
                            .reduce((a, b) => a > b ? a : b)
                            .toDouble()
                        : 10,
                lineBarsData: [
                  LineChartBarData(
                    spots:
                        userGrowthData.asMap().entries.map((entry) {
                          return FlSpot(
                            entry.key.toDouble(),
                            (entry.value['users'] as int).toDouble(),
                          );
                        }).toList(),
                    isCurved: true,
                    color: AppColors.adminPanelGreen600,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: AppColors.adminPanelGreen600,
                          strokeWidth: 2,
                          strokeColor: Colors.white,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.adminPanelGreen600.withOpacity(0.1),
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

  Widget _buildGenderChart() {
    if (isLoadingGenderData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (genderDataError != null) {
      return Center(child: Text('Error: ' + genderDataError!));
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminPanelGreen100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gender Distribution',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.adminPanelGreen800,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 300,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections:
                          genderData.map((data) {
                            return PieChartSectionData(
                              color: Color(data['color']),
                              value: data['value'].toDouble(),
                              title: '${data['value']}%',
                              radius: 80,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        genderData.map((data) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(data['color']),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    data['name'],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCategoriesChart(BuildContext context) {
    if (isLoadingQuestionCategories) {
      return const Center(child: CircularProgressIndicator());
    }
    if (questionCategoriesError != null) {
      return Center(child: Text('Error: ' + questionCategoriesError!));
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminPanelGreen100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Question Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.adminPanelGreen800,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 400,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY:
                    questionCategoriesData.isNotEmpty
                        ? questionCategoriesData
                            .map((e) => e['count'] as int)
                            .reduce((a, b) => a > b ? a : b)
                            .toDouble()
                        : 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 500,
                  getDrawingHorizontalLine:
                      (value) => FlLine(
                        color: Colors.grey.shade300,
                        strokeWidth: 1,
                        dashArray: [3, 3],
                      ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < questionCategoriesData.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              questionCategoriesData[value.toInt()]['category'],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups:
                    questionCategoriesData.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value['count'].toDouble(),
                            color: AppColors.adminPanelGreen600,
                            width: 40,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(4),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayHighlightsSection(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return Column(
        children: [
          _buildTodayActivityCard(),
          const SizedBox(height: 16),
          _buildTopContentCard(),
        ],
      );
    } else {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _buildTodayActivityCard()),
            const SizedBox(width: 16),
            Expanded(child: _buildTopContentCard()),
          ],
        ),
      );
    }
  }

  Widget _buildTodayActivityCard() {
    if (isLoadingTodayActivity) {
      return const Center(child: CircularProgressIndicator());
    }
    if (todayActivityError != null) {
      return Center(child: Text('Error: $todayActivityError'));
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminPanelGreen100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppColors.adminPanelGreen600,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Today\'s Activity',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.adminPanelGreen800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildActivityItem(
            'New Users',
            '${todayActivity['newusers'] ?? 0}',
            false,
          ),
          _buildActivityItem(
            'New Questions',
            '${todayActivity['newquestions'] ?? 0}',
            false,
          ),
          _buildActivityItem(
            'Content Flagged',
            '${todayActivity['newflags'] ?? 0}',
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String label, String value, bool isWarning) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  isWarning
                      ? Colors.red.shade100
                      : AppColors.adminPanelGreen100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color:
                    isWarning
                        ? Colors.red.shade800
                        : AppColors.adminPanelGreen800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopContentCard() {
    if (isLoadingTopContent) {
      return const Center(child: CircularProgressIndicator());
    }
    if (topContentError != null) {
      return Center(child: Text('Error: $topContentError'));
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminPanelGreen100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.star, color: AppColors.adminPanelGreen600, size: 20),
              SizedBox(width: 8),
              Text(
                'Top Content',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.adminPanelGreen800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top Liked Story',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                topContent['toplikedstories']?['title'] ?? 'N/A',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.adminPanelGreen700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Top Saved Story',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                topContent['topsavedstories']?['title'] ?? 'N/A',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.adminPanelGreen700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Most Saved Question',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                topContent['mostsavedquestion']?['text'] ?? 'N/A',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.adminPanelGreen700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
