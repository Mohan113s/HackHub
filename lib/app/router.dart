import 'package:flutter/material.dart';
import 'package:hackhub/auth/wrapper.dart';

// AUTH
import '../auth/login_page.dart';
import '../auth/signup_option_page.dart';
import '../auth/student_signup.dart';
import '../auth/college_signup.dart';
import '../auth/forgot_password_page.dart'; // ✅ ADD THIS

// STUDENT
import '../student/student_profile_setup.dart';
import '../student/student_dashboard.dart';

// COLLEGE
import '../college/college_dashboard.dart';
import '../college/college_profile_create.dart';
import '../college/college_profile_view.dart';
import '../college/college_profile_edit.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {

      // ================= HOME =================
      case '/':
        return MaterialPageRoute(
          builder: (_) => const Wrapper(),
        );

      // ================= AUTH =================
      case '/login':
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );

      case '/signup-option':
        return MaterialPageRoute(
          builder: (_) => const SignupOptionPage(),
        );

      case '/student-signup':
        return MaterialPageRoute(
          builder: (_) => const StudentSignup(),
        );

      case '/college-signup':
        return MaterialPageRoute(
          builder: (_) => const CollegeSignup(),
        );

      // ✅ ADD THIS BLOCK
      case '/forgot-password':
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordPage(),
        );

      // ================= STUDENT =================
      case '/student-profile-setup':
        return MaterialPageRoute(
          builder: (_) => const StudentProfileSetup(),
        );

      case '/student-dashboard':
        return MaterialPageRoute(
          builder: (_) => const StudentDashboard(),
        );

      // ================= COLLEGE =================
      case '/college-dashboard':
        return MaterialPageRoute(
          builder: (_) => const CollegeDashboard(),
        );

      case '/college-profile-create':
        return MaterialPageRoute(
          builder: (_) => const CollegeProfileCreate(),
        );

      case '/college-profile-view':
        return MaterialPageRoute(
          builder: (_) => const CollegeProfileView(),
        );

      case '/college-profile-edit':
        return MaterialPageRoute(
          builder: (_) => const CollegeProfileEdit(),
        );

      // ================= DEFAULT =================
      default:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );
    }
  }
}