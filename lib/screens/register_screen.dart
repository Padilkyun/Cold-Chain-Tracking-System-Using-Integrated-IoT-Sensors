import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _usernameController.text.trim());
    await prefs.setString('email', _emailController.text.trim());
    await prefs.setString('password', _passwordController.text);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pendaftaran berhasil! Silakan masuk.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                // Logo and Title centered
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.eco, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'BinaPanen',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text(
                  'Daftarkan Akun anda',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Username field
                const Text('Username', style: _labelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                  decoration: _buildInputDecoration('username'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username tidak boleh kosong';
                    }
                    if (value.trim().length < 3) {
                      return 'Username minimal 3 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Email field
                const Text('Email', style: _labelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                  decoration: _buildInputDecoration('email'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email tidak boleh kosong';
                    }
                    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(value)) {
                      return 'Masukkan email yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Password field
                const Text('Password', style: _labelStyle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                  decoration: _buildInputDecoration('password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textGrey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password tidak boleh kosong';
                    }
                    if (value.length < 8) {
                      return 'Password minimal 8 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                
                // Register Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Daftar',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Sudah memiliki akun ? ',
                      style: TextStyle(fontSize: 14, color: AppColors.textMedium),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textGrey, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      errorStyle: const TextStyle(fontSize: 12, height: 0.8),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.inputBorder, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.danger, width: 2),
      ),
      filled: false,
    );
  }
}

const _labelStyle = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w500,
  color: AppColors.textDark,
);
