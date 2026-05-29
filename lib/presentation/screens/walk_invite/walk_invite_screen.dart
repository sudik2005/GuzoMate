import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:byure/services/user_service.dart';
import 'package:byure/services/subscription_service.dart';
import 'package:byure/domain/entities/user_entity.dart';
import 'package:byure/presentation/providers/auth_provider.dart';
import 'package:byure/services/auth_service.dart';
import 'package:byure/presentation/widgets/route_selector.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

class WalkInviteScreen extends ConsumerStatefulWidget {
  final String userId;

  const WalkInviteScreen({super.key, required this.userId});

  @override
  ConsumerState<WalkInviteScreen> createState() => _WalkInviteScreenState();
}

class _WalkInviteScreenState extends ConsumerState<WalkInviteScreen> {
  final UserService _userService = UserService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final _supabase = Supabase.instance.client;
  
  UserEntity? _targetUser;
  bool _isLoading = true;
  bool _canSendInvite = false;
  
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedRouteId;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _loadUserAndCheckLimit();
  }

  Future<void> _loadUserAndCheckLimit() async {
    try {
      final user = await _userService.getUserById(widget.userId);
      AuthUser? currentUser;
      try {
        currentUser = ref.read(currentUserProvider);
      } catch (e) {
        debugPrint('Error reading current user: $e');
        return;
      }
      
      if (currentUser != null) {
        final canSend = await _subscriptionService.canSendWalkInvite(currentUser.id);
        setState(() {
          _targetUser = user;
          _canSendInvite = canSend;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _sendInvite() async {
    if (!_canSendInvite) {
      _showUpgradeDialog();
      return;
    }

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
      );
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final scheduledTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    await _supabase.from('walk_invites').insert({
      'from_user_id': currentUser.id,
      'to_user_id': widget.userId,
      'scheduled_time': scheduledTime.toIso8601String(),
      'message': _message.trim().isEmpty ? null : _message.trim(),
      'suggested_route_id': _selectedRouteId,
      'status': 'pending',
    });

    await _subscriptionService.recordWalkInviteSent(currentUser.id);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Walk invitation sent!')),
      );
      Navigator.pop(context);
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade Required'),
        content: const Text(
          'You\'ve reached your daily limit of 1 walk invite. Upgrade to GuzoMate+ for unlimited invites!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                context.push('/paywall');
              }
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_targetUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Send Walk Invite')),
        body: const Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Invite ${_targetUser!.name}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: _targetUser!.photoUrls.isNotEmpty
                          ? NetworkImage(_targetUser!.photoUrls.first)
                          : null,
                      child: _targetUser!.photoUrls.isEmpty
                          ? Text(_targetUser!.name[0].toUpperCase())
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _targetUser!.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Pace: ${_targetUser!.walkingPreferences.pace.name}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Date selector
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(
                  _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : 'Select date',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(height: 12),
            // Time selector
            Card(
              child: ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Time'),
                subtitle: Text(
                  _selectedTime != null
                      ? _selectedTime!.format(context)
                      : 'Select time',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selectTime,
              ),
            ),
            const SizedBox(height: 12),
            // Route selector
            Card(
              child: ListTile(
                leading: const Icon(Icons.route),
                title: const Text('Route (Optional)'),
                subtitle: const Text('Suggest a walking route'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final routeId = await showModalBottomSheet<String>(
                    context: context,
                    builder: (context) => const RouteSelector(),
                  );
                  if (routeId != null) {
                    setState(() => _selectedRouteId = routeId);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
            // Message
            TextField(
              decoration: const InputDecoration(
                labelText: 'Message (Optional)',
                hintText: 'Add a personal message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              onChanged: (value) => _message = value,
            ),
            const SizedBox(height: 32),
            // Send button
            ElevatedButton(
              onPressed: _sendInvite,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Send Walk Invitation'),
            ),
            if (!_canSendInvite) ...[
              const SizedBox(height: 8),
              Text(
                'Daily limit reached. Upgrade for unlimited invites!',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}


