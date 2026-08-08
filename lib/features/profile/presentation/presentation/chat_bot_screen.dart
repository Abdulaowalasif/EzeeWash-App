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
  final File? imageFile;
  final String? serviceId; // Non-null when bot recommends a specific service
  final String? botAction; // Navigation action

  const _Message({
    required this.text,
    required this.sender,
    required this.time,
    this.imageFile,
    this.serviceId,
    this.botAction,
  });
}

class BotResponse {
  final String reply;
  final String action;
  final String? serviceId;

  BotResponse({required this.reply, required this.action, this.serviceId});
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  State<ChatBotScreen> createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> with TickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _botTyping = false;
  late final AnimationController _floatController;
  final List<Offset> _bubbleOffsets = const [
    Offset(0.1, 0.2),
    Offset(0.85, 0.25),
    Offset(0.2, 0.55),
    Offset(0.8, 0.65),
    Offset(0.5, 0.85),
    Offset(0.4, 0.1),
    Offset(0.7, 0.9),
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  final List<_Message> _messages = [
    _Message(
      text:
          "Hi I am <blue>Bubble Bot</blue>💭. I can help you with orders, laundry tips, and more. What do you need?",
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
      final promptText = (t.isEmpty && image != null)
          ? "Please analyze this fabric/item."
          : t;

      final BotResponse botData = await ChatApi.sendMessage(
        promptText,
        imageFile: image,
      );

      if (!mounted) return;

      setState(() {
        _botTyping = false;
        _messages.add(
          _Message(
            text: botData.reply,
            sender: _Sender.bot,
            time: DateTime.now(),
            serviceId: botData.serviceId,
            botAction: botData.action != 'none' ? botData.action : null,
          ),
        );
      });

      _jump();
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
    _floatController.dispose();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bg,
      appBar: const GradientAppBar(
        backEnabled: false,
        title: 'Bubble Bot',
        trailing: _OnlinePill(),
      ),
      body: Stack(
        children: [
          ..._bubbleOffsets.asMap().entries.map((e) => _FloatingBubble(
            controller: _floatController,
            x: e.value.dx * size.width,
            y: e.value.dy * size.height,
            index: e.key,
            isDark: isDark,
          )),
          Column(
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

                return _Bubble(
                  msg: msg,
                  isDark: isDark,
                  onBookNow: msg.serviceId != null
                      ? () => context.go(
                          '/orders/place-orders',
                          extra: msg.serviceId,
                        )
                      : null,
                  onBotAction: msg.botAction != null
                      ? () {
                          switch (msg.botAction) {
                            case 'nav_track_order':
                              context.go('/orders/track-orders');
                              break;
                            case 'nav_pricing':
                              context.go('/services');
                              break;
                            case 'nav_profile':
                              context.pop();
                              break;
                          }
                        }
                      : null,
                );
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
      ],
      ),
    );
  }
}

// ─── Bubble ───────────────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  final _Message msg;
  final bool isDark;
  final VoidCallback? onBookNow;
  final VoidCallback? onBotAction;

  const _Bubble({
    required this.msg,
    required this.isDark,
    this.onBookNow,
    this.onBotAction,
  });

  List<TextSpan> _spans(bool isUser) {
    final base = AppTextStyles.body(isDark).copyWith(
      color: isUser
          ? Colors.white
          : (isDark ? AppColors.darkText : AppColors.lightText),
      height: 1.5,
      fontSize: 14.0,
    );
    final bold = base.copyWith(fontWeight: FontWeight.w700);
    final blueBold = bold.copyWith(color: Colors.blue);
    final spans = <TextSpan>[];
    final rx = RegExp(r'<blue>(.*?)</blue>|\*([^*]+)\*');
    int c = 0;
    for (final m in rx.allMatches(msg.text)) {
      if (m.start > c) {
        spans.add(TextSpan(text: msg.text.substring(c, m.start), style: base));
      }
      if (m.group(1) != null) {
        spans.add(TextSpan(text: m.group(1), style: blueBold));
      } else if (m.group(2) != null) {
        spans.add(TextSpan(text: m.group(2), style: bold));
      }
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
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[const _Avatar(size: 34), const SizedBox(width: 10)],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  decoration: BoxDecoration(
                    gradient: isUser ? AppColors.gradient : null,
                    color: isUser
                        ? null
                        : (isDark ? AppColors.darkSurface : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(22),
                      topRight: const Radius.circular(22),
                      bottomLeft: Radius.circular(isUser ? 22 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 22),
                    ),
                    
                    border: isUser
                        ? null
                        : Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : Colors.grey.withOpacity(0.15),
                            width: 1,
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

                      // BOOK NOW BUTTON — only for bot messages with a service
                      if (!isUser &&
                          msg.serviceId != null &&
                          onBookNow != null) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: onBookNow,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: AppColors.gradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.local_laundry_service_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Book This Service',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // ACTION BUTTON — for suggested navigation actions
                      if (!isUser &&
                          msg.botAction != null &&
                          onBotAction != null) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: onBotAction,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBackground
                                  : AppColors.lightBackground,
                              border: Border.all(
                                color: AppColors.primary.withOpacity(0.3),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  msg.botAction == 'nav_track_order'
                                      ? Iconsax.box
                                      : msg.botAction == 'nav_pricing'
                                      ? Iconsax.money_3
                                      : Iconsax.user,
                                  color: AppColors.primary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  msg.botAction == 'nav_track_order'
                                      ? 'Track My Order'
                                      : msg.botAction == 'nav_pricing'
                                      ? 'View All Pricing'
                                      : 'Go to Profile',
                                  style: TextStyle(color: AppColors.primary),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: AppColors.primary,
                                  size: 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                      color: isDark
                          ? AppColors.darkSubtext
                          : AppColors.lightSubtext,
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
                color: isDark
                    ? AppColors.darkBorder
                    : AppColors.lightBorder.withOpacity(0.6),
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
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurface.withOpacity(0.5)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder
                    : AppColors.primary.withOpacity(0.15),
                width: 1,
              ),
              
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chips[i].substring(0, 2), // The emoji
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(width: 6),
                Text(
                  chips[i].substring(2).trim(), // The text
                  style: AppTextStyles.captionMedium(isDark).copyWith(
                    color: isDark ? AppColors.darkText : AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
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
              margin: const EdgeInsets.only(bottom: 4, left: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground
                    : AppColors.lightBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.camera, color: AppColors.primary, size: 20),
            ),
          ),

          Expanded(
            child: TextField(
              controller: ctrl,
              style: AppTextStyles.body(isDark).copyWith(fontSize: 15),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: onSend,
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                hintStyle: AppTextStyles.hint(isDark).copyWith(fontSize: 14),
                filled: true,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 14,
                  bottom: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Send Button
          GestureDetector(
            onTap: () => onSend(ctrl.text),
            child: Container(
              margin: const EdgeInsets.only(bottom: 2, right: 2),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppColors.gradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.send_1, color: Colors.white, size: 18),
            ),
          ),
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
      
      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
    ),
    child: Icon(
      Icons.smart_toy_rounded,
      color: Colors.white,
      size: size * 0.58,
    ),
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
          style: AppTextStyles.captionMedium(false).copyWith(
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

  static Future<BotResponse> sendMessage(
    String message, {
    File? imageFile,
  }) async {
    String? base64Image;

    if (imageFile != null) {
      final bytes = await imageFile.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    // Get the current logged-in user ID to enable user-specific promos
    final userId = _supabase.auth.currentUser?.id;

    try {
      final res = await _supabase.functions.invoke(
        'bubble-bot',
        body: {
          'message': message,
          if (base64Image != null) 'image': base64Image,
          if (userId != null) 'user_id': userId,
        },
      );

      final data = res.data;
      if (data == null) {
        return BotResponse(reply: "Error processing request", action: "none");
      }

      debugPrint("EDGE FUNCTION RESPONSE: $data");

      if (data is Map) {
        return BotResponse(
          reply: data['reply']?.toString() ?? "Sorry, I didn't understand.",
          action: data['action']?.toString() ?? "none",
          serviceId: data['service_id']?.toString(),
        );
      } else {
        return BotResponse(
          reply: "Unexpected response format.",
          action: "none",
        );
      }
    } catch (e) {
      debugPrint("API CALL ERROR: $e");
      return BotResponse(
        reply: "Connection error. Please try again.",
        action: "none",
      );
    }
  }
}

// ─── Floating bubbles ─────────────────────────────────────────────────────────

class _FloatingBubble extends StatelessWidget {
  final AnimationController controller;
  final double x, y;
  final int index;
  final bool isDark;

  const _FloatingBubble({
    required this.controller,
    required this.x,
    required this.y,
    required this.index,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const sizes = [58.0, 38.0, 74.0, 46.0, 30.0];
    const delays = [0.0, 0.20, 0.45, 0.65, 0.85];
    final sz = sizes[index % sizes.length];
    final delay = delays[index % delays.length];

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = (controller.value + delay) % 1.0;
        final dy = sin(t * pi * 2) * 12;
        final dx = cos(t * pi) * 5;
        return Positioned(
          left: x - sz / 2 + dx,
          top: y - sz / 2 + dy,
          child: Container(
            width: sz, height: sz,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(isDark ? 0.08 : 0.05),
              border: Border.all(
                color: AppColors.primary.withOpacity(isDark ? 0.14 : 0.09),
                width: 1,
              ),
            ),
          ),
        );
      },
    );
  }
}
