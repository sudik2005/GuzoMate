import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:byure/domain/entities/chat_entity.dart';
import 'package:byure/domain/entities/user_entity.dart';
import 'package:byure/data/models/chat_model.dart';


class ChatService {
  final _supabase = Supabase.instance.client;
  // final _uuid = const Uuid();

  // --- Matching Logic ---

  /// Handles a user swiping on another user
  Future<String?> swipeUser({
    required UserEntity currentUser,
    required UserEntity targetUser,
    required bool isLike,
  }) async {
    try {
      // 1. Record the swipe
      await _supabase.from('swipes').upsert({
        'liker_id': currentUser.id,
        'target_id': targetUser.id,
        'is_like': isLike,
        // created_at auto
      });

      if (!isLike) return null;

      // 2. Check mutual like
      final response = await _supabase
          .from('swipes')
          .select()
          .eq('liker_id', targetUser.id)
          .eq('target_id', currentUser.id)
          .maybeSingle();

      if (response != null && response['is_like'] == true) {
        // IT'S A MATCH!
        return await _createMatch(currentUser, targetUser);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to swipe user: $e');
    }
  }

  Future<String> _createMatch(UserEntity user1, UserEntity user2) async {
    // Check existing match to avoid duplicates (user1→user2 OR user2→user1)
    final existing = await _supabase.from('matches').select()
      .or('and(user_id_1.eq.${user1.id},user_id_2.eq.${user2.id}),and(user_id_1.eq.${user2.id},user_id_2.eq.${user1.id})')
      .maybeSingle();
      
    if (existing != null) return existing['id'] as String;

    final result = await _supabase.from('matches').insert({
      'user_id_1': user1.id,
      'user_id_2': user2.id,
      'last_message': 'You matched! Say hi 👋',
      'last_message_time': DateTime.now().toIso8601String(),
    }).select().single();
    
    return result['id'] as String;
  }

  // --- Chat Logic ---

  /// Stream of matches (chat rooms) for a user
  /// Supabase Realtime for table changes is possible.
  Stream<List<ChatEntity>> getMatches(String userId) {
    // Using Stream from Realtime Channel or just polling/fetching.
    // For "Inbox", let's use a stream on the 'matches' table.
    
    return _supabase.from('matches').stream(primaryKey: ['id'])
      .order('last_message_time', ascending: false)
      .asyncMap((data) async {
         // The stream gives us the matches, but we need the User details.
         // 'stream' does NOT support joins/select parameters yet in Flutter SDK easily for complex relation.
         // Strategy: Stream IDs/updates, then fetch full data? Or just fetch periodically?
         // Actually, fetching the full list is better. 'stream' is good but limited.
         // Let's TRY to fetch associated users.
         // Since we can't JOIN in the stream, we have to fetch users manually for each match.
         // This is N+1 but for a chat list it's okay (usually < 20 active chats).
         // Better: Fetch all match IDs, then fetch users WHERE id IN (...).
         
         // Simplifying for this iteration: 
         // For each match, fetch the OTHER user's profile.
         
         final chats = <ChatEntity>[];
         for (final matchData in data) {
             // We need to fetch the user details because they aren't in the stream
             // matchData is Map<String, dynamic>
             final u1 = matchData['user_id_1'];
             final u2 = matchData['user_id_2'];
             
             // Fetch both (or just the other)
             // in_() is deprecated or missing in newer versions usually. 
             // Use filter('id', 'in', list)
             final userRes = await _supabase.from('users').select().filter('id', 'in', [u1, u2]);
             final usersMap = {for (var u in userRes) u['id']: u}; // Map<String, Map>
             
             // augment matchData with user objects for Model parsing
             final fullData = Map<String, dynamic>.from(matchData);
             fullData['user1'] = usersMap[u1];
             fullData['user2'] = usersMap[u2];
             
             chats.add(ChatModel.fromJson(fullData, userId));
         }
         return chats;
      });
  }

  /// Stream of messages for a specific chat
  Stream<List<ChatMessageEntity>> getMessages(String chatId) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('match_id', chatId)
        .order('created_at', ascending: false)
        .map((data) {
           return data.map((json) {
              return ChatMessageModel.fromJson(json);
           }).toList();
        });
  }

  /// Send a text message
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    // 1. Insert message
    await _supabase.from('messages').insert({
      'match_id': chatId,
      'sender_id': senderId,
      'content': content,
    });

    // 2. Update match summary
    await _supabase.from('matches').update({
      'last_message': content,
      'last_message_time': DateTime.now().toIso8601String(),
    }).eq('id', chatId);
  }
}
