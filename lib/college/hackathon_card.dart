import 'package:flutter/material.dart';

class HackathonCard extends StatelessWidget {
  final String title;
  final String dateTime;
  final String location;
  final String prize;
  final String rules;
  final String link;

  const HackathonCard({
    super.key,
    required this.title,
    required this.dateTime,
    required this.location,
    required this.prize,
    required this.rules,
    required this.link,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),

          Row(children: [
            const Icon(Icons.calendar_today, size: 16),
            const SizedBox(width: 6),
            Text(dateTime),
          ]),

          Row(children: [
            const Icon(Icons.location_on, size: 16),
            const SizedBox(width: 6),
            Text(location),
          ]),

          Row(children: [
            const Icon(Icons.emoji_events, size: 16),
            const SizedBox(width: 6),
            Text("Prize: $prize"),
          ]),

          Row(children: [
            const Icon(Icons.rule, size: 16),
            const SizedBox(width: 6),
            Expanded(child: Text("Rules: $rules")),
          ]),

          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text("View Registration"),
            ),
          )
        ]),
      ),
    );
  }
}
