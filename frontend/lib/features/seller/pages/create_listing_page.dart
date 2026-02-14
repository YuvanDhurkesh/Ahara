import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../location/pages/location_picker_page.dart';
import '../../../data/models/listing_model.dart';
import '../../../data/providers/app_auth_provider.dart';
import '../../../data/services/backend_service.dart';
import '../../../shared/styles/app_colors.dart';

class CreateListingPage extends StatefulWidget {
  final Listing? listing;
  const CreateListingPage({super.key, this.listing});

  @override
  State<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends State<CreateListingPage> {
  final _formKey = GlobalKey<FormState>();

  final _foodNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  FoodType _selectedFoodType = FoodType.prepared_meal;
  String _selectedUnit = 'portions';
  RedistributionMode _redistributionMode = RedistributionMode.free;
  HygieneStatus _hygieneStatus = HygieneStatus.excellent;
  DateTime _preparedAt = DateTime.now();
  BusinessType _businessType = BusinessType.restaurant;
  XFile? _pickedXFile;
  final ImagePicker _picker = ImagePicker();
  String _dietaryType = "vegetarian";

  final TextEditingController _pincodeController = TextEditingController();

  final List<String> _units = ['kg', 'portions', 'pieces', 'liters'];

  @override
  void initState() {
    super.initState();
    if (widget.listing != null) {
      final l = widget.listing!;
      _foodNameController.text = l.foodName;
      _quantityController.text = l.quantityValue.toString();
      _priceController.text = l.price?.toString() ?? "";
      _locationController.text = l.locationAddress;
      _pincodeController.text = l.pincode ?? "";
      _descriptionController.text = l.description;
      _selectedFoodType = l.foodType;
      _selectedUnit = l.quantityUnit;
      _redistributionMode = l.redistributionMode;
      _hygieneStatus = l.hygieneStatus;
      _preparedAt = l.preparedAt;
      if (l.businessType != null) {
        _businessType = l.businessType!;
      }
    }
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _pincodeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _preparedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Transform.scale(scale: 0.9, child: child);
      },
    );
    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_preparedAt),
        builder: (context, child) {
          return Transform.scale(scale: 0.9, child: child);
        },
      );
      if (time != null) {
        setState(() {
          _preparedAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _pickImage() async {
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
                  setState(() => _pickedXFile = image);
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
                  setState(() => _pickedXFile = image);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final expiryTime = Listing.calculateExpiryTime(
          _selectedFoodType,
          _preparedAt,
        );

        // 1. Get real user IDs
        final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
        final firebaseUser = authProvider.currentUser;
        if (firebaseUser == null) throw Exception("User not logged in");

        final profileData = await BackendService.getUserProfile(firebaseUser.uid);
        final realSellerId = profileData['user']['_id'];
        final realSellerProfileId = profileData['profile']['_id'];

        final listingMap = {
          "sellerId": realSellerId,
          "sellerProfileId": realSellerProfileId,
          "foodName": _foodNameController.text,
          "foodType": _selectedFoodType.name,
          "dietaryType": _dietaryType,
          "category": "cooked", 
          "quantityText": "${_quantityController.text} ${_selectedUnit}",
          "totalQuantity": double.parse(_quantityController.text),
          "description": _descriptionController.text,
          "pricing": {
            "discountedPrice": _redistributionMode == RedistributionMode.discounted 
                ? double.tryParse(_priceController.text) ?? 0 
                : 0,
            "isFree": _redistributionMode == RedistributionMode.free,
          },
          "pickupWindow": {
            "from": _preparedAt.toIso8601String(),
            "to": expiryTime.toIso8601String(),
          },
          "pickupAddressText": _locationController.text,
        };

        debugPrint('--- SUBMIT FORM ---');
        debugPrint('Initial listingMap: ${jsonEncode(listingMap)}');
        debugPrint('_pickedXFile status: ${_pickedXFile != null ? "HAS IMAGE" : "NO IMAGE"}');

        // 2. Upload image if picked
        if (_pickedXFile != null) {
          debugPrint('Uploading image: ${_pickedXFile!.name}...');
          try {
            final bytes = await _pickedXFile!.readAsBytes();
            final imageUrl = await BackendService.uploadImage(bytes, _pickedXFile!.name);
            debugPrint('Upload success! URL: $imageUrl');
            listingMap["images"] = [imageUrl];
          } catch (e) {
            debugPrint('!!! IMAGE UPLOAD FAILED: $e');
            rethrow;
          }
        } else if (widget.listing != null && widget.listing!.imageUrl.isNotEmpty) {
          debugPrint('Keeping existing image: ${widget.listing!.imageUrl}');
          listingMap["images"] = [widget.listing!.imageUrl];
        }

        debugPrint('Final listingMap being sent: ${jsonEncode(listingMap)}');

        if (widget.listing != null) {
          await BackendService.updateListing(widget.listing!.id, listingMap);
        } else {
          await BackendService.createListing(listingMap);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.listing != null ? 'Listing updated successfully!' : 'Listing created successfully!')),
        );
        Navigator.pop(context);
      } catch (e) {
        debugPrint('Error creating listing: $e');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.listing != null ? "Edit Listing" : "Create Listing",
          style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle("Food Image"),
                    const SizedBox(height: 12),
                    _buildImagePicker(),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Business Information"),
                    const SizedBox(height: 16),
                    _buildDropdown<BusinessType>(
                      label: "Type of Business",
                      value: _businessType,
                      items: BusinessType.values,
                      onChanged: (v) => setState(() => _businessType = v!),
                      itemToString: (e) => _getBusinessTypeLabel(e),
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Basic Information"),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _foodNameController,
                      label: "Food Name",
                      hint: "e.g. Mixed Veg Curry",
                      validator: (v) => v?.isEmpty ?? true ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    _buildCategorySelection(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _quantityController,
                            label: "Quantity",
                            hint: "0.0",
                            keyboardType: TextInputType.number,
                            validator: (v) =>
                                v?.isEmpty ?? true ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: _buildDropdown<String>(
                            label: "Unit",
                            value: _selectedUnit,
                            items: _units,
                            onChanged: (v) =>
                                setState(() => _selectedUnit = v!),
                            itemToString: (e) => e,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildSectionTitle("Redistribution Details"),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildModeRadio(RedistributionMode.free, "Free"),
                        const SizedBox(width: 24),
                        _buildModeRadio(
                          RedistributionMode.discounted,
                          "Discounted",
                        ),
                      ],
                    ),
                    if (_redistributionMode ==
                        RedistributionMode.discounted) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _priceController,
                        label: "Price (₹)",
                        hint: "0.00",
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            _redistributionMode ==
                                    RedistributionMode.discounted &&
                                (v?.isEmpty ?? true)
                            ? "Required"
                            : null,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _buildDateTimePicker(),
                    const SizedBox(height: 16),
                    _buildDropdown<HygieneStatus>(
                      label: "Hygiene Status",
                      value: _hygieneStatus,
                      items: HygieneStatus.values,
                      onChanged: (v) => setState(() => _hygieneStatus = v!),
                      itemToString: (e) =>
                          e.name.substring(0, 1).toUpperCase() +
                          e.name.substring(1),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _descriptionController,
                      label: "Description",
                      hint:
                          "e.g. Ingredients, allergens, or special instructions",
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle("Food Diet"),
                    const SizedBox(height: 12),
                    _buildDietarySelector(),

                    const SizedBox(height: 20),
                    _buildSectionTitle("Logistics"),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _locationController,
                      label: "Pickup Location",
                      hint: "Enter your full address",
                      maxLines: 2,
                      validator: (v) => v?.isEmpty ?? true ? "Required" : null,
                    ),
                    const SizedBox(height: 12),
                    _buildMapPicker(),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          widget.listing != null
                              ? "Update Listing"
                              : "Create Listing",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDietarySelector() {
    final diets = [
      {"label": "Veg", "value": "vegetarian", "icon": Icons.eco_outlined, "color": Colors.green},
      {"label": "Non-Veg", "value": "non_veg", "icon": Icons.kebab_dining_outlined, "color": Colors.red},
      {"label": "Vegan", "value": "vegan", "icon": Icons.grass_outlined, "color": Colors.teal},
      {"label": "Jain", "icon": Icons.spa_outlined, "value": "jain", "color": Colors.orange},
    ];

    return Wrap(
      spacing: 12,
      children: diets.map((diet) {
        final isSelected = _dietaryType == diet['value'];
        return ChoiceChip(
          label: Text(diet['label'] as String),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) setState(() => _dietaryType = diet['value'] as String);
          },
          avatar: Icon(
            diet['icon'] as IconData, 
            size: 16, 
            color: isSelected ? Colors.white : (diet['color'] as Color),
          ),
          selectedColor: diet['color'] as Color,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? (diet['color'] as Color) : AppColors.textLight.withOpacity(0.2),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.lora(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textLight.withOpacity(0.4)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.textLight.withOpacity(0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.textLight.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required void Function(T?) onChanged,
    required String Function(T) itemToString,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.textLight.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              onChanged: onChanged,
              items: items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemToString(item)),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeRadio(RedistributionMode mode, String label) {
    bool isSelected = _redistributionMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _redistributionMode = mode),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textLight.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.textDark : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Prepared At",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textLight.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _selectDateTime,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.textLight.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 10),
                Text(
                  DateFormat('MMM dd, hh:mm a').format(_preparedAt),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textLight.withOpacity(0.1)),
          image: _pickedXFile != null
              ? DecorationImage(
                  image: kIsWeb 
                    ? NetworkImage(_pickedXFile!.path) as ImageProvider
                    : FileImage(io.File(_pickedXFile!.path)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _pickedXFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 40,
                    color: AppColors.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Add food pictures",
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Capture or upload from gallery",
                    style: TextStyle(
                      color: AppColors.textLight.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    top: 12,
                    right: 12,
                    child: GestureDetector(
                      onTap: () => setState(() => _pickedXFile = null),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
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
              ),
      ),
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Category",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textLight.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: FoodType.values.map((type) {
              bool isSelected = _selectedFoodType == type;
              return GestureDetector(
                onTap: () => setState(() => _selectedFoodType = type),
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textLight.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getCategoryIcon(type),
                        color: isSelected ? Colors.white : AppColors.textDark,
                        size: 20,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getCategoryLabel(type),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(FoodType type) {
    switch (type) {
      case FoodType.prepared_meal:
        return Icons.restaurant_rounded;
      case FoodType.fresh_produce:
        return Icons.eco_rounded;
      case FoodType.packaged_food:
        return Icons.inventory_2_rounded;
      case FoodType.bakery_item:
        return Icons.bakery_dining_rounded;
      case FoodType.dairy_product:
        return Icons.egg_rounded;
    }
  }

  String _getCategoryLabel(FoodType type) {
    switch (type) {
      case FoodType.prepared_meal:
        return "Meal";
      case FoodType.fresh_produce:
        return "Fresh";
      case FoodType.packaged_food:
        return "Packaged";
      case FoodType.bakery_item:
        return "Bakery";
      case FoodType.dairy_product:
        return "Dairy";
    }
  }

  Widget _buildMapPicker() {
    return Column(
      children: [
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            hintText: "Enter your full address",
            hintStyle: TextStyle(color: AppColors.textLight.withOpacity(0.4)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.textLight.withOpacity(0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.textLight.withOpacity(0.1),
              ),
            ),
          ),
          maxLines: 2,
          validator: (value) =>
              value == null || value.isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _pincodeController,
          decoration: InputDecoration(
            hintText: "Pincode",
            hintStyle: TextStyle(color: AppColors.textLight.withOpacity(0.4)),
            prefixIcon: const Icon(Icons.pin_drop_outlined, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.textLight.withOpacity(0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.textLight.withOpacity(0.1),
              ),
            ),
          ),
          keyboardType: TextInputType.number,
          validator: (value) =>
              value == null || value.isEmpty ? "Required" : null,
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () async {
            final result = await Navigator.push<LocationResult>(
              context,
              MaterialPageRoute(
                builder: (context) => LocationPickerPage(
                  initialAddress: _locationController.text,
                  initialPincode: _pincodeController.text,
                ),
              ),
            );

            if (result != null) {
              setState(() {
                _locationController.text = result.address;
                _pincodeController.text = result.pincode;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.textLight.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    size: 20,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Pin exact location on map",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textLight),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getBusinessTypeLabel(BusinessType type) {
    switch (type) {
      case BusinessType.restaurant:
        return "Restaurant";
      case BusinessType.cafe:
        return "Cafe";
      case BusinessType.cloud_kitchen:
        return "Cloud Kitchen";
      case BusinessType.pet_shop:
        return "Pet Shop";
      case BusinessType.event_management:
        return "Event Management";
      case BusinessType.cafetaria:
        return "Cafetaria";
    }
  }
}
