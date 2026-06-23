import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/esp_service.dart';
import 'capsi_box_screen.dart';
import 'tea_harvest_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final espService = EspService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardView(context),
          const CapsiBoxScreen(),
          const TeaHarvestScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }

  Widget _buildDashboardView(BuildContext context) {
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
                
                // Connection indicator
                ListenableBuilder(
                  listenable: espService,
                  builder: (context, child) {
                    return Container(
                      margin: const EdgeInsets.only(right: 14),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: espService.isConnected
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: espService.isConnected
                              ? AppColors.primary.withOpacity(0.3)
                              : AppColors.danger.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: espService.isConnected ? AppColors.primary : AppColors.danger,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            espService.isConnected ? 'Online' : 'Offline',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: espService.isConnected ? AppColors.primary : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  const Text(
                    'Hallo!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pantau kondisi sistemmu saat ini, agar kondisi\nkomoditas pertanianmu tetap terjaga.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMedium,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // CapsiBox section card
                  GestureDetector(
                    onTap: () => setState(() => _selectedIndex = 1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.inventory_2_outlined,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'CapsiBox',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: const DecorationImage(
                                    image: AssetImage('assets/cabe.jpeg'), // Offline asset image
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: ListenableBuilder(
                                    listenable: espService,
                                    builder: (context, child) {
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _SensorValue(
                                            value: espService.isConnected 
                                                ? '${espService.suhu.toStringAsFixed(1)}°C' 
                                                : '-- °C', 
                                            label: 'Temp'
                                          ),
                                          _SensorValue(
                                            value: espService.isConnected 
                                                ? '${espService.kelembaban.toStringAsFixed(0)}%' 
                                                : '-- %', 
                                            label: 'RH'
                                          ),
                                          _SensorValue(
                                            value: espService.isConnected 
                                                ? '${espService.tvoc} ppb' 
                                                : '-- ppb', 
                                            label: 'TVOC'
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // TeaHarvest section card
                  GestureDetector(
                    onTap: () => setState(() => _selectedIndex = 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.grass, color: AppColors.primary, size: 20),
                            const SizedBox(width: 6),
                            Text(
                              'TeaHarvest',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: const DecorationImage(
                                    image: AssetImage('assets/teh.jpeg'), // Offline asset image
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    ),
                                  ),
                                  child: ListenableBuilder(
                                    listenable: espService,
                                    builder: (context, child) {
                                      final isCutterOn = espService.isConnected && espService.teaCutterActive;
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _SensorValue(
                                            value: espService.isConnected 
                                                ? (isCutterOn ? 'Aktif' : 'Mati') 
                                                : 'Offline', 
                                            label: 'Status'
                                          ),
                                          _SensorValue(
                                            value: espService.isConnected 
                                                ? '${espService.teaCutterSpeed}%' 
                                                : '--%', 
                                            label: 'Kecepatan'
                                          ),
                                          _SensorValue(
                                            value: espService.isConnected ? 'Lokal AP' : 'Terputus', 
                                            label: 'Koneksi'
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
  }
}

class _SensorValue extends StatelessWidget {
  final String value;
  final String label;

  const _SensorValue({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textGrey),
        ),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.grid_view_rounded,
            label: 'Dashboard',
            selected: selectedIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.inventory_2_outlined,
            label: 'CapsiBox',
            selected: selectedIndex == 1,
            onTap: () => onTap(1),
          ),
          _NavItem(
            icon: Icons.grass,
            label: 'Tea Harvest',
            selected: selectedIndex == 2,
            onTap: () => onTap(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textGrey;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
