import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/db_helper.dart';
import '../models/patient.dart';
import '../theme/app_theme.dart';

class AddEditPatientScreen extends StatefulWidget {
  final Patient? patient; // null if adding new, non-null if editing

  const AddEditPatientScreen({super.key, this.patient});

  @override
  State<AddEditPatientScreen> createState() => _AddEditPatientScreenState();
}

class _AddEditPatientScreenState extends State<AddEditPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _diagnosisController;
  late TextEditingController _historyController;
  late TextEditingController _prescriptionController;
  late TextEditingController _dateController;

  String _gender = 'Male';
  String _bloodGroup = 'O+';
  String _status = 'Active';
  String? _avatarPath;
  bool _isLoading = false;

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _bloodOptions = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  final List<String> _statusOptions = ['Active', 'Critical', 'Recovered', 'Follow-up'];

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _nameController = TextEditingController(text: p?.name ?? '');
    _ageController = TextEditingController(text: p != null ? p.age.toString() : '');
    _phoneController = TextEditingController(text: p?.phone ?? '');
    _emailController = TextEditingController(text: p?.email ?? '');
    _diagnosisController = TextEditingController(text: p?.diagnosis ?? '');
    _historyController = TextEditingController(text: p?.medicalHistory ?? '');
    _prescriptionController = TextEditingController(text: p?.prescription ?? '');
    _dateController = TextEditingController(
      text: p?.visitDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );

    if (p != null) {
      _gender = p.gender;
      _bloodGroup = p.bloodGroup;
      _status = p.status;
      _avatarPath = p.avatarPath;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _diagnosisController.dispose();
    _historyController.dispose();
    _prescriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      // Save permanently to local app storage
      final appDir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory(p.join(appDir.path, 'DoctorApp', 'Avatars'));
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
      final localFile = await File(pickedFile.path).copy(p.join(avatarDir.path, fileName));

      setState(() {
        _avatarPath = localFile.path;
      });
    }
  }

  Future<void> _selectDate() async {
    DateTime initial = DateTime.now();
    try {
      initial = DateFormat('yyyy-MM-dd').parse(_dateController.text);
    } catch (_) {}

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryTeal,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final now = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
      final patient = Patient(
        id: widget.patient?.id,
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        gender: _gender,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        bloodGroup: _bloodGroup,
        diagnosis: _diagnosisController.text.trim(),
        medicalHistory: _historyController.text.trim(),
        prescription: _prescriptionController.text.trim(),
        status: _status,
        visitDate: _dateController.text.trim(),
        avatarPath: _avatarPath,
        createdAt: widget.patient?.createdAt ?? now,
      );

      if (widget.patient == null) {
        await DatabaseHelper.instance.insertPatient(patient);
      } else {
        await DatabaseHelper.instance.updatePatient(patient);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.patient == null
                  ? 'Patient record added successfully!'
                  : 'Patient record updated successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppTheme.primaryTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving record: $e'),
            backgroundColor: AppTheme.statusCritical,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.patient != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Patient Record' : 'Add New Patient'),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _savePatient,
            icon: const Icon(Icons.check_circle_outline, color: AppTheme.primaryTeal),
            label: Text(
              'Save',
              style: GoogleFonts.inter(
                color: AppTheme.primaryTeal,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar Picker Header
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickAvatar,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 46,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  backgroundImage: _avatarPath != null &&
                                          File(_avatarPath!).existsSync()
                                      ? FileImage(File(_avatarPath!))
                                      : null,
                                  child: _avatarPath == null ||
                                          !File(_avatarPath!).existsSync()
                                      ? const Icon(Icons.person,
                                          size: 46, color: Color(0xFF94A3B8))
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryTeal,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to upload patient photo',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Personal Information
                    _buildSectionHeader(
                        icon: Icons.person_outline, title: 'Personal Information'),
                    const SizedBox(height: 12),

                    // Full Name
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'e.g. Dr. / Mr. / Ms. John Doe',
                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter the patient full name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Age & Gender Row
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Age *',
                              hintText: 'e.g. 35',
                              prefixIcon:
                                  Icon(Icons.cake_outlined, size: 20),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Required';
                              }
                              final numVal = int.tryParse(val.trim());
                              if (numVal == null || numVal <= 0 || numVal > 150) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            initialValue: _gender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.people_outline, size: 20),
                            ),
                            items: _genderOptions
                                .map((g) => DropdownMenuItem(
                                      value: g,
                                      child: Text(g),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _gender = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Phone & Email Row
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone *',
                        hintText: 'e.g. +92 300 1234567',
                        prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter contact number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address (Optional)',
                        hintText: 'patient@example.com',
                        prefixIcon: Icon(Icons.email_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Clinical Status & Vitals
                    _buildSectionHeader(
                        icon: Icons.health_and_safety_outlined,
                        title: 'Clinical Vitals & Visit'),
                    const SizedBox(height: 12),

                    // Blood Group & Status Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _bloodGroup,
                            decoration: const InputDecoration(
                              labelText: 'Blood Group',
                              prefixIcon:
                                  Icon(Icons.bloodtype_outlined, size: 20),
                            ),
                            items: _bloodOptions
                                .map((bg) => DropdownMenuItem(
                                      value: bg,
                                      child: Text(bg),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _bloodGroup = val);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Icon(Icons.flag_outlined, size: 20),
                            ),
                            items: _statusOptions
                                .map((st) => DropdownMenuItem(
                                      value: st,
                                      child: Text(st),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _status = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Visit Date Picker
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      onTap: _selectDate,
                      decoration: const InputDecoration(
                        labelText: 'Visit Date',
                        prefixIcon:
                            Icon(Icons.calendar_today_outlined, size: 20),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section: Medical Diagnosis & Notes
                    _buildSectionHeader(
                        icon: Icons.medical_services_outlined,
                        title: 'Diagnosis & Medical Notes'),
                    const SizedBox(height: 12),

                    // Diagnosis
                    TextFormField(
                      controller: _diagnosisController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Diagnosis / Chief Complaint *',
                        hintText: 'e.g. Acute Migraine with Aura, Stage 1 Hypertension...',
                        alignLabelWithHint: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter diagnosis';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Medical History
                    TextFormField(
                      controller: _historyController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Medical History & Allergies',
                        hintText: 'e.g. Penicillin allergy, diabetes for 5 years, smoker...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Prescription
                    TextFormField(
                      controller: _prescriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: "Doctor's Prescription & Treatment Plan",
                        hintText: '1. Tab Paracetamol 500mg (1-1-1)\n2. Complete bed rest for 2 days...',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _savePatient,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          isEditing ? 'Update Patient Record' : 'Save Patient Record',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryTeal),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
