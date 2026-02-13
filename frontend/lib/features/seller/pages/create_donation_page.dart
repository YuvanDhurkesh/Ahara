import 'package:flutter/material.dart';
import '../../../data/services/order_service.dart';
import '../../../data/providers/app_auth_provider.dart';
import 'package:provider/provider.dart';

class CreateDonationPage extends StatefulWidget {
  const CreateDonationPage({super.key});

  @override
  State<CreateDonationPage> createState() => _CreateDonationPageState();
}

class _CreateDonationPageState extends State<CreateDonationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _addressController = TextEditingController(text: "123 Main St"); // Default for now
  
  String _foodType = 'COOKED_VEG';
  String _storageCondition = 'ROOM_TEMP';
  TimeOfDay _cookedTime = TimeOfDay.now();
  bool _isLoading = false;

  final List<String> _foodTypes = [
    'COOKED_VEG',
    'COOKED_NON_VEG',
    'RAW_VEG',
    'BAKERY'
  ];

  final List<String> _storageConditions = [
    'ROOM_TEMP',
    'REFRIGERATED'
  ];

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _cookedTime,
    );
    if (picked != null && picked != _cookedTime) {
      setState(() {
        _cookedTime = picked;
      });
    }
  }

  Future<void> _submitDonation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = context.read<AppAuthProvider>().currentUser;
      if (user == null) throw Exception("User not logged in");

      // Convert TimeOfDay to DateTime
      final now = DateTime.now();
      final cookedDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        _cookedTime.hour,
        _cookedTime.minute,
      );

      final orderData = {
        "buyerId": user.uid,
        "storeId": "store_default", // Placeholder
        "items": [
          {
            "name": _nameController.text,
            "quantity": double.tryParse(_quantityController.text) ?? 0.0,
            "price": 0 // Donation
          }
        ],
        "totalAmount": 0,
        "deliveryAddress": _addressController.text,
        "foodType": _foodType,
        "storageCondition": _storageCondition,
        "cookedTime": cookedDateTime.toIso8601String(),
      };

      await OrderService().createOrder(orderData);

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Donation post created successfully!")),
      );
      Navigator.pop(context);

    } catch (e) {
      debugPrint("Donation Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to donate: ${e.toString().contains('unsafe') ? 'Food is unsafe for donation!' : e.toString()}"),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(label: "Details", onPressed: () => debugPrint(e.toString())),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Donate Food")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: "Food Item Name"),
                validator: (val) => val!.isEmpty ? "Enter name" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: "Quantity (servings)"),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? "Enter quantity" : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _foodType,
                decoration: const InputDecoration(labelText: "Food Type"),
                items: _foodTypes.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.replaceAll('_', ' ')),
                )).toList(),
                onChanged: (val) => setState(() => _foodType = val!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _storageCondition,
                decoration: const InputDecoration(labelText: "Storage Condition"),
                items: _storageConditions.map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type.replaceAll('_', ' ')),
                )).toList(),
                onChanged: (val) => setState(() => _storageCondition = val!),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text("Cooked At: ${_cookedTime.format(context)}"),
                  ),
                  TextButton(
                    onPressed: () => _selectTime(context),
                    child: const Text("Select Time"),
                  )
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDonation,
                  child: _isLoading 
                    ? const CircularProgressIndicator() 
                    : const Text("Post Donation"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
