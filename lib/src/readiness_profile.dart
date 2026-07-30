// readiness_profile.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReadinessProfileScreen extends StatefulWidget {
  final Map userData;

  const ReadinessProfileScreen({
    super.key,
    required this.userData,
  });

  @override
  State<ReadinessProfileScreen> createState() =>
      _ReadinessProfileScreenState();
}

class _ReadinessProfileScreenState
    extends State<ReadinessProfileScreen> {
  static const Color backgroundColor = Color(0xFF070B14);
  static const Color cardColor = Color(0xFF111827);
  static const Color secondaryCardColor = Color(0xFF161B22);
  static const Color goldColor = Color(0xFFFFC107);

  final String readinessApi =
      'https://new-disciples.com/api/get_readiness_profile.php';

  bool isLoading = true;
  bool isRefreshing = false;
  String errorMessage = '';

  Map<String, dynamic> readinessProfile = {};
  Map<String, dynamic> userProfile = {};
  Map<String, dynamic> breakdown = {};
  List<dynamic> badges = [];
  List<dynamic> availableBadges = [];
  List<dynamic> recommendations = [];
  List<dynamic> scoreHistory = [];
  Map<String, dynamic> leaderboard = {};
  Map<String, dynamic> readinessStats = {};

  @override
  void initState() {
    super.initState();
    fetchReadinessProfile();
  }

  ////////////////////////////////////////////////////////////
  /// FETCH READINESS PROFILE
  ////////////////////////////////////////////////////////////

  Future<void> fetchReadinessProfile({
    bool showRefreshIndicator = false,
  }) async {
    final dynamic rawUserId =
        widget.userData['id'] ?? widget.userData['user_id'];

    final String userId = rawUserId?.toString() ?? '';

    if (userId.isEmpty) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshing = false;
        errorMessage = 'Unable to identify the current contestant.';
      });

      return;
    }

    if (showRefreshIndicator && mounted) {
      setState(() {
        isRefreshing = true;
      });
    }

    try {
      final Uri uri = Uri.parse(
        '$readinessApi?user_id=${Uri.encodeQueryComponent(userId)}',
      );

      final http.Response response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 20),
      );

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Server returned status ${response.statusCode}.',
        );
      }

      final dynamic decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'The readiness server returned an invalid response.',
        );
      }

      final bool success =
          decoded['status'] == true || decoded['success'] == true;

      if (!success) {
        throw Exception(
          decoded['message']?.toString() ??
              'Unable to load the readiness profile.',
        );
      }

      final dynamic profileData = decoded['profile'];

      if (profileData is Map<String, dynamic>) {
        readinessProfile = profileData;
      } else {
        readinessProfile = {};
      }

      userProfile = _asMap(
        readinessProfile['user'],
      );

      breakdown = _asMap(
        readinessProfile['breakdown'],
      );

      badges = _asList(
        readinessProfile['badges'],
      );

      availableBadges = _asList(
        readinessProfile['available_badges'],
      );

      scoreHistory = _asList(
        readinessProfile['history'],
      );

      leaderboard = _asMap(
        readinessProfile['leaderboard'],
      );

      readinessStats = _asMap(
        readinessProfile['stats'],
      );

      recommendations = _asList(
        readinessProfile['recommendations'],
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshing = false;
        errorMessage = '';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshing = false;
        errorMessage = _cleanError(error);
      });
    }
  }

  ////////////////////////////////////////////////////////////
  /// HELPERS
  ////////////////////////////////////////////////////////////

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return {};
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) {
      return value;
    }

    return [];
  }

  String _cleanError(Object error) {
    return error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('FormatException: ', '');
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  double _clampScore(double score) {
    if (score < 0) return 0;
    if (score > 100) return 100;
    return score;
  }

  String _readinessLevel(double score) {
    final String apiLevel =
        userProfile['readiness_level']?.toString().trim() ??
            readinessProfile['level']?.toString().trim() ??
            '';

    if (apiLevel.isNotEmpty) {
      return apiLevel;
    }

    if (score >= 95) return 'Ambassador';
    if (score >= 80) return 'Advanced';
    if (score >= 60) return 'Prepared';
    if (score >= 40) return 'Active';
    if (score >= 20) return 'Emerging';

    return 'Starter';
  }

  double _nextThreshold(double score) {
    if (score < 20) return 20;
    if (score < 40) return 40;
    if (score < 60) return 60;
    if (score < 80) return 80;
    if (score < 95) return 95;

    return 100;
  }

  String _nextLevelName(double score) {
    if (score < 20) return 'Emerging';
    if (score < 40) return 'Active';
    if (score < 60) return 'Prepared';
    if (score < 80) return 'Advanced';
    if (score < 95) return 'Ambassador';

    return 'Maximum Level';
  }

  String _lastUpdatedText() {
    final dynamic value =
        userProfile['readiness_updated_at'] ??
            readinessProfile['updated_at'] ??
            breakdown['calculated_at'];

    if (value == null || value.toString().trim().isEmpty) {
      return 'Not calculated yet';
    }

    final String rawValue = value.toString();

    try {
      final DateTime date =
          DateTime.parse(rawValue).toLocal();

      return '${_twoDigits(date.day)}/'
          '${_twoDigits(date.month)}/'
          '${date.year} '
          '${_twoDigits(date.hour)}:'
          '${_twoDigits(date.minute)}';
    } catch (_) {
      return rawValue;
    }
  }

  String _twoDigits(int value) {
    return value.toString().padLeft(2, '0');
  }

  String _displayName() {
    return userProfile['full_name']?.toString() ??
        widget.userData['full_name']?.toString() ??
        'Contestant';
  }

  String _pictureUrl() {
    return userProfile['picture']?.toString() ??
        widget.userData['picture']?.toString() ??
        '';
  }

  double _finalScore() {
    return _clampScore(
      _toDouble(
        userProfile['readiness_score'] ??
            readinessProfile['score'] ??
            breakdown['final_score'],
      ),
    );
  }

  List<Map<String, dynamic>> _scoreCategories() {
    return [
      {
        'title': 'Social Engagement',
        'subtitle': 'Verified interactions on official social channels',
        'score': _clampScore(
          _toDouble(
            breakdown['social_score'],
          ),
        ),
        'icon': Icons.public_rounded,
      },
      {
        'title': 'In-App Participation',
        'subtitle': 'Activity inside the New Disciples application',
        'score': _clampScore(
          _toDouble(
            breakdown['app_score'],
          ),
        ),
        'icon': Icons.phone_android_rounded,
      },
      {
        'title': 'Contest Preparation',
        'subtitle': 'Completion of preparation and learning activities',
        'score': _clampScore(
          _toDouble(
            breakdown['preparation_score'],
          ),
        ),
        'icon': Icons.menu_book_rounded,
      },
      {
        'title': 'Community Conduct',
        'subtitle': 'Positive and responsible community behaviour',
        'score': _clampScore(
          _toDouble(
            breakdown['conduct_score'],
          ),
        ),
        'icon': Icons.handshake_rounded,
      },
      {
        'title': 'Consistency',
        'subtitle': 'Regular engagement over time',
        'score': _clampScore(
          _toDouble(
            breakdown['consistency_score'],
          ),
        ),
        'icon': Icons.calendar_month_rounded,
      },
    ];
  }

  ////////////////////////////////////////////////////////////
  /// BUILD
  ////////////////////////////////////////////////////////////

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: goldColor,
          backgroundColor: secondaryCardColor,
          onRefresh: () {
            return fetchReadinessProfile(
              showRefreshIndicator: true,
            );
          },
          child: isLoading
              ? _buildLoadingView()
              : errorMessage.isNotEmpty
                  ? _buildErrorView()
                  : _buildProfileView(),
        ),
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// LOADING
  ////////////////////////////////////////////////////////////

  Widget _buildLoadingView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 180),
        Center(
          child: CircularProgressIndicator(
            color: goldColor,
          ),
        ),
        SizedBox(height: 18),
        Center(
          child: Text(
            'Loading readiness profile...',
            style: TextStyle(
              color: Colors.white54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  ////////////////////////////////////////////////////////////
  /// ERROR
  ////////////////////////////////////////////////////////////

  Widget _buildErrorView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.red.withOpacity(0.25),
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Unable to Load Readiness',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: isRefreshing
                      ? null
                      : () {
                          fetchReadinessProfile(
                            showRefreshIndicator: true,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: goldColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  icon: isRefreshing
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                        ),
                  label: const Text(
                    'TRY AGAIN',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  ////////////////////////////////////////////////////////////
  /// PROFILE VIEW
  ////////////////////////////////////////////////////////////

  Widget _buildProfileView() {
    final double score = _finalScore();
    final String level = _readinessLevel(score);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(
        20,
        18,
        20,
        110,
      ),
      children: [
        _buildPageHeader(),
        const SizedBox(height: 22),
        _buildMainScoreCard(
          score: score,
          level: level,
        ),
        const SizedBox(height: 22),
        _buildNextLevelCard(score),
        const SizedBox(height: 16),
        _buildLiveSummaryCard(),
        const SizedBox(height: 26),
        _buildSectionTitle(
          title: 'Readiness Breakdown',
          subtitle:
              'Your current performance across all preparation categories.',
        ),
        const SizedBox(height: 14),
        ..._scoreCategories().map(
          (category) => Padding(
            padding: const EdgeInsets.only(
              bottom: 14,
            ),
            child: _buildCategoryCard(category),
          ),
        ),
        const SizedBox(height: 12),
        _buildSectionTitle(
          title: 'Recognition Badges',
          subtitle:
              'Badges earned through verified engagement and preparation.',
        ),
        const SizedBox(height: 14),
        _buildBadgesSection(),
        if (availableBadges.isNotEmpty) ...[
          const SizedBox(height: 20),
          _buildAvailableBadgesSection(),
        ],
        const SizedBox(height: 26),
        _buildSectionTitle(
          title: 'Recommended Actions',
          subtitle:
              'Complete these activities to strengthen your readiness profile.',
        ),
        const SizedBox(height: 14),
        _buildRecommendationsSection(score),
        const SizedBox(height: 22),
        _buildVisibilityNotice(score),
        const SizedBox(height: 18),
        _buildLastUpdatedCard(),
      ],
    );
  }

  ////////////////////////////////////////////////////////////
  /// HEADER
  ////////////////////////////////////////////////////////////

  Widget _buildPageHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Preparation Framework',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your dynamic readiness and community engagement profile.',
                style: TextStyle(
                  color: Colors.white54,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: secondaryCardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            tooltip: 'Refresh readiness profile',
            onPressed: isRefreshing
                ? null
                : () {
                    fetchReadinessProfile(
                      showRefreshIndicator: true,
                    );
                  },
            icon: isRefreshing
                ? const SizedBox(
                    width: 19,
                    height: 19,
                    child: CircularProgressIndicator(
                      color: goldColor,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.refresh_rounded,
                    color: goldColor,
                  ),
          ),
        ),
      ],
    );
  }

  ////////////////////////////////////////////////////////////
  /// MAIN SCORE CARD
  ////////////////////////////////////////////////////////////

  Widget _buildMainScoreCard({
    required double score,
    required String level,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD54F),
            Color(0xFFFFB300),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: goldColor.withOpacity(0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildProfilePicture(),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _displayName(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'REGISTERED CONTESTANT',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  level.toUpperCase(),
                  style: const TextStyle(
                    color: goldColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 116,
                    height: 116,
                    child: CircularProgressIndicator(
                      value: score / 100,
                      strokeWidth: 12,
                      backgroundColor: Colors.black12,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
                        Colors.black,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        score.toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'OUT OF 100',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT READINESS',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      level,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _levelDescription(level),
                      style: const TextStyle(
                        color: Colors.black87,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePicture() {
    final String pictureUrl = _pictureUrl();

    return Container(
      width: 60,
      height: 60,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: Colors.black,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: pictureUrl.isEmpty
            ? Container(
                color: secondaryCardColor,
                child: const Icon(
                  Icons.person_rounded,
                  color: goldColor,
                  size: 32,
                ),
              )
            : Image.network(
                pictureUrl,
                fit: BoxFit.cover,
                errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                ) {
                  return Container(
                    color: secondaryCardColor,
                    child: const Icon(
                      Icons.person_rounded,
                      color: goldColor,
                      size: 32,
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _levelDescription(String level) {
    switch (level.toLowerCase()) {
      case 'ambassador':
        return 'Exceptional preparation and verified community contribution.';
      case 'advanced':
        return 'Strong engagement and dependable participation.';
      case 'prepared':
        return 'You are showing solid readiness for greater visibility.';
      case 'active':
        return 'Your engagement is growing consistently.';
      case 'emerging':
        return 'You are beginning to build a visible preparation record.';
      default:
        return 'Complete verified activities to begin improving your profile.';
    }
  }

  ////////////////////////////////////////////////////////////
  /// NEXT LEVEL
  ////////////////////////////////////////////////////////////

  Widget _buildNextLevelCard(double score) {
    final double nextThreshold = _nextThreshold(score);
    final String nextLevel = _nextLevelName(score);
    final double remaining =
        (nextThreshold - score).clamp(0, 100).toDouble();

    final double progressToNext =
        nextThreshold <= 0
            ? 1
            : (score / nextThreshold).clamp(0, 1).toDouble();

    final bool maximumReached = score >= 100;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: goldColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  color: goldColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      maximumReached
                          ? 'Highest level achieved'
                          : 'Next level: $nextLevel',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      maximumReached
                          ? 'Maintain verified participation to retain your recognition.'
                          : '${remaining.toStringAsFixed(0)} more readiness points required.',
                      style: const TextStyle(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: maximumReached ? 1 : progressToNext,
              backgroundColor: Colors.white10,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(
                goldColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// SECTION TITLE
  ////////////////////////////////////////////////////////////

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.white54,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  ////////////////////////////////////////////////////////////
  /// CATEGORY CARD
  ////////////////////////////////////////////////////////////

  Widget _buildCategoryCard(
    Map<String, dynamic> category,
  ) {
    final double score =
        _clampScore(_toDouble(category['score']));

    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.045),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: goldColor.withOpacity(0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              category['icon'] as IconData,
              color: goldColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        category['title'].toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${score.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: goldColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  category['subtitle'].toString(),
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: score / 100,
                    backgroundColor: Colors.white10,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(
                      goldColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ////////////////////////////////////////////////////////////
  /// BADGES
  ////////////////////////////////////////////////////////////

  Widget _buildBadgesSection() {
    if (badges.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.workspace_premium_outlined,
              color: Colors.white30,
              size: 42,
            ),
            SizedBox(height: 12),
            Text(
              'No readiness badges earned yet',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Complete verified activities to unlock community recognition.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white38,
                height: 1.5,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: badges.map(
        (dynamic item) {
          final Map<String, dynamic> badge =
              _asMap(item);

          final String name =
              badge['badge_name']?.toString() ??
                  badge['name']?.toString() ??
                  'Achievement';

          return Container(
            width:
                (MediaQuery.of(context).size.width - 52) / 2,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: goldColor.withOpacity(0.12),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: goldColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: goldColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        },
      ).toList(),
    );
  }

  ////////////////////////////////////////////////////////////
  /// RECOMMENDATIONS
  ////////////////////////////////////////////////////////////

  Widget _buildRecommendationsSection(double score) {
    final List<String> items = recommendations.isNotEmpty
        ? recommendations
            .map(
              (dynamic item) {
                if (item is Map) {
                  return item['title']?.toString() ??
                      item['message']?.toString() ??
                      item['recommendation']?.toString() ??
                      '';
                }

                return item.toString();
              },
            )
            .where(
              (String item) => item.trim().isNotEmpty,
            )
            .toList()
        : _defaultRecommendations(score);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: List.generate(
          items.length,
          (int index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                    index == items.length - 1 ? 0 : 17,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 31,
                    height: 31,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: goldColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: goldColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      items[index],
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.55,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  List<String> _defaultRecommendations(double score) {
    if (score >= 95) {
      return [
        'Maintain consistent verified participation across official channels.',
        'Support other contestants through positive community engagement.',
        'Continue completing preparation activities before their deadlines.',
      ];
    }

    if (score >= 60) {
      return [
        'Complete more verified social engagement activities.',
        'Participate consistently in official New Disciples live sessions.',
        'Submit every eligible question and preparation task on time.',
      ];
    }

    return [
      'Connect and verify at least one approved social media account.',
      'Engage meaningfully with official New Disciples posts.',
      'Complete your profile and all available preparation activities.',
      'Participate regularly inside the mobile application.',
    ];
  }

  ////////////////////////////////////////////////////////////
  /// VISIBILITY NOTICE
  ////////////////////////////////////////////////////////////

  Widget _buildVisibilityNotice(double score) {
    final bool eligible = score >= 60;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: eligible
            ? const Color(0xFF0F2E24)
            : secondaryCardColor,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: eligible
              ? Colors.green.withOpacity(0.25)
              : goldColor.withOpacity(0.10),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            eligible
                ? Icons.visibility_rounded
                : Icons.visibility_outlined,
            color: eligible ? Colors.greenAccent : goldColor,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eligible
                      ? 'Featured visibility eligible'
                      : 'Build your community visibility',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  eligible
                      ? 'Your readiness profile currently meets the recommended visibility threshold. Final visibility may still depend on profile completion and community conduct.'
                      : 'Reach at least 60 readiness points to become eligible for enhanced visibility. Examination performance and jury evaluation remain separate progression requirements.',
                  style: const TextStyle(
                    color: Colors.white54,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildLiveSummaryCard() {
    final int rank =
        int.tryParse(leaderboard['rank']?.toString() ?? '') ?? 0;
    final int total =
        int.tryParse(leaderboard['total_contestants']?.toString() ?? '') ?? 0;

    final List<Map<String, String>> values = [
      {
        'label': 'Rank',
        'value': rank > 0 ? '#$rank/$total' : '—',
      },
      {
        'label': 'Badges',
        'value': (readinessStats['earned_badges'] ?? badges.length).toString(),
      },
      {
        'label': 'Verified',
        'value': (readinessStats['verified_activities'] ?? 0).toString(),
      },
      {
        'label': 'Pending',
        'value': (readinessStats['pending_activities'] ?? 0).toString(),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: values.map((item) {
          return Expanded(
            child: Column(
              children: [
                Text(
                  item['value']!,
                  style: const TextStyle(
                    color: goldColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  item['label']!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAvailableBadgesSection() {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        color: secondaryCardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Badge Progress',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ...availableBadges.take(6).map((dynamic raw) {
            final badge = _asMap(raw);
            final bool earned = badge['earned'] == true;
            final double progress = _clampScore(
              _toDouble(badge['progress_percent']),
            );

            return InkWell(
              onTap: () => _showBadgeDetails(badge),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      earned
                          ? Icons.verified_rounded
                          : Icons.workspace_premium_outlined,
                      color: earned ? Colors.greenAccent : goldColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            badge['badge_name']?.toString() ?? 'Badge',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 7),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              value: earned ? 1 : progress / 100,
                              backgroundColor: Colors.white10,
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                goldColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      earned ? 'EARNED' : '${progress.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: earned ? Colors.greenAccent : goldColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showBadgeDetails(Map<String, dynamic> badge) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: secondaryCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (BuildContext context) {
        final bool earned = badge['earned'] == true;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  earned
                      ? Icons.workspace_premium_rounded
                      : Icons.lock_outline_rounded,
                  color: goldColor,
                  size: 54,
                ),
                const SizedBox(height: 14),
                Text(
                  badge['badge_name']?.toString() ?? 'Readiness Badge',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  badge['description']?.toString() ??
                      'Complete the badge requirements to unlock this recognition.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Minimum score: ${badge['minimum_readiness_score'] ?? 0}  •  '
                  'Activities: ${badge['required_verified_activities'] ?? 0}  •  '
                  'Social accounts: ${badge['required_verified_social_accounts'] ?? 0}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: goldColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  ////////////////////////////////////////////////////////////
  /// LAST UPDATED
  ////////////////////////////////////////////////////////////

  Widget _buildLastUpdatedCard() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: secondaryCardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            color: Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Last readiness calculation: ${_lastUpdatedText()}',
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
