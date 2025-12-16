import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'login_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // مفاتيح للتحكم في الفورم وإخفاء الباسورد
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

  // متحكمات النصوص (Controllers)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Focus Nodes للانتقال بين الحقول
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // الاستماع لتغييرات كلمة المرور لتحديث متطلبات الباسورد
    _passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // دالة التحقق من متطلبات كلمة المرور
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasUpperCase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasSpecialChar => _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  // Generate random nonce for security
String _generateNonce([int length = 32]) {
  const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
}

// Hash the nonce
String _sha256ofString(String input) {
  final bytes = utf8.encode(input);
  final digest = sha256.convert(bytes);
  return digest.toString();
}

// Firebase Signup
Future<void> _handleSignUp() async {
  FocusScope.of(context).unfocus();

  if (!_formKey.currentState!.validate()) {
    return;
  }

  if (!_acceptTerms) {
    _showSnackBar("Please accept the Terms & Conditions", isError: true);
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Firebase Signup not a simulation
    UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    // Update user display name
    await userCredential.user?.updateDisplayName(_nameController.text.trim());
    
    // Send verification email
    await userCredential.user?.sendEmailVerification();

    debugPrint("Sign Up Successful!");
    debugPrint("User ID: ${userCredential.user?.uid}");
    debugPrint("Email: ${userCredential.user?.email}");
    debugPrint("Display Name: ${userCredential.user?.displayName}");
    debugPrint("Email Verified: ${userCredential.user?.emailVerified}");

    if (mounted) {
      _showSnackBar("Account created successfully! Check your email for verification. 🎉", isError: false);
      // Navigate to home or verification screen
    }
  } on FirebaseAuthException catch (e) {
    String errorMessage;
    switch (e.code) {
      case 'weak-password':
        errorMessage = 'The password provided is too weak.';
        break;
      case 'email-already-in-use':
        errorMessage = 'An account already exists for that email.';
        break;
      case 'invalid-email':
        errorMessage = 'The email address is not valid.';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Email/password accounts are not enabled.';
        break;
      default:
        errorMessage = 'An error occurred: ${e.message}';
    }
    _showSnackBar(errorMessage, isError: true);
  } catch (e) {
    _showSnackBar("Something went wrong. Please try again.", isError: true);
    debugPrint("Signup error: $e");
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}




  // دالة لعرض SnackBar
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }


   Future<void> _handleGoogleSignIn() async {
  if (_isLoading) return;
  FocusScope.of(context).unfocus();

  setState(() => _isLoading = true);

  try {
    UserCredential userCredential;

    if (kIsWeb) {
      // WEB: Use popup method
      debugPrint("Attempting Google Sign-In with Popup (Web)");
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      userCredential = await FirebaseAuth.instance.signInWithPopup(googleProvider);
    } else {
      // MOBILE (Android/iOS): Use google_sign_in package
      debugPrint("Attempting Google Sign-In (Mobile)");
      
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        debugPrint("Google Sign-In cancelled by user");
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    }

    debugPrint("Google Sign-In Successful for user: ${userCredential.user?.email}");
    if (mounted) {
      _showSnackBar("Signed in with Google! 🎉", isError: false);
    }
  } catch (e) {
    debugPrint("Google Sign-In error: $e");
    if (!e.toString().contains('popup-closed-by-user') && 
        !e.toString().contains('sign_in_canceled')) {
      _showSnackBar("Google Sign-In Failed: ${e.toString()}", isError: true);
    }
  } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
  if (_isLoading) return;
  FocusScope.of(context).unfocus();

  setState(() => _isLoading = true);

  try {
    UserCredential userCredential;

    if (kIsWeb) {
      // WEB: Use Firebase popup method
      debugPrint("Attempting Apple Sign-In with Popup (Web)");
      final appleProvider = OAuthProvider('apple.com');
      appleProvider.addScope('email');
      appleProvider.addScope('name');
      userCredential = await FirebaseAuth.instance.signInWithPopup(appleProvider);
    } else {
      // MOBILE: Use sign_in_with_apple package
      debugPrint("Attempting Apple Sign-In (Mobile)");

      // Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request Apple Sign-In
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Create OAuth credential
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      // Sign in to Firebase
      userCredential = await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      // Update display name if available (Apple only provides this on first sign-in)
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        final displayName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
        if (displayName.isNotEmpty) {
          await userCredential.user?.updateDisplayName(displayName);
        }
      }
    }

    debugPrint("Apple Sign-In Successful for user: ${userCredential.user?.email}");
    if (mounted) {
      _showSnackBar("Signed in with Apple! 🍎", isError: false);
    }
  } on SignInWithAppleAuthorizationException catch (e) {
    debugPrint("Apple Sign-In Authorization Error: ${e.code} - ${e.message}");
    if (e.code != AuthorizationErrorCode.canceled) {
      _showSnackBar("Apple Sign-In failed: ${e.message}", isError: true);
    }
  } on FirebaseAuthException catch (e) {
    debugPrint("Firebase Auth Error: ${e.code} - ${e.message}");
    _showSnackBar("Authentication failed: ${e.message}", isError: true);
  } catch (e) {
    debugPrint("Apple Sign-In error: $e");
    if (!e.toString().contains('popup-closed-by-user')) {
      _showSnackBar("Apple Sign-In Failed: ${e.toString()}", isError: true);
    }
  } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // --- التعديل الجوهري هنا ---
        // وضعنا خصائص شريط الحالة داخل الـ AppBar لضمان ظهور الأيقونات باللون الأسود
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent, // خلفية شفافة
          statusBarIconBrightness: Brightness.dark, // أيقونات سوداء (للأندرويد)
          statusBarBrightness: Brightness.light, // (للآيفون)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. العنوان والترحيب
                Text(
                  "Create Account",
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Start your journey with your personal AI Coach today.",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 32),

                // 2. حقل الاسم الكامل
                const Text("Full Name", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameController,
                  hint: "Ex. John Doe",
                  icon: Icons.person_outline,
                  onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 3. حقل الإيميل
                const Text("Email", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hint: "Ex. email@example.com",
                  icon: Icons.email_outlined,
                  inputType: TextInputType.emailAddress,
                  focusNode: _emailFocus,
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 4. حقل كلمة المرور
                const Text("Password", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passwordController,
                  hint: "••••••••",
                  icon: Icons.lock_outline,
                  isPassword: true,
                  isObscure: !_isPasswordVisible,
                  focusNode: _passwordFocus,
                  onVisibilityToggle: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return 'Password must contain at least one number';
                    }
                    return null;
                  },
                ),

                // 5. متطلبات كلمة المرور
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildPasswordRequirement("At least 8 characters", _hasMinLength),
                  const SizedBox(height: 4),
                  _buildPasswordRequirement("Contains a number", _hasNumber),
                  const SizedBox(height: 4),
                  _buildPasswordRequirement("Contains uppercase letter", _hasUpperCase),
                  const SizedBox(height: 4),
                  _buildPasswordRequirement("Contains special character", _hasSpecialChar),
                ],

                const SizedBox(height: 24),

                // 6. Terms & Conditions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _acceptTerms,
                        onChanged: (val) => setState(() => _acceptTerms = val!),
                        activeColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                        child: RichText(
                          text: TextSpan(
                            text: "I agree to the ",
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            children: [
                              TextSpan(
                                text: "Terms & Conditions",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: " and ",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              TextSpan(
                                text: "Privacy Policy",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 7. زر إنشاء الحساب
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    disabledBackgroundColor: Colors.grey[300],
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
                          "Sign Up",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),

                const SizedBox(height: 24),

                // 8. OR Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "OR",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                  ],
                ),

                const SizedBox(height: 24),

                // 9. Social Login Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        label: "Google",
                        icon: Icons.g_mobiledata,
                        onTap: _isLoading ? null : _handleGoogleSignIn,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSocialButton(
                        label: "Apple",
                        icon: Icons.apple,
                        onTap: _isLoading ? null : _handleAppleSignIn,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 10. زر الانتقال لصفحة تسجيل الدخول (Login)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: () {
                        // الانتقال لصفحة الـ Login
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        "Log In",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ويدجت لمتطلبات كلمة المرور
  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: isMet ? Colors.green : Colors.grey[400],
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isMet ? Colors.green : Colors.grey[600],
            fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // >>> New Widget to work with the google sign in functionality:

  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap, 
  }) {
    // If onTap is null (because _isLoading is true), the button is disabled.
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: onTap == null ? Colors.grey : Colors.black87, // Greys out icon if disabled
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: onTap == null ? Colors.grey : Colors.black87, // Greys out text if disabled
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ويدجت مخصص لحقول الإدخال
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onVisibilityToggle,
    FocusNode? focusNode,
    Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent, width: 2),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: inputType,
        focusNode: focusNode,
        onFieldSubmitted: onFieldSubmitted,
        textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey[500]),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isObscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[500],
                  ),
                  onPressed: onVisibilityToggle,
                )
              : null,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorStyle: const TextStyle(fontSize: 12),
        ),
        validator: validator,
      ),
    );
  }
}
/*
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 1. إضافة مكتبة الخدمات
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // مفاتيح للتحكم في الفورم وإخفاء الباسورد
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

  // متحكمات النصوص (Controllers)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Focus Nodes للانتقال بين الحقول
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // الاستماع لتغييرات كلمة المرور لتحديث متطلبات الباسورد
    _passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // دالة التحقق من متطلبات كلمة المرور
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasUpperCase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasSpecialChar => _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  // دالة التسجيل
  Future<void> _handleSignUp() async {
    // إغلاق الكيبورد
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      _showSnackBar("Please accept the Terms & Conditions", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // محاكاة عملية التسجيل
      await Future.delayed(const Duration(seconds: 2));

      debugPrint("Sign Up Successful!");
      debugPrint("Name: ${_nameController.text.trim()}");
      debugPrint("Email: ${_emailController.text.trim()}");

      // عرض رسالة نجاح
      if (mounted) {
        _showSnackBar("Account created successfully! 🎉", isError: false);
        // هنا يمكن الانتقال للشاشة التالية
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
      }
    } catch (e) {
      _showSnackBar("Something went wrong. Please try again.", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // دالة لعرض SnackBar
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 2. تغليف الـ Scaffold بـ AnnotatedRegion لإظهار شريط الحالة
    return AnnotatedRegion<SystemUiOverlayStyle>
    (
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // خلفية شفافة
        statusBarIconBrightness: Brightness.dark, // أيقونات سوداء (Android)
        statusBarBrightness: Brightness.light, // (iOS)
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. العنوان والترحيب
                  Text(
                    "Create Account",
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Start your journey with your personal AI Coach today.",
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 32),

                  // 2. حقل الاسم الكامل
                  const Text("Full Name", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: "Ex. John Doe",
                    icon: Icons.person_outline,
                    onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (value.trim().length < 3) {
                        return 'Name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. حقل الإيميل
                  const Text("Email", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _emailController,
                    hint: "Ex. email@example.com",
                    icon: Icons.email_outlined,
                    inputType: TextInputType.emailAddress,
                    focusNode: _emailFocus,
                    onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 4. حقل كلمة المرور
                  const Text("Password", style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _passwordController,
                    hint: "••••••••",
                    icon: Icons.lock_outline,
                    isPassword: true,
                    isObscure: !_isPasswordVisible,
                    focusNode: _passwordFocus,
                    onVisibilityToggle: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      if (!value.contains(RegExp(r'[0-9]'))) {
                        return 'Password must contain at least one number';
                      }
                      return null;
                    },
                  ),

                  // 5. متطلبات كلمة المرور
                  if (_passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildPasswordRequirement("At least 8 characters", _hasMinLength),
                    const SizedBox(height: 4),
                    _buildPasswordRequirement("Contains a number", _hasNumber),
                    const SizedBox(height: 4),
                    _buildPasswordRequirement("Contains uppercase letter", _hasUpperCase),
                    const SizedBox(height: 4),
                    _buildPasswordRequirement("Contains special character", _hasSpecialChar),
                  ],

                  const SizedBox(height: 24),

                  // 6. Terms & Conditions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 24,
                        width: 24,
                        child: Checkbox(
                          value: _acceptTerms,
                          onChanged: (val) => setState(() => _acceptTerms = val!),
                          activeColor: Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                          child: RichText(
                            text: TextSpan(
                              text: "I agree to the ",
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              children: [
                                TextSpan(
                                  text: "Terms & Conditions",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(
                                  text: " and ",
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                TextSpan(
                                  text: "Privacy Policy",
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 7. زر إنشاء الحساب
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      disabledBackgroundColor: Colors.grey[300],
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
                            "Sign Up",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // 8. OR Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "OR",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 9. Social Login Buttons
                  Row(
                    children: [
                      Expanded(
                        child: _buildSocialButton(
                          label: "Google",
                          icon: Icons.g_mobiledata,
                          onTap: () => debugPrint("Google Sign Up"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSocialButton(
                          label: "Apple",
                          icon: Icons.apple,
                          onTap: () => debugPrint("Apple Sign Up"),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 10. زر الانتقال لصفحة تسجيل الدخول (Login)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account? ",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      GestureDetector(
                        onTap: () {
                          // الانتقال لصفحة الـ Login
                          Navigator.push(
                             context,
                             MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        child: Text(
                          "Log In",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ويدجت لمتطلبات كلمة المرور
  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: isMet ? Colors.green : Colors.grey[400],
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isMet ? Colors.green : Colors.grey[600],
            fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ويدجت لأزرار Social Login
  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ويدجت مخصص لحقول الإدخال
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onVisibilityToggle,
    FocusNode? focusNode,
    Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent, width: 2),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: inputType,
        focusNode: focusNode,
        onFieldSubmitted: onFieldSubmitted,
        textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey[500]),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isObscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[500],
                  ),
                  onPressed: onVisibilityToggle,
                )
              : null,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorStyle: const TextStyle(fontSize: 12),
        ),
        validator: validator,
      ),
    );
  }
}
*/
/*
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // مفاتيح للتحكم في الفورم وإخفاء الباسورد
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _acceptTerms = false;

  // متحكمات النصوص (Controllers)
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Focus Nodes للانتقال بين الحقول
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    // الاستماع لتغييرات كلمة المرور لتحديث متطلبات الباسورد
    _passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // دالة التحقق من متطلبات كلمة المرور
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasUpperCase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasSpecialChar => _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  // دالة التسجيل
  Future<void> _handleSignUp() async {
    // إغلاق الكيبورد
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      _showSnackBar("Please accept the Terms & Conditions", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // محاكاة عملية التسجيل
      await Future.delayed(const Duration(seconds: 2));

      debugPrint("Sign Up Successful!");
      debugPrint("Name: ${_nameController.text.trim()}");
      debugPrint("Email: ${_emailController.text.trim()}");

      // عرض رسالة نجاح
      if (mounted) {
        _showSnackBar("Account created successfully! 🎉", isError: false);
        // هنا يمكن الانتقال للشاشة التالية
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
      }
    } catch (e) {
      _showSnackBar("Something went wrong. Please try again.", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // دالة لعرض SnackBar
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. العنوان والترحيب
                Text(
                  "Create Account",
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Start your journey with your personal AI Coach today.",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 32),

                // 2. حقل الاسم الكامل
                const Text("Full Name", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameController,
                  hint: "Ex. John Doe",
                  icon: Icons.person_outline,
                  onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    if (value.trim().length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 3. حقل الإيميل
                const Text("Email", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emailController,
                  hint: "Ex. email@example.com",
                  icon: Icons.email_outlined,
                  inputType: TextInputType.emailAddress,
                  focusNode: _emailFocus,
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 4. حقل كلمة المرور
                const Text("Password", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _passwordController,
                  hint: "••••••••",
                  icon: Icons.lock_outline,
                  isPassword: true,
                  isObscure: !_isPasswordVisible,
                  focusNode: _passwordFocus,
                  onVisibilityToggle: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (!value.contains(RegExp(r'[0-9]'))) {
                      return 'Password must contain at least one number';
                    }
                    return null;
                  },
                ),

                // 5. متطلبات كلمة المرور
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildPasswordRequirement("At least 8 characters", _hasMinLength),
                  const SizedBox(height: 4),
                  _buildPasswordRequirement("Contains a number", _hasNumber),
                  const SizedBox(height: 4),
                  _buildPasswordRequirement("Contains uppercase letter", _hasUpperCase),
                  const SizedBox(height: 4),
                  _buildPasswordRequirement("Contains special character", _hasSpecialChar),
                ],

                const SizedBox(height: 24),

                // 6. Terms & Conditions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _acceptTerms,
                        onChanged: (val) => setState(() => _acceptTerms = val!),
                        activeColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                        child: RichText(
                          text: TextSpan(
                            text: "I agree to the ",
                            style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            children: [
                              TextSpan(
                                text: "Terms & Conditions",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: " and ",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              TextSpan(
                                text: "Privacy Policy",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 7. زر إنشاء الحساب
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    disabledBackgroundColor: Colors.grey[300],
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
                          "Sign Up",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),

                const SizedBox(height: 24),

                // 8. OR Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "OR",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey[300], thickness: 1)),
                  ],
                ),

                const SizedBox(height: 24),

                // 9. Social Login Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        label: "Google",
                        icon: Icons.g_mobiledata,
                        onTap: () => debugPrint("Google Sign Up"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSocialButton(
                        label: "Apple",
                        icon: Icons.apple,
                        onTap: () => debugPrint("Apple Sign Up"),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 10. زر الانتقال لصفحة تسجيل الدخول (Login)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Already have an account? ",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: () {
                        // الانتقال لصفحة الـ Login
                        Navigator.push(
                           context,
                           MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        "Log In",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ويدجت لمتطلبات كلمة المرور
  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: isMet ? Colors.green : Colors.grey[400],
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isMet ? Colors.green : Colors.grey[600],
            fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ويدجت لأزرار Social Login
  Widget _buildSocialButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.black87),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ويدجت مخصص لحقول الإدخال
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
    bool isObscure = false,
    VoidCallback? onVisibilityToggle,
    FocusNode? focusNode,
    Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent, width: 2),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: inputType,
        focusNode: focusNode,
        onFieldSubmitted: onFieldSubmitted,
        textInputAction: isPassword ? TextInputAction.done : TextInputAction.next,
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: Colors.grey[500]),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isObscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey[500],
                  ),
                  onPressed: onVisibilityToggle,
                )
              : null,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          errorStyle: const TextStyle(fontSize: 12),
        ),
        validator: validator,
      ),
    );
  }
}
*/
