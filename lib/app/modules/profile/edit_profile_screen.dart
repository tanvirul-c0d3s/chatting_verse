import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../data/services/auth_service.dart';
import '../../data/services/storage_service.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/user_avatar.dart';
import 'profile_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileController profileController = Get.find<ProfileController>();
  final AuthService authService = Get.find<AuthService>();
  final StorageService storageService = Get.find<StorageService>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  Uint8List? imageBytes;
  String oldPhoto = '';
  bool isSaving = false;
  bool initialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await profileController.loadProfile();
      final user = profileController.user.value;

      if (user != null && mounted) {
        setState(() {
          nameController.text = user.fullName;
          addressController.text = user.address;
          oldPhoto = user.photoUrl;
          initialized = true;
        });
      } else {
        setState(() {
          initialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.single;
    Uint8List? pickedBytes = file.bytes;

    if (pickedBytes == null && !kIsWeb && file.path != null) {
      pickedBytes = await File(file.path!).readAsBytes();
    }

    if (pickedBytes == null) return;

    setState(() {
      imageBytes = pickedBytes;
    });
  }

  Future<void> updateProfile() async {
    final uid = authService.currentUser?.uid;
    if (uid == null) return;

    try {
      setState(() => isSaving = true);

      String photoUrl = oldPhoto;

      if (imageBytes != null) {
        photoUrl = await storageService.uploadProfileBytes(
          uid: uid,
          bytes: imageBytes!,
        );
      }

      await authService.updateProfile(
        uid: uid,
        fullName: nameController.text.trim(),
        address: addressController.text.trim(),
        photoUrl: photoUrl,
      );

      await profileController.loadProfile();

      Get.back();
      Get.snackbar('Success', 'Profile updated successfully');
    } catch (e) {
      Get.snackbar('Error', e.toString());
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = profileController.user.value;

    if (!initialized) {
      return const Scaffold(
        body: LoadingView(message: 'Loading profile...'),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // GestureDetector(
              //   onTap: pickImage,
              //   child: Stack(
              //     children: [
              //       imageBytes != null
              //           ? CircleAvatar(
              //         radius: 52,
              //         backgroundImage: MemoryImage(imageBytes!),
              //       )
              //           : UserAvatar(
              //         imageUrl: currentUser?.photoUrl ?? '',
              //         radius: 52,
              //       ),
              //       Positioned(
              //         right: 0,
              //         bottom: 0,
              //         child: Container(
              //           padding: const EdgeInsets.all(7),
              //           decoration: const BoxDecoration(
              //             color: Color(0xFF5B5FEF),
              //             shape: BoxShape.circle,
              //           ),
              //           child: const Icon(
              //             Icons.edit,
              //             size: 18,
              //             color: Colors.white,
              //           ),
              //         ),
              //       )
              //     ],
              //   ),
              // ),
              // const SizedBox(height: 12),
              // TextButton(
              //   onPressed: pickImage,
              //   child: const Text(
              //     'Change Photo',
              //     style: TextStyle(fontWeight: FontWeight.w700),
              //   ),
              // ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: nameController,
                hint: 'Full Name',
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: addressController,
                hint: 'Address',
                maxLines: 2,
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: isSaving ? null : updateProfile,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF5B5FEF),
                    disabledBackgroundColor:
                    const Color(0xFF5B5FEF).withOpacity(.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}