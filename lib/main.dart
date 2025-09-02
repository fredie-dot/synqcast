import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/home_screen.dart';
import 'screens/rooms_screen.dart';
import 'screens/recordings_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/room_screen.dart';
import 'screens/splash_screen.dart';
import 'services/room_service.dart';
import 'services/settings_service.dart';
import 'services/permission_service.dart';
import 'widgets/create_room_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // For web, servers need to be started manually
  // For mobile/desktop, we could add automatic server startup here
  if (kIsWeb) {
    debugPrint('Running on web - please ensure servers are running manually');
    debugPrint('Run: ./start_servers.sh to start required servers');
  }
  
  runApp(const SynqCastApp());
}

class SynqCastApp extends StatefulWidget {
  const SynqCastApp({super.key});

  @override
  State<SynqCastApp> createState() => _SynqCastAppState();
}

class _SynqCastAppState extends State<SynqCastApp> {
  String _themeMode = 'system';
  late SettingsService _settingsService;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    _settingsService = await SettingsService.getInstance();
    final themeMode = await _settingsService.getThemeMode();
    setState(() => _themeMode = themeMode);
  }

  void _updateTheme(String themeMode) {
    setState(() => _themeMode = themeMode);
  }

  void _onPermissionsGranted() {
    setState(() => _showSplash = false);
  }

  ThemeMode get _themeModeEnum {
    switch (_themeMode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('MainApp: Building with _showSplash = $_showSplash');
    
    return MaterialApp(
      title: 'SynqCast',
      debugShowCheckedModeBanner: false,
      themeMode: _themeModeEnum,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
        ),
        bottomAppBarTheme: const BottomAppBarTheme(
          color: Color(0xFF1E1E1E),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6C63FF),
          foregroundColor: Colors.white,
        ),
      ),
      home: _showSplash 
        ? SplashScreen(onPermissionsGranted: _onPermissionsGranted)
        : _RootTabs(onThemeChanged: _updateTheme),
      routes: {
        '/room': (context) => const RoomScreen(),
      },
    );
  }
}

class _RootTabs extends StatefulWidget {
  final Function(String) onThemeChanged;
  
  const _RootTabs({required this.onThemeChanged});

  @override
  State<_RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<_RootTabs> {
  int _index = 0;
  final RoomService _roomService = RoomService();

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(roomService: _roomService),
      RoomsScreen(roomService: _roomService),
      const RecordingsScreen(),
      SettingsScreen(onThemeChanged: widget.onThemeChanged),
    ];

    return Scaffold(
      extendBody: true,
      body: SafeArea(child: pages[_index]),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => _showCreateRoomDialog(context),
        elevation: 6,
        child: const Icon(Icons.screen_share_rounded, size: 30),
      ),
      bottomNavigationBar: _CurvedBottomBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }

  void _showCreateRoomDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateRoomDialog(roomService: _roomService),
    );
  }
}

class _CurvedBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _CurvedBottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = const [
      (Icons.home_rounded, 'Home'),
      (Icons.meeting_room_rounded, 'Rooms'),
      (Icons.video_library_rounded, 'Recordings'),
      (Icons.settings_rounded, 'Settings'),
    ];

    return ClipPath(
      clipper: _NavClipper(),
      child: BottomAppBar(
        height: 90,
        color: Theme.of(context).colorScheme.surface,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final selected = i == currentIndex;
            final (icon, label) = items[i];
            final color = selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant;
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onTap(i),
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color, size: 18),
                    const SizedBox(height: 2),
                    Text(
                      label, 
                      style: TextStyle(color: color, fontSize: 9),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    // Creates a gentle concave notch for the centered FAB.
    const notchRadius = 44.0;
    final notchCenterX = size.width / 2;
    final path = Path()..lineTo(0, 0)..lineTo(0, size.height);
    path.lineTo(notchCenterX - notchRadius * 2, size.height);
    path.cubicTo(
      notchCenterX - notchRadius * 1.2,
      size.height,
      notchCenterX - notchRadius * 1.2,
      0,
      notchCenterX,
      0,
    );
    path.cubicTo(
      notchCenterX + notchRadius * 1.2,
      0,
      notchCenterX + notchRadius * 1.2,
      size.height,
      notchCenterX + notchRadius * 2,
      size.height,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}


