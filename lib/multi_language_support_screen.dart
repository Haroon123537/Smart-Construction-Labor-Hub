import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'home_screen.dart';

class MultiLanguageSupportScreen extends StatefulWidget {
  const MultiLanguageSupportScreen({super.key});

  @override
  State<MultiLanguageSupportScreen> createState() =>
      _MultiLanguageSupportScreenState();
}

class _MultiLanguageSupportScreenState
    extends State<MultiLanguageSupportScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);

    // Restart app from HomePage with new locale
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => HomePage(),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
  final loc = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: AnimatedContainer(
        duration: const Duration(seconds: 5),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E1E2C), Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.language, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                Text(
                  loc.chooseLanguage,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () => _setLocale(const Locale('en')),
                  icon: const Icon(Icons.language),
                  label: const Text("English"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(200, 50),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _setLocale(const Locale('ur')),
                  icon: const Icon(Icons.language),
                  label: const Text("اردو"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(200, 50),
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
