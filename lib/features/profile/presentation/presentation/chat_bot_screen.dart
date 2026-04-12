// lib/features/profile/presentation/presentation/chat_bot_screen.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart'; // For action routing

import '../../../../core/constants/app_color.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/widgets.dart';

// ─── Data ─────────────────────────────────────────────────────────────────────

enum _Sender { user, bot }

class _Message {
  final String text;
  final _Sender sender;
  final DateTime time;
  final File? imageFile; // Added to support image rendering in bubbles

  const _Message({
    required this.text,
    required this.sender,
    required this.time,
    this.imageFile,
  });
}

class BotResponse {
  final String reply;
  final String action;

  BotResponse({required this.reply, required this.action});
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _botTyping = false;

  final List<_Message> _messages = [
    _Message(
      text: "I can help you with orders, laundry tips, and more. What do you need?",
      sender: _Sender.bot,
      time: DateTime.now(),
    ),
  ];

  static const _chips = [
    '📦 Track order',
    '💡 Laundry tips',
    '❓ How it works',
    '💰 Pricing',
  ];

  // ─── PICK IMAGE ──────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        // Send the image with an optional caption if they typed something
        _send(_ctrl.text, image: File(image.path));
      }
    } catch (e) {
      debugPrint("IMAGE PICK ERROR: $e");
    }
  }

  // ─── SEND MESSAGE (ACTION SUPPORTED) ─────────────────────────────────────

  Future<void> _send(String text, {File? image}) async {
    final t = text.trim();
    if (t.isEmpty && image == null) return;

    _ctrl.clear();

    setState(() {
      _messages.add(
        _Message(
          text: t,
          sender: _Sender.user,
          time: DateTime.now(),
          imageFile: image,
        ),
      );
      _botTyping = true;
    });

    _jump();

    try {
      // If user only sends an image, provide a default prompt for Gemini
      final promptText = (t.isEmpty && image != null) ? "Please analyze this fabric/item." : t;

      final BotResponse botData = await ChatApi.sendMessage(promptText, imageFile: image);

      if (!mounted) return;

      setState(() {
        _botTyping = false;
        _messages.add(
          _Message(
            text: botData.reply,
            sender: _Sender.bot,
            time: DateTime.now(),
          ),
        );
      });

      _jump();

      // Handle Automation Actions Returned by Gemini
      if (botData.action != 'none') {
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (!mounted) return;

          switch (botData.action) {
            case 'nav_track_order':
            // Example router push - update path based on your routes_name.dart
              context.push('/track-order');
              break;
            case 'nav_pricing':
            // context.push('/services');
              break;
            case 'nav_profile':
              context.pop(); // Go back
              break;
          }
        });
      }

    } catch (e) {
      debugPrint("CHAT ERROR: $e");

      setState(() {
        _botTyping = false;
        _messages.add(
          _Message(
            text: "ERROR: $e",
            sender: _Sender.bot,
            time: DateTime.now(),
          ),
        );
      });
    }

    _jump();
  }

  void _jump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;

    return Scaffold(
      backgroundColor: bg,
      appBar: const GradientAppBar(
        backEnabled:false,
        title: 'Bubble Bot',
        trailing: _OnlinePill(),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: EdgeInsets.fromLTRB(
                Responsive.horizontalPadding(context),
                24,
                Responsive.horizontalPadding(context),
                16,
              ),
              itemCount: _messages.length + (_botTyping ? 1 : 0),
              itemBuilder: (ctx, i) {
                if (_botTyping && i == _messages.length) {
                  return _TypingRow(isDark: isDark);
                }

                final msg = _messages[i];

                return _Bubble(msg: msg, isDark: isDark);
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _ChipRow(
              chips: _chips,
              isDark: isDark,
              onTap: (text) => _send(text),
            ),
          ),

          _Bar(
            ctrl: _ctrl,
            isDark: isDark,
            bg: bg,
            onSend: (text) => _send(text),
            onPickImage: _pickImage,
          ),
        ],
      ),
    );
  }
}

