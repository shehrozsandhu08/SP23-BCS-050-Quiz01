import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../database/db_helper.dart';
import '../models/patient.dart';
import '../theme/app_theme.dart';
import '../widgets/patient_card.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/stat_card.dart';
import 'add_edit_patient_screen.dart';
import 'patient_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Patient> _patients = [];
  Map<String, int> _stats = {
    'total': 0,
    'active': 0,
    'critical': 0,
    'recovered': 0,
    'followUp': 0,
  };
  bool _isLoading = true;
  String _selectedStatus = 'All';
  String _selectedSort = 'Recent';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final stats = await DatabaseHelper.instance.getStatistics();
    final patients = await DatabaseHelper.instance.getPatients(
      query: _searchController.text,
      statusFilter: _selectedStatus,
      sortBy: _selectedSort,
    );

    if (mounted) {
      setState(() {
        _stats = stats;
        _patients = patients;
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePatient(Patient patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Patient Record?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete ${patient.name}? This cannot be undone.',
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

    if (confirmed == true && patient.id != null) {
      await DatabaseHelper.instance.deletePatient(patient.id!);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${patient.name}\'s record deleted'),
            backgroundColor: AppTheme.statusCritical,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MedPulse Clinic',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'Doctor App • Offline EHR & Records',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.primaryTeal),
            tooltip: 'Refresh Records',
            onPressed: _loadData,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppTheme.primaryTeal,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statistics Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    StatCard(
                      title: 'Total Patients',
                      count: _stats['total']?.toString() ?? '0',
                      icon: Icons.people_alt_outlined,
                      color: AppTheme.primaryTeal,
                      bgColor: AppTheme.primaryLight,
                      isSelected: _selectedStatus == 'All',
                      onTap: () {
                        setState(() => _selectedStatus = 'All');
                        _loadData();
                      },
                    ),
                    const SizedBox(width: 10),
                    StatCard(
                      title: 'Active Cases',
                      count: _stats['active']?.toString() ?? '0',
                      icon: Icons.monitor_heart_outlined,
                      color: AppTheme.secondaryBlue,
                      bgColor: AppTheme.secondaryLight,
                      isSelected: _selectedStatus == 'Active',
                      onTap: () {
                        setState(() => _selectedStatus = 'Active');
                        _loadData();
                      },
                    ),
                    const SizedBox(width: 10),
                    StatCard(
                      title: 'Critical Attention',
                      count: _stats['critical']?.toString() ?? '0',
                      icon: Icons.warning_amber_rounded,
                      color: AppTheme.statusCritical,
                      bgColor: AppTheme.statusCriticalBg,
                      isSelected: _selectedStatus == 'Critical',
                      onTap: () {
                        setState(() => _selectedStatus = 'Critical');
                        _loadData();
                      },
                    ),
                    const SizedBox(width: 10),
                    StatCard(
                      title: 'Recovered',
                      count: _stats['recovered']?.toString() ?? '0',
                      icon: Icons.check_circle_outline_rounded,
                      color: AppTheme.statusRecovered,
                      bgColor: AppTheme.statusRecoveredBg,
                      isSelected: _selectedStatus == 'Recovered',
                      onTap: () {
                        setState(() => _selectedStatus = 'Recovered');
                        _loadData();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Search & Filter
              SearchFilterBar(
                searchController: _searchController,
                onSearchChanged: (val) => _loadData(),
                onClearSearch: () {
                  _searchController.clear();
                  _loadData();
                },
                selectedStatus: _selectedStatus,
                onStatusSelected: (status) {
                  setState(() => _selectedStatus = status);
                  _loadData();
                },
                selectedSort: _selectedSort,
                onSortChanged: (sort) {
                  setState(() => _selectedSort = sort);
                  _loadData();
                },
              ),
              const SizedBox(height: 16),

              // Section Header: Patient List Title & Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Patient Records (${_patients.length})',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  if (_selectedStatus != 'All')
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedStatus = 'All');
                        _loadData();
                      },
                      child: Text(
                        'Clear filter',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              // Patients List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppTheme.primaryTeal),
                  ),
                )
              else if (_patients.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_search_outlined,
                          size: 40,
                          color: AppTheme.primaryTeal,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No Patient Records Found',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _searchController.text.isNotEmpty
                            ? 'No matches for "${_searchController.text}". Try a different keyword.'
                            : 'Click the button below to add your first patient.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final added = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => const AddEditPatientScreen(),
                            ),
                          );
                          if (added == true) _loadData();
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Patient Record'),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _patients.length,
                  itemBuilder: (context, index) {
                    final patient = _patients[index];
                    return PatientCard(
                      patient: patient,
                      onTap: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => PatientDetailScreen(
                              patientId: patient.id!,
                            ),
                          ),
                        );
                        if (updated == true) _loadData();
                      },
                      onEdit: () async {
                        final updated = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => AddEditPatientScreen(
                              patient: patient,
                            ),
                          ),
                        );
                        if (updated == true) _loadData();
                      },
                      onDelete: () => _deletePatient(patient),
                    );
                  },
                ),
              const SizedBox(height: 70), // Padding for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => const AddEditPatientScreen(),
            ),
          );
          if (added == true) _loadData();
        },
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(
          'Add Patient',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryTeal,
      ),
    );
  }
}
