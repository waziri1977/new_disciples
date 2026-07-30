// readiness_leaderboard.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReadinessLeaderboardScreen extends StatefulWidget {
  final Map userData;

  const ReadinessLeaderboardScreen({
    super.key,
    required this.userData,
  });

  @override
  State<ReadinessLeaderboardScreen> createState() =>
      _ReadinessLeaderboardScreenState();
}

class _ReadinessLeaderboardScreenState
    extends State<ReadinessLeaderboardScreen> {
  static const Color background = Color(0xFF070B14);
  static const Color card = Color(0xFF111827);
  static const Color gold = Color(0xFFFFC107);

  static const String apiUrl =
      'https://new-disciples.com/api/get_readiness_leaderboard.php';

  bool loading = true;
  String error = '';
  List<dynamic> contestants = [];
  Map<String, dynamic> currentUser = {};

  String get userId =>
      (widget.userData['id'] ?? widget.userData['user_id'] ?? '').toString();

  @override
  void initState() {
    super.initState();
    loadLeaderboard();
  }

  Future<void> loadLeaderboard() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = '';
      });
    }

    try {
      final uri = Uri.parse(
        '$apiUrl?user_id=${Uri.encodeQueryComponent(userId)}&limit=10',
      );

      final response = await http.get(
        uri,
        headers: const {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 20));

      final dynamic decoded = jsonDecode(response.body);

      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          decoded is! Map ||
          !(decoded['success'] == true || decoded['status'] == true)) {
        throw Exception(
          decoded is Map
              ? decoded['message']?.toString() ?? 'Unable to load leaderboard.'
              : 'Invalid leaderboard response.',
        );
      }

      if (!mounted) return;

      setState(() {
        contestants =
            decoded['leaderboard'] is List ? decoded['leaderboard'] : [];
        currentUser = decoded['current_user'] is Map
            ? Map<String, dynamic>.from(decoded['current_user'])
            : {};
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String imageUrl(dynamic picture) {
    final value = picture?.toString().trim() ?? '';

    if (value.isEmpty) return '';
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    return 'https://new-disciples.com/Indpic/${Uri.encodeComponent(value)}';
  }

  double asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          color: gold,
          backgroundColor: card,
          onRefresh: loadLeaderboard,
          child: loading
              ? _loading()
              : error.isNotEmpty
                  ? _error()
                  : _content(),
        ),
      ),
    );
  }

  Widget _loading() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 240),
        Center(child: CircularProgressIndicator(color: gold)),
      ],
    );
  }

  Widget _error() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 110),
        const Icon(Icons.cloud_off_rounded, color: Colors.redAccent, size: 54),
        const SizedBox(height: 16),
        Text(
          error,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white60, height: 1.5),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: loadLeaderboard,
          style: ElevatedButton.styleFrom(
            backgroundColor: gold,
            foregroundColor: Colors.black,
          ),
          child: const Text(
            'TRY AGAIN',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }

  Widget _content() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: [
        const Text(
          'Readiness Leaderboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 27,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ranking is based on the readiness scores managed through the Preparation Framework.',
          style: TextStyle(color: Colors.white54, height: 1.5),
        ),
        if (currentUser.isNotEmpty) ...[
          const SizedBox(height: 20),
          _currentUserCard(),
        ],
        const SizedBox(height: 24),
        ...List.generate(
          contestants.length,
          (index) => _contestantCard(
            Map<String, dynamic>.from(contestants[index] as Map),
          ),
        ),
      ],
    );
  }

  Widget _currentUserCard() {
    final score = asDouble(currentUser['readiness_score']);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          Text(
            '#${currentUser['rank'] ?? '-'}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR POSITION',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  currentUser['full_name']?.toString() ?? 'Contestant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            score.toStringAsFixed(0),
            style: const TextStyle(
              color: Colors.black,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _contestantCard(Map<String, dynamic> item) {
    final rank = int.tryParse(item['rank']?.toString() ?? '') ?? 0;
    final score = asDouble(item['readiness_score']);
    final isMe = item['is_current_user'] == true;
    final picture = imageUrl(item['picture']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isMe ? gold.withOpacity(0.11) : card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMe ? gold.withOpacity(0.45) : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              '#$rank',
              style: TextStyle(
                color: rank <= 3 ? gold : Colors.white54,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          CircleAvatar(
            radius: 23,
            backgroundColor: const Color(0xFF161B22),
            backgroundImage:
                picture.isEmpty ? null : NetworkImage(picture),
            child: picture.isEmpty
                ? const Icon(Icons.person_rounded, color: gold)
                : null,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['full_name']?.toString() ?? 'Contestant',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item['readiness_level'] ?? 'Starter'} • '
                  '${item['badge_count'] ?? 0} badge(s)',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            score.toStringAsFixed(0),
            style: const TextStyle(
              color: gold,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