// ─── Bubble ───────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final _Message msg;
  final bool isDark;

  const _Bubble({required this.msg, required this.isDark});

  List<TextSpan> _spans(bool isUser) {
    final base = AppTextStyles.body(isDark).copyWith(
      color: isUser
          ? Colors.white
          : (isDark ? AppColors.darkText : AppColors.lightText),
      height: 1.5,
      fontSize: 14.0,
    );
    final bold = base.copyWith(fontWeight: FontWeight.w700);
    final spans = <TextSpan>[];
    final rx = RegExp(r'\*([^*]+)\*');
    int c = 0;
    for (final m in rx.allMatches(msg.text)) {
      if (m.start > c) {
        spans.add(TextSpan(text: msg.text.substring(c, m.start), style: base));
      }
      spans.add(TextSpan(text: m.group(1), style: bold));
      c = m.end;
    }
    if (c < msg.text.length) {
      spans.add(TextSpan(text: msg.text.substring(c), style: base));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isUser = msg.sender == _Sender.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
        isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[const _Avatar(size: 34), const SizedBox(width: 10)],
          Flexible(
            child: Column(
              crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser ? AppColors.gradient : null,
                    color: isUser
                        ? null
                        : (isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(24),
                      topRight: const Radius.circular(24),
                      bottomLeft: Radius.circular(isUser ? 24 : 6),
                      bottomRight: Radius.circular(isUser ? 6 : 24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isUser
                            ? AppColors.primary.withOpacity(0.25)
                            : Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: isUser
                        ? null
                        : Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder.withOpacity(0.6),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // IMAGE DISPLAY LOGIC
                      if (msg.imageFile != null)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: msg.text.trim().isNotEmpty ? 10.0 : 0,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              msg.imageFile!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      // TEXT LOGIC
                      if (msg.text.trim().isNotEmpty)
                        RichText(text: TextSpan(children: _spans(isUser))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    DateFormat('h:mm a').format(msg.time),
                    style: AppTextStyles.tiny(isDark).copyWith(
                      fontSize: 10.5,
                      color: isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─── Typing row ───────────────────────────────────────────────────────────────

class _TypingRow extends StatelessWidget {
  final bool isDark;

  const _TypingRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const _Avatar(size: 34),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder.withOpacity(0.6),
                width: 1.2,
              ),
            ),
            child: const _Dots(),
          ),
        ],
      ),
    );
  }
}

// ─── Animated dots ────────────────────────────────────────────────────────────

class _Dots extends StatefulWidget {
  const _Dots();

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _dot(double phase) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) => Transform.translate(
      offset: Offset(0, -sin(_c.value * 2 * pi + phase) * 4),
      child: child,
    ),
    child: Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.8),
        shape: BoxShape.circle,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      _dot(0),
      const SizedBox(width: 5),
      _dot(1.0),
      const SizedBox(width: 5),
      _dot(2.0),
    ],
  );
}

// ─── Chip row ─────────────────────────────────────────────────────────────────

class _ChipRow extends StatelessWidget {
  final List<String> chips;
  final bool isDark;
  final ValueChanged<String> onTap;

  const _ChipRow({
    required this.chips,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.horizontalPadding(context),
        ),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => onTap(chips[i]),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(isDark ? 0.1 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              chips[i],
              style: AppTextStyles.captionMedium(isDark).copyWith(
                color: AppColors.primary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Input bar ────────────────────────────────────────────────────────────────

class _Bar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool isDark;
  final Color bg;
  final ValueChanged<String> onSend;
  final VoidCallback onPickImage; // Added Image Pick Callback

  const _Bar({
    required this.ctrl,
    required this.isDark,
    required this.bg,
    required this.onSend,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        Responsive.horizontalPadding(context),
        0,
        Responsive.horizontalPadding(context),
        MediaQuery.of(context).padding.bottom + 16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder.withOpacity(0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Image Picker Button
          GestureDetector(
            onTap: onPickImage,
            child: Container(
              padding: const EdgeInsets.only(bottom: 12, right: 8, left: 14),
              child: Icon(
                Iconsax.gallery_add,
                color: AppColors.primary.withOpacity(0.8),
                size: 24,
              ),
            ),
          ),

          Expanded(
            child: TextField(
              controller: ctrl,
              style: AppTextStyles.body(isDark).copyWith(fontSize: 14.5),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: onSend,
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                hintStyle: AppTextStyles.hint(isDark),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.only(
                  left: 8,
                  right: 18,
                  top: 14,
                  bottom: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(34),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(34),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(34),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Send Button
          GestureDetector(
            onTap: () => onSend(ctrl.text),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Iconsax.send_1, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ─── Bot avatar ───────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final double size;

  const _Avatar({required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      gradient: AppColors.gradient,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withOpacity(0.3),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
    ),
    child: Icon(Icons.smart_toy_rounded, color: Colors.white, size: size * 0.55),
  );
}

// ─── Online pill ──────────────────────────────────────────────────────────────

class _OnlinePill extends StatelessWidget {
  const _OnlinePill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.success.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.success.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'Online',
          style: AppTextStyles.captionMedium(
            false,
          ).copyWith(
            color: AppColors.success,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

// ─── API ──────────────────────────────────────────────────────────────────────

class ChatApi {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<BotResponse> sendMessage(String message, {File? imageFile}) async {
    String? base64Image;

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    final res = await _supabase.functions.invoke(
      'bubble-bot',
      body: {
        'message': message,
        if (base64Image != null) 'image': base64Image,
      },
    );

    final data = res.data;
    if (data == null) return BotResponse(reply: "Error processing request", action: "none");

    print(data);
    try {
      // Because we used responseMimeType: application/json in Edge Function,
      // the reply text itself is a JSON string generated by Gemini.
      final String rawText = data['reply'];
      final Map<String, dynamic> parsed = jsonDecode(rawText);

      return BotResponse(
        reply: parsed['reply'] ?? "Sorry, I didn't understand.",
        action: parsed['action'] ?? "none",
      );
    } catch (e) {
      // Fallback if parsing fails or structure isn't perfect
      return BotResponse(reply: data['reply'].toString(), action: "none");
    }
  }
}