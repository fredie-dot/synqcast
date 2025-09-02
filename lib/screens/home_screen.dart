import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/room_service.dart';
import '../services/settings_service.dart';
import '../models/room.dart';
import '../widgets/enhanced_create_room_dialog.dart';
import '../widgets/create_room_dialog.dart';
import '../widgets/room_card.dart';


class HomeScreen extends StatefulWidget {
  final RoomService roomService;
  
  const HomeScreen({super.key, required this.roomService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<RoomModel> _recentRooms = [];
  List<String> _favoriteRooms = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRecentRooms();
    _loadFavoriteRooms();
  }

  Future<void> _loadFavoriteRooms() async {
    try {
      final settings = await SettingsService.getInstance();
      final favorites = await settings.getFavoriteRooms();
      setState(() => _favoriteRooms = favorites);
    } catch (e) {
      debugPrint('Error loading favorite rooms: $e');
    }
  }

  Future<void> _loadRecentRooms() async {
    setState(() => _isLoading = true);
    
    try {
      // For now, just set loading to false
      // Mobile implementation would load from local storage
      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error loading recent rooms: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: _AnimatedAppTitle(),
              background: Container(
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildRecentRooms(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _QuickActionCard(
                icon: Icons.add_circle_outline,
                title: 'Create Room',
                subtitle: 'Start a new stream',
                onTap: () => _showCreateRoomDialog(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickActionCard(
                icon: Icons.join_full,
                title: 'Join Room',
                subtitle: 'Enter with code',
                onTap: () => _showJoinRoomDialog(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentRooms() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Rooms',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to rooms screen by changing tab index
                final rootTabs = context.findAncestorStateOfType<State>();
                if (rootTabs != null && rootTabs.runtimeType.toString() == '_RootTabsState') {
                  rootTabs.setState(() {
                    // Access the _index field using reflection or a different approach
                    // For now, we'll just show a message
                  });
                }
                // Show a message that rooms screen is available
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Switch to the Rooms tab to see all rooms'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_recentRooms.isEmpty)
          _buildEmptyState()
        else
          ..._recentRooms.map((room) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: RoomCard(
              room: room,
              isFavorite: _favoriteRooms.contains(room.id),
              onTap: () => _joinRoom(room),
              onFavorite: () => _toggleFavorite(room),
              onDelete: () => _deleteRoom(room),
            ),
          )),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No recent rooms',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first room to start sharing',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => EnhancedCreateRoomDialog(roomService: widget.roomService),
    );
  }

  void _showJoinRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => JoinRoomDialog(roomService: widget.roomService),
    );
  }

  void _joinRoom(RoomModel room) {
    // Navigate to room screen
    Navigator.pushNamed(context, '/room');
  }

  Future<void> _saveRoomToHistory(RoomModel room) async {
    try {
      // Mobile implementation would save to local storage
      debugPrint('Room saved to history for mobile');
      
      // Update local state
      setState(() {
        _recentRooms.insert(0, room);
        if (_recentRooms.length > 10) {
          _recentRooms = _recentRooms.take(10).toList();
        }
      });
    } catch (e) {
      debugPrint('Error saving room to history: $e');
    }
  }

  Future<void> _toggleFavorite(RoomModel room) async {
    try {
      final settings = await SettingsService.getInstance();
      if (_favoriteRooms.contains(room.id)) {
        await settings.removeFavoriteRoom(room.id);
        setState(() => _favoriteRooms.remove(room.id));
      } else {
        await settings.addFavoriteRoom(room.id);
        setState(() => _favoriteRooms.add(room.id));
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  Future<void> _deleteRoom(RoomModel room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Are you sure you want to delete "${room.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Remove from recent rooms (mobile implementation)
        debugPrint('Room removed from history for mobile');

        // Remove from favorites
        final settings = await SettingsService.getInstance();
        await settings.removeFavoriteRoom(room.id);
        setState(() {
          _recentRooms.removeWhere((r) => r.id == room.id);
          _favoriteRooms.remove(room.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Room "${room.name}" deleted')),
          );
        }
      } catch (e) {
        debugPrint('Error deleting room: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete room: $e')),
          );
        }
      }
    }
  }
}

class _AnimatedAppTitle extends StatefulWidget {
  const _AnimatedAppTitle();

  @override
  State<_AnimatedAppTitle> createState() => _AnimatedAppTitleState();
}

class _AnimatedAppTitleState extends State<_AnimatedAppTitle>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(_glowAnimation.value * 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // SC Logo
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'SC',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // App Name
                Text(
                  'SynqCast',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
