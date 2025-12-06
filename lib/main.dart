import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const FPLWrapApp());
}

// ====================== COLOR PALETTE =========================
const Color _deepBlack = Color(0xFF121212);
const Color _deepPurple = Color(0xFF6200EE);
const Color _brightBlue = Color(0xFF03DAC6); // Main highlight color
const Color _white = Colors.white;
const Color _lightGrey = Color(0xFFE0E0E0);
const Color _darkGrey = Color(0xFF2C2C2C);


class FPLWrapApp extends StatelessWidget {
  const FPLWrapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FPL Wrapped',
      theme: ThemeData(
        fontFamily: 'Montserrat', 
        primaryColor: _deepPurple,
        scaffoldBackgroundColor: _deepBlack,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: _brightBlue,
          primary: _deepPurple,
        ),
        useMaterial3: true,
      ),
      home: const FPLEntryScreen(),
    );
  }
}

// ====================== ENTRY SCREEN (Refactored for Comparison) =========================

class FPLEntryScreen extends StatefulWidget {
  const FPLEntryScreen({super.key});

  @override
  State<FPLEntryScreen> createState() => _FPLEntryScreenState();
}

class _FPLEntryScreenState extends State<FPLEntryScreen> {
  final TextEditingController _idControllerA = TextEditingController();
  final TextEditingController _idControllerB = TextEditingController();
  bool isLoading = false;
  bool isComparisonMode = false;
  String error = "";

  Future<Map<String, dynamic>> fetchEntry(String id) async {
    final res = await http.get(
      Uri.parse('https://fantasy.premierleague.com/api/entry/$id/'),
    );
    if (res.statusCode != 200) throw Exception("Error fetching entry for ID $id");
    return json.decode(res.body);
  }

  Future<Map<String, dynamic>> fetchHistory(String id) async {
    final res = await http.get(
      Uri.parse('https://fantasy.premierleague.com/api/entry/$id/history/'),
    );
    if (res.statusCode != 200) throw Exception("Error fetching history for ID $id");
    return json.decode(res.body);
  }

  Future<void> generateWrap() async {
    final idA = _idControllerA.text.trim();
    final idB = _idControllerB.text.trim();

    if (idA.isEmpty) {
      setState(() => error = "Manager 1 FPL ID is required.");
      return;
    }
    if (isComparisonMode && idB.isEmpty) {
      setState(() => error = "Manager 2 FPL ID is required for comparison mode.");
      return;
    }

    setState(() {
      isLoading = true;
      error = "";
    });

    try {
      final dataA = await Future.wait([fetchEntry(idA), fetchHistory(idA)]);
      final resultA = FPLManagerData(entry: dataA[0], history: dataA[1]);

      if (isComparisonMode) {
        final dataB = await Future.wait([fetchEntry(idB), fetchHistory(idB)]);
        final resultB = FPLManagerData(entry: dataB[0], history: dataB[1]);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FPLComparisonScreen(managerA: resultA, managerB: resultB),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FPLSingleWrapScreen(data: resultA),
          ),
        );
      }
    } catch (e) {
      setState(() => error = e.toString().contains("ID") ? e.toString() : "API Error: Check FPL IDs.");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _deepBlack,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 380,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "FPL ⚽ WRAPPED",
                style: TextStyle(
                  color: _brightBlue,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 40),

              // Manager A Input
              _buildIdTextField(_idControllerA, "Manager 1 FPL ID", Icons.person_add, isComparisonMode ? _deepPurple : _brightBlue),
              
              if (isComparisonMode) const SizedBox(height: 20),

              // Manager B Input (Conditional)
              if (isComparisonMode)
                _buildIdTextField(_idControllerB, "Manager 2 FPL ID", Icons.compare_arrows, _deepPurple),
              
              const SizedBox(height: 20),

              // Toggle Button
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    isComparisonMode = !isComparisonMode;
                    error = "";
                  });
                },
                icon: Icon(isComparisonMode ? Icons.arrow_back : Icons.group_add, color: _lightGrey),
                label: Text(
                  isComparisonMode ? "Switch to Single Manager" : "Compare with a Friend",
                  style: TextStyle(color: _lightGrey.withOpacity(0.8), fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 20),

              // Action Button
              ElevatedButton(
                onPressed: isLoading ? null : generateWrap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brightBlue, // Use bright blue for the main action
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: _deepBlack)
                    : Text(
                        isComparisonMode ? "Compare Wraps" : "Generate My Wrap",
                        style: const TextStyle(color: _deepBlack, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),

              const SizedBox(height: 20),
              if (error.isNotEmpty)
                Text(
                  error,
                  style: const TextStyle(color: Colors.redAccent),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIdTextField(TextEditingController controller, String hint, IconData icon, Color focusColor) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: _white),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _white.withOpacity(0.6)),
        filled: true,
        fillColor: _darkGrey,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: focusColor, width: 2),
        ),
        prefixIcon: Icon(icon, color: focusColor),
      ),
    );
  }
}

