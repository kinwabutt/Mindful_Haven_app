import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;
  bool _isDark = false; // By default light, app theme provider handles the rest

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Checking credentials...')),
      );

      String? errorMessage = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (errorMessage == null && mounted) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_uid', _authService.currentUserUid ?? '');
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      } else if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage ?? "Invalid email or password."),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // StreamBuilder remove kar diya gaya hai, Colors ab variable theme ke mutabiq set honge
    final Color bgColor = _isDark ? Colors.black : const Color(0xFFF2F5F8);
    final Color textColor = _isDark ? Colors.white : Colors.black;
    final Color labelColor = _isDark ? Colors.white70 : const Color(0xFF1A2138);
    final Color inputFillColor = _isDark ? const Color(0xFF1A1F36) : Colors.white;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // --- LOGO SECTION WITH FILTER ---
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      bgColor,
                      BlendMode.darken,
                    ),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      width: 160,
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Welcome to Mindful Haven',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please login in to continue',
                    style: TextStyle(
                        fontSize: 13,
                        color: _isDark ? Colors.white60 : Colors.grey[600]),
                  ),
                  const SizedBox(height: 40),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildFieldLabel('Email Address', labelColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          style: TextStyle(fontSize: 13, color: textColor),
                          decoration: _buildInputDecoration('name@example.com',
                              Icons.email_outlined, inputFillColor),
                          validator: (v) => (!v!.contains('@'))
                              ? 'Enter a valid email'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        _buildFieldLabel('Password', labelColor),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(fontSize: 13, color: textColor),
                          decoration: _buildInputDecoration(
                                  '••••••••', Icons.lock_outline_rounded, inputFillColor)
                              .copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  size: 20,
                                  color: Colors.grey),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (v) => (v!.length < 6)
                              ? 'Min 6 characters required'
                              : null,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const ForgetPasswordScreen())),
                            child: const Text('Forgot password?',
                                style: TextStyle(
                                    color: Color(0xFF26C6DA),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF26C6DA),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            child: const Text('Login',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Don't have an account? ",
                          style: TextStyle(color: textColor, fontSize: 13)),
                      GestureDetector(
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignUpScreen())),
                        child: const Text("Sign Up",
                            style: TextStyle(
                                color: Color(0xFF26C6DA),
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, Color color) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ),
      );

  InputDecoration _buildInputDecoration(
          String hint, IconData icon, Color fillColor) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: _isDark ? Colors.white38 : Colors.grey, fontSize: 12),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
                color: _isDark ? Colors.white10 : Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF26C6DA), width: 1.5)),
      );
}