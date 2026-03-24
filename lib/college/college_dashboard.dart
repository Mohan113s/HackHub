import 'package:flutter/material.dart';
import 'college_home.dart';
import 'add_hackathon.dart';
import 'college_profile_view.dart';
import 'package:hackhub/college/hackathon_cleanup.dart';

class CollegeDashboard extends StatefulWidget {
  const CollegeDashboard({super.key});

  @override
  State<CollegeDashboard> createState() => _CollegeDashboardState();
}

class _CollegeDashboardState extends State<CollegeDashboard> {
  int index = 0;

  late List<Widget> pages;

  @override
  void initState() {
    super.initState();

    // 🗑️ Auto-delete expired hackathons
    deleteExpiredHackathons();

    pages = [
      const CollegeHome(),
      AddHackathonPage(
        onPosted: () {
          // ✅ SAFE refresh & navigation
          setState(() => index = 0);
        },
      ),
      const CollegeProfileView(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: index,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: (i) => setState(() => index = i),
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF1E3A8A), // Navy blue from logo
          unselectedItemColor: const Color(0xFF94A3B8), // Muted blue-grey
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              activeIcon: Icon(Icons.home_rounded, size: 28),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle, size: 28),
              label: "Post",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_rounded),
              activeIcon: Icon(Icons.school_rounded, size: 28),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}