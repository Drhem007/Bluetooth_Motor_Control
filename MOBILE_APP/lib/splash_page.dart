import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'device_list_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Navigate to DeviceListPage after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DeviceListPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Logo with animation
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.bluetooth_audio_rounded,
                      size: 80,
                      color: Theme.of(context).primaryColor,
                    );
                  },
                ),
              ),
            )
                .animate()
                .fade(duration: 800.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                  curve: Curves.easeOutBack,
                )
                .then(delay: 200.ms)
                .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.4)),
            
            const SizedBox(height: 24),
            
            Text(
              "Motor Controller",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: 0.5,
              ),
            ).animate().fade(delay: 400.ms).slideY(begin: 0.2, end: 0),
            
            const Spacer(),
            
            // Branding badge
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Powered by "),
                  const FlutterLogo(size: 20),
                  Text(
                    " Flutter",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ).animate().fade(delay: 800.ms),
            ),
          ],
        ),
      ),
    );
  }
}
