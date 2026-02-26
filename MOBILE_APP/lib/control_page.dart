import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ControlPage extends StatefulWidget {
  final BluetoothConnection? connection;
  final String deviceName;

  const ControlPage({super.key, required this.connection, required this.deviceName});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  int _currentSpeed = 0; // 0=Stop, 1-4=Speed
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    // Listen for disconnection
    if (widget.connection != null) {
      widget.connection!.input?.listen((Uint8List data) {
         // Optional: Handle incoming data
      }).onDone(() {
        if (mounted) {
          setState(() {
            _isConnected = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Device disconnected', style: GoogleFonts.poppins()),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      });
    }
  }

  Future<void> _sendCommand(String command, int speedLevel) async {
    // If we are disconnected (and not mocking), return.
    // If mocking (connection == null), _isConnected is true by default.
    if (!_isConnected) return;

    try {
      if (widget.connection != null) {
        widget.connection!.output.add(utf8.encode(command));
        await widget.connection!.output.allSent;
      } else {
        // Mock delay for UI feedback
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      HapticFeedback.mediumImpact();

      if (mounted) {
        setState(() {
          _currentSpeed = speedLevel;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending command: $e')),
        );
      }
    }
  }

  Color _getSpeedColor(int level) {
    switch (level) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow[700]!; // Darker yellow for visibility on white
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      default:
        return Theme.of(context).primaryColor;
    }
  }

  Widget _buildSpeedButton(int level, String command, String label) {
    bool isActive = _currentSpeed == level;
    Color activeColor = _getSpeedColor(level);
    
    return GestureDetector(
      onTap: () => _sendCommand(command, level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isActive ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          gradient: isActive 
              ? LinearGradient(
                  colors: [activeColor, activeColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: isActive 
                  ? activeColor.withOpacity(0.4) 
                  : Colors.black.withOpacity(0.05),
              blurRadius: isActive ? 20 : 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.speed, 
              color: isActive ? Colors.white : Colors.grey[400],
              size: 32,
            ).animate(target: isActive ? 1 : 0).scale(begin: const Offset(1,1), end: const Offset(1.2, 1.2)),
            
            const SizedBox(height: 12),
            
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isActive ? Colors.white : Colors.grey[800],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color speedometerColor = _currentSpeed > 0 ? _getSpeedColor(_currentSpeed) : Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.deviceName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () {
            widget.connection?.finish();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: !_isConnected 
          ? Center(child: Text("Disconnected", style: GoogleFonts.poppins(color: Colors.grey[500], fontSize: 18)))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0),
              child: Column(
                children: [
                   // --- Speedometer Widget ---
                  Container(
                    height: 220,
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2962FF).withOpacity(0.08),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(200, 100),
                                painter: SpeedometerPainter(
                                  speedLevel: _currentSpeed,
                                  colorObj: speedometerColor,
                                  secondaryColor: speedometerColor.withOpacity(0.5),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _currentSpeed == 0 ? "STOPPED" : "LEVEL $_currentSpeed",
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        color: _currentSpeed == 0 ? Colors.grey[400] : speedometerColor,
                                      ),
                                    ).animate(key: ValueKey(_currentSpeed)).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 200.ms),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: -0.2, end: 0, duration: 600.ms, curve: Curves.easeOutBack),
                  
                  const SizedBox(height: 24),
                  
                  // --- Speed Grid ---
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.2,
                      children: [
                        _buildSpeedButton(1, "1", "Sleep"),
                        _buildSpeedButton(2, "2", "Eco"),
                        _buildSpeedButton(3, "3", "Normal"),
                        _buildSpeedButton(4, "4", "Turbo"),
                      ]
                      .animate(interval: 100.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),
                    ),
                  ),
                  
                  // --- Stop Button ---
                  SizedBox(
                    width: double.infinity,
                    height: 90,
                    child: ElevatedButton(
                      onPressed: () => _sendCommand("0", 0),
                      style: ElevatedButton.styleFrom(
                         elevation: 8,
                         shadowColor: const Color(0xFFFF5252).withOpacity(0.4),
                         backgroundColor: const Color(0xFFFF5252), // Red
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(30),
                         ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stop_circle_outlined, size: 40, color: Colors.white),
                          const SizedBox(width: 16),
                          Text(
                            "STOP",
                            textAlign: TextAlign.start,
                            style: GoogleFonts.poppins(
                              fontSize: 24, // Increased font size since text is shorter
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().slideY(begin: 0.5, end: 0, delay: 400.ms, duration: 600.ms, curve: Curves.elasticOut),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
    ); 
  }
}

class SpeedometerPainter extends CustomPainter {
  final int speedLevel;
  final Color colorObj;
  final Color secondaryColor;

  SpeedometerPainter({required this.speedLevel, required this.colorObj, required this.secondaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    // We draw an arc from 135 degrees to 45 degrees (sweeping 270 degrees)
    // Or simpler: semi-circle for 0-4 speeds.
    
    final center = Offset(size.width / 2, size.height);
    final radius = min(size.width / 2, size.height) - 10;
    
    // Background Arc
    final bgPaint = Paint()
      ..color = Colors.grey[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 25
      ..strokeCap = StrokeCap.round;

    // Draw from PI (180 deg) to 2*PI (360 deg) for a semi-circle
    // In Flutter CustomPaint, 0 is 3 o'clock. PI is 9 o'clock. 
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi, 
      pi, 
      false, 
      bgPaint
    );

    // Active Arc
    if (speedLevel > 0) {
      final activePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 25
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(colors: [colorObj, secondaryColor]).createShader(Rect.fromCircle(center: center, radius: radius));

      double sweepAngle = (pi / 4) * speedLevel; // 4 levels max for 180 deg (pi)
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        pi, 
        sweepAngle, 
        false, 
        activePaint
      );
    }
  }

  @override
  bool shouldRepaint(covariant SpeedometerPainter oldDelegate) {
    return oldDelegate.speedLevel != speedLevel || oldDelegate.colorObj != colorObj;
  }
}
