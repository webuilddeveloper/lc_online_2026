import 'package:flutter/material.dart';

appBarHome(
    {String? name = "",
    String? memberType = "",
    String? imageUrl = "",
    String? typeLogin = "local",
    Widget? rightWidget,
    Function? rightAction,
    Function? profileAction}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(130),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 17,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => profileAction,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      width: 1,
                      color: const Color(0xFFDBDBDB),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Container(
                      //   width: 32,
                      //   height: 32,
                      //   decoration: BoxDecoration(
                      //     borderRadius: BorderRadius.circular(14),
                      //     image: DecorationImage(
                      //       image: NetworkImage(imageUrl!),
                      //       // assets/images/avatar.png
                      //     ),
                      //   ),
                      // ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: typeLogin == 'local'
                            ? Image.asset(
                                imageUrl!,
                                fit: BoxFit.cover,
                                width: 32,
                                height: 32,
                              )
                            : Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                                width: 32,
                                height: 32,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name!,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            memberType!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      // const SizedBox(width: 6),
                      // Icon(
                      //   Icons.keyboard_arrow_down,
                      //   color: Color(0xFF000000).withOpacity(0.6),
                      // ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              rightWidget!
            ],
          ),
        ),
      ),
    ),
  );
}

appBar(
    {String? title = "",
    bool backBtn = true,
    bool rightBtn = true,
    Function? rightAction,
    Function? backAction,
    bool isFavorite = false}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(80),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 17,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              backBtn
                  ? GestureDetector(
                      onTap: () => backAction!(),
                      child: Container(
                        width: 40,
                        alignment: Alignment.center,
                        // padding: const EdgeInsets.symmetric(
                        //   horizontal: 12,
                        //   vertical: 10,
                        // ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          // borderRadius: BorderRadius.circular(22),
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 1,
                            color: const Color(0xFFDBDBDB),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 15,
                        ),
                      ),
                    )
                  : Container(
                      width: 40,
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Center(
                  child: Text(
                    title!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ignore: unrelated_type_equality_checks
              rightBtn
                  ? GestureDetector(
                      onTap: () => rightAction?.call(),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isFavorite
                              ? const Color(0xFFFFF0F0)
                              : const Color(0xFFFAFAFA),
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 1,
                            color: isFavorite
                                ? Colors.red
                                : const Color(0xFFDBDBDB),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            key: ValueKey(isFavorite),
                            size: 18,
                            color: isFavorite ? Colors.red : Colors.black54,
                          ),
                        ),
                      ),
                    )
                  : Container(width: 40),
            ],
          ),
        ),
      ),
    ),
  );
}

appBarCustom(
    {String? title = "",
    String? subTitle = "",
    bool backBtn = true,
    bool isRightWidget = true,
    Widget? rightWidget,
    Function? backAction}) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(80), // 🔻 ลดความสูง
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 17,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              /// 🔹 LEFT
              backBtn
                  ? GestureDetector(
                      onTap: () => backAction!(),
                      child: Container(
                        width: 40,
                        alignment: Alignment.center,
                        // padding: const EdgeInsets.symmetric(
                        //   horizontal: 12,
                        //   vertical: 10,
                        // ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          // borderRadius: BorderRadius.circular(22),
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 1,
                            color: const Color(0xFFDBDBDB),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 15,
                        ),
                      ),
                    )
                  : Container(
                      width: 40,
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              /// 🔔 RIGHT
              // ignore: unrelated_type_equality_checks
              isRightWidget
                  ? rightWidget!
                  : Container(
                      width: 40,
                    ),
            ],
          ),
        ),
      ),
    ),
  );
}

// ─── AppBar สำหรับหน้าแชทโดยเฉพาะ ───────────────────────────────
PreferredSizeWidget appBarChat({
  required VoidCallback onBack,
  required Widget avatarWidget,
  required String name,
  String? statusText,
  Widget? actions,
}) {
  return _DynamicAppBar(
    onBack: onBack,
    avatarWidget: avatarWidget,
    name: name,
    statusText: statusText,
    actions: actions,
  );
}

class _DynamicAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onBack;
  final Widget avatarWidget;
  final String name;
  final String? statusText;
  final Widget? actions;

  const _DynamicAppBar({
    required this.onBack,
    required this.avatarWidget,
    required this.name,
    this.statusText,
    this.actions,
  });

  @override
  Size get preferredSize {
    // contentHeight + statusBar (ประมาณ) + bottom padding
    return const Size.fromHeight(80);
  }

  @override
  Widget build(BuildContext context) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final contentHeight = 80.0; // ความสูง row content

    return Container(
      padding: EdgeInsets.fromLTRB(16, statusBarHeight + 12, 16, 12),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 17,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                shape: BoxShape.circle,
                border: Border.all(width: 1, color: const Color(0xFFDBDBDB)),
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 15),
            ),
          ),
          const SizedBox(width: 12),
          avatarWidget,
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // ✅ ให้ Column หดตามเนื้อหา
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (statusText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    statusText!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8593A8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actions != null) actions!,
        ],
      ),
    );
  }
}
