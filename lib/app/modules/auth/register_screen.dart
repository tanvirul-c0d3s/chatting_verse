import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../utils/validators.dart';
import '../../widgets/custom_text_field.dart';
import 'auth_controller.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthController controller = Get.find<AuthController>();

  Uint8List? imageBytes;

  Future<void> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        imageBytes = result.files.single.bytes!;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Create Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: const Color(0xFFEDEFFF),
                            backgroundImage:
                            imageBytes != null ? MemoryImage(imageBytes!) : null,
                            child: imageBytes == null
                                ? const Icon(
                              Icons.person,
                              size: 42,
                              color: Color(0xFF5B5FEF),
                            )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF5B5FEF),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: pickImage,
                      child: const Text(
                        'Upload Photo',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomTextField(
                      controller: _nameController,
                      hint: 'Full name',
                      validator: (v) => Validators.requiredField(v, 'Full name'),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _addressController,
                      hint: 'Address',
                      validator: (v) => Validators.requiredField(v, 'Address'),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _emailController,
                      hint: 'Email',
                      validator: Validators.email,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      controller: _passwordController,
                      hint: 'Password',
                      obscureText: true,
                      validator: Validators.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: Obx(
                            () => ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () {
                            if (_formKey.currentState!.validate()) {
                              controller.register(
                                fullName: _nameController.text.trim(),
                                address: _addressController.text.trim(),
                                email: _emailController.text.trim(),
                                password: _passwordController.text.trim(),
                                imageBytes: imageBytes,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF5B5FEF),
                            disabledBackgroundColor:
                            const Color(0xFF5B5FEF).withOpacity(.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Create account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}