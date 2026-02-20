import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart'; // Removed
import 'package:byure/core/theme/app_theme.dart';
import 'package:byure/domain/entities/user_entity.dart';
import 'package:byure/presentation/providers/auth_provider.dart';
import 'package:byure/services/user_service.dart';
import 'package:byure/services/storage_service.dart'; // Added
import 'package:byure/presentation/widgets/mesh_gradient_background.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _interestController = TextEditingController(); // For adding new interests
  
  // State variables
  bool _isLoading = true;
  bool _isSaving = false;
  UserEntity? _currentUser;
  List<String> _interests = [];
  WalkingPace _selectedPace = WalkingPace.moderate;
  double _preferredDistance = 1.0;
  Gender _selectedGender = Gender.male;
  GenderPreference _selectedPreference = GenderPreference.women;
  
  // Image Picker
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final authUser = ref.read(currentUserProvider);
      if (authUser == null) {
        context.go('/auth/login');
        return;
      }

      final userService = UserService();
      final user = await userService.getUserById(authUser.id);
      
      if (user != null) {
        setState(() {
          _currentUser = user;
          _nameController.text = user.name;
          _bioController.text = user.bio ?? '';
          _interests = List.from(user.interests);
          _selectedPace = user.walkingPreferences.pace;
          _preferredDistance = user.walkingPreferences.preferredDistanceKm;
          _selectedGender = user.gender;
          _selectedPreference = user.genderPreference;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<String?> _uploadImage(String userId) async {
    if (_imageFile == null) return null;
    
    try {
      final storageService = StorageService();
      // Returns the public URL
      return await storageService.uploadProfileImage(userId, _imageFile!);
    } catch (e) {
      debugPrint('Upload failed: $e');
      rethrow; // Let saveProfile handle the error
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || _currentUser == null) return;

    setState(() => _isSaving = true);

    try {
      // 1. Upload image if selected
      String? newPhotoUrl;
      if (_imageFile != null) {
        try {
          newPhotoUrl = await _uploadImage(_currentUser!.id);
        } catch (e) {
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload image: $e')),
            );
          }
          // Continue saving other data even if image fails?
          // For now, let's just proceed.
        }
      }

      // 2. Update user entity
      List<String> photoUrls = List.from(_currentUser!.photoUrls);
      if (newPhotoUrl != null) {
        if (photoUrls.isNotEmpty) {
           photoUrls[0] = newPhotoUrl; // Replace primary photo
        } else {
           photoUrls.add(newPhotoUrl);
        }
      }

      final updatedUser = _currentUser!.copyWith(
        name: _nameController.text.trim(),
        bio: _bioController.text.trim(),
        interests: _interests,
        photoUrls: photoUrls,
        walkingPreferences: _currentUser!.walkingPreferences.copyWith(
          pace: _selectedPace,
          preferredDistanceKm: _preferredDistance,
        ),
        gender: _selectedGender,
        genderPreference: _selectedPreference,
      );

      final userService = UserService();
      
      try {
        await userService.updateUser(updatedUser);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (firebaseError) {
        // Firebase might not be configured in dev environment
        // Show warning but still proceed to update local UI
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Note: Changes saved locally only. Firebase error: ${firebaseError.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
      
      // Always go back to refresh the profile screen with updated data
      if (mounted) {
        context.pop(updatedUser); // Pass the updated user back
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addInterest() {
    final interest = _interestController.text.trim();
    if (interest.isNotEmpty && !_interests.contains(interest)) {
      setState(() {
        _interests.add(interest);
        _interestController.clear();
      });
    }
  }

  void _removeInterest(String interest) {
    setState(() {
      _interests.remove(interest);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurface.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: MeshGradientBackground(
        isDark: isDark,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 100, 24, 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Photo Section
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryGreen, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!) as ImageProvider
                              : (_currentUser?.photoUrls.isNotEmpty == true
                                  ? NetworkImage(_currentUser!.photoUrls.first)
                                  : null),
                          child: (_imageFile == null && (_currentUser?.photoUrls.isEmpty ?? true))
                              ? Icon(Icons.person, size: 60, color: isDark ? Colors.grey[600] : Colors.grey[400])
                              : null,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                  const SizedBox(height: 32),
                
                 // Walking Partner Preferences Section
                Text(
                  'Walking Partner Preferences',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Gender>(
                  value: _selectedGender, // Changed from _gender to _selectedGender
                  decoration: InputDecoration(
                    labelText: 'I am',
                    filled: true,
                    fillColor: isDark ? Colors.grey[900] : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: Gender.values.map((g) {
                    return DropdownMenuItem(value: g, child: Text(g.name[0].toUpperCase() + g.name.substring(1)));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedGender = val!), // Changed from _gender to _selectedGender
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<GenderPreference>(
                  value: _selectedPreference, // Changed from _genderPreference to _selectedPreference
                  decoration: InputDecoration(
                     labelText: 'Prefer walking with',
                     prefixIcon: Icon(Icons.favorite),
                   ),
                   items: GenderPreference.values.map((p) {
                     return DropdownMenuItem(
                       value: p,
                       child: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                     );
                   }).toList(),
                   onChanged: (val) => setState(() => _selectedPreference = val!),
                 ),
                 const SizedBox(height: 16),

                // Existing Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bioController,
                  decoration: const InputDecoration(
                    labelText: 'Bio',
                    helperText: 'Tell us a bit about yourself',
                    prefixIcon: Icon(Icons.edit_note),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 32),

                // Walking Preferences Section
                _buildSectionTitle('Walking Preferences'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferred Pace',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: WalkingPace.values.map((pace) {
                          final isSelected = _selectedPace == pace;
                          return ChoiceChip(
                            label: Text(pace.name.toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedPace = pace);
                            },
                            selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? AppTheme.primaryGreen : null,
                              fontWeight: isSelected ? FontWeight.bold : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Preferred Distance',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            '${_preferredDistance.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _preferredDistance,
                        min: 0.5,
                        max: 10.0,
                        divisions: 19,
                        activeColor: AppTheme.primaryGreen,
                        label: '${_preferredDistance.toStringAsFixed(1)} km',
                        onChanged: (value) => setState(() => _preferredDistance = value),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Interests Section
                _buildSectionTitle('Interests'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _interests.map((interest) {
                          return Chip(
                            label: Text(interest),
                            deleteIcon: const Icon(Icons.close, size: 18),
                            onDeleted: () => _removeInterest(interest),
                            backgroundColor: AppTheme.primaryTeal.withValues(alpha: 0.1),
                            labelStyle: const TextStyle(color: AppTheme.primaryTealDark),
                            side: BorderSide.none,
                          );
                        }).toList(),
                      ),
                      if (_interests.isNotEmpty) const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _interestController,
                              decoration: const InputDecoration(
                                hintText: 'Add an interest (e.g., Hiking)',
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onSubmitted: (_) => _addInterest(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: _addInterest,
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
