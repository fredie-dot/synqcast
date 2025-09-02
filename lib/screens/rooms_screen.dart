import 'package:flutter/material.dart';
import '../services/room_service.dart';
import '../services/settings_service.dart';
import '../models/room.dart';
import '../widgets/room_card.dart';


class RoomsScreen extends StatefulWidget {
  final RoomService roomService;
  
  const RoomsScreen({super.key, required this.roomService});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  List<RoomModel> _recentRooms = [];
  List<String> _favoriteRooms = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _isLoading = true);
    
    try {
      // Load recent rooms from localStorage
      final recentRooms = _getRecentRooms();
      final favoriteRooms = await _getFavoriteRooms();
      
      setState(() {
        _recentRooms = recentRooms;
        _favoriteRooms = favoriteRooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load rooms: $e')),
        );
      }
    }
  }

  List<RoomModel> _getRecentRooms() {
    // Mobile implementation would load from local storage
    return [];
  }

  Future<List<String>> _getFavoriteRooms() async {
    try {
      final settings = await SettingsService.getInstance();
      return await settings.getFavoriteRooms();
    } catch (e) {
      debugPrint('Error loading favorite rooms: $e');
      return [];
    }
  }

  Future<void> _saveRecentRoom(RoomModel room) async {
    try {
      final rooms = _getRecentRooms();
      
      // Remove if already exists
      rooms.removeWhere((r) => r.id == room.id);
      
      // Add to beginning
      rooms.insert(0, room);
      
      // Keep only last 10 rooms
      if (rooms.length > 10) {
        rooms.removeRange(10, rooms.length);
      }
      
      // Save to localStorage (mobile implementation)
      debugPrint('Room saved to localStorage for mobile');
      
      await _loadRooms();
    } catch (e) {
              debugPrint('Error saving recent room: $e');
    }
  }

  Future<void> _toggleFavorite(String roomId) async {
    try {
      final settings = await SettingsService.getInstance();
      
      if (_favoriteRooms.contains(roomId)) {
        await settings.removeFavoriteRoom(roomId);
      } else {
        await settings.addFavoriteRoom(roomId);
      }
      
      await _loadRooms();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorites: $e')),
        );
      }
    }
  }

  Future<void> _joinRoom(RoomModel room) async {
    try {
      // Save to recent rooms
      await _saveRecentRoom(room);
      
      // Join the room
      if (room.inviteCode != null) {
        await widget.roomService.joinRoom(room.inviteCode!, 'User');
      }
      
      if (mounted) {
        Navigator.pushNamed(context, '/room');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join room: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteRoom(RoomModel room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Are you sure you want to remove "${room.name}" from your history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final rooms = _getRecentRooms();
        rooms.removeWhere((r) => r.id == room.id);
        
        // Mobile implementation would save to localStorage
        debugPrint('Room deleted from localStorage for mobile');
        
        await _loadRooms();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room removed from history')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete room: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRooms,
            tooltip: 'Refresh Rooms',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterTabs(),
                Expanded(
                  child: _buildRoomsList(),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            isSelected: _selectedFilter == 'all',
            onTap: () => setState(() => _selectedFilter = 'all'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Recent',
            isSelected: _selectedFilter == 'recent',
            onTap: () => setState(() => _selectedFilter = 'recent'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Favorites',
            isSelected: _selectedFilter == 'favorites',
            onTap: () => setState(() => _selectedFilter = 'favorites'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomsList() {
    List<RoomModel> filteredRooms = [];
    
    switch (_selectedFilter) {
      case 'recent':
        filteredRooms = _recentRooms;
        break;
      case 'favorites':
        filteredRooms = _recentRooms.where((room) => _favoriteRooms.contains(room.id)).toList();
        break;
      default:
        filteredRooms = _recentRooms;
    }

    if (filteredRooms.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredRooms.length,
      itemBuilder: (context, index) {
        final room = filteredRooms[index];
        return RoomCard(
          room: room,
          isFavorite: _favoriteRooms.contains(room.id),
          onTap: () => _joinRoom(room),
          onFavorite: () => _toggleFavorite(room.id),
          onDelete: () => _deleteRoom(room),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message;
    String subtitle;
    
    switch (_selectedFilter) {
      case 'recent':
        message = 'No Recent Rooms';
        subtitle = 'Join rooms to see them here';
        break;
      case 'favorites':
        message = 'No Favorite Rooms';
        subtitle = 'Mark rooms as favorites to see them here';
        break;
      default:
        message = 'No Rooms';
        subtitle = 'Join or create rooms to get started';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.add),
            label: const Text('Create Room'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? Theme.of(context).colorScheme.onPrimary 
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
