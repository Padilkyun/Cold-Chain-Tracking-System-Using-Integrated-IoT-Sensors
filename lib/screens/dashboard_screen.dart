import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../services/esp_service.dart';
import '../services/profile_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final espService = EspService();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DASHBOARD UTAMA',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        actions: [
          ListenableBuilder(
            listenable: ProfileService(),
            builder: (context, _) {
              final profile = ProfileService();
              return GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/profile'),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[700],
                    backgroundImage: profile.imagePath != null
                        ? FileImage(File(profile.imagePath!))
                        : null,
                    child: profile.imagePath == null
                        ? const Icon(Icons.person, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFF43F5E)),
            onPressed: () {
              // Confirm logout
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Logout', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  content: Text('Apakah Anda yakin ingin keluar dari aplikasi?', style: GoogleFonts.outfit()),
                  actions: [
                    TextButton(
                      child: Text('Batal', style: GoogleFonts.outfit(color: Colors.grey)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: Text('Keluar', style: GoogleFonts.outfit(color: const Color(0xFFF43F5E))),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(context, '/login');
                      },
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

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                // Welcome Text
                Text(
                  'Selamat Datang,',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
                ListenableBuilder(
                  listenable: ProfileService(),
                  builder: (context, _) {
                    return Text(
                      ProfileService().username,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Connection Status Card
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isConnected
                        ? const Color(0xFF10B981).withOpacity(0.15)
                        : const Color(0xFFF43F5E).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isConnected
                          ? const Color(0xFF10B981).withOpacity(0.4)
                          : const Color(0xFFF43F5E).withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isConnected ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isConnected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isConnected ? 'Terhubung dengan Alat' : 'Koneksi Terputus',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isConnected ? const Color(0xFF10B981) : const Color(0xFFF43F5E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isConnected
                                  ? 'ESP32 merespons dengan baik di IP 192.168.4.1'
                                  : 'Hubungkan HP Anda ke Hotspot WiFi "CapsiBox_AP"',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                  'PILIH ALAT KONTROL',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 16),

                // Card 1: Capsi Box (Chili Storage)
                _buildDeviceCard(
                  context: context,
                  title: 'CAPSI BOX',
                  subtitle: 'Penyimpanan Cabai Pintar',
                  imagePath: 'assets/cabe.jpeg',
                  icon: Icons.thermostat_rounded,
                  iconColor: const Color(0xFFEF4444),
                  route: '/capsibox',
                  statusInfo: isConnected 
                      ? 'Suhu: ${espService.suhu.toStringAsFixed(1)}°C | Kelembaban: ${espService.kelembaban.toStringAsFixed(0)}%'
                      : 'Status Offline',
                ),
                const SizedBox(height: 50),

                // Card 2: Tea Harvest (Tea Cutter)
                _buildDeviceCard(
                  context: context,
                  title: 'TEA HARVEST',
                  subtitle: 'Alat Pemotong Teh Otomatis',
                  imagePath: 'assets/teh.jpeg',
                  icon: Icons.cut_rounded,
                  iconColor: const Color(0xFF10B981),
                  route: '/tea_harvest',
                  statusInfo: isConnected
                      ? (espService.teaCutterActive 
                          ? 'Pemotong: AKTIF (${espService.teaCutterSpeed}%)' 
                          : 'Pemotong: DINONAKTIFKAN')
                      : 'Status Offline',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDeviceCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String imagePath,
    required IconData icon,
    required Color iconColor,
    required String route,
    required String statusInfo,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        child: Container(
          height: 320,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(imagePath),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.65), // Overlay for readability
                BlendMode.srcOver,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(icon, color: iconColor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusInfo,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey[200],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
