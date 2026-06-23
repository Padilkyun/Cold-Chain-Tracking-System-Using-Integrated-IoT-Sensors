import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'dart:async';
import '../services/esp_service.dart';

class TeaHarvestScreen extends StatefulWidget {
  const TeaHarvestScreen({super.key});

  @override
  State<TeaHarvestScreen> createState() => _TeaHarvestScreenState();
}

class _TeaHarvestScreenState extends State<TeaHarvestScreen> with SingleTickerProviderStateMixin {
  final espService = EspService();
  late AnimationController _rotationController;
  int _localSpeed = 50;
  bool _isInit = true;
  StreamSubscription? _alertSub;

  @override
  void initState() {
    super.initState();
    // Animation controller for blade rotation
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    // Initial state check
    if (espService.isConnected && espService.teaCutterActive) {
      _rotationController.repeat();
    }

    // Listen for alerts and show popups (SnackBars)
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
    _rotationController.dispose();
    super.dispose();
  }

  // Adjust rotation speed based on motor speed percentage (0-100)
  void _updateAnimationSpeed() {
    if (!espService.teaCutterActive) {
      _rotationController.stop();
      return;
    }

    // Map 0-100% speed to a duration. Higher speed -> shorter duration (faster spin)
    // 0% -> 2000ms, 100% -> 200ms
    final int speedPercent = espService.teaCutterSpeed;
    final int durationMs = (2000 - (speedPercent * 18)).clamp(200, 2000);
    
    _rotationController.duration = Duration(milliseconds: durationMs);
    _rotationController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TEA HARVEST CONTROL',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Connection indicator
          ListenableBuilder(
            listenable: espService,
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: espService.isConnected ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                  boxShadow: [
                    BoxShadow(
                      color: (espService.isConnected ? const Color(0xFF10B981) : const Color(0xFFF43F5E)).withOpacity(0.5),
                      blurRadius: 6,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: espService,
        builder: (context, child) {
          final isConnected = espService.isConnected;

          if (isConnected) {
            if (_isInit) {
              _localSpeed = espService.teaCutterSpeed;
              _isInit = false;
            }
            
            // Sync rotation animation speed with ESP status
            _updateAnimationSpeed();
          }

          return SafeArea(
            child: isConnected
                ? ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    children: [
                      // Blade Micro-Animation Card
                      _buildBladeAnimationCard(),
                      const SizedBox(height: 32),

                      // Control Panel Card
                      _buildCutterControlPanel(),
                      const SizedBox(height: 40),
                    ],
                  )
                : _buildOfflinePlaceholder(),
          );
        },
      ),
    );
  }

  Widget _buildBladeAnimationCard() {
    final isActive = espService.teaCutterActive;

    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.02),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.white.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20),
        child: Column(
          children: [
            Text(
              'ANIMASI PISAU PEMOTONG',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF10B981),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 36),

            // Spinning Blade Container
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _rotationController.value * 2 * math.pi,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive 
                          ? const Color(0xFF10B981).withOpacity(0.05) 
                          : Colors.grey.withOpacity(0.02),
                      border: Border.all(
                        color: isActive 
                            ? const Color(0xFF10B981).withOpacity(0.3) 
                            : Colors.white.withOpacity(0.05),
                        width: 2,
                      ),
                      boxShadow: isActive ? [
                        BoxShadow(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ] : [],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Center hub
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white54,
                          ),
                        ),
                        // Blade 1 (Vertical)
                        Positioned(
                          top: 10,
                          child: Container(
                            width: 14,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [Colors.white24, Colors.white60],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        // Blade 2 (Horizontal)
                        Positioned(
                          left: 10,
                          child: Container(
                            width: 70,
                            height: 14,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [Colors.white24, Colors.white60],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                        // Blade 3 (Vertical Bottom)
                        Positioned(
                          bottom: 10,
                          child: Container(
                            width: 14,
                            height: 70,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [Colors.white60, Colors.white24],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ),
                        // Blade 4 (Horizontal Right)
                        Positioned(
                          right: 10,
                          child: Container(
                            width: 70,
                            height: 14,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: const LinearGradient(
                                colors: [Colors.white60, Colors.white24],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 36),

            // Status Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? const Color(0xFF10B981) : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isActive 
                      ? 'MEMOTONG - Kecepatan ${espService.teaCutterSpeed}%' 
                      : 'STANDBY - Motor Mati',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive ? const Color(0xFF10B981) : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCutterControlPanel() {
    final isActive = espService.teaCutterActive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Power Toggle Button
        GestureDetector(
          onTap: () {
            espService.sendControl({'tea_cutter_active': !isActive});
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFF43F5E) : const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isActive ? const Color(0xFFF43F5E) : const Color(0xFF10B981)).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isActive ? Icons.power_settings_new_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 26,
                ),
                const SizedBox(width: 12),
                Text(
                  isActive ? 'HENTIKAN PEMOTONGAN' : 'MULAI PEMOTONGAN',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Speed Slider Panel
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kecepatan Motor',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '$_localSpeed%',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: const Color(0xFF10B981),
                  inactiveTrackColor: Colors.grey[700],
                  thumbColor: Colors.white,
                  overlayColor: const Color(0xFF10B981).withOpacity(0.2),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                ),
                child: Slider(
                  value: _localSpeed.toDouble(),
                  min: 10,
                  max: 100,
                  divisions: 9, // Steps of 10%
                  onChanged: (val) {
                    setState(() {
                      _localSpeed = val.toInt();
                    });
                  },
                  onChangeEnd: (val) {
                    espService.sendControl({'tea_cutter_speed': val.toInt()});
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mengatur siklus PWM pada GPIO 19. Memungkinkan kontrol laju potong teh secara tepat.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOfflinePlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF43F5E).withOpacity(0.1),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 64,
                color: Color(0xFFF43F5E),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Perangkat Offline',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Aplikasi tidak dapat terhubung ke alat pemotong teh. Pastikan HP Anda terhubung ke jaringan WiFi "CapsiBox_AP".',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: Colors.grey[400],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                espService.fetchData();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Coba Hubungkan Kembali',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
