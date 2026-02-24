import 'dart:io';

import 'package:ezeewash/routes/routes_name.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;

  // Controllers for text fields
  final nameController = TextEditingController(text: "John Doe");
  final emailController = TextEditingController(text: "john.doe@email.com");
  final phoneController = TextEditingController(text: "+1 (555) 123-4567");

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
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Profile'),
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (isEditing) {
                  // Optionally reset changes on Cancel:
                  nameController.text = nameController.text;
                  emailController.text = emailController.text;
                  phoneController.text = phoneController.text;
                }
                isEditing = !isEditing;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                isEditing ? "Cancel" : "Edit",
                style: GoogleFonts.alexandria(color: Colors.blue),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xffF3F4F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ProfileHeaderCard(
                isEditing: isEditing,
                nameController: nameController,
                emailController: emailController,
                phoneController: phoneController,
                imageFile: _imageFile,
                onImagePick: _pickImage,
              ),
              const SizedBox(height: 20),
              if (!isEditing) const StatsCard(),
              const SizedBox(height: 20),
              if (!isEditing) ...[
                SettingsTile(
                  onPress: () {
                    context.push(RoutesName.addressNavigate);
                  },
                  icon: Iconsax.location,
                  title: "Manage Addresses",
                  subtitle: "2 saved addresses",
                ),
                const SizedBox(height: 14),
                 SettingsTile(
                  onPress: () {
                    context.go(RoutesName.alerts);
                  },
                  icon: Iconsax.notification,
                  title: "Notifications",
                  subtitle: "Push notifications, SMS alerts",
                ),
                const SizedBox(height: 14),
                 SettingsTile(
                   onPress: () {
                     context.push(RoutesName.helpSupportNavigate);
                   },
                  icon: Icons.headset_mic_outlined,
                  title: "Help & Support",
                  subtitle: "FAQs, technical support, help contacts",
                ),
                const SizedBox(height: 14),
                 SettingsTile(
                  onPress: () {
                    context.push(RoutesName.termsPolicyNavigate);
                  },
                  icon: Iconsax.document,
                  title: "Terms & Privacy",
                  subtitle: "Legal information and regulations",
                ),
                const SizedBox(height: 14),
                 SettingsTile(
                   onPress: () {
                     context.push(RoutesName.chatBotNavigate);
                   },
                  icon: Icons.smart_toy_outlined,
                  title: "Bubble Bot",
                  subtitle: "Chat with bot for any queries",
                ),
                const SizedBox(height: 14),
                Center(
                  child: SizedBox(
                    width: 250,
                    child: OutlinedButton.icon(
                      icon: Icon(Iconsax.logout, color: Colors.red),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => context.go(RoutesName.login),
                      label: Text(
                        "Sign out",
                        style: TextStyle(color: Colors.red),
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
                            side: const BorderSide(
                              color: Colors.blue,
                              width: 1,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusGeometry.circular(15),
                            ),
                          ),

                          onPressed: () {
                            setState(() {
                              // Cancel editing, reset values and image if needed
                              nameController.text = "John Doe";
                              emailController.text = "john.doe@email.com";
                              phoneController.text = "+1 (555) 123-4567";
                              _imageFile = null; // reset image
                              isEditing = false;
                            });
                          },
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.alexandria(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadiusGeometry.circular(15),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              isEditing = false;
                            });
                          },
                          child: Text(
                            "Save Changes",
                            style: GoogleFonts.alexandria(color: Colors.white),
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

  const ProfileHeaderCard({
    super.key,
    required this.isEditing,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.imageFile,
    required this.onImagePick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: imageFile != null
                        ? FileImage(imageFile!)
                        : const NetworkImage("https://i.pravatar.cc/150?img=3")
                              as ImageProvider,
                  ),
                  if (isEditing)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: onImagePick,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.camera,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: isEditing
                    ? TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      )
                    : Text(
                        nameController.text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(),
          const SizedBox(height: 4),
          isEditing
              ? TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Iconsax.sms),
                    border: OutlineInputBorder(),
                  ),
                )
              : ContactRow(icon: Iconsax.sms, text: emailController.text),
          const SizedBox(height: 10),
          isEditing
              ? TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Iconsax.call),
                    border: OutlineInputBorder(),
                  ),
                )
              : ContactRow(icon: Iconsax.call, text: phoneController.text),
        ],
      ),
    );
  }
}

class ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const ContactRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

class StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  const StatItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPress;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.grey[700]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}

class StatsCard extends StatelessWidget {
  const StatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: _cardDecoration(),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StatItem(
            icon: Iconsax.receipt,
            iconColor: Colors.blue,
            value: "24",
            label: "Total Orders",
          ),
          StatItem(
            icon: Iconsax.money,
            iconColor: Colors.green,
            value: "৳340",
            label: "Total Spent",
          ),
          StatItem(
            icon: Iconsax.gift,
            iconColor: Colors.orange,
            value: "150",
            label: "Reward Points",
          ),
        ],
      ),
    );
  }
}
