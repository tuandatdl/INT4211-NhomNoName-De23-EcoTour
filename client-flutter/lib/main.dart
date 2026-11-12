import 'package:flutter/material.dart';
import 'screens/booking/suat_picker_screen.dart';
import 'screens/ticket/my_bookings_screen.dart';

void main() {
  runApp(const EcoTourClientApp());
}

class EcoTourClientApp extends StatelessWidget {
  const EcoTourClientApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoTour Cần Giờ Vũng Tàu - NhomNoName',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 2,
          centerTitle: true,
        ),
      ),
      home: const EcoTourHomeScreen(),
    );
  }
}

class EcoTourHomeScreen extends StatefulWidget {
  const EcoTourHomeScreen({super.key});

  @override
  State<EcoTourHomeScreen> createState() => _EcoTourHomeScreenState();
}

class _EcoTourHomeScreenState extends State<EcoTourHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    SuatPickerScreen(
      tourId: 1,
      tenTour: 'Tour 1: Khám phá Rừng Sác Cần Giờ - Đảo Khỉ 1 Ngày',
      giaNguoiLon: 650000,
      giaTreEm: 450000,
    ),
    MyBookingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      // Khung ứng dụng NavigationBar theo tiêu chí C.2.5
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _currentIndex = idx;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.travel_explore_outlined),
            selectedIcon: Icon(Icons.travel_explore, color: Colors.teal),
            label: 'Đặt Tour',
          ),
          NavigationDestination(
            icon: Icon(Icons.airplane_ticket_outlined),
            selectedIcon: Icon(Icons.airplane_ticket, color: Colors.teal),
            label: 'Đơn Của Tôi',
          ),
        ],
      ),
    );
  }
}
