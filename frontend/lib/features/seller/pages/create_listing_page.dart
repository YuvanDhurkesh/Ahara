import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/listing_model.dart';
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
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _preparedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_preparedAt),
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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final expiryTime = Listing.calculateExpiryTime(
        _selectedFoodType,
        _preparedAt,
      );

      final newListing = Listing(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temporary ID
        foodName: _foodNameController.text,
        foodType: _selectedFoodType,
        quantityValue: double.parse(_quantityController.text),
        quantityUnit: _selectedUnit,
        redistributionMode: _redistributionMode,
        price: _redistributionMode == RedistributionMode.discounted
            ? double.tryParse(_priceController.text)
            : null,
        preparedAt: _preparedAt,
        expiryTime: expiryTime,
        hygieneStatus: _hygieneStatus,
        locationAddress: _locationController.text,
        latitude: 0.0, // Default for now
        longitude: 0.0, // Default for now
        imageUrl: 'https://via.placeholder.com/150', // Default placeholder
        description: _descriptionController.text,
        status: ListingStatus.active,
        businessType: _businessType,
      );

      // TODO: Call service to save listing
      debugPrint('New Listing Created: ${newListing.foodName}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing created successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.listing != null ? "Edit Listing" : "Create Listing",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                    const SizedBox(height: 24),
                    _buildSectionTitle("Location"),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
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
      onTap: () {
        // TODO: Implement image picker
      },
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.textLight.withOpacity(0.1),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              size: 40,
              color: AppColors.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              "Add food pictures",
              style: TextStyle(
                color: AppColors.textLight.withOpacity(0.6),
                fontWeight: FontWeight.w500,
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
    return InkWell(
      onTap: () {
        // TODO: Implement map selection
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.textLight.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                size: 20,
                color: Colors.redAccent,
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