// ====================== DATA MODEL =========================

// Data structure to hold parsed manager information
class FPLManagerData {
  final Map<String, dynamic> entry;
  final Map<String, dynamic> history;
  late final int overallRank;
  late final int totalPoints;
  late final int avgPoints;
  late final int bestGW;
  late final int worstGW;
  late final int totalTransfers;
  late final int hitsTaken;
  late final int benchPoints;
  late final int bestRank;
  late final int worstRank;
  late final String teamName;
  late final String managerName;
  late final String country;
  late final List<String> chips;
  late final List<dynamic> weeks;

  FPLManagerData({required this.entry, required this.history}) {
    weeks = history["current"] ?? [];
    
    // Helper function to safely cast to int
    int safeInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    // Official data from entry endpoint
    overallRank = safeInt(entry["summary_overall_rank"]);
    totalPoints = safeInt(entry["summary_overall_points"]); 
    teamName = entry["name"] ?? "Unknown Team";
    managerName = "${entry["player_first_name"] ?? ""} ${entry["player_last_name"] ?? ""}";
    country = entry["player_region_name"] ?? "";

    // Data derived from history endpoint (weeks)
    avgPoints = weeks.isNotEmpty ? (totalPoints / weeks.length).round() : 0; 
    
    // Weekly stats
    bestGW = weeks.map((g) => safeInt(g["points"])).fold(0, (a, b) => a > b ? a : b);
    worstGW = weeks.map((g) => safeInt(g["points"])).fold(9999, (a, b) => a < b ? a : b);
    totalTransfers = weeks.fold(0, (sum, gw) => sum + safeInt(gw["event_transfers"]));
    hitsTaken = weeks.fold(0, (sum, gw) => sum + safeInt(gw["event_transfers_cost"]));
    benchPoints = weeks.fold(0, (sum, gw) => sum + safeInt(gw["bench_points"]));
    bestRank = weeks.map((g) => safeInt(g["overall_rank"])).fold(9999999, (a, b) => a < b ? a : b);
    worstRank = weeks.map((g) => safeInt(g["overall_rank"])).fold(0, (a, b) => a > b ? a : b);
    chips = (history["chips"] ?? []).map((c) => c["name"] ?? "").toList().cast<String>();
  }
}

// ====================== SINGLE WRAP SCREEN (Previously FPLWrapScreen) =========================

class FPLSingleWrapScreen extends StatelessWidget {
  final FPLManagerData data;

