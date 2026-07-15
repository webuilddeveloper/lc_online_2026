import 'package:flutter/material.dart';

class TopNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final String? imageUrl;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const TopNotificationBanner({
    super.key,
    required this.title,
    required this.body,
    this.imageUrl,
    this.onTap,
    required this.onDismiss,
  });

  @override
  State<TopNotificationBanner> createState() => _TopNotificationBannerState();
}

class _TopNotificationBannerState extends State<TopNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _offset = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _dismiss();
    });
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildAvatar() {
    final url = widget.imageUrl?.trim() ?? '';
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          url,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackIcon(),
        ),
      );
    }
    return _fallbackIcon();
  }

  Widget _fallbackIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF0262EC).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.notifications, color: Color(0xFF0262EC)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _offset,
        child: SafeArea(
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {
                _dismiss();
                widget.onTap?.call();
              },
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) < 0) _dismiss();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(widget.body,
                              style: const TextStyle(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
