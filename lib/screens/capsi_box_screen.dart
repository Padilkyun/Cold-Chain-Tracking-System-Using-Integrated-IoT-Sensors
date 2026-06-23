import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../theme/app_theme.dart';
import '../services/esp_service.dart';
import '../services/database_helper.dart';
import '../services/profile_service.dart';
import 'notification_screen.dart';
import 'history_screen.dart';

class CapsiBoxScreen extends StatefulWidget {
  const CapsiBoxScreen({super.key});

  @override
  State<CapsiBoxScreen> createState() => _CapsiBoxScreenState();
}

class _CapsiBoxScreenState extends State<CapsiBoxScreen> {
  final espService = EspService();
  double _localSetpoint = 19.0;
  bool _isInit = true;
  StreamSubscription? _alertSub;
  String _selectedFilter = '12h';

  @override
  void initState() {
    super.initState();
    _alertSub = espService.alerts.listen((message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: message.contains('⚠️') || message.contains('❌') 
                ? Colors.redAccent : Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListenableBuilder(
        listenable: espService,
        builder: (context, child) {
          final isConnected = espService.isConnected;

          if (_isInit && isConnected) {
            _localSetpoint = espService.setpoint;
            _isInit = false;
          }

          // Sensor variables from EspService or default fallback
          final suhuText = isConnected ? '${espService.suhu.toStringAsFixed(1)}°C' : '-- °C';
          final humidText = isConnected ? '${espService.kelembaban.toStringAsFixed(0)}%' : '-- %';
          final tvocText = isConnected ? '${espService.tvoc}' : '--';
          
          return SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.eco, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'BinaPanen',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      
                      // Notification bell
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NotificationScreen()),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.notifications_outlined,
                                color: AppColors.textDark, size: 26),
                            if (isConnected && espService.tvoc >= 1000)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.danger,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      ListenableBuilder(
                        listenable: ProfileService(),
                        builder: (context, _) {
                          final profile = ProfileService();
                          return GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/profile'),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey[300],
                              backgroundImage: profile.imagePath != null
                                  ? FileImage(File(profile.imagePath!))
                                  : null,
                              child: profile.imagePath == null
                                  ? const Icon(Icons.person, color: Colors.white, size: 20)
                                  : null,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero image with overlay
                        Stack(
                          children: [
                            Container(
                              height: 180,
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                image: DecorationImage(
                                  image: AssetImage('assets/cabe.jpeg'), // Offline asset
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Container(
                              height: 180,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.black.withAlpha(128), Colors.transparent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 20,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'CapsiBox',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black45,
                                          blurRadius: 6,
                                        )
                                      ],
                                    ),
                                  ),
                                  Text(
                                    'Smart Chili Storage System',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Offline status warning
                        if (!isConnected || !espService.espNowConnected)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.dangerLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.danger.withAlpha(51)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    !isConnected 
                                      ? 'Aplikasi terputus dari ESP32 (Cek WiFi)'
                                      : 'Sensor ESP-NOW Terputus (Cek Pemancar)',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Sensor readings card
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _SensorChip(value: suhuText, label: 'Temp'),
                                _SensorChip(value: humidText, label: 'RH'),
                                _SensorChip(value: tvocText, label: 'TVOC', unit: 'ppb'),
                              ],
                            ),
                          ),
                        ),

                        // System Mode Controller
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Mode Sistem',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 12),
                              
                              // Auto/Manual Selection Tabs
                              Container(
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F0F0),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: isConnected ? () {
                                          espService.sendControl({'mode_auto': 1});
                                        } : null,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          margin: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: isConnected && espService.modeAuto
                                                ? AppColors.white
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(26),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Auto (PID)',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isConnected && espService.modeAuto
                                                    ? AppColors.primary
                                                    : AppColors.textGrey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: isConnected ? () {
                                          espService.sendControl({'mode_auto': 0});
                                        } : null,
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          margin: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: isConnected && !espService.modeAuto
                                                ? AppColors.white
                                                : Colors.transparent,
                                            borderRadius: BorderRadius.circular(26),
                                          ),
                                          child: Center(
                                            child: Text(
                                              'Manual',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isConnected && !espService.modeAuto
                                                    ? AppColors.primary
                                                    : AppColors.textGrey,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Slider Setpoint (Only active in Auto mode)
                              if (isConnected && espService.modeAuto) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: const [
                                              Text(
                                                'TARGET SUHU BOX',
                                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 1.2),
                                              ),
                                              Text(
                                                'Otomatis dijaga oleh PID',
                                                style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${_localSetpoint.toStringAsFixed(1)}°C',
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor: AppColors.primary,
                                          inactiveTrackColor: AppColors.primary.withOpacity(0.1),
                                          thumbColor: AppColors.primary,
                                          overlayColor: AppColors.primary.withOpacity(0.2),
                                          valueIndicatorColor: AppColors.primary,
                                          valueIndicatorTextStyle: const TextStyle(color: Colors.white),
                                        ),
                                        child: Slider(
                                          value: _localSetpoint,
                                          min: 5.0,
                                          max: 30.0,
                                          label: '${_localSetpoint.toStringAsFixed(1)}°C',
                                          divisions: 30,
                                          onChanged: (val) {
                                            setState(() {
                                              _localSetpoint = val;
                                            });
                                          },
                                          onChangeEnd: (val) {
                                            espService.sendControl({'setpoint': val});
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],

                              // Actuators Toggles
                              _ControlRow(
                                icon: Icons.ac_unit,
                                label: 'Peltier Cooler',
                                value: isConnected && (espService.modeAuto ? (espService.peltierPwm > 0) : espService.manualPeltier),
                                enabled: isConnected && !espService.modeAuto,
                                onChanged: (v) {
                                  espService.sendControl({'manual_peltier': v});
                                },
                              ),
                              const SizedBox(height: 12),
                              _ControlRow(
                                icon: Icons.wind_power,
                                label: 'Exhaust Fan',
                                value: isConnected && (espService.modeAuto ? true : espService.manualKipas),
                                enabled: isConnected && !espService.modeAuto,
                                onChanged: (v) {
                                  espService.sendControl({'manual_kipas': v});
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // History Header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Riwayat Sensor',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textDark,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedFilter,
                                    icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: AppColors.primary),
                                    style: const TextStyle(
                                      fontSize: 13, 
                                      color: AppColors.primary, 
                                      fontWeight: FontWeight.w800
                                    ),
                                    dropdownColor: Colors.white, // Background menu dropdown putih
                                    borderRadius: BorderRadius.circular(12),
                                    items: ['1h', '6h', '12h', '24h'].map((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        _selectedFilter = newValue!;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // History Chart Card
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            height: 240,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.only(top: 20, right: 20, left: 10, bottom: 10),
                              child: _HistoryChart(filter: _selectedFilter),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Action logs
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Tindakan terbaru',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: DatabaseHelper().getRecentActions(limit: 5),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Text('Belum ada tindakan tercatat', 
                                  style: TextStyle(color: AppColors.textGrey, fontSize: 13));
                              }
                              
                              final actions = snapshot.data!;
                              return Column(
                                children: actions.map((action) {
                                  final DateTime time = DateTime.parse(action['timestamp']);
                                  final String formattedTime = DateFormat('HH:mm').format(time.toLocal());
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _ActionItem(
                                      icon: action['title'].toString().contains('aktif') 
                                          ? Icons.play_circle_outline 
                                          : Icons.settings_input_component,
                                      title: action['title'],
                                      time: formattedTime,
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SensorChip extends StatelessWidget {
  final String value;
  final String label;
  final String? unit;

  const _SensorChip({required this.value, required this.label, this.unit});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            if (unit != null && value != '--') ...[
              const SizedBox(width: 2),
              Text(
                unit!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
      ],
    );
  }
}

class _ControlRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ControlRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = enabled ? AppColors.textDark : AppColors.textGrey;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.textGrey, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                if (!enabled)
                  const Text(
                    'Dikelola Otomatis oleh PID',
                    style: TextStyle(fontSize: 11, color: AppColors.textGrey),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCCCCCC),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
          ],
        ),
      ],
    );
  }
}

class _HistoryChart extends StatelessWidget {
  final String filter;
  const _HistoryChart({required this.filter});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper().getHistory(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return const Center(
            child: Text('Belum ada data riwayat', style: TextStyle(color: AppColors.textGrey, fontSize: 12)),
          );
        }

        // Limit data points for performance if needed
        List<FlSpot> suhuSpots = [];
        List<FlSpot> humSpots = [];
        List<FlSpot> tvocSpots = [];

        for (int i = 0; i < data.length; i++) {
          double x = i.toDouble();
          suhuSpots.add(FlSpot(x, (data[i]['suhu'] as num).toDouble()));
          humSpots.add(FlSpot(x, (data[i]['kelembaban'] as num).toDouble()));
          tvocSpots.add(FlSpot(x, (data[i]['tvoc'] as num).toDouble() / 10)); // Scaled TVOC for visibility
        }

        return Column(
          children: [
            Expanded(
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: (data.length / 5).clamp(1, 100).toDouble(),
                        getTitlesWidget: (value, meta) {
                          return const Text(''); // Hide individual X labels for simplicity
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 20,
                        getTitlesWidget: (value, meta) {
                          return Text(value.toInt().toString(), 
                            style: const TextStyle(color: AppColors.textGrey, fontSize: 10));
                        },
                        reservedSize: 28,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    _lineData(suhuSpots, const Color(0xFF8B7FD4)),
                    _lineData(humSpots, const Color(0xFFE8847A)),
                    _lineData(tvocSpots, const Color(0xFF6CC4C8)),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final textStyle = const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          );
                          String label = touchedSpot.barIndex == 0 ? 'Suhu' : 
                                        touchedSpot.barIndex == 1 ? 'Hum' : 'TVOC';
                          double val = touchedSpot.barIndex == 2 ? touchedSpot.y * 10 : touchedSpot.y;
                          return LineTooltipItem(
                            '$label: ${val.toStringAsFixed(1)}',
                            textStyle,
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _LegendDot(color: Color(0xFF8B7FD4), label: 'Suhu'),
                SizedBox(width: 14),
                _LegendDot(color: Color(0xFFE8847A), label: 'Hum'),
                SizedBox(width: 14),
                _LegendDot(color: Color(0xFF6CC4C8), label: 'TVOC (x10)'),
              ],
            ),
          ],
        );
      },
    );
  }

  LineChartBarData _lineData(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(fontSize: 10, color: AppColors.textGrey)),
      ],
    );
  }
}

