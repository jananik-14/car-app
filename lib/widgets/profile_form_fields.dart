import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class ProfileFormFields extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController cityController;
  final TextEditingController dobController;
  final TextEditingController? mobileController;
  final Uint8List? initialProfileImageBytes;
  final Function(XFile?, Uint8List?) onImageChanged;
  final VoidCallback onChanged;

  const ProfileFormFields({
    super.key,
    required this.nameController,
    required this.emailController,
    required this.cityController,
    required this.dobController,
    this.mobileController,
    this.initialProfileImageBytes,
    required this.onImageChanged,
    required this.onChanged,
  });

  @override
  State<ProfileFormFields> createState() => _ProfileFormFieldsState();
}

class _ProfileFormFieldsState extends State<ProfileFormFields> {
  Uint8List? _profileImageBytes;
  
  int? selectedDay;
  int? selectedMonth;
  int? selectedYear;
  bool isDateInvalid = false;

  final List<int> days = List.generate(31, (i) => i + 1);
  final List<String> monthNames = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];
  late final List<int> years;

  @override
  void initState() {
    super.initState();
    _profileImageBytes = widget.initialProfileImageBytes;
    years = List.generate(
      (DateTime.now().year - 18) - 1940 + 1,
      (i) => (DateTime.now().year - 18) - i,
    );

    // Parse existing DOB
    if (widget.dobController.text.isNotEmpty) {
      try {
        final parsedDate = DateTime.parse(widget.dobController.text);
        selectedDay = parsedDate.day;
        selectedMonth = parsedDate.month;
        selectedYear = parsedDate.year;
      } catch (_) {
        try {
          final parsedDate = DateFormat('dd MMM yyyy').parse(widget.dobController.text);
          selectedDay = parsedDate.day;
          selectedMonth = parsedDate.month;
          selectedYear = parsedDate.year;
        } catch (_) {}
      }
    }
  }

  void _updateDobController() {
    if (selectedDay != null && selectedMonth != null && selectedYear != null) {
      final date = DateTime(selectedYear!, selectedMonth!, selectedDay!);
      if (date.day != selectedDay) {
        setState(() {
          isDateInvalid = true;
        });
        widget.dobController.text = "";
      } else {
        setState(() {
          isDateInvalid = false;
        });
        widget.dobController.text = date.toIso8601String();
      }
    } else {
      setState(() {
        isDateInvalid = false;
      });
      widget.dobController.text = "";
    }
    widget.onChanged();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _profileImageBytes = bytes;
      });
      widget.onImageChanged(pickedFile, bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildProfilePhoto(),
        const SizedBox(height: 32),
        _buildTextField('Full Name *', widget.nameController, TextInputType.name),
        if (widget.mobileController != null) ...[
          const SizedBox(height: 16),
          _buildTextField('Mobile Number', widget.mobileController!, TextInputType.phone, readOnly: true),
        ],
        const SizedBox(height: 16),
        _buildTextField('Email Address *', widget.emailController, TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildTextField('City / Location *', widget.cityController, TextInputType.text),
        const SizedBox(height: 16),
        _buildDobRow(),
      ],
    );
  }

  Widget _buildProfilePhoto() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: _profileImageBytes != null ? MemoryImage(_profileImageBytes!) : null,
          child: _profileImageBytes == null
              ? Icon(Icons.person, size: 50, color: Colors.grey.shade400)
              : null,
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.camera_alt,
              size: 20,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDobDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDDDDDD)),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              menuMaxHeight: 280,
              hint: Text('--', style: TextStyle(color: Colors.grey.shade400)),
              icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF001128), size: 20),
              borderRadius: BorderRadius.circular(12),
              dropdownColor: Colors.white,
              items: items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item), style: const TextStyle(fontSize: 14, color: Color(0xFF001128))),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDobRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date of Birth',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildDobDropdown<int>(
                label: 'Day',
                value: selectedDay,
                items: days,
                itemLabel: (d) => d.toString().padLeft(2, '0'),
                onChanged: (val) {
                  setState(() => selectedDay = val);
                  _updateDobController();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _buildDobDropdown<int>(
                label: 'Month',
                value: selectedMonth,
                items: List.generate(12, (i) => i + 1),
                itemLabel: (m) => monthNames[m - 1].substring(0, 3),
                onChanged: (val) {
                  setState(() => selectedMonth = val);
                  _updateDobController();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDobDropdown<int>(
                label: 'Year',
                value: selectedYear,
                items: years,
                itemLabel: (y) => y.toString(),
                onChanged: (val) {
                  setState(() => selectedYear = val);
                  _updateDobController();
                },
              ),
            ),
          ],
        ),
        if (isDateInvalid)
          const Padding(
            padding: EdgeInsets.only(top: 8.0, left: 4.0),
            child: Text(
              'Please select a valid date',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, TextInputType keyboardType, {bool readOnly = false, VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: (_) => widget.onChanged(),
          style: TextStyle(
            color: readOnly && label == 'Mobile Number' ? Colors.grey.shade600 : Colors.black87,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: readOnly && label == 'Mobile Number' ? Colors.grey.shade50 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
