import 'dart:io';
import 'package:ezeewash/routes/routes_name.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

const primaryColor = Color(0xFF1D4BC7);
const primaryGradient = LinearGradient(
  colors: [Color(0xFF1D4BC7), Color(0xFF2F2E98)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;

  final nameController = TextEditingController(text: "Asif Imran");
  final emailController = TextEditingController(text: "asif.imran@email.com");
  final phoneController = TextEditingController(text: "+8801401439995");

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedImage = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (pickedImage != null) {
        setState(() {
          _imageFile = File(pickedImage.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: primaryGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Profile",
                  style: GoogleFonts.alexandria(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => isEditing = !isEditing),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isEditing ? "Cancel" : "Edit",
                      style: GoogleFonts.alexandria(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              ProfileHeaderCard(
                isEditing: isEditing,
                nameController: nameController,
                emailController: emailController,
                phoneController: phoneController,
                imageFile: _imageFile,
                onImagePick: _pickImage,
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              if (!isEditing) ...[
                const StatsCard(),
                const SizedBox(height: 24),
                SettingsTile(
                  onPress: () => context.push(RoutesName.addressNavigate),
                  icon: Iconsax.location,
                  title: "Manage Addresses",
                  subtitle: "View saved addresses",
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                SettingsTile(
                  onPress: () => context.go(RoutesName.alerts),
                  icon: Iconsax.notification,
                  title: "Notifications",
                  subtitle: "Push notifications, SMS alerts",
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                SettingsTile(
                  onPress: () => context.push(RoutesName.helpSupportNavigate),
                  icon: Icons.headset_mic_outlined,
                  title: "Help & Support",
                  subtitle: "FAQs, technical support, help contacts",
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                SettingsTile(
                  onPress: () => context.push(RoutesName.termsPolicyNavigate),
                  icon: Iconsax.document,
                  title: "Terms & Privacy",
                  subtitle: "Legal information and regulations",
                  isDark: isDark,
                ),
                const SizedBox(height: 14),
                SettingsTile(
                  onPress: () => context.push(RoutesName.chatBotNavigate),
                  icon: Icons.smart_toy_outlined,
                  title: "Bubble Bot",
                  subtitle: "Chat with bot for any queries",
                  isDark: isDark,
                ),
                const SizedBox(height: 30),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE53935), Color(0xFFC62828)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => context.go(RoutesName.login),
                        icon: const Icon(Iconsax.logout, color: Colors.white, size: 20),
                        label: Text(
                          "Sign Out",
                          style: GoogleFonts.alexandria(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              if (isEditing)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            setState(() {
                              nameController.text = "Asif Imran";
                              emailController.text = "asif.imran@email.com";
                              phoneController.text = "+8801401439995";
                              _imageFile = null;
                              isEditing = false;
                            });
                          },
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.alexandria(
                              color: isDark ? Colors.white : const Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => setState(() => isEditing = false),
                            child: Text(
                              "Save Changes",
                              style: GoogleFonts.alexandria(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileHeaderCard extends StatelessWidget {
  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final File? imageFile;
  final VoidCallback onImagePick;
  final bool isDark;

  const ProfileHeaderCard({
    super.key,
    required this.isEditing,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.imageFile,
    required this.onImagePick,
    required this.isDark,
  });

  InputDecoration _editInputDeco(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: primaryColor, size: 20),
      hintText: hint,
      filled: true,
      fillColor: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryColor, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: imageFile != null
                          ? FileImage(imageFile!)
                          : const AssetImage("assets/images/asifimran.jpg") as ImageProvider,
                    ),
                  ),
                  if (isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: onImagePick,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            gradient: primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Iconsax.camera, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: isEditing
                    ? TextField(
                  controller: nameController,
                  style: GoogleFonts.alexandria(fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: _editInputDeco("Full Name", Iconsax.user),
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nameController.text,
                      style: GoogleFonts.alexandria(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Verified Account",
                      style: GoogleFonts.alexandria(fontSize: 12, color: const Color(0xFF10B981), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: isDark ? Colors.white10 : Colors.grey.shade100),
          const SizedBox(height: 12),
          isEditing
              ? Column(
            children: [
              TextField(
                controller: emailController,
                decoration: _editInputDeco("Email Address", Iconsax.sms),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: _editInputDeco("Phone Number", Iconsax.call),
              ),
            ],
          )
              : Column(
            children: [
              ContactRow(icon: Iconsax.sms, text: emailController.text, isDark: isDark),
              const SizedBox(height: 12),
              ContactRow(icon: Iconsax.call, text: phoneController.text, isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }
}

class ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isDark;

  const ContactRow({super.key, required this.icon, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 16, color: primaryColor),
        ),
        const SizedBox(width: 14),
        Text(
          text,
          style: GoogleFonts.alexandria(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class StatsCard extends StatelessWidget {
  const StatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: _cardDecoration(isDark),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StatItem(icon: Iconsax.receipt, iconColor: Color(0xFF3B82F6), value: "24", label: "Orders"),
          StatItem(icon: Iconsax.money, iconColor: Color(0xFF10B981), value: "৳3400", label: "Spent"),
          StatItem(icon: Iconsax.gift, iconColor: Color(0xFFF59E0B), value: "166", label: "Points"),
        ],
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const StatItem({super.key, required this.icon, required this.iconColor, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: GoogleFonts.alexandria(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.alexandria(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPress;
  final bool isDark;

  const SettingsTile({super.key, required this.icon, required this.title, required this.subtitle, this.onPress, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(isDark),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: isDark ? Colors.grey.shade400 : const Color(0xFF475569), size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.alexandria(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.alexandria(fontSize: 12, color: Colors.grey.shade500),
                  )
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration(bool isDark) {
  return BoxDecoration(
    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
    boxShadow: isDark
        ? []
        : [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 15,
        offset: const Offset(0, 6),
      ),
    ],
  );
}