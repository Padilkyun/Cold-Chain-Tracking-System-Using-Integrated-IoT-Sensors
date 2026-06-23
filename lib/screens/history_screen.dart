import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// HistoryScreen displays a list of recent sensor readings.
/// It follows the BinaPanen light theme and mirrors the design
/// language used across the app.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Dummy history data – replace with real data source as needed.
  static const _history = <Map<String, String>>[
    {
      'time': '10 menit yang lalu',
      'temp': '25.4°C',
      'humidity': '66%',
      'tvoc': '28 ppb',
    },
    {
      'time': '30 menit yang lalu',
      'temp': '25.1°C',
      'humidity': '65%',
      'tvoc': '30 ppb',
    },
    {
      'time': '1 jam yang lalu',
      'temp': '24.8°C',
      'humidity': '64%',
      'tvoc': '32 ppb',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Riwayat',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _history.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _history[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['time']!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Suhu: ${item['temp']}, RH: ${item['humidity']}, TVOC: ${item['tvoc']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.chevron_right, color: AppColors.textGrey),
              ],
            ),
          );
        },
      ),
    );
  }
}
