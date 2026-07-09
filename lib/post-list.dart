import 'dart:ffi';
import 'dart:io';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/app_dropdown.dart';
import 'package:LawyerOnline/component/dialog_service.dart';
import 'package:LawyerOnline/component/gallery_view.dart';
import 'package:LawyerOnline/component/media_picker_sheet.dart';
import 'package:LawyerOnline/login.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';

// ─── Data Models ───────────────────────────────────────────────────────────────

enum UserRole { client, lawyer }

class CommunityUser {
  final String id;
  final String name;
  final String avatarUrl;
  final UserRole role;
  final String? specialty;
  final bool isVerified;

  const CommunityUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.role,
    this.specialty,
    this.isVerified = false,
  });
}

class PostComment {
  final String id;
  final CommunityUser author;
  String content;
  final DateTime createdAt;
  int likes;
  bool isLiked;
  final List<PostComment> replies;

  PostComment({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    this.likes = 0,
    this.isLiked = false,
    List<PostComment>? replies,
  }) : replies = replies ?? [];
}

class CommunityPost {
  final String id;
  final CommunityUser author;
  String content;
  final String category;
  String subTopicTitle;
  final DateTime createdAt;
  final List<String> imagePaths;
  int likes;
  int views;
  int shares;
  bool isLiked;
  bool isBookmarked;
  final List<PostComment> comments;

  CommunityPost({
    required this.id,
    required this.author,
    required this.content,
    required this.category,
    this.subTopicTitle = '',
    required this.createdAt,
    this.imagePaths = const [],
    this.likes = 0,
    this.views = 0,
    this.shares = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    List<PostComment>? comments,
  }) : comments = comments ?? [];

  String get displayTopicTitle => subTopicTitle;
}

class CommunityTopicLookup {
  static final Map<String, String> _topicTitles = {};
  static final Map<String, String> _subTopicTitles = {};
  static bool _loaded = false;
  static Future<void>? _loading;

  static Future<void> ensureLoaded() {
    if (_loaded) return Future.value();
    _loading ??= _load();
    return _loading!;
  }

  static Future<void> _load() async {
    try {
      final topics = await postDio('${server}/m/topic/read', {});
      final topicData = topics is Map ? topics['objectData'] : null;
      if (topicData is List) {
        for (final item in topicData.whereType<Map>()) {
          final code = item['code']?.toString() ?? '';
          final title = item['title']?.toString() ?? '';
          if (code.isNotEmpty && title.isNotEmpty) {
            _topicTitles[code] = title;
          }
        }
      }

      final subTopics = await postDio('${server}/m/topic/subTopic/read', {});
      final subData = subTopics is Map ? subTopics['objectData'] : null;
      if (subData is List) {
        for (final item in subData.whereType<Map>()) {
          final code = item['code']?.toString() ?? '';
          final title = item['title']?.toString() ?? '';
          if (code.isNotEmpty && title.isNotEmpty) {
            _subTopicTitles[code] = title;
          }
        }
      }
      _loaded = true;
    } catch (_) {}
  }

  static String resolveTitle(Map<String, dynamic> map) {
    final rawTitle = map['subTopicTitle']?.toString() ?? '';
    if (rawTitle.isNotEmpty) return rawTitle;

    final subTopic = map['subTopic']?.toString() ?? '';
    if (subTopic.isNotEmpty) {
      final title = _subTopicTitles[subTopic];
      if (title != null && title.isNotEmpty) return title;
    }

    final category = map['category']?.toString() ?? '';
    if (category.isNotEmpty) {
      final subTitle = _subTopicTitles[category];
      if (subTitle != null && subTitle.isNotEmpty) return subTitle;

      final topicTitle = _topicTitles[category];
      if (topicTitle != null && topicTitle.isNotEmpty) return topicTitle;
    }

    return '';
  }
}

// ─── Current User (loaded from profile) ────────────────────────────────────────

CommunityUser get currentUser {
  final store = UserProfileStore.instance;
  return CommunityUser(
    id: store.code.isNotEmpty ? store.code : 'me',
    name: store.name.isNotEmpty ? store.name : 'defaultUser'.tr(),
    avatarUrl: store.imageUrl,
    role: store.userType == 'lawyer' ? UserRole.lawyer : UserRole.client,
    isVerified: store.userType == 'lawyer',
  );
}

String _communityProfileCode() => UserProfileStore.instance.code.trim();

Map<String, dynamic> _communityActionPayload(String postCode) {
  final profileCode = _communityProfileCode();
  return {
    'profileCode': profileCode,
    'reference': postCode,
    'referenceUser': profileCode,
    'code': postCode,
  };
}

Map<String, dynamic> _communityReadCriteria([Map<String, dynamic>? extra]) {
  final profileCode = _communityProfileCode();
  return {
    if (profileCode.isNotEmpty) 'profileCode': profileCode,
    ...?extra,
  };
}

bool _isLikedFromMap(Map<String, dynamic> map) =>
    map['isLiked'] == true || map['isLike'] == true;

void _applyCommunityActionFields(dynamic post, dynamic objectData) {
  if (objectData is! Map) return;
  final data = Map<String, dynamic>.from(objectData);

  final isLiked = data['isLiked'] == true || data['isLike'] == true;
  final isBookmarked =
      data['isBookmarked'] == true || data['isBookmark'] == true;
  final likes = int.tryParse(data['likes']?.toString() ?? '');
  final shares = int.tryParse(data['shares']?.toString() ?? '');
  final views = int.tryParse(
      data['views']?.toString() ?? data['view']?.toString() ?? '');

  if (post is CommunityPost) {
    if (data.containsKey('isLiked') || data.containsKey('isLike')) {
      post.isLiked = isLiked;
    }
    if (data.containsKey('isBookmarked') || data.containsKey('isBookmark')) {
      post.isBookmarked = isBookmarked;
    }
    if (likes != null) post.likes = likes;
    if (shares != null) post.shares = shares;
    if (views != null) post.views = views;
    return;
  }

  if (post is Map) {
    if (data.containsKey('isLiked') || data.containsKey('isLike')) {
      post['isLiked'] = isLiked;
    }
    if (data.containsKey('isBookmarked') || data.containsKey('isBookmark')) {
      post['isBookmarked'] = isBookmarked;
    }
    if (likes != null) post['likes'] = likes;
    if (shares != null) post['shares'] = shares;
    if (views != null) {
      post['views'] = views;
      post['view'] = views;
    }
  }
}

void _syncCommunityPostFields(CommunityPost target, CommunityPost source) {
  target.likes = source.likes;
  target.views = source.views;
  target.shares = source.shares;
  target.isLiked = source.isLiked;
  target.isBookmarked = source.isBookmarked;
  target.content = source.content;
  if (source.subTopicTitle.isNotEmpty) {
    target.subTopicTitle = source.subTopicTitle;
  }
}

PostComment _mapCommunityComment(Map<String, dynamic> map) {
  final first = map['firstName']?.toString() ?? '';
  final last = map['lastName']?.toString() ?? '';
  final name = map['createBy']?.toString() ?? '$first $last'.trim();
  final profileCode = map['profileCode']?.toString() ?? '';
  final rawDate = map['createDate'] ?? map['docDate'];

  return PostComment(
    id: map['code']?.toString() ?? '',
    author: CommunityUser(
      id: profileCode,
      name: name.isNotEmpty ? name : 'defaultUser'.tr(),
      avatarUrl: map['imageUrlCreateBy']?.toString() ?? '',
      role: map['userType']?.toString() == 'lawyer'
          ? UserRole.lawyer
          : UserRole.client,
      isVerified: map['userType']?.toString() == 'lawyer',
    ),
    content: map['description']?.toString() ?? '',
    createdAt: rawDate is DateTime
        ? rawDate
        : DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now(),
    likes: int.tryParse(map['likes']?.toString() ?? '') ?? 0,
    isLiked: map['isLiked'] == true || map['isLike'] == true,
  );
}

