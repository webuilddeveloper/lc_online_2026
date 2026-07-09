import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onAttach;
  final bool isUploading;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttach,
    this.isUploading = false,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  void _handleSend() {
    if (widget.isUploading || widget.controller.text.trim().isEmpty) return;
    widget.onSend();
    widget.controller.value = const TextEditingValue(
      text: '',
      selection: TextSelection.collapsed(offset: 0),
    );
    _focusNode.requestFocus();
    setState(() {});
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.enter) {
      return KeyEventResult.ignored;
    }
    if (HardwareKeyboard.instance.isShiftPressed) return KeyEventResult.ignored;
    if (widget.isUploading || widget.controller.text.trim().isEmpty) {
      return KeyEventResult.ignored;
    }

    _handleSend();
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSend =
        !widget.isUploading && widget.controller.text.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: Container(
        color: const Color(0xFFEEF2F5),
        padding: EdgeInsets.only(
          left: 15,
          right: 15,
          bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 15 : 25,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isUploading)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'chatUploading'.tr(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8593A8),
                      ),
                    ),
                  ],
                ),
              ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 9 * 24.0 + 20),
              child: Focus(
                onKeyEvent: _onKey,
                child: TextField(
                  focusNode: _focusNode,
                  controller: widget.controller,
                  enabled: !widget.isUploading,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.normal,
                    fontSize: 15,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.fromLTRB(14.0, 10.0, 14.0, 10.0),
                    hintText: 'typeMessage'.tr(),
                    hintStyle: const TextStyle(color: Color(0xFF8593A8)),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 13, 15, 13),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: widget.isUploading ? null : widget.onAttach,
                            child: Opacity(
                              opacity: widget.isUploading ? 0.4 : 1,
                              child: Image.asset(
                                'assets/icons/input-gallery.png',
                                width: 26,
                                height: 26,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: canSend ? _handleSend : null,
                            child: Icon(
                              Icons.send,
                              size: 26,
                              color: canSend
                                  ? const Color(0xFF0262EC)
                                  : const Color(0xFFBDBDBD),
                            ),
                          ),
                        ],
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFF0262EC)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: Color(0xFF0262EC)),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide:
                          BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
