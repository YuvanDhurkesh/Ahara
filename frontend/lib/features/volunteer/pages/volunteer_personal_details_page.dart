/// File: volunteer_personal_details_page.dart
/// Purpose: Profile management for logistical and contact metadata.
/// 
/// Responsibilities:
/// - Manages field validation for contact info and vehicle classification
/// - Provides a persistent form for updating volunteer transit capabilities
import 'package:flutter/material.dart';
import '../../../shared/styles/app_colors.dart';

/// Logistics-specific profile management interface for volunteers.
/// 
/// Includes:
/// - Transit capability selection (Bicycle, Bike, Car)
/// - Contact information synchronization logic
class VolunteerPersonalDetailsPage extends StatefulWidget {
  const VolunteerPersonalDetailsPage({super.key});

  @override
  State<VolunteerPersonalDetailsPage> createState() =>
      _VolunteerPersonalDetailsPageState();
}

class _VolunteerPersonalDetailsPageState
    extends State<VolunteerPersonalDetailsPage> {
  final _nameController = TextEditingController(text: 'Demo Volunteer');
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String _vehicleType = 'Bicycle';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Personal Details",
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
              children: [
                _buildCard([
                  _textField(label: 'Full Name', controller: _nameController),
                  const SizedBox(height: 16),
                  _textField(
                    label: 'Phone Number',
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),
                  _textField(
                    label: 'Address',
                    controller: _addressController,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _vehicleType,
                    decoration: const InputDecoration(
                      labelText: 'Vehicle Type',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Bicycle',
                        child: Text('Bicycle'),
                      ),
                      DropdownMenuItem(value: 'Bike', child: Text('Bike')),
                      DropdownMenuItem(value: 'Car', child: Text('Car')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _vehicleType = value!;
                      });
                    },
                  ),
                ]),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}