List<PostComment> _mapCommunityComments(List<dynamic> raw) {
  final items = raw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
  final topLevel = <PostComment>[];
  final repliesByParent = <String, List<PostComment>>{};

  for (final map in items) {
    final comment = _mapCommunityComment(map);
    final parentCode = map['parentCode']?.toString() ?? '';
    if (parentCode.isEmpty) {
      topLevel.add(comment);
    } else {
      repliesByParent.putIfAbsent(parentCode, () => []).add(comment);
    }
  }

  for (final comment in topLevel) {
    comment.replies.addAll(repliesByParent[comment.id] ?? const []);
  }
  return topLevel;
}

Future<List<PostComment>> _loadCommunityComments(String postCode) async {
  final result = await postObjectData('/m/community/comment/read', {
    'reference': postCode,
    'code': postCode,
    'skip': 0,
    'limit': 100,
  });
  if (result['status'] != 'S') return const [];
  final data = result['objectData'];
  if (data is! List) return const [];
  return _mapCommunityComments(data);
}

Future<Map<String, dynamic>?> _readCommunityPost(String postCode) async {
  final result = await postObjectData(
    '/m/community/read',
    _communityReadCriteria({'code': postCode}),
  );
  if (result['status'] != 'S') return null;
  final data = result['objectData'];
  if (data is List && data.isNotEmpty && data.first is Map) {
    return Map<String, dynamic>.from(data.first as Map);
  }
  if (data is Map) return Map<String, dynamic>.from(data);
  return null;
}

Future<dynamic> _toggleCommunityLike(String postCode) async {
  return postObjectData('/m/community/like', _communityActionPayload(postCode));
}

Future<dynamic> _toggleCommunityBookmark(String postCode) async {
  return postObjectData(
      '/m/community/bookmark', _communityActionPayload(postCode));
}

Future<dynamic> _toggleCommunityCommentLike(String commentCode) async {
  final profileCode = _communityProfileCode();
  return postObjectData('/m/community/comment/like', {
    'profileCode': profileCode,
    'reference': commentCode,
    'referenceUser': profileCode,
    'code': commentCode,
  });
}

Future<dynamic> _shareCommunityPost(String postCode) async {
  final payload = _communityActionPayload(postCode);
  for (final path in ['share', 'shares', 'share/create']) {
    final result = await postObjectData('/m/community/$path', payload);
    if (result['status'] == 'S') return result;
  }
  return null;
}

// ─── Mock Data ─────────────────────────────────────────────────────────────────

// ─── แทนที่ส่วน postModel ในไฟล์หลัก ─────────────────────────────────────────
// วางแทน List<CommunityPost> postModel = [...]; ตัวเดิม

