import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'onboarding_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    // الانتقال التلقائي بعد 3 ثوانٍ
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _animation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDF4FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology, 
                    size: 80,
                    color: Color(0xFF0055FF),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _controller,
                child: Column(
                  children: const [
                    Text(
                      'AI Life Coach',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2B2B),
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Empowering your journey',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
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
/*
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// التعديل 1: استيراد ملف الـ Onboarding بشكل صحيح
// بما أن الملفين في نفس المجلد (screens)، يكفي كتابة اسم الملف فقط
import 'onboarding_screen.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    // التعديل 2: تفعيل الانتقال التلقائي (إزالة علامات التعليق)
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        // تأكد أن اسم الكلاس هنا يطابق اسم الكلاس في ملف onboarding_screen.dart
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // التصحيح: return واحدة فقط في البداية، واستخدام child: قبل الـ Scaffold
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold( // <--- لاحظ هنا: كلمة child ضرورية ولا يوجد return هنا
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _animation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEDF4FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology, 
                    size: 80,
                    color: Color(0xFF0055FF),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeTransition(
                opacity: _controller,
                child: Column(
                  children: const [
                    Text(
                      'AI Life Coach',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B2B2B),
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Empowering your journey',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
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
*/

/*
// ملف: lib/screens/splash_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
// import '../task/onboarding_view.dart'; // 1. قمت بتعليق الاستيراد حتى لا يسبب خطأ إذا لم تكن الصفحة جاهزة
import 'lib\screens\onbording_screen.dart'
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    
    // إعداد الأنيميشن (يعمل كما هو)
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);

    // 2. قمت بإيقاف (Comment) كود المؤقت والانتقال التلقائي
    // بمجرد أن تريد تفعيل الانتقال مرة أخرى، فقط قم بإزالة العلامات (//)
    
    /* Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingView()),
      );
    });
    */
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFEDF4FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.psychology, 
                  size: 80,
                  color: Color(0xFF0055FF),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FadeTransition(
              opacity: _controller,
              child: Column(
                children: const [
                  Text(
                    'AI Life Coach',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2B2B2B),
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Empowering your journey',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/