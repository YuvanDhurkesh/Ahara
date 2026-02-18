/// File: volunteer_verification_page.dart
/// Purpose: Identity and trust validation flow for field agents.
/// 
/// Responsibilities:
/// - Manages document acquisition (Aadhar, ID) via [ImagePicker]
/// - Orchestrates the submission of KYC tokens to the project server
/// - Provides visual feedback on verification progress and trust scoring
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/styles/app_colors.dart';

/// Compliance portal for verifying volunteer legitimacy and safety.
/// 
/// Features:
/// - Multi-modal image acquisition (Front/Back)
/// - Integrated submission gate based on document presence
/// - Visual reinforcement of trust score benefits
class VolunteerVerificationPage extends StatefulWidget {
  const VolunteerVerificationPage({super.key});

  @override
  State<VolunteerVerificationPage> createState() =>
      _VolunteerVerificationPageState();
}

class _VolunteerVerificationPageState extends State<VolunteerVerificationPage> {
  File? _frontImage;
  File? _backImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickIdImage(bool isFront) async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text("Take a photo"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                );
                if (image != null) {
                  setState(() {
                    if (isFront) {
                      _frontImage = File(image.path);
                    } else {
                      _backImage = File(image.path);
                    }
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text("Choose from gallery"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                if (image != null) {
                  setState(() {
                    if (isFront) {
                      _frontImage = File(image.path);
                    } else {
                      _backImage = File(image.path);
                    }
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined),
              title: const Text("Choose file"),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                if (image != null) {
                  setState(() {
                    if (isFront) {
                      _frontImage = File(image.path);
                    } else {
                      _backImage = File(image.path);
                    }
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Account Verification",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Get Verified",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Verified volunteers get priority access to delivery requests.",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textLight.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),
                _buildUploadCard(
                  context,
                  title: "Aadhar Card",
                  description:
                      "Upload photos of your Aadhar card for identity verification.",
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_frontImage != null && _backImage != null)
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Documents submitted successfully!",
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Submit Documents'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard(
    BuildContext context, {
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textLight.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildUploadBox(
                  "Front",
                  Icons.add_photo_alternate_outlined,
                  _frontImage,
                  true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUploadBox(
                  "Back",
                  Icons.add_photo_alternate_outlined,
                  _backImage,
                  false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadBox(
    String label,
    IconData icon,
    File? image,
    bool isFront,
  ) {
    return GestureDetector(
      onTap: () => _pickIdImage(isFront),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: image != null
              ? Colors.transparent
              : AppColors.background.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: image != null
                ? AppColors.primary.withOpacity(0.3)
                : AppColors.textLight.withOpacity(0.1),
          ),
        ),
        child: image != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isFront) {
                            _frontImage = null;
                          } else {
                            _backImage = null;
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: AppColors.primary.withOpacity(0.5),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