List<dynamic> postModel = [];
// ─── Community Feed Screen ─────────────────────────────────────────────────────

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  static const int _pageSize = 10;

  List<dynamic> _posts = [];
  int _totalPosts = 0;
  bool _hasMore = true;
  bool _isInitialLoading = false;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  int _fetchSeq = 0;
  bool _loadMoreScheduled = false;
  final ScrollController _scrollController = ScrollController();

  String typeLogin = "";
  final storage = FlutterSecureStorage();

  int _selectedCategoryIndex = 0;
  int _selectedTabIndex = 0;

  final List<String> _categories = [
    'category.all',
    'category.criminal',
    'category.civil',
    'category.labor',
    'category.real_estate',
    'category.family',
  ];
  final List<String> _tabs = [
    'home_tabs.popular',
    'home_tabs.newest',
    'home_tabs.saved',
  ];

  String _postId(dynamic post) {
    if (post is CommunityPost) return post.id;
    if (post is Map) return (post['id'] ?? post['code'] ?? '').toString();
    return '';
  }

  String _postCategory(dynamic post) {
    if (post is CommunityPost) return post.category;
    if (post is Map) return post['category']?.toString() ?? '';
    return '';
  }

  bool _postIsBookmarked(dynamic post) {
    if (post is CommunityPost) return post.isBookmarked;
    if (post is Map) return post['isBookmarked'] == true;
    return false;
  }

  int _postLikes(dynamic post) {
    if (post is CommunityPost) return post.likes;
    if (post is Map) return int.tryParse(post['likes']?.toString() ?? '') ?? 0;
    return 0;
  }

  DateTime _postCreatedAt(dynamic post) {
    if (post is CommunityPost) return post.createdAt;
    if (post is Map) {
      final raw = post['createdAt'] ?? post['createDate'] ?? post['docDate'];
      if (raw is DateTime) return raw;
      if (raw is String && raw.isNotEmpty) {
        return DateTime.tryParse(raw) ?? DateTime.now();
      }
    }
    return DateTime.now();
  }

  CommunityPost _asCommunityPost(dynamic post) {
    if (post is CommunityPost) return post;
    if (post is Map) {
      final map = Map<String, dynamic>.from(post);
      final authorMap = map['author'];
      final firstName = map['firstName']?.toString() ?? '';
      final lastName = map['lastName']?.toString() ?? '';
      final fallbackName = '$firstName $lastName'.trim();
      final author = authorMap is Map
          ? CommunityUser(
              id: (authorMap['id'] ?? authorMap['code'] ?? '').toString(),
              name: authorMap['name']?.toString() ?? fallbackName,
              avatarUrl: authorMap['avatarUrl']?.toString() ??
                  authorMap['imageUrl']?.toString() ??
                  map['imageUrlCreateBy']?.toString() ??
                  '',
              role: authorMap['userType']?.toString() == 'lawyer'
                  ? UserRole.lawyer
                  : UserRole.client,
              specialty: authorMap['specialty']?.toString(),
              isVerified: authorMap['isVerified'] == true ||
                  authorMap['userType']?.toString() == 'lawyer',
            )
          : CommunityUser(
              id: map['profileCode']?.toString() ?? '',
              name: fallbackName.isNotEmpty
                  ? fallbackName
                  : map['createBy']?.toString() ?? 'defaultUser',
              avatarUrl: map['imageUrlCreateBy']?.toString() ?? '',
              role: map['userType']?.toString() == 'lawyer'
                  ? UserRole.lawyer
                  : UserRole.client,
              isVerified: map['userType']?.toString() == 'lawyer',
            );

      return CommunityPost(
        id: _postId(map),
        author: author,
        content: map['content']?.toString() ?? map['description'] ?? '',
        category:
            _postCategory(map).isNotEmpty ? _postCategory(map) : 'category.all',
        subTopicTitle: map['subTopicTitle']?.toString().isNotEmpty == true
            ? map['subTopicTitle'].toString()
            : CommunityTopicLookup.resolveTitle(map),
        createdAt: _postCreatedAt(map),
        imagePaths: (map['gallery'] as List?)
                ?.map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList() ??
            (map['imagePaths'] as List?)
                ?.map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toList() ??
            const [],
        likes: _postLikes(map),
        views: int.tryParse(
                map['views']?.toString() ?? map['view']?.toString() ?? '') ??
            0,
        shares: int.tryParse(map['shares']?.toString() ?? '') ?? 0,
        isLiked: _isLikedFromMap(map),
        isBookmarked: _postIsBookmarked(map),
      );
    }
    throw StateError('Unsupported post type: ${post.runtimeType}');
  }

  // ── Filtered & sorted posts ──────────────────────────────
  List<dynamic> get _filteredPosts {
    // "บันทึกไว้" — show ALL bookmarked, ignore category
    if (_selectedTabIndex == 2) {
      final result =
          _posts.where((p) => _postIsBookmarked(p)).toList(growable: true);
      result.sort((a, b) => _postCreatedAt(b).compareTo(_postCreatedAt(a)));
      return result;
    }

    // 1) Filter by category
    List<dynamic> result;
    if (_selectedCategoryIndex == 0) {
      result = List<dynamic>.from(_posts);
    } else {
      final selectedCategory = _categories[_selectedCategoryIndex];
      result = _posts
          .where((p) => _postCategory(p) == selectedCategory)
          .toList(growable: true);
    }

    // 2) Sort by tab
    if (_selectedTabIndex == 0) {
      result.sort((a, b) => _postLikes(b).compareTo(_postLikes(a)));
    } else {
      result.sort((a, b) => _postCreatedAt(b).compareTo(_postCreatedAt(a)));
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    UserProfileStore.instance.addListener(_onProfileChanged);
    _scrollController.addListener(_onScroll);
    CommunityTopicLookup.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
    callRead();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    UserProfileStore.instance.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (!_hasMore || _isLoadingMore || _isInitialLoading || _isRefreshing) return;

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMorePosts();
    }
  }

  void _onProfileChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  int _appendPosts(List<dynamic> batch) {
    final existingIds = _posts.map(_postId).toSet();
    var added = 0;
    for (final post in batch) {
      final item = _asCommunityPost(post);
      final id = item.id;
      if (id.isNotEmpty && !existingIds.contains(id)) {
        _posts.add(item);
        existingIds.add(id);
        added++;
      }
    }
    return added;
  }

  void _syncPostFromDetail(CommunityPost updated) {
    final idx = _posts.indexWhere((p) => _postId(p) == updated.id);
    if (idx < 0) return;
    final target = _posts[idx];
    if (target is CommunityPost) {
      _syncCommunityPostFields(target, updated);
    } else {
      _posts[idx] = updated;
    }
    setState(() {});
  }

  void _updatePaginationState(List<dynamic> batch, int total, {bool loadMore = false}) {
    if (loadMore && batch.isEmpty) {
      _hasMore = false;
      return;
    }

    if (total > 0) {
      _totalPosts = total;
      _hasMore = _posts.length < total;
    } else {
      _hasMore = batch.length >= _pageSize;
    }
    if (batch.isEmpty) _hasMore = false;
  }

  void _autoFillIfNotScrollable() {
    if (_loadMoreScheduled) return;
    _loadMoreScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMoreScheduled = false;
      if (!mounted) return;
      if (!_hasMore || _isLoadingMore || _isInitialLoading || _isRefreshing) {
        return;
      }
      if (!_scrollController.hasClients) return;

      final position = _scrollController.position;
      final notScrollable =
          position.maxScrollExtent <= position.viewportDimension * 0.5;
      if (notScrollable) {
        _loadMorePosts();
      }
    });
  }

  Future<void> callRead({bool refresh = false, bool loadMore = false}) async {
    if (loadMore) {
      if (_isLoadingMore || _isRefreshing || _isInitialLoading || !_hasMore || _posts.isEmpty) {
        return;
      }
    } else if (refresh) {
      // refresh เสมอ — ยกเลิกผลจาก request ที่ค้างอยู่
    } else if (_isInitialLoading) {
      return;
    }

    final seq = ++_fetchSeq;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else if (refresh) {
        _isRefreshing = true;
        _isLoadingMore = false;
        _hasMore = true;
        _totalPosts = 0;
      } else {
        _isInitialLoading = true;
      }
    });

    try {
      final type = await storage.read(key: 'typeLogin');
      final skip = loadMore ? _posts.length : 0;
      final result = await postObjectData("/m/community/read", {
        ..._communityReadCriteria(),
        'skip': skip,
        'limit': _pageSize,
      });

      if (!mounted || seq != _fetchSeq) return;

      if (result['status'] == 'S' && result['objectData'] is List) {
        final batch = List<dynamic>.from(result['objectData'] as List);
        final total = result['totalData'] is int
            ? result['totalData'] as int
            : int.tryParse(result['totalData']?.toString() ?? '') ?? 0;

        setState(() {
          if (loadMore) {
            final added = _appendPosts(batch);
            _updatePaginationState(batch, total, loadMore: true);
            if (added == 0) _hasMore = false;
          } else {
            _posts = batch.map((e) => _asCommunityPost(e)).toList();
            _updatePaginationState(batch, total);
          }
          typeLogin = type.toString();
        });

        if (refresh && _scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }

        if (!refresh) {
          _autoFillIfNotScrollable();
        }
      }
    } finally {
      if (!mounted || seq != _fetchSeq) return;
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _loadMorePosts() => callRead(loadMore: true);

  Future<void> _refreshPosts() => callRead(refresh: true);

  Future<void> _toggleLike(String postId) async {
    final index = _posts.indexWhere((p) => _postId(p) == postId);
    if (index < 0) return;

    final post = _posts[index];
    final wasLiked = post is CommunityPost
        ? post.isLiked
        : post is Map
            ? post['isLiked'] == true
            : false;

    setState(() {
      if (post is CommunityPost) {
        post.isLiked ? post.likes-- : post.likes++;
        post.isLiked = !post.isLiked;
      } else if (post is Map) {
        post['isLiked'] = !wasLiked;
        post['likes'] = _postLikes(post) + (wasLiked ? -1 : 1);
      }
    });

    final result = await _toggleCommunityLike(postId);
    if (!mounted) return;
    if (result?['status'] != 'S') {
      setState(() {
        if (post is CommunityPost) {
          post.isLiked = wasLiked;
          post.likes += wasLiked ? 1 : -1;
        } else if (post is Map) {
          post['isLiked'] = wasLiked;
          post['likes'] = _postLikes(post) + (wasLiked ? 1 : -1);
        }
      });
      return;
    }
    setState(() => _applyCommunityActionFields(post, result?['objectData']));
  }

  Future<void> _toggleBookmark(String postId) async {
    final index = _posts.indexWhere((p) => _postId(p) == postId);
    if (index < 0) return;

    final post = _posts[index];
    final wasBookmarked = _postIsBookmarked(post);

    setState(() {
      if (post is CommunityPost) {
        post.isBookmarked = !post.isBookmarked;
      } else if (post is Map) {
        post['isBookmarked'] = !wasBookmarked;
      }
    });
    HapticFeedback.lightImpact();

    final result = await _toggleCommunityBookmark(postId);
    if (!mounted) return;
    if (result?['status'] != 'S') {
      setState(() {
        if (post is CommunityPost) {
          post.isBookmarked = wasBookmarked;
        } else if (post is Map) {
          post['isBookmarked'] = wasBookmarked;
        }
      });
      return;
    }
    setState(() => _applyCommunityActionFields(post, result?['objectData']));
  }

  Future<void> _sharePost(CommunityPost post) async {
    final text = post.content.trim();
    if (text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
    }

    final result = await _shareCommunityPost(post.id);
    if (!mounted) return;

    if (result?['status'] == 'S') {
      final index = _posts.indexWhere((p) => _postId(p) == post.id);
      if (index >= 0) {
        setState(() {
          _applyCommunityActionFields(_posts[index], result?['objectData']);
          if (_posts[index] is CommunityPost) {
            (_posts[index] as CommunityPost).shares++;
          } else if (_posts[index] is Map) {
            final map = _posts[index] as Map;
            map['shares'] = (int.tryParse(map['shares']?.toString() ?? '') ?? 0) + 1;
          }
        });
      } else {
        setState(() => post.shares++);
      }
    } else if (text.isNotEmpty) {
      setState(() => post.shares++);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result?['status'] == 'S' || text.isNotEmpty
              ? 'คัดลอกเนื้อหาโพสต์แล้ว'
              : 'ไม่สามารถแชร์โพสต์ได้',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    HapticFeedback.lightImpact();
  }

  void _openPostForm() async {
    final newPost = await Navigator.push<CommunityPost>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (newPost != null) {
      setState(() => _posts.insert(0, newPost));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('โพสต์สำเร็จแล้ว'),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);
    final bool isTablet = ResponsiveLayout.isTablet(context);
    final bool isDesktop = ResponsiveLayout.isDesktop(context);

    // Responsive horizontal padding
    final double hPadding = isDesktop ? 20 : (isTablet ? 24 : 16);
    // Responsive top spacing
    final double topSpacing = isMobile ? 12 : 24;

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: isDesktop
            ? const Color.fromARGB(255, 233, 242, 249)
            : (isMobile ? Colors.white : const Color(0xFFF8F9FA)),
        body: SafeArea(
          bottom: false,
          child: AppLayout(
            child: Container(
              clipBehavior: isDesktop ? Clip.antiAlias : Clip.none,
              decoration: isDesktop
                  ? const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    )
                  : null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: Column(
                  children: [
                    SizedBox(height: topSpacing),
                    // ── Header ──
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        children: [
                          Text(
                            'community'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'communitySubtitle'.tr(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCategories(isMobile: isMobile),
                    SizedBox(height: isMobile ? 12 : 24),
                    if (!isMobile) ...[
                      _buildCreatePostCard(isMobile: false),
                      const SizedBox(height: 24),
                    ],
                    _buildTabs(),
                    SizedBox(height: isMobile ? 8 : 16),
                    Expanded(child: _buildPostsList()),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: isMobile ? _buildFAB() : null,
      ),
    );
  }

  // ── Mobile FAB ──────────────────────────────────────────
  Widget _buildFAB() {
    return GestureDetector(
      onTap: () {
        if (typeLogin != 'null') {
          _openPostForm();
        } else {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => LoginPage(isBack: true)));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.only(bottom: 80),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF5E4BFF), Color(0xFF3D2DB5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5E4BFF).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // ── Categories chips ────────────────────────────────────
  Widget _buildCategories({required bool isMobile}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _categories.asMap().entries.map((entry) {
          int idx = entry.key;
          String text = entry.value;
          bool isSelected = idx == _selectedCategoryIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = idx),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 6),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 20,
                vertical: isMobile ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF5E4BFF) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF5E4BFF)
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                text.tr(),
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Create post card ────────────────────────────────────
  Widget _buildCreatePostCard({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            radius: isMobile ? 18 : 20,
            child: Icon(Icons.person,
                color: Colors.grey.shade500, size: isMobile ? 20 : 24),
          ),
          SizedBox(width: isMobile ? 10 : 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (typeLogin != 'null') {
                  _openPostForm();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage(isBack: true)),
                  );
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'postQuestionHint'.tr(),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tabs (ยอดนิยม / มาใหม่) ───────────────────────────
  Widget _buildTabs() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: TabBar(
        onTap: (idx) => setState(() => _selectedTabIndex = idx),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: const Color(0xFF5E4BFF),
        labelColor: const Color(0xFF5E4BFF),
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        indicatorWeight: 2,
        dividerColor: Colors.transparent,
        tabs: _tabs.map((tabKey) {
          return Tab(
            text: tabKey.tr(), // มาแปลภาษาตรงนี้
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2))
            ]),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Text('searchHint'.tr(),
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(10)),
            child: Text('search'.tr(),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  Widget _buildPostsList() {
    final bool isMobile = ResponsiveLayout.isMobile(context);
    final posts = _filteredPosts;

    Widget emptyState() {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedTabIndex == 2
                  ? Icons.bookmark_outline_rounded
                  : Icons.article_outlined,
              size: 48,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              _selectedTabIndex == 2
                  ? 'noSavedPosts'.tr()
                  : 'noPostsInCategory'.tr(),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    if (_isInitialLoading && _posts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5E4BFF)),
      );
    }

    final showLoadMoreFooter = _isLoadingMore && !_isRefreshing;

    return RefreshIndicator(
      color: const Color(0xFF5E4BFF),
      onRefresh: _refreshPosts,
      child: posts.isEmpty
          ? LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: emptyState(),
                  ),
                );
              },
            )
          : ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(0, 4, 0, isMobile ? 140 : 40),
              itemCount: posts.length + (showLoadMoreFooter ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= posts.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: _isLoadingMore
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF5E4BFF),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                }

                final post = _asCommunityPost(posts[index]);
                return PostCard(
                  key: ValueKey(_postId(post)),
                  post: post,
                  onLike: () => _toggleLike(post.id),
                  onBookmark: () => _toggleBookmark(post.id),
                  onShare: () => _sharePost(post),
                  typeLogin: typeLogin,
                  onTap: () async {
                    final updated = await Navigator.push<CommunityPost>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailScreen(post: post),
                      ),
                    );
                    if (!mounted) return;
                    if (updated != null) {
                      _syncPostFromDetail(updated);
                    }
                  },
                );
              },
              separatorBuilder: (context, index) {
                if (index >= posts.length - 1) {
                  return const SizedBox.shrink();
                }
                return isMobile
                    ? Divider(height: 1, color: Colors.grey.shade100)
                    : const SizedBox(height: 16);
              },
            ),
    );
  }
}

