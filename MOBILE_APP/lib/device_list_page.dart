import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'control_page.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceListPage extends StatefulWidget {
  const DeviceListPage({super.key});

  @override
  State<DeviceListPage> createState() => _DeviceListPageState();
}

class _DeviceListPageState extends State<DeviceListPage> {
  List<BluetoothDevice> _devices = [];
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    // Request permissions first (Android 12+ requires specific runtime permissions)
    await _requestPermissions();

    List<BluetoothDevice> devices = [];
    try {
      devices = await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      print("Error getting devices: $e");
    }

    if (mounted) {
      setState(() {
        _devices = devices;
        // Inject Mock Device for testing
        _devices.add(const BluetoothDevice(
          name: "HC-05", 
          address: "00:00:00:00:00:00",
          type: BluetoothDeviceType.classic, // or .unknown
          bondState: BluetoothBondState.bonded, 
        ));
      });
    }
  }

  Future<void> _requestPermissions() async {
    try {
      // Request multiple permissions at once
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      if (statuses[Permission.bluetoothConnect] == PermissionStatus.permanentlyDenied) {
        // Open settings if permission is permanently denied
        openAppSettings();
      }
    } catch (e) {
      print("Error requesting permissions (ignore if on Windows): $e");
    }
  }

  Future<void> _connect(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true;
    });

    try {
      BluetoothConnection? connection;
      if (device.address == "00:00:00:00:00:00") {
        // Mock connection
        // Simulate connection delay
        await Future.delayed(const Duration(seconds: 1));
        connection = null; // Pass null to indicate mock mode
      } else {
        connection = await BluetoothConnection.toAddress(device.address);
      }
      
      if (!mounted) return;

      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ControlPage(
            connection: connection, 
            deviceName: device.name ?? "Unknown"
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
             const begin = Offset(1.0, 0.0);
             const end = Offset.zero;
             const curve = Curves.easeInOutQuart;
             var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
             return SlideTransition(position: animation.drive(tween), child: child);
          },
        ),
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not connect to ${device.name}"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Connect Device',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.blueAccent),
            onPressed: () {
              _loadDevices();
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   content: Text("Refreshing device list...", style: GoogleFonts.poppins()),
                   duration: const Duration(milliseconds: 500),
                   behavior: SnackBarBehavior.floating,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                   margin: const EdgeInsets.all(16),
                 )
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FA),
              Color(0xFFE3F2FD),
            ],
          ),
        ),
        child: _isConnecting
            ? _buildConnectingState()
            : _devices.isEmpty
                ? _buildEmptyState()
                : _buildDeviceList(),
      ),
    );
  }

  Widget _buildConnectingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Custom pulsing animation
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bluetooth_connected, size: 40, color: Theme.of(context).primaryColor),
          )
          .animate(onPlay: (controller) => controller.repeat())
          .scale(begin: const Offset(1, 1), end: const Offset(1.5, 1.5), duration: 1000.ms)
          .fadeOut(duration: 1000.ms),
          
          const SizedBox(height: 30),
          
          Text(
            "Connecting...",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ).animate(onPlay: (controller) => controller.repeat())
           .shimmer(duration: 1500.ms, color: Theme.of(context).primaryColor),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Radar-like animation
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.2), width: 2),
                ),
              ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(0.5, 0.5), end: const Offset(1.2, 1.2), duration: 2000.ms).fadeOut(duration: 2000.ms),
              
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.4), width: 2),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.0, 1.0), duration: 2000.ms),

              Icon(
                Icons.bluetooth_searching, 
                size: 50, 
                color: Colors.blueAccent.withOpacity(0.6)
              ).animate(onPlay: (c) => c.repeat()).rotate(duration: 3000.ms),
            ],
          ),
          
          const SizedBox(height: 30),
          Text(
            "No devices found",
            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _loadDevices,
            icon: const Icon(Icons.refresh),
            label: const Text("Scan Again"),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        BluetoothDevice device = _devices[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2962FF).withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor.withOpacity(0.1),
                    Theme.of(context).primaryColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bluetooth,
                color: Theme.of(context).primaryColor,
              ),
            ),
            title: Text(
              device.name ?? "Unknown Device",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              device.address,
              style: GoogleFonts.poppins(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            trailing: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2962FF), Color(0xFF00B0FF)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00B0FF).withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () => _connect(device),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.2, end: 0);
      },
    );
  }
}
