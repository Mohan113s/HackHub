import 'package:firebase_database/firebase_database.dart';

/// Deletes hackathons that are 2 days past their event date
Future<void> deleteExpiredHackathons() async {
  try {
    final DatabaseReference ref = FirebaseDatabase.instance.ref().child('hackathons');
    final snapshot = await ref.get();

    if (!snapshot.exists) return;

    final Map<dynamic, dynamic> hackathons = snapshot.value as Map<dynamic, dynamic>;
    final now = DateTime.now();

    for (var entry in hackathons.entries) {
      final hackathonId = entry.key;
      final hackathonData = entry.value as Map<dynamic, dynamic>;

      // Get the event date
      final String? dateString = hackathonData['date'];
      
      if (dateString == null || dateString.isEmpty) continue;

      try {
        // Parse different date formats
        DateTime? eventDate = _parseDate(dateString);
        
        if (eventDate == null) continue;

        // Calculate days difference
        final difference = now.difference(eventDate).inDays;

        // Delete if event was more than 2 days ago
        if (difference > 2) {
          print("🗑️ Deleting expired hackathon: ${hackathonData['title']} ($hackathonId)");
          await ref.child(hackathonId).remove();
          
          // Also delete from favorites for all users
          await _deleteFromAllFavorites(hackathonId);
        }
      } catch (e) {
        print("⚠️ Error parsing date for hackathon $hackathonId: $e");
      }
    }
    
    print("✅ Cleanup completed successfully");
  } catch (e) {
    print("❌ Error during cleanup: $e");
  }
}

/// Parse date from various formats
DateTime? _parseDate(String dateString) {
  // Remove extra whitespace
  dateString = dateString.trim();

  // Try different date formats
  final formats = [
    // DD-MM-YYYY
    RegExp(r'^(\d{1,2})-(\d{1,2})-(\d{4})$'),
    // DD/MM/YYYY
    RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$'),
    // YYYY-MM-DD
    RegExp(r'^(\d{4})-(\d{1,2})-(\d{1,2})$'),
  ];

  for (var format in formats) {
    final match = format.firstMatch(dateString);
    if (match != null) {
      try {
        if (format.pattern.contains(r'^\d{4}')) {
          // YYYY-MM-DD format
          return DateTime(
            int.parse(match.group(1)!),
            int.parse(match.group(2)!),
            int.parse(match.group(3)!),
          );
        } else {
          // DD-MM-YYYY or DD/MM/YYYY format
          return DateTime(
            int.parse(match.group(3)!),
            int.parse(match.group(2)!),
            int.parse(match.group(1)!),
          );
        }
      } catch (e) {
        continue;
      }
    }
  }

  // Try ISO 8601 format (just in case)
  try {
    return DateTime.parse(dateString);
  } catch (e) {
    return null;
  }
}

/// Delete hackathon from all users' favorites
Future<void> _deleteFromAllFavorites(String hackathonId) async {
  try {
    final DatabaseReference favRef = FirebaseDatabase.instance.ref().child('favorites');
    final snapshot = await favRef.get();

    if (!snapshot.exists) return;

    final Map<dynamic, dynamic> users = snapshot.value as Map<dynamic, dynamic>;

    for (var userId in users.keys) {
      await favRef.child(userId).child(hackathonId).remove();
    }
    
    print("🗑️ Removed hackathon $hackathonId from all favorites");
  } catch (e) {
    print("⚠️ Error removing from favorites: $e");
  }
}