  const FPLSingleWrapScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _deepBlack,
      body: SafeArea(
        child: PageView(
          children: [
            _buildHeroScreen(data),
            _buildStatsScreen(data),
          ],
        ),
      ),
    );
  }

  // --- SCREEN 1: HERO SCREEN ---

  Widget _buildHeroScreen(FPLManagerData data) {
    return Container(
      color: _deepBlack,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '2025',
                style: TextStyle(
                  fontSize: 180,
                  color: _deepPurple.withOpacity(0.3),
                  fontWeight: FontWeight.w900,
                  height: 0.8,
                ),
              ),
              Column(
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: _deepPurple,
                    child: const Icon(Icons.shield, size: 70, color: _white),
                  ),
                  const SizedBox(height: 24),
                  Text(data.managerName.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 36, fontWeight: FontWeight.bold, color: _white, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text(data.teamName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w300, color: _white.withOpacity(0.8))),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _heroStatItem('Total Points', '${data.totalPoints}', _brightBlue),
                      const SizedBox(width: 30),
                      _heroStatItem('Avg/week', '${data.avgPoints}', _lightGrey),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    decoration: BoxDecoration(
                      color: _brightBlue,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: _brightBlue.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5))
                      ]
                    ),
                    child: Text(
                      'Overall Rank: ${data.overallRank.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                        color: _deepBlack,
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStatItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(color: _white.withOpacity(0.7), fontSize: 14),
        ),
      ],
    );
  }

  // --- SCREEN 2: STATS SCREEN ---

  Widget _buildStatsScreen(FPLManagerData data) {
    return Container(
      color: _darkGrey,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: SingleChildScrollView( 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Season Highlights',
              style: TextStyle(
                color: _white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Stat Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _statCard("Country", data.country, Icons.flag, _deepPurple),
                _statCard("Best GW", '${data.bestGW} pts', Icons.star, _brightBlue),
                _statCard("Worst GW", '${data.worstGW} pts', Icons.sentiment_dissatisfied, Colors.redAccent),
                _statCard("Best Rank", '${data.bestRank}', Icons.leaderboard, Colors.greenAccent),
                _statCard("Total Transfers", '${data.totalTransfers}', Icons.swap_horiz, _deepPurple),
                _statCard("Hits Taken", '${data.hitsTaken}', Icons.money_off, Colors.orangeAccent),
                _statCard("Bench Points", '${data.benchPoints}', Icons.event_seat, _brightBlue),
                _statCard("Chips Used", data.chips.join(', '), Icons.casino, Colors.amberAccent),
              ],
            ),
            const SizedBox(height: 32),
            
            // Weekly points chart (Bar Chart)
            _buildWeeklyPointsChart(data.weeks),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _deepBlack,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(color: _deepBlack.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(title,
                    style: TextStyle(color: _white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const Spacer(),
          Flexible( 
            child: Text(
              value,
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
              maxLines: 2, 
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.w900, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to safely cast to int (duplicated for standalone function, but now handled by model)
  int _safeInt(dynamic val) {
    if (val == null) return 0;
    if (val is int) return val;
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }
  
  Widget _buildWeeklyPointsChart(List weeks) {
    final List<int> points = weeks.map((gw) => _safeInt(gw["points"])).toList();
    if (points.isEmpty) return Container();
    
    final int maxPoints = points.fold(0, max);
    final double scaleFactor = 100.0 / maxPoints;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _deepBlack,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _deepPurple.withOpacity(0.5), width: 1),
          boxShadow: [
            BoxShadow(
                color: _deepBlack.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 8))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gameweek Performance',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: _white)),
          Text('Max GW: $maxPoints pts',
              style: TextStyle(fontWeight: FontWeight.w300, fontSize: 14, color: _lightGrey)),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: points.map<Widget>((p) {
                double height = p * scaleFactor;
                return Expanded(
                  child: Tooltip(
                    message: '$p points',
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      height: height,
                      decoration: BoxDecoration(
                          color: _brightBlue.withOpacity(0.9),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}

// ====================== COMPARISON SCREEN (New Feature) =========================

class FPLComparisonScreen extends StatelessWidget {
  final FPLManagerData managerA;
  final FPLManagerData managerB;

  const FPLComparisonScreen({super.key, required this.managerA, required this.managerB});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _deepBlack,
      appBar: AppBar(
        title: const Text('FPL Head-to-Head Comparison', style: TextStyle(color: _white)),
        backgroundColor: _deepPurple,
        iconTheme: const IconThemeData(color: _white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Manager Names Header
            _buildComparisonHeader(),
            const SizedBox(height: 30),
            
            // Total Points & Rank Comparison
            _buildStatComparisonRow("Overall Rank", Icons.leaderboard, managerA.overallRank, managerB.overallRank, true),
            _buildStatComparisonRow("Total Points", Icons.star, managerA.totalPoints, managerB.totalPoints, false),
            _buildStatComparisonRow("Average GW Score", Icons.trending_up, managerA.avgPoints, managerB.avgPoints, false),
            
            // Weekly Stats
            const Divider(color: _darkGrey, height: 40),
            _buildStatComparisonRow("Best GW Score", Icons.military_tech, managerA.bestGW, managerB.bestGW, false),
            _buildStatComparisonRow("Transfers Made", Icons.swap_horiz, managerA.totalTransfers, managerB.totalTransfers, true),
            _buildStatComparisonRow("Hits Taken", Icons.money_off, managerA.hitsTaken, managerB.hitsTaken, true),
            _buildStatComparisonRow("Bench Points", Icons.event_seat, managerA.benchPoints, managerB.benchPoints, false),
            
            // Custom Comparison Item for Chips
            _buildChipComparisonRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonHeader() {
    return Row(
      children: [
        const Spacer(flex: 2),
        Expanded(
          flex: 4,
          child: _managerLabel(managerA.managerName, _brightBlue),
        ),
        Expanded(
          flex: 4,
          child: _managerLabel(managerB.managerName, _deepPurple),
        ),
      ],
    );
  }

  Widget _managerLabel(String name, Color color) {
    final manager = color == _brightBlue ? managerA : managerB;
    return Column(
      children: [
        Icon(Icons.person, color: color, size: 30),
        const SizedBox(height: 5),
        Text(
          name.split(' ').first, // Use only first name for compactness
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          manager.teamName,
          textAlign: TextAlign.center,
          style: TextStyle(color: _lightGrey, fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStatComparisonRow(
      String title, IconData icon, int valA, int valB, bool lowerIsBetter) {
    
    Color colorA = (lowerIsBetter ? (valA < valB ? Colors.green : (valA > valB ? Colors.red : _lightGrey)) : (valA > valB ? Colors.green : (valA < valB ? Colors.red : _lightGrey)));
    Color colorB = (lowerIsBetter ? (valB < valA ? Colors.green : (valB > valA ? Colors.red : _lightGrey)) : (valB > valA ? Colors.green : (valB < valA ? Colors.red : _lightGrey)));
    
    // Handle Ties
    if (valA == valB) {
      colorA = colorB = _lightGrey;
    }

    // Format Rank with commas
    String displayA = title == "Overall Rank" ? valA.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},') : valA.toString();
    String displayB = title == "Overall Rank" ? valB.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},') : valB.toString();


    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          // Stat Title and Icon
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: _lightGrey, size: 18),
                Text(title, style: const TextStyle(color: _white, fontSize: 14)),
              ],
            ),
          ),
          
          // Value A
          Expanded(
            flex: 4,
            child: Text(
              displayA,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorA, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
          
          // Value B
          Expanded(
            flex: 4,
            child: Text(
              displayB,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorB, fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipComparisonRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.casino, color: _lightGrey, size: 18),
              const SizedBox(width: 8),
              const Text("Chips Used", style: TextStyle(color: _white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  managerA.chips.join('\n'), // Display chips vertically
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _brightBlue, fontSize: 14),
                ),
              ),
              Expanded(
                child: Text(
                  managerB.chips.join('\n'), // Display chips vertically
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _deepPurple, fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}