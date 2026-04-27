import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/router.dart';
import 'splash/splash_gif_screen.dart';

// ✅ ADD THIS (optional but good for direct usage)

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyB3uAgCEqnAS6-WsbVzlMfToMNr7gXas_4",
        authDomain: "hackhub-e5521.firebaseapp.com",
        databaseURL: "https://hackhub-e5521-default-rtdb.firebaseio.com",
        projectId: "hackhub-e5521",
        storageBucket: "hackhub-e5521.firebasestorage.app",
        messagingSenderId: "235564253996",
        appId: "1:235564253996:web:e121f90236749bdc4f2289",
        measurementId: "G-9YFL6GNXKH",
      ),
    );
  } else {
    await Firebase.initializeApp();

    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20;
  }

  runApp(const HackHub());
}

class HackHub extends StatelessWidget {
  const HackHub({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HackHub',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashGifScreen(),

      // ✅ ROUTING handled here
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}