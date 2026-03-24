import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'package:hackhub/college/college_dashboard.dart';
import 'package:hackhub/college/college_profile_create.dart';
import 'package:hackhub/student/student_dashboard.dart';
import 'package:hackhub/student/student_profile_setup.dart';

/* ================= WRAPPER ================= */

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // ✅ Use authStateChanges for immediate login response
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Debug prints
        debugPrint("🔄 Wrapper - Connection State: ${authSnapshot.connectionState}");
        debugPrint("🔄 Has Data: ${authSnapshot.hasData}");
        debugPrint("🔄 User: ${authSnapshot.data?.email}");

        // 🔄 Auth loading
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ Not logged in
        if (!authSnapshot.hasData || authSnapshot.data == null) {
          debugPrint("❌ No user - showing login");
          return const LoginPageRedirect();
        }

        final user = authSnapshot.data!;
        debugPrint("✅ User logged in: ${user.email}");

        // ❌ Email not verified
        if (!user.emailVerified) {
          debugPrint("⚠️ Email not verified");
          return EmailVerificationScreen(user: user);
        }

        debugPrint("✅ Email verified - checking role");
        // ✅ Logged in & verified → check DB
        return RoleChecker(uid: user.uid);
      },
    );
  }
}

/* ================= EMAIL VERIFICATION ================= */

class EmailVerificationScreen extends StatelessWidget {
  final User user;
  const EmailVerificationScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.email_outlined, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text(
                "Verify your email",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                user.email ?? "",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              const Text(
                "We've sent a verification link to your email.\nPlease check your inbox and click the link.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await user.sendEmailVerification();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Verification email sent! Check your inbox."),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: $e"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.send),
                label: const Text("Resend Verification Email"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              OutlinedButton.icon(
                onPressed: () async {
                  await user.reload();
                  final currentUser = FirebaseAuth.instance.currentUser;

                  if (currentUser != null && currentUser.emailVerified) {
                    // ✅ Verified - sign out and go to login
                    await FirebaseAuth.instance.signOut();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Email verified! Please login to continue."),
                          backgroundColor: Colors.green,
                        ),
                      );

                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  } else {
                    // ❌ Not verified yet
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Email not verified yet. Please check your inbox."),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text("I have verified, Go to Login"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ================= ROLE CHECKER ================= */

class RoleChecker extends StatelessWidget {
  final String uid;
  const RoleChecker({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final dbRef = FirebaseDatabase.instance.ref("users/$uid");

    return StreamBuilder<DatabaseEvent>(
      stream: dbRef.onValue,
      builder: (context, snapshot) {
        debugPrint("🔄 RoleChecker - Connection State: ${snapshot.connectionState}");

        // 🔄 DB loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ❌ User removed from DB
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          debugPrint("❌ No user data in database");
          FirebaseAuth.instance.signOut();

          Future.microtask(() {
            if (context.mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            }
          });

          return const Scaffold(
            body: Center(child: Text("Session expired. Please login again.")),
          );
        }

        final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

        final role = data['role'];
        final profileCompleted = data['profileCompleted'] == true;

        debugPrint("✅ Role: $role, Profile Completed: $profileCompleted");

        // STUDENT
        if (role == "student") {
          return profileCompleted
              ? const StudentDashboard()
              : const StudentProfileSetup();
        }

        // COLLEGE
        if (role == "college") {
          return profileCompleted
              ? const CollegeDashboard()
              : const CollegeProfileCreate();
        }

        // Invalid role
        debugPrint("❌ Invalid role: $role");
        return const Scaffold(
          body: Center(
            child: Text("Invalid user role. Please contact support."),
          ),
        );
      },
    );
  }
}

/* ================= LOGIN REDIRECT ================= */

class LoginPageRedirect extends StatelessWidget {
  const LoginPageRedirect({super.key});

  @override
  Widget build(BuildContext context) {
    Future.microtask(() {
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}