// ─── Post Card ─────────────────────────────────────────────────────────────────

class PostCard extends StatefulWidget {
  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onShare;
  final VoidCallback onTap;
  final String typeLogin;

  const PostCard(
      {super.key,
      required this.post,
      required this.onLike,
      required this.onBookmark,
      required this.onShare,
      required this.typeLogin,
      required this.onTap});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeCtrl;
  late Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _likeScale = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _likeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _likeCtrl.dispose();
    super.dispose();
  }

  void _handleLike() {
    _likeCtrl.forward(from: 0);
    HapticFeedback.lightImpact();
    widget.onLike();
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'category.labor':
        return const Color(0xFF2196F3);
      case 'category.real_estate':
        return const Color(0xFF4CAF50);
      case 'category.family':
        return const Color(0xFFE91E63);
      case 'category.criminal':
        return const Color(0xFFFF5722);
      default:
        return const Color(0xFF9C27B0);
    }
  }

  String _formatTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60)
      return 'time.minutesAgo'.tr(args: [d.inMinutes.toString()]);
    if (d.inHours < 24) return 'time.hoursAgo'.tr(args: [d.inHours.toString()]);
    return 'time.daysAgo'.tr(args: [d.inDays.toString()]);
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  Widget _buildPostImage(String path) {
    if (path.startsWith('http')) {
      return Image.network(path, fit: BoxFit.cover, width: double.infinity);
    }
    return Image.file(File(path), fit: BoxFit.cover, width: double.infinity);
  }

  Widget _buildPreviewImageCell(
    String path, {
    bool showOverlay = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildPostImage(path),
          if (showOverlay)
            Container(
              color: Colors.black.withOpacity(0.5),
              alignment: Alignment.center,
              child: const Text(
                '3+',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostImagesPreview(List<String> paths) {
    if (paths.isEmpty) return const SizedBox.shrink();

    const totalHeight = 140.0;
    const gap = 4.0;
    final hasMore = paths.length > 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 16, 0),
      child: SizedBox(
        height: totalHeight,
        child: paths.length == 1
            ? _buildPreviewImageCell(paths[0])
            : Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildPreviewImageCell(paths[0]),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    flex: 2,
                    child: paths.length == 2
                        ? _buildPreviewImageCell(paths[1])
                        : Column(
                            children: [
                              Expanded(
                                child: _buildPreviewImageCell(paths[1]),
                              ),
                              const SizedBox(height: gap),
                              Expanded(
                                child: _buildPreviewImageCell(
                                  paths[2],
                                  showOverlay: hasMore,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cc = _categoryColor(widget.post.category);
    final lawyerComments = widget.post.comments
        .where((c) => c.author.role == UserRole.lawyer)
        .toList();

    bool isDesktop = ResponsiveLayout.isDesktop(context);

    return GestureDetector(
      onTap: () {
        if (widget.typeLogin != 'null') {
          widget.onTap();
        } else {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => LoginPage(isBack: true)));
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 16, 16, 0),
        margin: isDesktop
            ? const EdgeInsets.symmetric(horizontal: 2)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isDesktop ? Border.all(color: Colors.grey.shade200) : null,
          boxShadow: isDesktop
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatar(widget.post.author, 42),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text.rich(
                                    TextSpan(
                                      text: widget.post.author.name,
                                      style: GoogleFonts.prompt(
                                        color: const Color(0xFF1A1A2E),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
                                      children: <TextSpan>[
                                        if (widget
                                            .post.displayTopicTitle.isNotEmpty)
                                          TextSpan(
                                            text: ' > ${widget.post.displayTopicTitle}',
                                            style: GoogleFonts.prompt(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                              color: const Color(0xFF1A1A2E),
                                            ),
                                          ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Text(
                                //   widget.post.author.name,
                                //   style: const TextStyle(
                                //     fontSize: 13,
                                //     fontWeight: FontWeight.w600,
                                //     color: Color(0xFF1A1A2E),
                                //   ),
                                // ),
                                // Container(
                                //   // padding: const EdgeInsets.symmetric(
                                //   //     horizontal: 10, vertical: 4),
                                //   // decoration: BoxDecoration(
                                //   //     color: cc.withOpacity(0.1),
                                //   //     borderRadius: BorderRadius.circular(8)),
                                //   child: Text(
                                //     ' > ${widget.post.category}',
                                //     style: TextStyle(
                                //       fontSize: 11,
                                //       fontWeight: FontWeight.w600,
                                //       // color: cc,
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (widget.typeLogin != 'null') {
                            widget.onBookmark();
                          } else {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => LoginPage(isBack: true)));
                          }
                        },
                        child: Icon(
                            widget.post.isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 20,
                            color: widget.post.isBookmarked
                                ? Colors.yellow.shade800
                                : Colors.grey.shade300),
                      ),
                    ],
                  ),
                  Text(
                    _formatTime(widget.post.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  // Divider(height: 1, color: Colors.grey.shade100),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text(widget.post.title,
                        //     style: const TextStyle(
                        //         fontSize: 14,
                        //         fontWeight: FontWeight.w600,
                        //         color: Color(0xFF1A1A2E),
                        //         height: 1.4,
                        //         letterSpacing: -0.3)),
                        // const SizedBox(height: 6),
                        Text(
                          widget.post.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A1A2E),
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  if (widget.post.imagePaths.isNotEmpty)
                    _buildPostImagesPreview(widget.post.imagePaths),
                  // if (lawyerComments.isNotEmpty) _lawyerPreview(lawyerComments.first),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 14),
                    child: Row(
                      children: [
                        _actionBtn(
                          icon: widget.post.isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          label: _fmt(widget.post.likes),
                          color: widget.post.isLiked
                              ? const Color(0xFFE53935)
                              : const Color(0xFF9E9E9E),
                          onTap: () {
                            if (widget.typeLogin != 'null') {
                              _handleLike();
                            } else {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => LoginPage(isBack: true)));
                            }
                          },
                          scale: _likeScale,
                        ),
                        const SizedBox(width: 16),
                        _actionBtn(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: '${widget.post.comments.length}',
                          color: const Color(0xFF9E9E9E),
                          onTap: () {
                            if (widget.typeLogin != 'null') {
                              widget.onTap();
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoginPage(isBack: true),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        _actionBtn(
                            icon: Icons.ios_share_rounded,
                            label: _fmt(widget.post.shares),
                            color: const Color(0xFF9E9E9E),
                            onTap: () {
                              if (widget.typeLogin != 'null') {
                                widget.onShare();
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LoginPage(isBack: true),
                                  ),
                                );
                              }
                            }),
                        const Spacer(),
                        Icon(Icons.remove_red_eye_outlined,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(_fmt(widget.post.views),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lawyerPreview(PostComment c) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3F2FD))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(6)),
          child: Text('lawyerBadge'.tr(),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.author.name,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1565C0))),
          const SizedBox(height: 2),
          Text(c.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF546E7A), height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _actionBtn(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap,
      Animation<double>? scale}) {
    Widget i = Icon(icon, size: 18, color: color);
    if (scale != null)
      i = AnimatedBuilder(
          animation: scale,
          builder: (_, child) =>
              Transform.scale(scale: scale.value, child: child),
          child: i);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          i,
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                fontSize: 13, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _avatar(CommunityUser user, double size) {
    final isLawyer = user.role == UserRole.lawyer;
    final isMe = user.id == currentUser.id;
    final initials = user.name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join();
    return Stack(children: [
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                colors: isMe
                    ? [const Color(0xFFF57F17), const Color(0xFFFF8F00)]
                    : (isLawyer
                        ? [const Color(0xFF1565C0), const Color(0xFF1976D2)]
                        : [const Color(0xFF37474F), const Color(0xFF546E7A)]),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)),
        child: ClipOval(
          child: user.avatarUrl.isNotEmpty
              ? (user.avatarUrl.startsWith('http') ||
                      user.avatarUrl.startsWith('https')
                  ? Image.network(user.avatarUrl, fit: BoxFit.cover)
                  : Image.asset(user.avatarUrl, fit: BoxFit.cover))
              : Center(
                  child: Text(initials,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: size * 0.33,
                          fontWeight: FontWeight.w700)),
                ),
        ),
      ),
      if (user.isVerified)
        Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.33,
              height: size * 0.33,
              decoration: BoxDecoration(
                  color: const Color(0xFF00ACC1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5)),
              child: Icon(Icons.check_rounded,
                  size: size * 0.18, color: Colors.white),
            )),
    ]);
  }
}

// ─── Post Detail Screen ────────────────────────────────────────────────────────

class PostDetailScreen extends StatefulWidget {
  final CommunityPost post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late List<PostComment> _comments;
  bool _isSending = false;

  // ── Reply / Edit state ──────────────────────────────────
  PostComment? _replyTarget;
  PostComment? _editingComment;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.post.comments);
    _loadDetailData();
  }

  Future<void> _loadDetailData() async {
    final postMap = await _readCommunityPost(widget.post.id);
    if (postMap != null && mounted) {
      setState(() {
        _applyCommunityActionFields(widget.post, postMap);
        widget.post.isLiked = _isLikedFromMap(postMap);
        widget.post.isBookmarked =
            postMap['isBookmarked'] == true || postMap['isBookmark'] == true;
        widget.post.subTopicTitle = postMap['subTopicTitle']?.toString().isNotEmpty == true
            ? postMap['subTopicTitle'].toString()
            : CommunityTopicLookup.resolveTitle(postMap);
      });
    }

    final comments = await _loadCommunityComments(widget.post.id);
    if (!mounted) return;
    setState(() {
      _comments = comments;
      widget.post.comments
        ..clear()
        ..addAll(comments);
    });
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60)
      return 'time.minutesAgo'.tr(args: [d.inMinutes.toString()]);
    if (d.inHours < 24) return 'time.hoursAgo'.tr(args: [d.inHours.toString()]);
    return 'time.daysAgo'.tr(args: [d.inDays.toString()]);
  }

  ImageProvider _detailImageProvider(String path) {
    if (path.startsWith('http')) return NetworkImage(path);
    return FileImage(File(path));
  }

  void _openImageViewer(int initialIndex) {
    final providers = widget.post.imagePaths
        .map(_detailImageProvider)
        .toList(growable: false);
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ImageViewer(
          initialIndex: initialIndex,
          imageProviders: providers,
        ),
      ),
    );
  }

  Widget _buildDetailImageGallery() {
    final paths = widget.post.imagePaths;
    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: paths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final path = paths[index];
          return GestureDetector(
            onTap: () => _openImageViewer(index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 140,
                height: 140,
                child: path.startsWith('http')
                    ? Image.network(path, fit: BoxFit.cover)
                    : Image.file(File(path), fit: BoxFit.cover),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Send comment (or reply or save edit) ────────────────
  Future<void> _sendComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _isSending) return;
    if (_communityProfileCode().isEmpty) return;

    setState(() => _isSending = true);

    try {
      if (_editingComment != null) {
        final result = await postObjectData('/m/community/comment/update', {
          'code': _editingComment!.id,
          'profileCode': _communityProfileCode(),
          'description': text,
        });
        if (!mounted) return;
        if (result['status'] == 'S') {
          setState(() {
            _editingComment!.content = text;
            _editingComment = null;
          });
          _commentCtrl.clear();
          _focusNode.unfocus();
          HapticFeedback.lightImpact();
        }
        return;
      }

      final payload = <String, dynamic>{
        'profileCode': _communityProfileCode(),
        'reference': widget.post.id,
        'description': text,
      };
      if (_replyTarget != null) {
        payload['parentCode'] = _replyTarget!.id;
      }

      final result = await postObjectData('/m/community/comment/create', payload);
      if (!mounted) return;

      if (result['status'] == 'S') {
        final comments = await _loadCommunityComments(widget.post.id);
        if (!mounted) return;
        setState(() {
          _comments = comments;
          widget.post.comments
            ..clear()
            ..addAll(comments);
          _replyTarget = null;
        });
        _commentCtrl.clear();
        _focusNode.unfocus();
        HapticFeedback.lightImpact();
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _toggleCommentLike(PostComment comment) async {
    final wasLiked = comment.isLiked;
    setState(() {
      comment.isLiked ? comment.likes-- : comment.likes++;
      comment.isLiked = !comment.isLiked;
    });
    HapticFeedback.lightImpact();

    final result = await _toggleCommunityCommentLike(comment.id);
    if (!mounted) return;
    if (result?['status'] != 'S') {
      setState(() {
        comment.isLiked = wasLiked;
        comment.likes += wasLiked ? 1 : -1;
      });
      return;
    }

    final data = result?['objectData'];
    if (data is Map) {
      setState(() {
        comment.isLiked =
            data['isLiked'] == true || data['isLike'] == true;
        final likes = int.tryParse(data['likes']?.toString() ?? '');
        if (likes != null) comment.likes = likes;
      });
    }
  }

  Future<void> _sharePostDetail() async {
    final text = widget.post.content.trim();
    if (text.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: text));
    }

    final result = await _shareCommunityPost(widget.post.id);
    if (!mounted) return;

    if (result?['status'] == 'S') {
      setState(() {
        _applyCommunityActionFields(widget.post, result?['objectData']);
        widget.post.shares++;
      });
    } else if (text.isNotEmpty) {
      setState(() => widget.post.shares++);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result?['status'] == 'S' || text.isNotEmpty
              ? 'คัดลอกเนื้อหาโพสต์แล้ว'
              : 'ไม่สามารถแชร์โพสต์ได้',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    HapticFeedback.lightImpact();
  }

  Future<void> _togglePostLikeDetail() async {
    final wasLiked = widget.post.isLiked;
    setState(() {
      widget.post.isLiked ? widget.post.likes-- : widget.post.likes++;
      widget.post.isLiked = !widget.post.isLiked;
    });
    HapticFeedback.lightImpact();

    final result = await _toggleCommunityLike(widget.post.id);
    if (!mounted) return;
    if (result?['status'] != 'S') {
      setState(() {
        widget.post.isLiked = wasLiked;
        widget.post.likes += wasLiked ? 1 : -1;
      });
      return;
    }
    setState(() => _applyCommunityActionFields(widget.post, result?['objectData']));
  }

  Future<void> _togglePostBookmarkDetail() async {
    final wasBookmarked = widget.post.isBookmarked;
    setState(() => widget.post.isBookmarked = !widget.post.isBookmarked);
    HapticFeedback.lightImpact();

    final result = await _toggleCommunityBookmark(widget.post.id);
    if (!mounted) return;
    if (result?['status'] != 'S') {
      setState(() => widget.post.isBookmarked = wasBookmarked);
      return;
    }
    setState(() => _applyCommunityActionFields(widget.post, result?['objectData']));
  }

  void _startReply(PostComment target) {
    setState(() {
      _replyTarget = target;
      _editingComment = null;
    });
    _commentCtrl.clear();
    _focusNode.requestFocus();
  }

  void _startEditComment(PostComment c) {
    setState(() {
      _editingComment = c;
      _replyTarget = null;
    });
    _commentCtrl.text = c.content;
    _focusNode.requestFocus();
  }

  void _cancelReplyOrEdit() {
    setState(() {
      _replyTarget = null;
      _editingComment = null;
    });
    _commentCtrl.clear();
    _focusNode.unfocus();
  }

  // ── Edit Post ───────────────────────────────────────────
  void _editPost() {
    final ctrl = TextEditingController(text: widget.post.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('editPost'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'postContentHint'.tr(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('cancel'.tr(),
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E4BFF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => widget.post.content = ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child:
                Text('save'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveLayout.isDesktop(context);

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, widget.post);
        return false;
      },
      child: Scaffold(
      backgroundColor: isDesktop
          ? const Color.fromARGB(255, 233, 242, 249)
          : const Color(0xFFF5F4F0),
      appBar: isDesktop
          ? null
          : appBarCustom(
              title: "postDetailTitle".tr(),
              backBtn: true,
              isRightWidget: false,
              backAction: () => goBack(),
            ),
      body: AppLayout(
        child: Container(
          clipBehavior: isDesktop ? Clip.antiAlias : Clip.none,
          decoration: isDesktop
              ? const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                )
              : null,
          child: Column(
            children: [
              if (isDesktop) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        onPressed: () => goBack(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "postDetailTitle".tr(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPostContent(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'commentsAndAnswers'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_comments.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._comments.map((c) => _buildCommentCard(c)),
                      if (_comments.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded,
                                    size: 40, color: Colors.grey.shade300),
                                const SizedBox(height: 10),
                                Text(
                                  'noComments'.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade400,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _buildCommentInput(),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildPostContent() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 3))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _avatar(widget.post.author, 38),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.post.author.name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              Text(_formatTime(widget.post.createdAt),
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
            ]),
          ),
          if (widget.post.author.id == currentUser.id)
            GestureDetector(
              onTap: _editPost,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F4F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_outlined,
                    size: 18, color: Color(0xFF5E4BFF)),
              ),
            ),
        ]),
        if (widget.post.displayTopicTitle.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF5E4BFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.post.displayTopicTitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5E4BFF),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        // Text(
        //   widget.post.title,
        //   style: const TextStyle(
        //       fontSize: 17,
        //       fontWeight: FontWeight.w800,
        //       color: Color(0xFF1A1A2E),
        //       height: 1.4,
        //       letterSpacing: -0.5),
        // ),
        const SizedBox(height: 8),
        Text(
          widget.post.content,
          style: const TextStyle(
              fontSize: 14, color: Color(0xFF1A1A2E), height: 1.6),
        ),
        if (widget.post.imagePaths.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildDetailImageGallery(),
        ],
        const SizedBox(height: 16),
        Row(children: [
          GestureDetector(
            onTap: _togglePostLikeDetail,
            child: _statChip(
              widget.post.isLiked
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              '${widget.post.likes}',
              widget.post.isLiked
                  ? const Color(0xFFE53935)
                  : const Color(0xFF9E9E9E),
            ),
          ),
          const SizedBox(width: 12),
          _statChip(Icons.chat_bubble_outline_rounded,
              '${_comments.length}', const Color(0xFF1565C0)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sharePostDetail,
            child: _statChip(Icons.ios_share_rounded, '${widget.post.shares}',
                const Color(0xFF9E9E9E)),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _togglePostBookmarkDetail,
            child: _statChip(
              widget.post.isBookmarked
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              widget.post.isBookmarked ? 'home_tabs.saved'.tr() : 'save'.tr(),
              widget.post.isBookmarked
                  ? Colors.yellow.shade800
                  : const Color(0xFF9E9E9E),
            ),
          ),
          const Spacer(),
          _statChip(Icons.remove_red_eye_outlined, '${widget.post.views}',
              const Color(0xFF9E9E9E)),
        ]),
      ]),
    );
  }

  Widget _buildCommentCard(PostComment c, {bool isReply = false}) {
    final isLawyer = c.author.role == UserRole.lawyer;
    final isMe = c.author.id == currentUser.id;
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 32 : 0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFFFFF8E1)
              : (isLawyer ? const Color(0xFFF0F7FF) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: isMe
              ? Border.all(color: const Color(0xFFFFE082))
              : (isLawyer ? Border.all(color: const Color(0xFFBBDEFB)) : null),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _avatar(c.author, 36),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Flexible(
                        child: Text(
                      isMe ? 'you'.tr() : c.author.name,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isMe
                              ? const Color(0xFFF57F17)
                              : (isLawyer
                                  ? const Color(0xFF1565C0)
                                  : const Color(0xFF1A1A2E))),
                    )),
                    if (isLawyer) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(c.author.specialty ?? 'lawyerBadge'.tr(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF57F17),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text('you'.tr(),
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                  Text(_formatTime(c.createdAt),
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF9E9E9E))),
                ])),
          ]),
          const SizedBox(height: 10),
          Text(c.content,
              style: TextStyle(
                  fontSize: 13,
                  color: isLawyer
                      ? const Color(0xFF37474F)
                      : const Color(0xFF616161),
                  height: 1.6)),
          const SizedBox(height: 10),
          Row(children: [
            GestureDetector(
              onTap: () => _toggleCommentLike(c),
              child: Row(children: [
                Icon(
                    c.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    size: 15,
                    color: c.isLiked
                        ? const Color(0xFFE53935)
                        : Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('${c.likes}',
                    style: TextStyle(
                        fontSize: 12,
                        color: c.isLiked
                            ? const Color(0xFFE53935)
                            : Colors.grey.shade400)),
              ]),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => _startReply(c),
              child: Text('reply'.tr(),
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500)),
            ),
            if (isMe) ...[
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _startEditComment(c),
                child: Text('edit'.tr(),
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5E4BFF),
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ]),
          // ── Nested replies ──
          if (c.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...c.replies.map((r) => _buildCommentCard(r, isReply: true)),
          ],
        ]),
      ),
    );
  }

  Widget _buildCommentInput() {
    final hasContext = _replyTarget != null || _editingComment != null;
    String hintText = 'commentHint'.tr();
    if (_replyTarget != null) {
      hintText = 'replyingTo'.tr(args: [_replyTarget!.author.name]);
    } else if (_editingComment != null) {
      hintText = 'editingComment'.tr();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Context banner (reply / edit) ──
        if (hasContext)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _editingComment != null
                ? const Color(0xFFF3F0FF)
                : const Color(0xFFF0F7FF),
            child: Row(children: [
              Icon(
                _editingComment != null
                    ? Icons.edit_outlined
                    : Icons.reply_rounded,
                size: 16,
                color: _editingComment != null
                    ? const Color(0xFF5E4BFF)
                    : const Color(0xFF1565C0),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _editingComment != null
                      ? 'editingComment'.tr()
                      : 'replyingTo'.tr(args: [_replyTarget!.author.name]),
                  style: TextStyle(
                    fontSize: 12,
                    color: _editingComment != null
                        ? const Color(0xFF5E4BFF)
                        : const Color(0xFF1565C0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _cancelReplyOrEdit,
                child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
              ),
            ]),
          ),
        // ── Input row ──
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, -3))
          ]),
          child: Row(children: [
            _avatar(currentUser, 34),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: const Color(0xFFF5F4F0),
                    borderRadius: BorderRadius.circular(14)),
                child: TextField(
                  controller: _commentCtrl,
                  focusNode: _focusNode,
                  decoration: InputDecoration.collapsed(
                    hintText: hintText,
                    hintStyle:
                        const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                  ),
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendComment,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2D2D5E), Color(0xFF1A1A2E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _isSending
                    ? const Center(
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)))
                    : Icon(
                        _editingComment != null
                            ? Icons.check_rounded
                            : Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _avatar(CommunityUser user, double size) {
    final isLawyer = user.role == UserRole.lawyer;
    final isMe = user.id == currentUser.id;
    final initials = user.name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join();
    return Stack(children: [
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                colors: isMe
                    ? [const Color(0xFFF57F17), const Color(0xFFFF8F00)]
                    : (isLawyer
                        ? [const Color(0xFF1565C0), const Color(0xFF1976D2)]
                        : [const Color(0xFF37474F), const Color(0xFF546E7A)]),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)),
        child: ClipOval(
          child: user.avatarUrl.isNotEmpty
              ? (user.avatarUrl.startsWith('http') ||
                      user.avatarUrl.startsWith('https')
                  ? Image.network(user.avatarUrl, fit: BoxFit.cover)
                  : Image.asset(user.avatarUrl, fit: BoxFit.cover))
              : Center(
                  child: Text(initials,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: size * 0.33,
                          fontWeight: FontWeight.w700)),
                ),
        ),
      ),
      if (user.isVerified)
        Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.33,
              height: size * 0.33,
              decoration: BoxDecoration(
                  color: const Color(0xFF00ACC1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5)),
              child: Icon(Icons.check_rounded,
                  size: size * 0.18, color: Colors.white),
            )),
    ]);
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w500))
    ]);
  }

  void goBack() async {
    Navigator.pop(context, widget.post);
  }
}

