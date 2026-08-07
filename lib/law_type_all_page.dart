import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/component/loading_service.dart';
import 'package:LawyerOnline/lawyer-online-list.dart';
import 'package:LawyerOnline/shared/api_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

class LawTypeAllPage extends StatefulWidget {
  const LawTypeAllPage({super.key});

  @override
  State<LawTypeAllPage> createState() => _LawTypeAllPageState();
}

class _LawTypeAllPageState extends State<LawTypeAllPage> {
  dynamic _selectedTopic;
  dynamic _selectedSubTopic;
  String _search = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _caseTypeList = [];

  static const _palette = <int>[
    0xFF64748B,
    0xFF0262EC,
    0xFFE11D48,
    0xFFFF6B35,
    0xFFDC2626,
    0xFF059669,
    0xFF7C3AED,
    0xFF0891B2,
    0xFFD97706,
    0xFFDB2777,
    0xFF6D28D9,
    0xFF0F766E,
  ];

  @override
  void initState() {
    super.initState();
    _readTopic();
  }

  Future<void> _readTopic() async {
    setState(() => _isLoading = true);
    try {
      final param = await postDio('$server/m/topic/read', {});
      final objectData = param is Map ? param['objectData'] : null;
      if (!mounted) return;

      final list = <Map<String, dynamic>>[];
      if (objectData is List) {
        for (var i = 0; i < objectData.length; i++) {
          final raw = objectData[i];
          if (raw is! Map) continue;
          final item = Map<String, dynamic>.from(raw);
          final title = item['title']?.toString().trim() ?? '';
          if (title.isEmpty) continue;

          final code = item['code']?.toString().trim() ?? '';
          final imageUrl = item['imageUrl']?.toString().trim() ?? '';
          final subRaw = item['subTopics'] ?? item['subCase'] ?? const [];
          final subCase = <Map<String, dynamic>>[];
          if (subRaw is List) {
            for (final s in subRaw) {
              if (s is! Map) continue;
              final sub = Map<String, dynamic>.from(s);
              if ((sub['title']?.toString().trim() ?? '').isEmpty) continue;
              subCase.add(sub);
            }
          }

          list.add({
            'code': code.isNotEmpty ? code : '$i',
            'title': title,
            'imageUrl': imageUrl,
            'color': _palette[i % _palette.length],
            'subCase': subCase,
          });
        }
      }

      setState(() {
        _caseTypeList = list;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _caseTypeList = [];
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _subCases {
    if (_selectedTopic == null) return [];
    final raw = _selectedTopic!['subCase'];
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .where((s) => (s['title']?.toString().trim() ?? '').isNotEmpty)
        .toList();
  }

  bool get _hasSubCase => _subCases.isNotEmpty;

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _caseTypeList;
    final q = _search.toLowerCase();
    return _caseTypeList.where((item) {
      final title = (item['title']?.toString() ?? '').toLowerCase();
      final sub = (item['subCase'] as List).any((s) =>
          (s is Map) &&
          (s['title']?.toString().toLowerCase() ?? '').contains(q));
      return title.contains(q) || sub;
    }).toList();
  }

  void _navigate(Map<String, dynamic> topic) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LawyerOnlineList(
          topic: topic['title'] as String,
          subTopic: _selectedSubTopic?['title']?.toString() ?? '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final selectedColor = _selectedTopic != null
        ? Color(_selectedTopic!['color'] as int)
        : const Color(0xFF0262EC);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F6FF),
        appBar: appBarCustom(
          title: 'lawTopicsTitle'.tr(),
          backBtn: true,
          isRightWidget: false,
          backAction: () => Navigator.pop(context),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 768;
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : 500),
                child: Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(
                      child: _isLoading
                          ? AppLoadingView(message: 'lawTopicsLoading'.tr())
                          : isDesktop
                              ? _buildDesktopLayout(filtered, selectedColor)
                              : _buildMobileLayout(filtered, selectedColor),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
      List<Map<String, dynamic>> filtered, Color selectedColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            child: filtered.isEmpty
                ? _buildEmpty()
                : _buildGrid(filtered, isDesktop: true),
          ),
        ),
        if (_selectedTopic != null && _hasSubCase)
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(0, 8, 16, 40),
              child: _buildSubCaseSection(selectedColor),
            ),
          )
        else
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.touch_app_rounded,
                        size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'lawTopicsSelectHint'.tr(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileLayout(
      List<Map<String, dynamic>> filtered, Color selectedColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (filtered.isEmpty)
            _buildEmpty()
          else
            _buildGrid(filtered, isDesktop: false),
          if (_selectedTopic != null && _hasSubCase) ...[
            const SizedBox(height: 20),
            _buildSubCaseSection(selectedColor),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: const Color(0xFFDDE5F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          onChanged: (v) => setState(() {
            _search = v;
            if (_selectedTopic != null) {
              final titles = _filtered.map((e) => e['title']).toList();
              if (!titles.contains(_selectedTopic!['title'])) {
                _selectedTopic = null;
                _selectedSubTopic = null;
              }
            }
          }),
          style: const TextStyle(color: Color(0xFF1A2340), fontSize: 13),
          decoration: InputDecoration(
            hintText: 'lawTopicsSearchHint'.tr(),
            hintStyle: TextStyle(
                color: const Color(0xFF1A2340).withValues(alpha: 0.3),
                fontSize: 13),
            prefixIcon: Icon(Icons.search_rounded,
                color: const Color(0xFF1A2340).withValues(alpha: 0.35),
                size: 18),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.only(top: 9, bottom: 0),
          ),
        ),
      ),
    );
  }

