import 'package:ezeewash/routes/routes_name.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

const primaryColor = Color(0xFF1D4BC7);
const secondaryColor = Color(0xFF2F2E98);
const primaryGradient = LinearGradient(
  colors: [primaryColor, secondaryColor],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final List<Map<String, String>> demoGoogleAccounts = [
    {"name": "Asif Imran", "email": "ai@example.com"},
    {"name": "Hello World", "email": "hw@example.com"},
    {"name": "Brown Fox", "email": "bf@example.com"},
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /// Logo
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: primaryGradient,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.local_laundry_service_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    "EzeeWash",
                    style: GoogleFonts.pacifico(
                      fontSize: 32,
                      color: isDark ? Colors.white : primaryColor,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    isLogin
                        ? "Welcome back! Sign in to continue"
                        : "Create an account to get started",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.alexandria(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 40),

                  /// Form Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.grey.shade100,
                      ),
                      boxShadow: isDark ? [] : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          /// Toggle Auth Mode
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.black26 : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                _toggleItem("Signin", isLogin, () => setState(() => isLogin = true)),
                                _toggleItem("Signup", !isLogin, () => setState(() => isLogin = false)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          if (!isLogin)
                            LoginTextField(
                              controller: nameController,
                              label: 'Full Name',
                              hint: 'Enter your name',
                              leading: Iconsax.user,
                              obscureText: false,
                              isDark: isDark,
                            ),

                          LoginTextField(
                            controller: phoneController,
                            label: isLogin ? 'Phone / Email' : 'Phone Number',
                            hint: isLogin ? 'Enter phone or email' : 'Enter your phone',
                            leading: Iconsax.call,
                            obscureText: false,
                            isDark: isDark,
                          ),

                          LoginTextField(
                            controller: passwordController,
                            label: 'Password',
                            hint: 'Enter your password',
                            leading: Iconsax.lock,
                            obscureText: true,
                            isDark: isDark,
                          ),

                          if (!isLogin)
                            LoginTextField(
                              controller: confirmController,
                              label: 'Confirm Password',
                              hint: 'Re-enter password',
                              leading: Iconsax.lock,
                              obscureText: true,
                              isDark: isDark,
                            ),

                          const SizedBox(height: 10),

                          /// Main Action Button
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  context.push(RoutesName.main);
                                }
                              },
                              child: Text(
                                isLogin ? "Sign In" : "Create Account",
                                style: GoogleFonts.alexandria(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          /// Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.grey.shade200)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  "OR",
                                  style: GoogleFonts.alexandria(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.grey.shade200)),
                            ],
                          ),

                          const SizedBox(height: 24),

                          /// Offline-Ready Google Login
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                side: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
                                backgroundColor: isDark ? Colors.white.withOpacity(0.02) : Colors.white,
                              ),
                              onPressed: () => _showGooglePicker(context),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Offline-safe Icon
                                  const Icon(Icons.g_mobiledata_rounded, color: primaryColor, size: 30),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Continue with Google",
                                    style: GoogleFonts.alexandria(
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white : Colors.black87,
                                      fontSize: 14,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleItem(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: active ? primaryGradient : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.alexandria(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: active ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showGooglePicker(BuildContext context) async {
    final selected = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Choose Account", style: GoogleFonts.alexandria(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: demoGoogleAccounts.map((acc) {
            return ListTile(
              leading: const Icon(Iconsax.user, color: primaryColor),
              title: Text(acc['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(acc['email']!),
              onTap: () => Navigator.pop(context, acc),
            );
          }).toList(),
        ),
      ),
    );
    if (selected != null && mounted) {
      context.push(RoutesName.main);
    }
  }
}

class LoginTextField extends StatefulWidget {
  const LoginTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.leading,
    required this.obscureText,
    required this.controller,
    required this.isDark,
  });

  final String label;
  final String hint;
  final IconData leading;
  final bool obscureText;
  final TextEditingController controller;
  final bool isDark;

  @override
  State<LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<LoginTextField> {
  late bool isObscured;

  @override
  void initState() {
    super.initState();
    isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            widget.label,
            style: GoogleFonts.alexandria(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: widget.isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: isObscured,
          style: GoogleFonts.alexandria(fontSize: 14),
          validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(widget.leading, size: 20, color: primaryColor.withOpacity(0.7)),
            hintText: widget.hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            filled: true,
            fillColor: widget.isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF8FAFC),
            suffixIcon: widget.obscureText
                ? IconButton(
              icon: Icon(isObscured ? Iconsax.eye_slash : Iconsax.eye, size: 18, color: Colors.grey),
              onPressed: () => setState(() => isObscured = !isObscured),
            )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: widget.isDark ? Colors.white10 : Colors.grey.shade100),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: primaryColor, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}