// ─── Create Post Screen ────────────────────────────────────────────────────────

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();
  List<Map<String, dynamic>> _subTopics = [];
  Map<String, dynamic>? _selectedSubTopic;
  bool _loadingSubTopics = true;
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _loadSubTopics();
  }

  Future<void> _loadSubTopics() async {
    setState(() => _loadingSubTopics = true);
    try {
      final param = await postDio('${server}/m/topic/subTopic/read', {});
      if (!mounted) return;

      final raw = param is Map ? param['objectData'] : null;
      final list = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .where((item) => (item['title'] as String? ?? '').trim().isNotEmpty)
              .toList()
          : <Map<String, dynamic>>[];

      setState(() {
        _subTopics = list;
        _loadingSubTopics = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSubTopics = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<List<String>> _uploadImages() async {
    final urls = <String>[];
    for (final image in _selectedImages) {
      final url = await uploadImageX(image);
      if (url.isNotEmpty) urls.add(url);
    }
    return urls;
  }

  CommunityPost _buildCreatedPost({
    Map<String, dynamic>? apiData,
    List<String> galleryUrls = const [],
  }) {
    if (apiData != null) {
      final gallery = (apiData['gallery'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          galleryUrls;

      return CommunityPost(
        id: (apiData['id'] ?? apiData['code'] ?? 'p_${DateTime.now().millisecondsSinceEpoch}')
            .toString(),
        author: currentUser,
        content: apiData['description']?.toString() ??
            apiData['content']?.toString() ??
            _contentCtrl.text.trim(),
        category: apiData['subTopic']?.toString() ??
            apiData['category']?.toString() ??
            _selectedSubTopic?['code']?.toString() ??
            '',
        subTopicTitle: apiData['subTopicTitle']?.toString() ??
            _selectedSubTopic?['title']?.toString() ??
            '',
        createdAt: DateTime.now(),
        imagePaths: gallery,
      );
    }

    return CommunityPost(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      author: currentUser,
      content: _contentCtrl.text.trim(),
      category: _selectedSubTopic?['code']?.toString() ?? '',
      subTopicTitle: _selectedSubTopic?['title']?.toString() ?? '',
      createdAt: DateTime.now(),
      imagePaths: galleryUrls.isNotEmpty
          ? galleryUrls
          : _selectedImages.map((x) => x.path).toList(),
    );
  }

  Future<void> _submitPost() async {
    if (_isPosting) return;

    if (_contentCtrl.text.trim().isEmpty) {
      _showError('enterDetails'.tr());
      return;
    }
    if (_selectedSubTopic == null) {
      _showError('selectCategory'.tr());
      return;
    }

    final subTopicCode = _selectedSubTopic!['code']?.toString() ?? '';
    final subTopicTitle = _selectedSubTopic!['title']?.toString() ?? '';

    setState(() => _isPosting = true);
    DialogService.showLoading(context);

    try {
      final galleryUrls = await _uploadImages();
      final title = _titleCtrl.text.trim();
      final content = _contentCtrl.text.trim();
      final description = title.isNotEmpty ? '$title\n\n$content' : content;

      final result = await postObjectData('/m/community/create', {
        'profileCode': UserProfileStore.instance.code.trim(),
        'description': description,
        'category': subTopicCode,
        'subTopic': subTopicCode,
        'subTopicTitle': subTopicTitle,
        'gallery': galleryUrls,
      });

      if (!mounted) return;
      Navigator.pop(context);

      if (result['status'] == 'S') {
        final data = result['objectData'];
        Map<String, dynamic>? createdMap;
        if (data is Map) {
          createdMap = Map<String, dynamic>.from(data);
        } else if (data is List && data.isNotEmpty && data.first is Map) {
          createdMap = Map<String, dynamic>.from(data.first as Map);
        }

        final newPost = _buildCreatedPost(
          apiData: createdMap,
          galleryUrls: galleryUrls,
        );
        Navigator.pop(context, newPost);
        return;
      }

      _showError(result['message']?.toString() ?? 'เกิดข้อผิดพลาด กรุณาลองใหม่');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showError('เกิดข้อผิดพลาด กรุณาลองใหม่');
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        for (final img in images) {
          if (_selectedImages.length < 4) _selectedImages.add(img);
        }
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (image != null && _selectedImages.length < 4)
      setState(() => _selectedImages.add(image));
  }

  void _showImageSourceSheet() {
    MediaPickerSheet.showImageSources(
      context,
      onGallery: _pickFromGallery,
      onCamera: _pickFromCamera,
    );
  }

  Widget _buildSubTopicDropdown() {
    if (_loadingSubTopics) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return AppDropdownField<String>(
      value: _selectedSubTopic?['code'] as String?,
      hint: 'selectCategory'.tr(),
      prefixIcon: Icons.category_outlined,
      accentColor: const Color(0xFF1A1A2E),
      enabled: _subTopics.isNotEmpty,
      elevated: true,
      items: _subTopics
          .where((item) => (item['code']?.toString() ?? '').isNotEmpty)
          .map(
            (item) => DropdownMenuItem<String>(
              value: item['code']!.toString(),
              child: Text(
                item['title']?.toString() ?? '',
                style: AppDropdownStyles.itemStyle(),
              ),
            ),
          )
          .toList(),
      onChanged: _subTopics.isEmpty
          ? null
          : (code) {
              final selected = _subTopics.firstWhere(
                (item) => item['code']?.toString() == code,
                orElse: () => {},
              );
              setState(() {
                _selectedSubTopic = selected.isEmpty ? null : selected;
              });
            },
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFE53935),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  bool get _canPost =>
      _contentCtrl.text.trim().isNotEmpty && _selectedSubTopic != null;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: isDesktop
          ? const Color.fromARGB(255, 233, 242, 249)
          : const Color(0xFFF5F4F0),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5F4F0),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.close_rounded,
                      size: 20, color: Color(0xFF1A1A2E)),
                ),
              ),
              title: Text('newQuestion'.tr(),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: _canPost && !_isPosting ? _submitPost : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: _canPost
                              ? const Color(0xFF1A1A2E)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10)),
                      child: _isPosting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text('post'.tr(),
                              style: TextStyle(
                                  color: _canPost
                                      ? Colors.white
                                      : Colors.grey.shade400,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
      body: AppLayout(
        child: Container(
          clipBehavior: isDesktop ? Clip.antiAlias : Clip.none,
          decoration: isDesktop
              ? const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                )
              : null,
          child: Column(
            children: [
              if (isDesktop) ...[
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF5F4F0),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.close_rounded,
                              size: 20, color: Color(0xFF1A1A2E)),
                        ),
                      ),
                      Text(
                        'newQuestion'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      GestureDetector(
                        onTap: _canPost && !_isPosting ? _submitPost : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                              color: _canPost
                                  ? const Color(0xFF1A1A2E)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10)),
                          child: _isPosting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text('post'.tr(),
                                  style: TextStyle(
                                      color: _canPost
                                          ? Colors.white
                                          : Colors.grey.shade400,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User info
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ]),
                        child: Row(children: [
                          _avatarWidget(currentUser, 40),
                          const SizedBox(width: 10),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(currentUser.name,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF1A1A2E))),
                                Text('postPublicly'.tr(),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9E9E9E))),
                              ]),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF5F4F0),
                                borderRadius: BorderRadius.circular(8)),
                            child: Row(children: [
                              Icon(Icons.public_rounded,
                                  size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text('public'.tr(),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600))
                            ]),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 16),

                      // Category
                      Text('problemCategory'.tr(),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 8),
                      _buildSubTopicDropdown(),

                      const SizedBox(height: 16),

                      // // Title
                      // const Text('หัวข้อคำถาม *',
                      //     style: TextStyle(
                      //         fontSize: 13,
                      //         fontWeight: FontWeight.w700,
                      //         color: Color(0xFF1A1A2E))),
                      // const SizedBox(height: 8),
                      // Container(
                      //   decoration: BoxDecoration(
                      //       color: Colors.white,
                      //       borderRadius: BorderRadius.circular(14),
                      //       boxShadow: [
                      //         BoxShadow(
                      //             color: Colors.black.withOpacity(0.04),
                      //             blurRadius: 8,
                      //             offset: const Offset(0, 2))
                      //       ]),
                      //   child: TextField(
                      //     controller: _titleCtrl,
                      //     onChanged: (_) => setState(() {}),
                      //     decoration: const InputDecoration(
                      //       hintText: 'เช่น "ถูกเลิกจ้างไม่มีสาเหตุ ต้องทำอย่างไร?"',
                      //       hintStyle: TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
                      //       contentPadding: EdgeInsets.all(16),
                      //       border: InputBorder.none,
                      //     ),
                      //     style: const TextStyle(
                      //         fontSize: 14,
                      //         color: Color(0xFF1A1A2E),
                      //         fontWeight: FontWeight.w600),
                      //     maxLines: 2,
                      //   ),
                      // ),

                      const SizedBox(height: 14),

                      // Content
                      Text('details'.tr(),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E))),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2))
                            ]),
                        child: TextField(
                          controller: _contentCtrl,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'describeProblemHint'.tr(),
                            hintStyle: TextStyle(
                                color: Color(0xFFBDBDBD), fontSize: 13),
                            contentPadding: EdgeInsets.all(16),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF424242),
                              height: 1.6),
                          maxLines: 6,
                          minLines: 4,
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Images
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('attachmentImages'.tr(),
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1A2E))),
                            Text('${_selectedImages.length}/4',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade500)),
                          ]),
                      const SizedBox(height: 8),

                      if (_selectedImages.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length +
                                (_selectedImages.length < 4 ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == _selectedImages.length) {
                                return GestureDetector(
                                  onTap: _showImageSourceSheet,
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey.shade200,
                                            width: 1.5)),
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_rounded,
                                              size: 24,
                                              color: Colors.grey.shade400),
                                          const SizedBox(height: 4),
                                          Text('addImage'.tr(),
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade400)),
                                        ]),
                                  ),
                                );
                              }
                              return Stack(children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  margin: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                          File(_selectedImages[i].path),
                                          fit: BoxFit.cover)),
                                ),
                                Positioned(
                                    top: 4,
                                    right: 12,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                          () => _selectedImages.removeAt(i)),
                                      child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: const BoxDecoration(
                                              color: Color(0xFFE53935),
                                              shape: BoxShape.circle),
                                          child: const Icon(Icons.close_rounded,
                                              size: 14, color: Colors.white)),
                                    )),
                              ]);
                            },
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _showImageSourceSheet,
                          child: Container(
                            width: double.infinity,
                            height: 90,
                            decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: Colors.grey.shade200, width: 1.5)),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      size: 28, color: Colors.grey.shade400),
                                  const SizedBox(height: 6),
                                  Text('tapToAddImages'.tr(),
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade400)),
                                ]),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Tips
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF0F7FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFBBDEFB))),
                        child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.lightbulb_outline_rounded,
                                  size: 18, color: Color(0xFF1565C0)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text('tipTitle'.tr(),
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1565C0))),
                                    const SizedBox(height: 4),
                                    Text('tipBody'.tr(),
                                        style: TextStyle(
                                            fontSize: 11.5,
                                            color: Colors.blue.shade700,
                                            height: 1.5)),
                                  ])),
                            ]),
                      ),

                      const SizedBox(height: 30),
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

  Widget _avatarWidget(CommunityUser user, double size) {
    final initials = user.name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
              colors: [Color(0xFFF57F17), Color(0xFFFF8F00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      child: ClipOval(
        child: user.avatarUrl.isNotEmpty
            ? (user.avatarUrl.startsWith('http') ||
                    user.avatarUrl.startsWith('https')
                ? Image.network(user.avatarUrl, fit: BoxFit.cover)
                : Image.asset(user.avatarUrl, fit: BoxFit.cover))
            : Center(
                child: Text(initials,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.33,
                        fontWeight: FontWeight.w700)),
              ),
      ),
    );
  }
}
