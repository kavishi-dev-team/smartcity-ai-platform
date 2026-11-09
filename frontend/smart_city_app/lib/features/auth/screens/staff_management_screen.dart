import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../../core/utils/validators.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';

class StaffManagementScreen extends StatefulWidget {
  final bool embedded;

  const StaffManagementScreen({super.key, this.embedded = false});

  @override
  State<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  String _selectedRoleFilter = 'ALL';

  List<UserModel> _users = [];
  List<Map<String, dynamic>> _departments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait<Object?>([
        _api.get(ApiConstants.staffUsers),
        _api.get(ApiConstants.departments, auth: false).catchError((_) => []),
      ]);

      if (!mounted) return;

      final rawUsers = results[0];
      final rawDepts = results[1];

      final parsedUsers = <UserModel>[];
      if (rawUsers is List) {
        for (final item in rawUsers) {
          if (item is Map<String, dynamic>) {
            parsedUsers.add(UserModel.fromJson(item));
          }
        }
      }

      final parsedDepts = <Map<String, dynamic>>[];
      if (rawDepts is List) {
        for (final d in rawDepts) {
          if (d is Map<String, dynamic>) {
            parsedDepts.add(d);
          }
        }
      } else if (rawDepts is Map<String, dynamic> && rawDepts['items'] is List) {
        for (final d in rawDepts['items'] as List) {
          if (d is Map<String, dynamic>) {
            parsedDepts.add(d);
          }
        }
      }

      setState(() {
        _users = parsedUsers;
        _departments = parsedDepts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<UserModel> get _filteredUsers {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _users.where((u) {
      if (_selectedRoleFilter == 'ALL_STAFF' && u.isCitizen) {
        return false;
      } else if (_selectedRoleFilter != 'ALL' &&
          _selectedRoleFilter != 'ALL_STAFF' &&
          u.role.apiValue != _selectedRoleFilter) {
        return false;
      }

      if (q.isNotEmpty) {
        final matchName = u.fullName.toLowerCase().contains(q);
        final matchEmail = u.email.toLowerCase().contains(q);
        final matchDept =
            (u.departmentName ?? '').toLowerCase().contains(q);
        final matchPhone = (u.phoneNumber ?? '').toLowerCase().contains(q);
        return matchName || matchEmail || matchDept || matchPhone;
      }
      return true;
    }).toList();
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return AppColors.navy;
      case UserRole.cityManager:
        return AppColors.primary;
      case UserRole.departmentOfficer:
        return AppColors.cyan;
      case UserRole.citizen:
        return AppColors.success;
    }
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return Icons.security_rounded;
      case UserRole.cityManager:
        return Icons.account_balance_rounded;
      case UserRole.departmentOfficer:
        return Icons.engineering_rounded;
      case UserRole.citizen:
        return Icons.person_outline_rounded;
    }
  }

  Future<void> _showRegisterStaffModal() async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final positionCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();