  Widget _topicImage(String imageUrl, {double size = 44}) {
    final url = imageUrl.trim();
    if (url.isEmpty) {
      return Icon(
        Icons.gavel_rounded,
        size: size * 0.7,
        color: const Color(0xFF94A3B8),
      );
    }
    if (url.startsWith('assets/')) {
      return Image.asset(url, width: size, height: size, fit: BoxFit.contain);
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      memCacheWidth: 160,
      placeholder: (_, __) => SizedBox(
        width: size,
        height: size,
        child: const Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Icon(
        Icons.gavel_rounded,
        size: size * 0.7,
        color: const Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> items, {bool isDesktop = false}) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 4 : 3,
        crossAxisSpacing: isDesktop ? 16 : 8,
        mainAxisSpacing: isDesktop ? 16 : 8,
        childAspectRatio: isDesktop ? 1.3 : 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final color = Color(item['color'] as int);
        final isSelected = _selectedTopic?['code'] == item['code'];
        final imageUrl = item['imageUrl']?.toString() ?? '';

        return GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            final subCases = (item['subCase'] as List)
                .whereType<Map>()
                .where((s) => (s['title']?.toString().trim() ?? '').isNotEmpty)
                .toList();
            if (subCases.isEmpty) {
              _selectedSubTopic = null;
              _navigate(item);
            } else {
              setState(() {
                _selectedTopic = isSelected ? null : item;
                _selectedSubTopic = null;
              });
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.1)
                  : const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? color : const Color(0xFFE2E8F4),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _topicImage(imageUrl, size: isDesktop ? 52 : 44),
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    item['title'] as String,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? color : const Color(0xFF5B6E8A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubCaseSection(Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'lawTopicsSubOf'.tr(args: [_selectedTopic!['title'].toString()]),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A2340)),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: _subCases.asMap().entries.map((e) {
              final idx = e.key;
              final sub = e.value;
              final isLast = idx == _subCases.length - 1;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedSubTopic = sub);
                  _navigate(_selectedTopic!);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  decoration: BoxDecoration(
                    border: !isLast
                        ? const Border(
                            bottom: BorderSide(color: Color(0xFFF0F4F8)))
                        : null,
                  ),
                  child: Row(children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        sub['title'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              const Color(0xFF1A2340).withValues(alpha: 0.75),
                          height: 1.4,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color:
                            const Color(0xFF1A2340).withValues(alpha: 0.2)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty() {
    final hasSearch = _search.trim().isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
                color: Color(0xFFF0F4F8), shape: BoxShape.circle),
            child: Icon(
                hasSearch ? Icons.search_off_rounded : Icons.inbox_outlined,
                color: const Color(0xFF1A2340).withValues(alpha: 0.25),
                size: 28),
          ),
          const SizedBox(height: 12),
          Text(
              hasSearch ? 'notFoundQuery'.tr(args: [_search]) : 'lawTopicsEmpty'.tr(),
              style: TextStyle(
                  color: const Color(0xFF1A2340).withValues(alpha: 0.55),
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
              hasSearch ? 'tryOtherSearch'.tr() : 'tryAgain'.tr(),
              style: TextStyle(
                  color: const Color(0xFF1A2340).withValues(alpha: 0.3),
                  fontSize: 12)),
          if (!hasSearch) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _readTopic,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text('reload'.tr()),
            ),
          ],
        ]),
      ),
    );
  }
}
