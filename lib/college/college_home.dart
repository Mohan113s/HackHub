import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'hackathon_cleanup.dart';
import 'edit_event_page.dart';

class CollegeHome extends StatefulWidget {
  const CollegeHome({super.key});

  @override
  State<CollegeHome> createState() => _CollegeHomeState();
}

class _CollegeHomeState extends State<CollegeHome> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final DatabaseReference ref =
      FirebaseDatabase.instance.ref().child("hackathons");

  @override
  void initState() {
    super.initState();
    deleteExpiredHackathons();
  }

  // Get responsive width constraint
  double _getMaxWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return 1200; // Desktop
    if (screenWidth > 800) return 800;   // Tablet
    return screenWidth;                   // Mobile
  }

  // Check if device is mobile
  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  // Delete event function
  Future<void> _deleteEvent(String eventKey, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Delete Event",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        content: Text(
          "Are you sure you want to delete '$title'?",
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF1E3A8A),
            ),
          ),
        );
      }

      await ref.child(eventKey).remove();

      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Event deleted successfully"),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: ${e.toString()}"),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _editEvent(Map<String, dynamic> event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventPage(
          eventKey: event['key'],
          eventData: event,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final maxWidth = _getMaxWidth(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: StreamBuilder<DatabaseEvent>(
        stream: ref.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 64,
                    color: Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Something went wrong",
                    style: TextStyle(
                      fontSize: 18,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            );
          }

          final data = snapshot.data?.snapshot.value;
          if (data == null) {
            return _buildEmptyState();
          }

          final Map<String, dynamic> map =
              Map<String, dynamic>.from(data as Map);

          final myPosts = map.entries
              .where((entry) {
                final eventData = Map<String, dynamic>.from(entry.value);
                return eventData["collegeId"] == uid;
              })
              .map((entry) => {
                    'key': entry.key,
                    ...Map<String, dynamic>.from(entry.value),
                  })
              .toList();

          if (myPosts.isEmpty) {
            return _buildEmptyState();
          }

          myPosts.sort((a, b) {
            final dateA = a['createdAt'] ?? '';
            final dateB = b['createdAt'] ?? '';
            return dateB.compareTo(dateA);
          });

          return Column(
            children: [
              // Header - Fixed at top
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  isMobile ? 16 : 24,
                  isMobile ? 12 : 20,
                  isMobile ? 16 : 24,
                  isMobile ? 12 : 20,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_note_rounded,
                            color: Colors.white,
                            size: isMobile ? 26 : 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Your Events",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isMobile ? 18 : 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${myPosts.length} event${myPosts.length == 1 ? '' : 's'} posted",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: isMobile ? 13 : 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Events List
              Expanded(
                child: Center(
                  child: Container(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: isMobile
                        ? ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: myPosts.length,
                            itemBuilder: (context, index) {
                              return _buildEventCard(myPosts[index], isMobile);
                            },
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.all(24),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: maxWidth > 900 ? 2 : 1,
                              childAspectRatio: 1.2,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                            ),
                            itemCount: myPosts.length,
                            itemBuilder: (context, index) {
                              return _buildEventCard(myPosts[index], false);
                            },
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isMobile = _isMobile(context);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24 : 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: isMobile ? 80 : 120,
              color: const Color(0xFFCBD5E1),
            ),
            SizedBox(height: isMobile ? 16 : 24),
            Text(
              "No Events Posted Yet",
              style: TextStyle(
                fontSize: isMobile ? 20 : 26,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              "Create your first event to get started!",
              style: TextStyle(
                fontSize: isMobile ? 14 : 18,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 24 : 32),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded),
              label: const Text("Create Event"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 40,
                  vertical: isMobile ? 14 : 18,
                ),
                textStyle: TextStyle(fontSize: isMobile ? 15 : 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, bool isMobile) {
    final String posterUrl = event["poster"] ?? 
                              event["image"] ?? 
                              event["posterUrl"] ?? 
                              event["imageUrl"] ?? "";
    final String title = event["title"] ?? "No Title";
    final String date = event["date"] ?? "Date TBA";
    final String eventKey = event["key"] ?? "";

    return Card(
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 0),
      elevation: 2,
      shadowColor: const Color(0xFF1E3A8A).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poster Image with fixed height
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: isMobile ? 200 : 250,
                  child: posterUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: posterUrl,
                          width: double.infinity,
                          height: isMobile ? 200 : 250,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: const Color(0xFFF1F5F9),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            print('Image load error: $error for URL: $url');
                            return Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1E3A8A),
                                    Color(0xFF3B82F6),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.event_rounded,
                                    size: isMobile ? 50 : 60,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Event Poster",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: isMobile ? 13 : 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFF1E3A8A),
                                Color(0xFF3B82F6),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_rounded,
                                size: isMobile ? 50 : 60,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Event Poster",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: isMobile ? 13 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),
              // Delete Button
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_rounded,
                      color: Colors.white,
                      size: isMobile ? 20 : 22,
                    ),
                    onPressed: () => _deleteEvent(eventKey, title),
                    tooltip: "Delete Event",
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            ],
          ),
          // Event Details
          Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCE9FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        size: isMobile ? 14 : 16,
                        color: const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Event Date",
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 11,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (event["mode"] != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 10 : 12,
                          vertical: isMobile ? 5 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6366F1)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.computer_rounded,
                              size: isMobile ? 12 : 14,
                              color: const Color(0xFF4F46E5),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event["mode"],
                              style: TextStyle(
                                fontSize: isMobile ? 11 : 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (event["prize"] != null)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 10 : 12,
                          vertical: isMobile ? 5 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emoji_events_rounded,
                              size: isMobile ? 12 : 14,
                              color: const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                event["prize"],
                                style: TextStyle(
                                  fontSize: isMobile ? 11 : 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD97706),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editEvent(event),
                        icon: Icon(Icons.edit_rounded, size: isMobile ? 16 : 18),
                        label: Text(
                          "Edit",
                          style: TextStyle(fontSize: isMobile ? 13 : 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E3A8A),
                          side: const BorderSide(color: Color(0xFF1E3A8A)),
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showEventDetails(event),
                        icon: Icon(Icons.visibility_rounded, size: isMobile ? 16 : 18),
                        label: Text(
                          "View",
                          style: TextStyle(fontSize: isMobile ? 13 : 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: isMobile ? 10 : 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEventDetails(Map<String, dynamic> event) {
    final isMobile = _isMobile(context);
    final posterUrl = event["poster"] ?? 
                      event["image"] ?? 
                      event["posterUrl"] ?? 
                      event["imageUrl"] ?? "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    isMobile ? 20 : 32,
                    0,
                    isMobile ? 20 : 32,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Poster
                      if (posterUrl.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: CachedNetworkImage(
                            imageUrl: posterUrl,
                            width: double.infinity,
                            height: isMobile ? 200 : 300,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              height: isMobile ? 200 : 300,
                              color: const Color(0xFFF1F5F9),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              height: isMobile ? 200 : 300,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.event, size: 64, color: Colors.white70),
                              ),
                            ),
                          ),
                        ),
                      
                      SizedBox(height: isMobile ? 16 : 20),
                      // Title
                      Text(
                        event["title"] ?? "No Title",
                        style: TextStyle(
                          fontSize: isMobile ? 22 : 26,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                          height: 1.2,
                        ),
                      ),
                      
                      SizedBox(height: isMobile ? 20 : 24),
                      // Key Info Cards
                      Row(
                        children: [
                          if (event["mode"] != null)
                            Expanded(
                              child: _buildInfoCard(
                                Icons.computer_rounded,
                                "Mode",
                                event["mode"],
                                const Color(0xFF6366F1),
                                const Color(0xFFE0E7FF),
                                isMobile,
                              ),
                            ),
                          if (event["mode"] != null && event["prize"] != null)
                            const SizedBox(width: 12),
                          if (event["prize"] != null)
                            Expanded(
                              child: _buildInfoCard(
                                Icons.emoji_events_rounded,
                                "Prize Pool",
                                event["prize"],
                                const Color(0xFFF59E0B),
                                const Color(0xFFFEF3C7),
                                isMobile,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 20 : 24),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                      SizedBox(height: isMobile ? 20 : 24),
                      // Event Details Section
                      Text(
                        "Event Details",
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(Icons.calendar_today_rounded, "Date", event["date"], isMobile),
                      _buildDetailRow(Icons.access_time_rounded, "Time", event["time"], isMobile),
                      _buildDetailRow(Icons.location_on_rounded, "Location", event["location"], isMobile),
                      _buildDetailRow(Icons.groups_rounded, "Team Size", event["teamSize"]?.toString(), isMobile),
                      _buildDetailRow(Icons.payment_rounded, "Registration Fee", event["registrationFee"], isMobile),
                      
                      if (event["description"] != null && event["description"].toString().isNotEmpty) ...[
                        SizedBox(height: isMobile ? 20 : 24),
                        const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                        SizedBox(height: isMobile ? 20 : 24),
                        _buildSectionWithContent("📝 Description", event["description"], isMobile),
                      ],
                      if (event["rules"] != null && event["rules"].toString().isNotEmpty) ...[
                        SizedBox(height: isMobile ? 20 : 24),
                        _buildSectionWithContent("📋 Rules & Guidelines", event["rules"], isMobile),
                      ],
                      if (event["eligibility"] != null && event["eligibility"].toString().isNotEmpty) ...[
                        SizedBox(height: isMobile ? 20 : 24),
                        _buildSectionWithContent("✅ Eligibility Criteria", event["eligibility"], isMobile),
                      ],
                      
                      SizedBox(height: isMobile ? 20 : 24),
                      const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                      SizedBox(height: isMobile ? 20 : 24),
                      // Contact Information
                      Text(
                        "Contact Information",
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (event["contact"] != null)
                        _buildContactRow(Icons.person_rounded, "Contact Person", event["contact"], isMobile),
                      if (event["email"] != null)
                        _buildContactRow(Icons.email_rounded, "Email", event["email"], isMobile, isEmail: true),
                      if (event["phone"] != null)
                        _buildContactRow(Icons.phone_rounded, "Phone", event["phone"], isMobile, isPhone: true),
                      // Registration Link
                      if (event["registrationLink"] != null && event["registrationLink"].toString().isNotEmpty) ...[
                        SizedBox(height: isMobile ? 20 : 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _launchURL(event["registrationLink"]),
                            icon: const Icon(Icons.app_registration_rounded),
                            label: const Text("Open Registration Link"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: isMobile ? 14 : 16),
                              textStyle: TextStyle(
                                fontSize: isMobile ? 15 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value, Color iconColor, Color bgColor, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: isMobile ? 20 : 24, color: iconColor),
          SizedBox(height: isMobile ? 6 : 8),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: iconColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value, bool isMobile) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: const Color(0xFFDCE9FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: isMobile ? 18 : 20, color: const Color(0xFF1E3A8A)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isMobile ? 15 : 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionWithContent(String title, String content, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(isMobile ? 14 : 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            content,
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              color: const Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactRow(IconData icon, String label, String value, bool isMobile, {bool isEmail = false, bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          if (isEmail) {
            _launchURL("mailto:$value");
          } else if (isPhone) {
            _launchURL("tel:$value");
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 10 : 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE9FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: isMobile ? 18 : 20, color: const Color(0xFF1E3A8A)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: isMobile ? 14 : 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              if (isEmail || isPhone)
                Icon(
                  isEmail ? Icons.mail_outline : Icons.phone_outlined,
                  size: isMobile ? 18 : 20,
                  color: const Color(0xFF64748B),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not open: $url"),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}