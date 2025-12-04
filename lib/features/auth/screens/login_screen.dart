import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true; // toggle value

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            children: [
              SizedBox(height: size.height * 0.06),

              /// Logo Container
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.local_laundry_service_outlined,
                  size: 45,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "EzeeWash",
                style: GoogleFonts.pacifico(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                isLogin
                    ? "Welcome back! Sign in to continue"
                    : "Create an account to get started",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16),
              ),

              SizedBox(height: size.height * 0.05),

              /// Form Container
              Material(
                elevation: 5,
                shadowColor: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    spacing: 20,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // -------------------
                      //     TOGGLE BUTTON
                      // -------------------
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isLogin = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !isLogin
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Signup",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: !isLogin
                                            ? CupertinoColors.activeBlue
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => isLogin = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isLogin
                                        ? CupertinoColors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Signin",
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: isLogin
                                            ? CupertinoColors.systemBlue
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// Signup Fields (only when !isLogin)
                      if (!isLogin)
                        const LoginTextField(
                          label: 'Full Name',
                          hint: 'Enter your name',
                          leading: Iconsax.user,
                          obscureText: false,
                        ),

                      const LoginTextField(
                        label: 'Phone Number',
                        hint: 'Enter your phone number',
                        leading: Iconsax.call,
                        obscureText: false,
                      ),

                      const LoginTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        leading: Iconsax.lock,
                        obscureText: true,
                      ),

                      /// Signup extra field
                      if (!isLogin)
                        const LoginTextField(
                          label: 'Confirm Password',
                          hint: 'Re-enter password',
                          leading: Iconsax.lock,
                          obscureText: true,
                        ),

                      /// Login/Signup Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CupertinoColors.systemBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            isLogin ? "Login" : "Create Account",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.06),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable Login TextField Widget
class LoginTextField extends StatefulWidget {
  const LoginTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.leading,
    required this.obscureText,
  });

  final String label;
  final String hint;
  final IconData leading;
  final bool obscureText;

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
      spacing: 8,
      children: [
        Text(
          widget.label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),

        TextField(
          obscureText: isObscured,
          decoration: InputDecoration(
            prefixIcon: Icon(widget.leading),
            hintText: widget.hint,
            hintStyle: GoogleFonts.poppins(fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 10,
            ),

            /// Password toggle (only shows if obscureText = true)
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(isObscured ? Iconsax.eye_slash : Iconsax.eye),
                    onPressed: () {
                      setState(() {
                        isObscured = !isObscured;
                      });
                    },
                  )
                : null,

            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: CupertinoColors.activeBlue,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}
