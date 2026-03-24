import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hackhub/hackathon_detail_page.dart';

class FavoriteEvents extends StatefulWidget {
  const FavoriteEvents({super.key});

  @override
  State<FavoriteEvents> createState() => _FavoriteEventsState();
}

class _FavoriteEventsState extends State<FavoriteEvents> with SingleTickerProviderStateMixin {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "guest";
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  // HackHub Brand Colors
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFF60A5FA);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _removeFavorite(String eventKey) async {
    try {
      await FirebaseDatabase.instance
          .ref()
          .child('favorites')
          .child(userId)
          .child(eventKey)
          .remove();

      if (mounted) {
        _showSnackBar("💔 Removed from favorites", isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Error: ${e.toString()}", isError: true);
      }
    }
  }

  Future<void> _openEventDetail(Map<String, dynamic> favorite) async {
    try {
      final eventKey = favorite['key'];
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('hackathons')
          .child(eventKey)
          .get();

      if (snapshot.exists && mounted) {
        final eventData = Map<String, dynamic>.from(snapshot.value as Map);
        eventData['key'] = eventKey;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HackathonDetailPage(event: eventData),
          ),
        );
      } else {
        if (mounted) {
          _showSnackBar("⚠️ Event details not available", isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Error: ${e.toString()}", isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId == "guest") {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryBlue.withOpacity(0.05),
                lightBlue.withOpacity(0.05),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accentBlue.withOpacity(0.2), lightBlue.withOpacity(0.2)],
                      ),
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 60,
                      color: accentBlue,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "Sign in Required",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Please sign in to view your\nfavorite events",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryBlue.withOpacity(0.05),
              lightBlue.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<DatabaseEvent>(
            stream: FirebaseDatabase.instance
                .ref()
                .child('favorites')
                .child(userId)
                .onValue,
            builder: (context, snapshot) {
              // Error state
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.red.shade300, Colors.red.shade400],
                          ),
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          size: 50,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Oops! Something went wrong",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(accentBlue),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Loading favorites...",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final data = snapshot.data?.snapshot.value;

              // Parse favorites
              List<Map<String, dynamic>> favorites = [];

              if (data != null && data is Map) {
                data.forEach((key, value) {
                  Map<String, dynamic> favoriteData = {'key': key.toString()};

                  if (value is Map) {
                    value.forEach((k, v) {
                      favoriteData[k.toString()] = v;
                    });
                  }

                  favorites.add(favoriteData);
                });
              }

              // Sort by date (newest first)
              favorites.sort((a, b) {
                final aDate = a['addedAt']?.toString() ?? '';
                final bDate = b['addedAt']?.toString() ?? '';
                return bDate.compareTo(aDate);
              });

              // Empty state
              if (favorites.isEmpty) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [accentBlue.withOpacity(0.2), lightBlue.withOpacity(0.2)],
                            ),
                          ),
                          child: Icon(
                            Icons.favorite_border,
                            size: 60,
                            color: accentBlue,
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          "No Favorites Yet",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Start adding events to\nyour favorites!",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tap the ❤️ icon on any event",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Display favorites
              return FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accentBlue, lightBlue],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentBlue.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Favorite Events",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                "${favorites.length} ${favorites.length == 1 ? 'Event' : 'Events'} Saved",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // List of favorites
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final fav = favorites[index];
                          final eventKey = fav['key']?.toString() ?? '';
                          final title = fav['title']?.toString() ?? 'No Title';
                          final date = fav['date']?.toString() ?? 'No Date';
                          final poster = fav['poster']?.toString() ?? '';

                          return Dismissible(
                            key: Key(eventKey),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.red.shade400, Colors.red.shade600],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Remove",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Icon(
                                          Icons.warning_amber_rounded,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        "Remove Favorite?",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: Text(
                                    "Are you sure you want to remove '$title' from your favorites?",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      height: 1.5,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text(
                                        "Cancel",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.red.shade400, Colors.red.shade600],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: const Text(
                                          "Remove",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) {
                              _removeFavorite(eventKey);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryBlue.withOpacity(0.08),
                                    blurRadius: 15,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _openEventDetail(fav),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        // Event Poster
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: poster.isNotEmpty
                                              ? CachedNetworkImage(
                                                  imageUrl: poster,
                                                  width: 90,
                                                  height: 90,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) => Container(
                                                    width: 90,
                                                    height: 90,
                                                    color: Colors.grey.shade100,
                                                    child: Center(
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(accentBlue),
                                                      ),
                                                    ),
                                                  ),
                                                  errorWidget: (context, url, error) => Container(
                                                    width: 90,
                                                    height: 90,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [accentBlue, lightBlue],
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                      ),
                                                    ),
                                                    child: const Icon(
                                                      Icons.event,
                                                      color: Colors.white,
                                                      size: 40,
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  width: 90,
                                                  height: 90,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [accentBlue, lightBlue],
                                                      begin: Alignment.topLeft,
                                                      end: Alignment.bottomRight,
                                                    ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.event,
                                                    color: Colors.white,
                                                    size: 40,
                                                  ),
                                                ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Event Details
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 16,
                                                  color: primaryBlue,
                                                  letterSpacing: -0.3,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: lightBlue.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today,
                                                      size: 14,
                                                      color: accentBlue,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Flexible(
                                                      child: Text(
                                                        date,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: accentBlue,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Favorite Icon
                                        Container(
                                          margin: const EdgeInsets.only(left: 8),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.red.shade50,
                                          ),
                                          child: IconButton(
                                            icon: const Icon(
                                              Icons.favorite,
                                              color: Colors.red,
                                              size: 24,
                                            ),
                                            onPressed: () => _removeFavorite(eventKey),
                                            tooltip: "Remove from favorites",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}