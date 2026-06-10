import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  final _ageController = TextEditingController();

  bool _isLoading = false;
  bool _isAccepted = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      if (!_isAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please accept terms & conditions')),
        );
        return;
      }

      setState(() => _isLoading = true);

      bool success = await _authService.registerUser(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (success) {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          // --- Updated Firestore logic with default fields ---
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'name': _nameController.text.trim(),
                'age': int.tryParse(_ageController.text.trim()) ?? 0,
                // 'father_name': _fatherNameController.text.trim(),
                'bio': 'My Bio',
                'total_breathing_sessions': 0,
                'total_breathing_minutes': 0,
                'streak': 0,
                'is_dark_mode': false,
                'created_at': FieldValue.serverTimestamp(),
                // Yeh naya map add kiya hai taake stats screen error na de
                'emotions_stats': {
                  'happy_count': 0,
                  'stress_count': 0,
                  'sad_count': 0,
                },
              });
        }
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign up failed. Please check your details.'),
            ),
          );
        }
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87, size: 20),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Create Account",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Start your mindful journey today.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 25),

                  _buildTextField(
                    _nameController,
                    "Full Name",
                    Icons.person_outline,
                    validator: (val) => val!.isEmpty ? "Enter your name" : null,
                  ),
                  const SizedBox(height: 14),

                  _buildTextField(
                    _emailController,
                    "Email Address",
                    Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (val) {
                      if (val == null || val.isEmpty)
                        return "Email is required";
                      if (!val.contains('@')) return "Enter a valid email";
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // 3️⃣ UI ke andar Email ke niche Age ka Input Box add kar diya
                  _buildTextField(
                    _ageController,
                    "Age",
                    Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number, // Sirf number keypad khulega
                    validator: (val) {
                      if (val == null || val.isEmpty) return "Age is required";
                      if (int.tryParse(val) == null) return "Enter a valid age number";
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildTextField(
                    _passwordController,
                    "Password",
                    Icons.lock_outline,
                    isPassword: true,
                    obscure: _obscurePassword,
                    onToggle: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    validator: (val) {
                      if (val == null || val.length < 6)
                        return "Min 6 characters required";
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  _buildTextField(
                    _confirmPasswordController,
                    "Confirm Password",
                    Icons.lock_reset_outlined,
                    isPassword: true,
                    obscure: _obscureConfirmPassword,
                    onToggle: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword,
                    ),
                    validator: (val) {
                      if (val != _passwordController.text)
                        return "Passwords do not match";
                      return null;
                    },
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: Checkbox(
                          value: _isAccepted,
                          onChanged: (v) => setState(() => _isAccepted = v!),
                          activeColor: const Color(0xFF26C6DA),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "I agree to the Terms & Privacy Policy",
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF26C6DA),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Create Account",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    bool obscure = false,
    VoidCallback? onToggle,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscure : false,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black45, fontSize: 12),
        prefixIcon: Icon(icon, color: const Color(0xFF26C6DA), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.black26,
                  size: 18,
                ),
                onPressed: onToggle,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF26C6DA), width: 1.2),
        ),
        errorStyle: const TextStyle(fontSize: 11),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
        ),
      ),
    );
  }
}
