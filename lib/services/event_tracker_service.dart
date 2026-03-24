import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';

class EventTrackerService {
  static const String _lastEventCountKey = 'last_event_count';
  static const String _lastCheckTimeKey = 'last_check_time';

  /// Check if there are new events since last app open
  static Future<bool> hasNewEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCount = prefs.getInt(_lastEventCountKey) ?? 0;
      
      // Get current event count from Firebase
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child("hackathons")
          .once();
      
      final currentCount = snapshot.snapshot.children.length;
      
      // Check if there are new events
      return currentCount > lastCount;
    } catch (e) {
      print('Error checking new events: $e');
      return false;
    }
  }

  /// Update the stored event count after user has seen the notification
  static Future<void> updateEventCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current event count from Firebase
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child("hackathons")
          .once();
      
      final currentCount = snapshot.snapshot.children.length;
      
      // Store the current count
      await prefs.setInt(_lastEventCountKey, currentCount);
      await prefs.setInt(_lastCheckTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error updating event count: $e');
    }
  }

  /// Initialize event count on first install
  static Future<void> initializeEventCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Only initialize if not already set
      if (!prefs.containsKey(_lastEventCountKey)) {
        final snapshot = await FirebaseDatabase.instance
            .ref()
            .child("hackathons")
            .once();
        
        final currentCount = snapshot.snapshot.children.length;
        await prefs.setInt(_lastEventCountKey, currentCount);
        await prefs.setInt(_lastCheckTimeKey, DateTime.now().millisecondsSinceEpoch);
      }
    } catch (e) {
      print('Error initializing event count: $e');
    }
  }

  /// Reset tracking (useful for testing)
  static Future<void> resetTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastEventCountKey);
    await prefs.remove(_lastCheckTimeKey);
  }
}