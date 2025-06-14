import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:ui';
import '../services/auth_services.dart';
import '../widgets/text_styles.dart';
import '../widgets/wave_painter.dart';
import '../Screens/welcome_screen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _avatarAnimation;
  late Animation<double> _infoAnimation;
  late Animation<double> _buttonAnimation;
  late Animation<double> _statsAnimation;
  final TextEditingController _nameController = TextEditingController();
  bool _isEditing = false;
  bool _notificationsEnabled = true;
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controller with current user's displayName
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? 'User';

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _avatarAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOutCubic),
      ),
    );

    _infoAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _statsAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _buttonAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Function to pick and upload profile picture
  Future<void> _uploadProfilePicture() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _imageFile = image;
        _isUploading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        setState(() {
          _isUploading = false;
        });
        return;
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child('${user.uid}.jpg');
      final uploadTask = storageRef.putFile(File(image.path));
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await user.updatePhotoURL(downloadUrl);
      await user.reload(); // Refresh user data

      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated successfully')),
      );
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload profile picture: $e')),
      );
    }
  }

  // Function to update user display name
  Future<void> _updateProfile(String newName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && newName.trim().isNotEmpty) {
        await user.updateDisplayName(newName.trim());
        await user.reload(); // Refresh user data
        setState(() {
          _isEditing = false;
          _nameController.text =
              newName.trim(); // Update controller with new name
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid name')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  // Function to show logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: Colors.white.withOpacity(0.9),
        title: Text(
          'Confirm Logout',
          style: AppTextStyles.welcomeText.copyWith(fontSize: 20),
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style:
                  AppTextStyles.outlinedButtonText.copyWith(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await AuthServices.logout();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const WelcomeScreen()),
                  (Route<dynamic> route) => false,
                );
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Logout',
              style: AppTextStyles.buttonText,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final User? user = snapshot.data;

        return Scaffold(
          body: Stack(
            children: [
              // Gradient background with subtle wave
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.pink.shade100,
                        Colors.pink.shade50,
                        Colors.white,
                      ],
                    ),
                  ),
                  child: CustomPaint(
                    painter: WavePainter(),
                  ),
                ),
              ),
              // Main content
              SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // AppBar-like header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const SizedBox(width: 48),
                          ],
                        ),
                        const SizedBox(height: 70),
                        // Animated Avatar with upload functionality
                        FadeTransition(
                          opacity: _avatarAnimation,
                          child: GestureDetector(
                            onTap: _uploadProfilePicture,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 160,
                                  height: 160,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        Colors.pink.shade200,
                                        Colors.pink.shade400
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: _isUploading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : user?.photoURL != null
                                          ? ClipOval(
                                              child: Image.network(
                                                user!.photoURL!,
                                                width: 140,
                                                height: 140,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    const Icon(
                                                  Icons.account_circle,
                                                  size: 140,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.account_circle,
                                              size: 140,
                                              color: Colors.white,
                                            ),
                                ),
                                Positioned(
                                  bottom: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.pink.shade300,
                                      shape: BoxShape.circle,
                                    ),
                                    /*child: const Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: Colors.white,
                                    ),*/
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // User Info Card with Glassmorphism
                        FadeTransition(
                          opacity: _infoAnimation,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    _isEditing
                                        ? TextField(
                                            controller: _nameController,
                                            decoration: InputDecoration(
                                              labelText: 'Name',
                                              filled: true,
                                              fillColor:
                                                  Colors.white.withOpacity(0.3),
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            style: AppTextStyles.welcomeText
                                                .copyWith(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          )
                                        : Text(
                                            user?.displayName ?? 'User',
                                            style: AppTextStyles.welcomeText
                                                .copyWith(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                    const SizedBox(height: 10),
                                    Text(
                                      user?.email ?? 'User@gmail.com',
                                      style: AppTextStyles.outlinedButtonText
                                          .copyWith(
                                        color: Colors.black54,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    // Edit Profile Buttons
                                    /*Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            if (_isEditing) {
                                              _updateProfile(
                                                  _nameController.text);
                                            } else {
                                              setState(() {
                                                _isEditing = true;
                                              });
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.pink.shade300,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 10),
                                          ),
                                          child: Text(
                                            _isEditing
                                                ? 'Save'
                                                : 'Edit Profile',
                                            style: AppTextStyles.buttonText,
                                          ),
                                        ),
                                        if (_isEditing) ...[
                                          const SizedBox(width: 10),
                                          OutlinedButton(
                                            onPressed: () {
                                              setState(() {
                                                _isEditing = false;
                                                _nameController.text =
                                                    user?.displayName ??
                                                        'No name set';
                                              });
                                            },
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                  color: Colors.pink.shade300),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(25),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 10),
                                            ),
                                            child: Text(
                                              'Cancel',
                                              style: AppTextStyles
                                                  .outlinedButtonText,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    */const SizedBox(height: 20),
                                    // Notification Toggle
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Notifications',
                                          style: AppTextStyles.welcomeText
                                              .copyWith(fontSize: 16),
                                        ),
                                        Switch(
                                          value: _notificationsEnabled,
                                          onChanged: (value) {
                                            setState(() {
                                              _notificationsEnabled = value;
                                            });
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Notifications ${value ? 'enabled' : 'disabled'}',
                                                ),
                                              ),
                                            );
                                          },
                                          activeColor: Colors.pink.shade300,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        // Animated Logout Button
                        FadeTransition(
                          opacity: _buttonAnimation,
                          child: ElevatedButton(
                            onPressed: _showLogoutDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade400,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              minimumSize: const Size(double.infinity, 50),
                              elevation: 5,
                            ),
                            child: Text(
                              'Logout',
                              style: AppTextStyles.buttonText.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper widget for stat items
  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.welcomeText.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.pink.shade300,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: AppTextStyles.outlinedButtonText.copyWith(
            fontSize: 14,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}
