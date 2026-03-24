import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class HackathonDetailPage extends StatefulWidget {
  final Map<String, dynamic> event;

  const HackathonDetailPage({super.key, required this.event});

  @override
  State<HackathonDetailPage> createState() => _HackathonDetailPageState();
}

class _HackathonDetailPageState extends State<HackathonDetailPage> {
  bool isFavorite = false;
  bool isLoading = true;
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "guest";

  // HackHub Brand Colors
  static const Color primaryBlue = Color(0xFF1E3A8A);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFF60A5FA);

  @override
  void initState() {
    super.initState();
    print("DEBUG: Initializing HackathonDetailPage");
    print("DEBUG: User ID = $userId");
    print("DEBUG: Event data = ${widget.event}");
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      if (userId == "guest") {
        print("DEBUG: User not logged in");
        setState(() => isLoading = false);
        return;
      }

      final eventKey = widget.event['key'];
      print("DEBUG: Checking favorite status for event key = $eventKey");
      
      if (eventKey == null) {
        print("DEBUG: Event key is null");
        setState(() => isLoading = false);
        return;
      }

      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('favorites')
          .child(userId)
          .child(eventKey)
          .get();

      print("DEBUG: Favorite exists = ${snapshot.exists}");

      if (mounted) {
        setState(() {
          isFavorite = snapshot.exists;
          isLoading = false;
        });
      }
    } catch (e) {
      print("DEBUG: Error checking favorite status = $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      print("DEBUG: Toggle favorite called");
      
      if (userId == "guest" || FirebaseAuth.instance.currentUser == null) {
        print("DEBUG: User not authenticated");
        _showSnackBar("❌ Please sign in to add favorites", isError: true);
        return;
      }

      final eventKey = widget.event['key'];
      print("DEBUG: Event Key = $eventKey");
      print("DEBUG: User ID = $userId");
      
      if (eventKey == null) {
        print("DEBUG: Event key is null - cannot add to favorites");
        _showSnackBar("❌ Cannot add to favorites - missing event key", isError: true);
        return;
      }

      final favRef = FirebaseDatabase.instance
          .ref()
          .child('favorites')
          .child(userId)
          .child(eventKey);

      print("DEBUG: Firebase path = favorites/$userId/$eventKey");

      if (isFavorite) {
        print("DEBUG: Removing from favorites");
        await favRef.remove();
        setState(() => isFavorite = false);
        _showSnackBar("💔 Removed from favorites", isError: false);
        print("DEBUG: Successfully removed from favorites");
      } else {
        final dataToSave = {
          'title': widget.event['title'] ?? 'No Title',
          'date': widget.event['date'] ?? 'No Date',
          'poster': widget.event['poster'] ?? 
                    widget.event['image'] ?? 
                    widget.event['posterUrl'] ?? 
                    widget.event['imageUrl'] ?? '',
          'addedAt': DateTime.now().toIso8601String(),
        };
        
        print("DEBUG: Saving data = $dataToSave");
        
        await favRef.set(dataToSave);
        setState(() => isFavorite = true);
        _showSnackBar("❤️ Added to favorites!", isError: false);
        
        print("DEBUG: Save successful!");
        
        final verifySnapshot = await favRef.get();
        print("DEBUG: Verification - Data exists = ${verifySnapshot.exists}");
        print("DEBUG: Verification - Data = ${verifySnapshot.value}");
      }
    } on FirebaseException catch (e) {
      print("DEBUG: Firebase Error Code = ${e.code}");
      print("DEBUG: Firebase Error Message = ${e.message}");
      print("DEBUG: Firebase Error Details = ${e.toString()}");
      
      if (e.code == 'permission-denied') {
        _showSnackBar("❌ Permission denied. Please check Firebase rules.", isError: true);
      } else {
        _showSnackBar("❌ Firebase Error: ${e.message}", isError: true);
      }
    } catch (e) {
      print("DEBUG: General Error = $e");
      _showSnackBar("❌ Error: ${e.toString()}", isError: true);
    }
  }

  Future<void> _downloadPoster() async {
    try {
      final posterUrl = widget.event["poster"] ?? 
                        widget.event["image"] ?? 
                        widget.event["posterUrl"] ?? 
                        widget.event["imageUrl"] ?? "";

      if (posterUrl.isEmpty) {
        _showSnackBar("❌ No poster available to download", isError: true);
        return;
      }

      var status = await Permission.photos.request();
      
      if (!status.isGranted) {
        _showSnackBar("❌ Storage permission denied", isError: true);
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: accentBlue.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(accentBlue),
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Downloading poster...",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final response = await Dio().get(
        posterUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final tempDir = await getTemporaryDirectory();
      final fileName = 'hackathon_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response.data);

      await Gal.putImage(file.path, album: 'HackHub');

      await file.delete();

      if (mounted) Navigator.pop(context);

      _showSnackBar("✅ Poster saved to gallery!", isError: false);
    } catch (e) {
      print("DEBUG: Download error = $e");
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      _showSnackBar("❌ Download failed: ${e.toString()}", isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    final String posterUrl = widget.event["poster"] ?? 
                              widget.event["image"] ?? 
                              widget.event["posterUrl"] ?? 
                              widget.event["imageUrl"] ?? "";
    final String title = widget.event["title"] ?? "No Title";

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // App Bar with Poster Image
          SliverAppBar(
            expandedHeight: 450,
            pinned: true,
            backgroundColor: accentBlue,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: primaryBlue),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              // Download Button
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.download, color: primaryBlue),
                  onPressed: _downloadPoster,
                  tooltip: "Download Poster",
                ),
              ),
              // Favorite Button
              Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isLoading
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(accentBlue),
                          ),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : primaryBlue,
                        ),
                        onPressed: _toggleFavorite,
                        tooltip: isFavorite ? "Remove from favorites" : "Add to favorites",
                      ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Poster Image
                  posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: posterUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            color: Colors.grey.shade100,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(accentBlue),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [accentBlue, lightBlue],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.event,
                                  size: 100,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Event Poster",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accentBlue, lightBlue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event,
                                size: 100,
                                color: Colors.white.withOpacity(0.8),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Event Poster",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                  // Gradient Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Section
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryBlue.withOpacity(0.02),
                    lightBlue.withOpacity(0.02),
                    Colors.white,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: primaryBlue,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Info Cards
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickInfoCard(
                            Icons.calendar_today,
                            "Date",
                            widget.event["date"] ?? "TBA",
                            accentBlue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (widget.event["time"] != null)
                          Expanded(
                            child: _buildQuickInfoCard(
                              Icons.access_time,
                              "Time",
                              widget.event["time"],
                              Colors.orange.shade600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Location & Mode
                    Row(
                      children: [
                        if (widget.event["location"] != null)
                          Expanded(
                            child: _buildQuickInfoCard(
                              Icons.location_on,
                              "Location",
                              widget.event["location"],
                              Colors.red.shade600,
                            ),
                          ),
                        if (widget.event["location"] != null && widget.event["mode"] != null)
                          const SizedBox(width: 12),
                        if (widget.event["mode"] != null)
                          Expanded(
                            child: _buildQuickInfoCard(
                              Icons.computer,
                              "Mode",
                              widget.event["mode"],
                              Colors.purple.shade600,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Prize Section
                    if (widget.event["prize"] != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.amber.shade600, Colors.amber.shade800],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.4),
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
                                Icons.emoji_events,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Prize Pool",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.event["prize"],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // Description Section
                    if (widget.event["description"] != null) ...[
                      _buildSectionHeader("About This Event"),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.06),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.event["description"],
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            color: Colors.grey.shade800,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Rules Section
                    if (widget.event["rules"] != null) ...[
                      _buildSectionHeader("Rules & Guidelines"),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.orange.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.06),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.rule,
                                    color: Colors.orange.shade700,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "Important Rules",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.event["rules"],
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.7,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Eligibility Section
                    if (widget.event["eligibility"] != null) ...[
                      _buildSectionHeader("Eligibility"),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.06),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Who Can Participate",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: primaryBlue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.event["eligibility"],
                                    style: TextStyle(
                                      fontSize: 15,
                                      height: 1.7,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Event Details
                    _buildSectionHeader("Event Details"),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.06),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (widget.event["college"] != null ||
                              widget.event["organization"] != null)
                            _buildDetailRow(
                              Icons.school,
                              "Organized By",
                              widget.event["college"] ?? widget.event["organization"] ?? "",
                              accentBlue,
                            ),

                          if (widget.event["teamSize"] != null) ...[
                            const Divider(height: 32),
                            _buildDetailRow(
                              Icons.group,
                              "Team Size",
                              widget.event["teamSize"].toString(),
                              Colors.purple.shade600,
                            ),
                          ],

                          if (widget.event["registrationFee"] != null) ...[
                            const Divider(height: 32),
                            _buildDetailRow(
                              Icons.currency_rupee,
                              "Registration Fee",
                              widget.event["registrationFee"],
                              Colors.green.shade600,
                            ),
                          ],

                          if (widget.event["deadline"] != null) ...[
                            const Divider(height: 32),
                            _buildDetailRow(
                              Icons.event_available,
                              "Registration Deadline",
                              widget.event["deadline"],
                              Colors.red.shade600,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Contact Information
                    if (widget.event["contact"] != null ||
                        widget.event["email"] != null ||
                        widget.event["phone"] != null) ...[
                      _buildSectionHeader("Contact Information"),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryBlue.withOpacity(0.06),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (widget.event["contact"] != null)
                              _buildContactRow(
                                  Icons.person, "Contact Person", widget.event["contact"]),
                            if (widget.event["email"] != null) ...[
                              if (widget.event["contact"] != null) const Divider(height: 28),
                              _buildContactRow(Icons.email, "Email", widget.event["email"]),
                            ],
                            if (widget.event["phone"] != null) ...[
                              if (widget.event["contact"] != null || widget.event["email"] != null)
                                const Divider(height: 28),
                              _buildContactRow(Icons.phone, "Phone", widget.event["phone"]),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Glassmorphic Register Button
                    if (widget.event["registrationLink"] != null || widget.event["url"] != null)
                      Container(
                        width: double.infinity,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [accentBlue, lightBlue],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentBlue.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => _launchURL(
                            context,
                            widget.event["registrationLink"] ?? widget.event["url"],
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.app_registration, size: 26, color: Colors.white),
                              SizedBox(width: 12),
                              Text(
                                "Register Now",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accentBlue, lightBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 14),
        Text(
          title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: primaryBlue,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfoCard(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: accentBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accentBlue, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _launchURL(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      _showSnackBar("❌ No registration link available", isError: true);
      return;
    }

    try {
      String cleanUrl = url.trim();
      
      if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
        cleanUrl = 'https://$cleanUrl';
      }

      final uri = Uri.parse(cleanUrl);

      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched && context.mounted) {
        _showSnackBar("❌ Could not open the registration link", isError: true);
      }
    } catch (e) {
      _showSnackBar("❌ Error: ${e.toString()}", isError: true);
    }
  }
}