    String selectedRole = UserRole.departmentOfficer.apiValue;
    int? selectedDepartmentId =
        _departments.isNotEmpty ? _departments.first['id'] as int? : null;
    bool obscurePassword = true;
    bool submitting = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              6,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.lightBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Register Official Staff Account',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.text,
                                ),
                              ),
                              Text(
                                'Provision Department Officer, City Manager, or Super Admin',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Access Role & Authority Level',
                        prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'DEPARTMENT_OFFICER',
                          child: Text('Department Officer (Field & Case Ops)'),
                        ),
                        DropdownMenuItem(
                          value: 'CITY_MANAGER',
                          child: Text('City Manager (Cross-Dept Executive)'),
                        ),
                        DropdownMenuItem(
                          value: 'SUPER_ADMIN',
                          child: Text('Super Admin (Full System Access)'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedRole = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    if (_departments.isNotEmpty)
                      DropdownButtonFormField<int?>(
                        initialValue: selectedDepartmentId,
                        decoration: const InputDecoration(
                          labelText: 'Assigned Municipal Department',
                          prefixIcon: Icon(Icons.apartment_rounded),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('All / Executive Cross-Department'),
                          ),
                          ..._departments.map(
                            (d) => DropdownMenuItem<int?>(
                              value: d['id'] as int,
                              child: Text(d['name']?.toString() ?? 'Department'),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setModalState(() => selectedDepartmentId = val),
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: positionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Official Title / Position',
                        hintText: 'e.g., Senior Traffic Officer, Chief City Manager',
                        prefixIcon: Icon(Icons.work_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl,
                      validator: Validators.fullName,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        hintText: 'e.g., Nuwan Bandara',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailCtrl,
                      validator: Validators.email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Official Email Address *',
                        hintText: 'name@smartcity-dev.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      validator: Validators.phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile Phone Number *',
                        hintText: '0771234567 or +94771234567',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressCtrl,
                      validator: Validators.address,
                      decoration: const InputDecoration(
                        labelText: 'Office / Residential Address *',
                        hintText: 'Enter street address and city (no default)',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: passwordCtrl,
                      obscureText: obscurePassword,
                      validator: Validators.newPassword,
                      decoration: InputDecoration(
                        labelText: 'Initial Login Password *',
                        hintText: '8+ chars with uppercase, lowercase & number',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setModalState(
                            () => obscurePassword = !obscurePassword,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: submitting
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => submitting = true);
                                try {
                                  await _api.post(
                                    ApiConstants.staffUsers,
                                    body: {
                                      'full_name': nameCtrl.text.trim(),
                                      'email': emailCtrl.text.trim(),
                                      'phone_number': phoneCtrl.text.trim(),
                                      'address': addressCtrl.text.trim(),
                                      'role': selectedRole,
                                      'department_id': selectedDepartmentId,
                                      'position':
                                          positionCtrl.text.trim().isEmpty
                                              ? null
                                              : positionCtrl.text.trim(),
                                      'password': passwordCtrl.text,
                                    },
                                  );
                                  if (!mounted) return;
                                  if (ctx.mounted) Navigator.of(ctx).pop();
                                  AppSnackBar.success(
                                    context,
                                    'Staff account registered and activated with immediate login access.',
                                  );
                                  await _loadData();
                                } catch (e) {
                                  setModalState(() => submitting = false);
                                  if (mounted) {
                                    AppSnackBar.error(context, e.toString());
                                  }
                                }
                              },
                        icon: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.verified_user_rounded),
                        label: Text(
                          submitting
                              ? 'Provisioning Account...'
                              : 'Register & Activate Staff Account',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _confirmAndDeleteUser(UserModel target) async {
    final currentUserId = context.read<AuthProvider>().user?.id;
    if (target.id == currentUserId) {
      AppSnackBar.error(
        context,
        'You cannot delete your own active Super Admin account.',
      );
      return false;
    }

    final accountTypeLabel = target.isCitizen
        ? 'Citizen Account'
        : '${target.role.displayName} Staff Account';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.error,
              size: 26,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Delete $accountTypeLabel?',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete ${target.fullName}?',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Email: ${target.email}\n'
              '• Role: ${target.role.displayName}\n'
              '${target.departmentName != null ? "• Department: ${target.departmentName}\n" : ""}'
              '\nThis will immediately revoke all active login sessions and remove this ${target.isCitizen ? "citizen" : "staff"} account from the platform.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Delete Account'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return false;

    try {
      await _api.delete('${ApiConstants.staffUsers}/${target.id}');
      if (!mounted) return false;
      AppSnackBar.success(
        context,
        'Deleted ${target.role.displayName} account (${target.fullName}) successfully.',
      );
      await _loadData();
      return true;
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, e.toString());
      }
      return false;
    }
  }

  Future<void> _showEditStaffModal(UserModel target) async {
    final nameCtrl = TextEditingController(text: target.fullName);
    final phoneCtrl = TextEditingController(text: target.phoneNumber ?? '');
    final addressCtrl = TextEditingController(text: target.address ?? '');
    final positionCtrl = TextEditingController(text: target.position ?? '');
    final newPassCtrl = TextEditingController();

    String selectedRole = target.role.apiValue;
    int selectedDeptId = target.departmentId ?? 0;
    bool isActive = target.isActive;
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              6,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Account: ${target.fullName}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    target.email,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'Assigned System Role',
                      prefixIcon: Icon(Icons.security_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'SUPER_ADMIN',
                        child: Text('Super Admin (Full System Control)'),
                      ),
                      DropdownMenuItem(
                        value: 'CITY_MANAGER',
                        child: Text('City Manager (Executive Operations)'),
                      ),
                      DropdownMenuItem(
                        value: 'DEPARTMENT_OFFICER',
                        child: Text('Department Officer (Department Ops)'),
                      ),
                      DropdownMenuItem(
                        value: 'CITIZEN',
                        child: Text('Citizen (Standard Portal)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedRole = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (_departments.isNotEmpty && selectedRole != 'CITIZEN')
                    DropdownButtonFormField<int>(
                      initialValue: _departments.any(
                        (d) => d['id'] == selectedDeptId,
                      )
                          ? selectedDeptId
                          : 0,
                      decoration: const InputDecoration(
                        labelText: 'Department Assignment',
                        prefixIcon: Icon(Icons.apartment_rounded),
                      ),
                      items: [
                        const DropdownMenuItem<int>(
                          value: 0,
                          child: Text('Unassigned / All Departments'),
                        ),
                        ..._departments.map(
                          (d) => DropdownMenuItem<int>(
                            value: d['id'] as int,
                            child: Text(d['name']?.toString() ?? 'Department'),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedDeptId = val);
                        }
                      },
                    ),
                  const SizedBox(height: 12),
                  if (selectedRole != 'CITIZEN') ...[
                    TextField(
                      controller: positionCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Official Position / Title',
                        prefixIcon: Icon(Icons.work_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Reset Password (optional)',
                      hintText: 'Leave blank to keep existing password',
                      prefixIcon: Icon(Icons.lock_reset_rounded),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Account Active Status',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      isActive
                          ? 'Permitted to sign in and perform role operations'
                          : 'Suspended — active sessions revoked',
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: isActive,
                    onChanged: (val) => setModalState(() => isActive = val),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: saving
                          ? null
                          : () async {
                              setModalState(() => saving = true);
                              try {
                                final body = <String, dynamic>{
                                  'full_name': nameCtrl.text.trim(),
                                  'phone_number': phoneCtrl.text.trim().isEmpty
                                      ? null
                                      : phoneCtrl.text.trim(),
                                  'address': addressCtrl.text.trim(),
                                  'role': selectedRole,
                                  'department_id': selectedDeptId,
                                  'position': positionCtrl.text.trim(),
                                  'is_active': isActive,
                                };
                                if (newPassCtrl.text.trim().isNotEmpty) {
                                  body['new_password'] =
                                      newPassCtrl.text.trim();
                                }

                                await _api.patch(
                                  '${ApiConstants.staffUsers}/${target.id}',
                                  body: body,
                                );
                                if (!mounted) return;
                                if (ctx.mounted) Navigator.of(ctx).pop();
                                AppSnackBar.success(
                                  context,
                                  'Updated ${target.fullName} successfully.',
                                );
                                await _loadData();
                              } catch (e) {
                                setModalState(() => saving = false);
                                if (mounted) {
                                  AppSnackBar.error(context, e.toString());
                                }
                              }
                            },
                      icon: const Icon(Icons.save_outlined),
                      label: Text(saving ? 'Saving...' : 'Save Access & Profile Changes'),
                    ),
                  ),
                  if (target.id != context.read<AuthProvider>().user?.id) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: saving
                            ? null
                            : () async {
                                Navigator.of(ctx).pop();
                                await _confirmAndDeleteUser(target);
                              },
                        icon: const Icon(Icons.delete_forever_rounded),
                        label: Text(
                          'Delete ${target.isCitizen ? "Citizen" : "Staff"} Account',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAccessMatrixCard(bool isSuperAdmin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Production Role-Based Access Control (RBAC) Matrix',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isSuperAdmin
                      ? AppColors.navy.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isSuperAdmin ? 'FULL ADMIN WRITE ACCESS' : 'READ-ONLY DIRECTORY',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: isSuperAdmin ? AppColors.navy : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _matrixRow(
            role: 'Super Admin',
            color: AppColors.navy,
            permissions:
                'Full System Access • Register & manage Super Admins, City Managers & Department Officers • Assign departments, reset credentials, suspend accounts • Full AI triage, analytics & all municipal domains',
          ),
          const Divider(height: 16),
          _matrixRow(
            role: 'City Manager',
            color: AppColors.primary,
            permissions:
                'Executive Operations Access • Cross-department SLA & analytics oversight • Assign issues across all municipal departments • Manage public safety alerts, waste schedules & AI priority overrides • View staff directory',
          ),
          const Divider(height: 16),
          _matrixRow(
            role: 'Department Officer',
            color: AppColors.cyan,
            permissions:
                'Department Field & Case Access • Inspect & resolve assigned department issues (Traffic, Waste, Energy, Water, Safety, Air Quality) • Post citizen timeline updates & internal officer notes • Update field status (`Assigned` → `In Progress` → `Resolved`)',
          ),
        ],
      ),
    );
  }

  Widget _matrixRow({
    required String role,
    required Color color,
    required String permissions,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 118,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            role,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            permissions,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().user;
    final isSuperAdmin = currentUser?.role == UserRole.superAdmin;

    final superAdminCount =
        _users.where((u) => u.role == UserRole.superAdmin).length;
    final cityManagerCount =
        _users.where((u) => u.role == UserRole.cityManager).length;
    final officerCount =
        _users.where((u) => u.role == UserRole.departmentOfficer).length;
    final citizenCount =
        _users.where((u) => u.role == UserRole.citizen).length;

    final body = RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 940),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Hero Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.navy, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isSuperAdmin
                                ? 'Super Admin Staff & Access Control'
                                : 'Municipal Staff & Department Directory',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSuperAdmin
                                ? 'Register Department Officers & City Managers, assign departments, and manage role permissions.'
                                : 'Inspect active Department Officers, City Managers, and municipal department assignments.',
                            style: const TextStyle(
                              color: AppColors.lightBlue,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      if (isSuperAdmin)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.navy,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onPressed: _showRegisterStaffModal,
                          icon: const Icon(
                            Icons.person_add_alt_1_rounded,
                            size: 18,
                          ),
                          label: const Text(
                            'Register Officer / Manager',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Role Count Summary Cards
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _roleCountChip(
                      'Super Admins',
                      superAdminCount,
                      AppColors.navy,
                      'SUPER_ADMIN',
                    ),
                    _roleCountChip(
                      'City Managers',
                      cityManagerCount,
                      AppColors.primary,
                      'CITY_MANAGER',
                    ),
                    _roleCountChip(
                      'Dept Officers',
                      officerCount,
                      AppColors.cyan,
                      'DEPARTMENT_OFFICER',
                    ),
                    if (isSuperAdmin)
                      _roleCountChip(
                        'Citizens',
                        citizenCount,
                        AppColors.success,
                        'CITIZEN',
                      ),
                  ],
                ),

                const SizedBox(height: 14),
                _buildAccessMatrixCard(isSuperAdmin),
                const SizedBox(height: 16),

                // Search & Role Filter Bar
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText:
                              'Search by name, email, phone, or department...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() {});
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filledTonal(
                      tooltip: 'Refresh Directory',
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.white,
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.88, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        if (isSuperAdmin) ...[
                          _filterChip('All Accounts', 'ALL',
                              Icons.people_alt_rounded),
                          const SizedBox(width: 8),
                        ],
                        _filterChip(
                            'All Staff', 'ALL_STAFF', Icons.badge_rounded),
                        const SizedBox(width: 8),
                        _filterChip('Department Officers', 'DEPARTMENT_OFFICER',
                            Icons.apartment_rounded),
                        const SizedBox(width: 8),
                        _filterChip('City Managers', 'CITY_MANAGER',
                            Icons.location_city_rounded),
                        const SizedBox(width: 8),
                        _filterChip('Super Admins', 'SUPER_ADMIN',
                            Icons.admin_panel_settings_rounded),
                        if (isSuperAdmin) ...[
                          const SizedBox(width: 8),
                          _filterChip(
                              'Citizens', 'CITIZEN', Icons.person_outline_rounded),
                        ],
                        const SizedBox(width: 16),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _loadData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_filteredUsers.isEmpty)
                  Card(
                    child: const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(
                        child: Text(
                          'No accounts match the selected filter.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                    ),
                  )
                else
                  ..._filteredUsers.map(
                    (u) => _buildUserCard(u, isSuperAdmin: isSuperAdmin),
                  ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.embedded) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors.navy,
          foregroundColor: Colors.white,
          title: Text(
            isSuperAdmin
                ? 'Staff & Access Control (Super Admin)'
                : 'Municipal Staff Directory',
          ),
          actions: [
            if (isSuperAdmin)
              IconButton(
                tooltip: 'Register Staff Account',
                onPressed: _showRegisterStaffModal,
                icon: const Icon(Icons.person_add_alt_1_rounded),
              ),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: body,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(
          isSuperAdmin
              ? 'Staff & Access Control'
              : 'Municipal Staff Directory',
        ),
        actions: [
          if (isSuperAdmin)
            IconButton(
              tooltip: 'Register Staff Account',
              onPressed: _showRegisterStaffModal,
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
        ],
      ),
      body: body,
    );
  }

  Widget _roleCountChip(
    String label,
    int count,
    Color color,
    String filterKey,
  ) {
    final selected = _selectedRoleFilter == filterKey;
    return InkWell(
      onTap: () => setState(() => _selectedRoleFilter = filterKey),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value, [IconData? icon]) {
    final selected = _selectedRoleFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedRoleFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.lightBlue.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: selected ? Colors.white : AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel u, {required bool isSuperAdmin}) {
    final rColor = _roleColor(u.role);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: rColor.withValues(alpha: 0.14),
              child: Icon(_roleIcon(u.role), color: rColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        u.fullName,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: rColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          u.role.displayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: rColor,
                          ),
                        ),
                      ),
                      if (!u.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SUSPENDED',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    u.email,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (u.departmentName != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.apartment_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${u.departmentName}${u.position != null ? " • ${u.position}" : ""}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                      if (u.phoneNumber != null && u.phoneNumber!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              u.phoneNumber!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      if (u.address != null && u.address!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              u.address!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSuperAdmin)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Manage Role, Department & Access',
                    onPressed: () => _showEditStaffModal(u),
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  if (u.id != context.read<AuthProvider>().user?.id)
                    IconButton(
                      tooltip:
                          'Delete ${u.isCitizen ? "Citizen" : "Staff"} Account',
                      onPressed: () => _confirmAndDeleteUser(u),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
