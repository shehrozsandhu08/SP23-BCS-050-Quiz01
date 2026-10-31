import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../database/db_helper.dart';
import '../models/patient.dart';
import '../models/patient_document.dart';
import '../theme/app_theme.dart';
import 'add_edit_patient_screen.dart';
import 'document_preview_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final int patientId;

  const PatientDetailScreen({super.key, required this.patientId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen>
    with SingleTickerProviderStateMixin {
  Patient? _patient;
  List<PatientDocument> _documents = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadPatientData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    setState(() => _isLoading = true);
    final patient = await DatabaseHelper.instance.getPatientById(widget.patientId);
    final docs = await DatabaseHelper.instance.getDocumentsByPatientId(widget.patientId);
    if (mounted) {
      setState(() {
        _patient = patient;
        _documents = docs;
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePatient() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Patient Record?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to permanently delete ${_patient?.name}\'s record and all associated documents?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusCritical,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper.instance.deletePatient(widget.patientId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient record deleted successfully'),
            backgroundColor: AppTheme.statusCritical,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _pickAndUploadDocument() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Patient Document',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add lab reports, prescriptions, or clinical scans',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library_outlined,
                      color: AppTheme.primaryTeal),
                ),
                title: Text('Image from Gallery',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: const Text('Upload photo of report or prescription'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined,
                      color: AppTheme.secondaryBlue),
                ),
                title: Text('Take Photo via Camera',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: const Text('Capture report instantly'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.attach_file_rounded,
                      color: Color(0xFFD97706)),
                ),
                title: Text('Choose Document / PDF / File',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: const Text('Select PDF, DOCX, or scanned reports'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickFile();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      _promptAndSaveDocument(picked.path, 'image');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles();
    if (result.isNotEmpty && result.first.path != null) {
      final filePath = result.first.path!;
      final ext = p.extension(filePath).toLowerCase();
      final type = (ext == '.jpg' || ext == '.jpeg' || ext == '.png')
          ? 'image'
          : (ext == '.pdf' ? 'pdf' : 'document');
      _promptAndSaveDocument(filePath, type);
    }
  }

  Future<void> _promptAndSaveDocument(String sourcePath, String type) async {
    final defaultTitle = '${type.toUpperCase()} - ${DateFormat('dd MMM yyyy').format(DateTime.now())}';
    final titleController = TextEditingController(text: defaultTitle);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Save Document', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Enter a label for this file:', style: GoogleFonts.inter(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Document Title',
                hintText: 'e.g. Blood Test Report, Chest X-Ray',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true && titleController.text.trim().isNotEmpty) {
      final file = File(sourcePath);
      final sizeInBytes = await file.length();
      final sizeStr = sizeInBytes > 1024 * 1024
          ? '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB'
          : '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';

      // Store permanently in App Directory
      final appDir = await getApplicationDocumentsDirectory();
      final docDir = Directory(p.join(appDir.path, 'DoctorApp', 'PatientDocs_${widget.patientId}'));
      if (!await docDir.exists()) {
        await docDir.create(recursive: true);
      }
      final fileName = 'doc_${DateTime.now().millisecondsSinceEpoch}${p.extension(sourcePath)}';
      final permanentFile = await file.copy(p.join(docDir.path, fileName));

      final doc = PatientDocument(
        patientId: widget.patientId,
        title: titleController.text.trim(),
        filePath: permanentFile.path,
        fileType: type,
        fileSize: sizeStr,
        uploadedAt: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      );

      await DatabaseHelper.instance.insertDocument(doc);
      await _loadPatientData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document "${doc.title}" saved successfully!'),
            backgroundColor: AppTheme.primaryTeal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal)),
      );
    }

    if (_patient == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Details')),
        body: const Center(child: Text('Patient record not found')),
      );
    }

    final p = _patient!;
    final statusColor = AppTheme.getStatusColor(p.status);
    final statusBgColor = AppTheme.getStatusBgColor(p.status);

    return Scaffold(
      appBar: AppBar(
        title: Text(p.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppTheme.secondaryBlue),
            tooltip: 'Edit Patient',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => AddEditPatientScreen(patient: p),
                ),
              );
              if (result == true) {
                _loadPatientData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.statusCritical),
            tooltip: 'Delete Record',
            onPressed: _deletePatient,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.01),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                // Avatar
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 64,
                    height: 64,
                    color: AppTheme.primaryLight,
                    child: p.avatarPath != null && File(p.avatarPath!).existsSync()
                        ? Image.file(
                            File(p.avatarPath!),
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Text(
                              p.name.isNotEmpty ? p.name[0].toUpperCase() : 'P',
                              style: GoogleFonts.inter(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryTeal,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              p.name,
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Blood Group
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              p.bloodGroup,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.age} Years Old • ${p.gender}',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              p.status,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppTheme.primaryTeal,
              unselectedLabelColor: AppTheme.textSecondary,
              indicatorColor: AppTheme.primaryTeal,
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(text: 'Vitals & Info'),
                Tab(text: 'Diagnosis & History'),
                Tab(text: 'Prescription'),
                Tab(text: 'Documents & Reports'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVitalsTab(p),
                _buildDiagnosisTab(p),
                _buildPrescriptionTab(p),
                _buildDocumentsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndUploadDocument,
        icon: const Icon(Icons.upload_file),
        label: const Text('Add Document'),
        backgroundColor: AppTheme.primaryTeal,
      ),
    );
  }

  Widget _buildVitalsTab(Patient p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoTile(
            icon: Icons.phone_outlined,
            label: 'Phone Contact',
            value: p.phone,
            color: AppTheme.primaryTeal,
          ),
          _buildInfoTile(
            icon: Icons.email_outlined,
            label: 'Email Address',
            value: p.email.isNotEmpty ? p.email : 'Not Provided',
            color: AppTheme.secondaryBlue,
          ),
          _buildInfoTile(
            icon: Icons.bloodtype_outlined,
            label: 'Blood Group',
            value: p.bloodGroup,
            color: const Color(0xFFDC2626),
          ),
          _buildInfoTile(
            icon: Icons.calendar_month_outlined,
            label: 'Last Clinical Visit',
            value: p.visitDate,
            color: const Color(0xFF8B5CF6),
          ),
          _buildInfoTile(
            icon: Icons.access_time_outlined,
            label: 'Record Registered On',
            value: p.createdAt,
            color: const Color(0xFF64748B),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisTab(Patient p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Diagnosis Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.medical_services_outlined,
                        color: AppTheme.primaryTeal, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Primary Diagnosis / Condition',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  p.diagnosis,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // History Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history_edu_outlined,
                        color: AppTheme.secondaryBlue, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Past Medical History & Known Allergies',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  p.medicalHistory.isNotEmpty
                      ? p.medicalHistory
                      : 'No past medical history or allergies recorded.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionTab(Patient p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.receipt_long_outlined,
                          color: AppTheme.primaryTeal, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Doctor's Prescription & Rx",
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.visitDate,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 16),
            Text(
              p.prescription.isNotEmpty
                  ? p.prescription
                  : 'No prescription details entered for this visit.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF334155),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsTab() {
    if (_documents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.folder_open_outlined,
                  size: 48,
                  color: AppTheme.primaryTeal,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No Documents Attached Yet',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Upload lab tests, X-Rays, scan results, or prescription slips.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickAndUploadDocument,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Upload First Document'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _documents.length,
      itemBuilder: (context, index) {
        final doc = _documents[index];
        final isImage = doc.fileType == 'image' ||
            doc.filePath.toLowerCase().endsWith('.jpg') ||
            doc.filePath.toLowerCase().endsWith('.jpeg') ||
            doc.filePath.toLowerCase().endsWith('.png');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 48,
                height: 48,
                color: isImage
                    ? const Color(0xFFCCFBF1)
                    : const Color(0xFFFEE2E2),
                child: isImage && File(doc.filePath).existsSync()
                    ? Image.file(
                        File(doc.filePath),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.image,
                            color: AppTheme.primaryTeal),
                      )
                    : Icon(
                        isImage ? Icons.image : Icons.picture_as_pdf_outlined,
                        color: isImage
                            ? AppTheme.primaryTeal
                            : const Color(0xFFDC2626),
                      ),
              ),
            ),
            title: Text(
              doc.title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${doc.fileType.toUpperCase()} • ${doc.fileSize} • ${doc.uploadedAt}',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined,
                      size: 20, color: AppTheme.primaryTeal),
                  tooltip: 'Preview File',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => DocumentPreviewScreen(
                          document: doc,
                          onDelete: () async {
                            await DatabaseHelper.instance.deleteDocument(doc.id!);
                            _loadPatientData();
                          },
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppTheme.statusCritical),
                  tooltip: 'Delete File',
                  onPressed: () async {
                    await DatabaseHelper.instance.deleteDocument(doc.id!);
                    _loadPatientData();
                  },
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => DocumentPreviewScreen(
                    document: doc,
                    onDelete: () async {
                      await DatabaseHelper.instance.deleteDocument(doc.id!);
                      _loadPatientData();
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
