import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/debt/models/debt.dart';
import 'package:vintage_ledger/features/debt/services/debt_service.dart';
import 'package:vintage_ledger/common/widgets/amount_input_field.dart';
import 'package:vintage_ledger/common/widgets/dropdown_field.dart';
import 'package:vintage_ledger/common/widgets/selection_sheet.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/core/service_locator.dart';

enum PartyInputMode { freeText, emailLookup }

class DebtFormScreen extends StatefulWidget {
  final Debt? debt;

  const DebtFormScreen({super.key, this.debt});

  @override
  State<DebtFormScreen> createState() => _DebtFormScreenState();
}

class _DebtFormScreenState extends State<DebtFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = DebtService();
  
  late DebtType _type;
  final _partyNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _amountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  bool _isLoading = false;
  List<Wallet> _wallets = [];
  String? _walletId;

  // Linked debt state
  PartyInputMode _partyInputMode = PartyInputMode.freeText;
  final _emailController = TextEditingController();
  String? _partyUserId;
  String? _partyAccountId;
  String? _foundPartyName;
  bool _isSearching = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _type = widget.debt?.type ?? DebtType.lend;
    if (widget.debt != null) {
      _partyNameController.text = widget.debt!.partyName;
      _contactController.text = widget.debt!.partyContact ?? '';
      _amountController.text = widget.debt!.totalAmount.toString();
      _interestRateController.text = widget.debt!.interestRate?.toString() ?? '';
      _descriptionController.text = widget.debt!.description ?? '';
      _dueDate = widget.debt!.dueDate;
      _walletId = widget.debt!.walletId;
    }
    _loadWallets();
  }

  @override
  void dispose() {
    _partyNameController.dispose();
    _contactController.dispose();
    _amountController.dispose();
    _interestRateController.dispose();
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    final wallets = await sl.walletService.getWallets();
    if (!mounted) return;
    setState(() {
      _wallets = wallets.where((w) => w.type == WalletType.debt).toList();
      _walletId ??= _wallets.firstOrNull?.id;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.debt == null ? S.of(context, 'addDebt') : S.of(context, 'editDebt'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildTypeSelector(),
            const SizedBox(height: AppSpacing.lg),
            _buildPartyInputModeSelector(),
            const SizedBox(height: AppSpacing.md),
            if (_partyInputMode == PartyInputMode.freeText) ...[
              _buildTextField(
                controller: _partyNameController,
                label: '${S.of(context, 'debtPerson')} ${_type == DebtType.lend ? S.of(context, 'borrow').toLowerCase() : S.of(context, 'lend').toLowerCase()}',
                hint: S.of(context, 'partyNameRequired'),
                icon: Icons.person,
                validator: (v) => v?.isEmpty ?? true ? S.of(context, 'partyNameRequired') : null,
              ),
            ] else ...[
              _buildEmailSearchField(),
            ],
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _contactController,
              label: 'Số điện thoại (tùy chọn)',
              hint: 'Nhập số điện thoại',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.md),
            AmountInputField(
              controller: _amountController,
              label: S.of(context, 'debtAmount'),
            ),
            if (_wallets.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              DropdownField<String>(
                label: S.of(context, 'wallet'),
                value: _wallets.where((w) => w.id == _walletId).firstOrNull?.name,
                prefixIcon: Icons.account_balance_wallet_outlined,
                items: _wallets.map((w) => SelectionItem(
                  value: w.id!,
                  label: '${w.type.emoji} ${w.name}',
                )).toList(),
                selected: _walletId,
                onChanged: (v) => setState(() => _walletId = v),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            _buildDateField(),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _interestRateController,
              label: 'Lãi suất % (tùy chọn)',
              hint: 'Nhập lãi suất',
              icon: Icons.percent,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _descriptionController,
              label: '${S.of(context, 'debtNote')} (tùy chọn)',
              hint: S.of(context, 'noteHint'),
              icon: Icons.note,
              maxLines: 3,
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyInputModeSelector() {
    return SegmentedButton<PartyInputMode>(
      segments: const [
        ButtonSegment(
          value: PartyInputMode.freeText,
          label: Text('Nhập tên'),
          icon: Icon(Icons.edit),
        ),
        ButtonSegment(
          value: PartyInputMode.emailLookup,
          label: Text('Tìm người dùng'),
          icon: Icon(Icons.email),
        ),
      ],
      selected: {_partyInputMode},
      onSelectionChanged: (selected) {
        setState(() {
          _partyInputMode = selected.first;
          // Clear linked user info when switching modes
          if (_partyInputMode == PartyInputMode.freeText) {
            _emailController.clear();
            _partyUserId = null;
            _partyAccountId = null;
            _foundPartyName = null;
            _emailError = null;
          } else {
            _partyNameController.clear();
          }
        });
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildEmailSearchField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email người dùng',
                  hintText: 'Nhập email để tìm...',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _partyInputMode == PartyInputMode.emailLookup && _partyUserId == null
                    ? (_) => 'Vui lòng tìm và chọn người dùng'
                    : null,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              onPressed: _isSearching ? null : _searchByEmail,
              icon: _isSearching
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.search),
            ),
          ],
        ),
        if (_emailError != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _emailError!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.expense),
          ),
        ],
        if (_foundPartyName != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md2),
            decoration: BoxDecoration(
              color: AppColors.income.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSm),
              border: Border.all(color: AppColors.income.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.income, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_foundPartyName!, style: AppTextStyles.bodyBold),
                      Text(_emailController.text, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeOption(
            type: DebtType.lend,
            label: S.of(context, 'lendDebts'),
            icon: Icons.trending_up,
            color: AppColors.income,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildTypeOption(
            type: DebtType.borrow,
            label: S.of(context, 'borrowDebts'),
            icon: Icons.trending_down,
            color: AppColors.expense,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required DebtType type,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          border: Border.all(
            color: isSelected ? color : AppColors.divider,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 32),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.bodyBold.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '${S.of(context, 'debtDueDate')} (tùy chọn)',
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          _dueDate == null ? 'Chọn ngày' : _formatDate(_dueDate!),
          style: _dueDate == null ? AppTextStyles.hint : AppTextStyles.body,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _save,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(widget.debt == null ? S.of(context, 'createDebt') : S.of(context, 'updateDebt')),
      ),
    );
  }

  Future<void> _searchByEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Vui lòng nhập email');
      return;
    }

    // Validate: reject self-lookup
    final currentEmail = sl.authService.currentUser?.email;
    if (currentEmail != null && email.toLowerCase() == currentEmail.toLowerCase()) {
      setState(() {
        _emailError = 'Không thể tạo nợ với chính mình';
        _partyUserId = null;
        _partyAccountId = null;
        _foundPartyName = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _emailError = null;
      _partyUserId = null;
      _partyAccountId = null;
      _foundPartyName = null;
    });

    try {
      final userId = await sl.accountService.findUserIdByEmail(email);
      if (!mounted) return;

      if (userId == null) {
        setState(() {
          _emailError = 'Không tìm thấy người dùng';
          _isSearching = false;
        });
        return;
      }

      // Get display name and account ID
      final displayName = await sl.accountService.getAccountNameForUser(userId);
      final accounts = await sl.accountService.getAccountsForUser(userId);
      if (!mounted) return;

      if (accounts.isEmpty) {
        setState(() {
          _emailError = 'Không tìm thấy tài khoản người dùng';
          _isSearching = false;
        });
        return;
      }

      setState(() {
        _partyUserId = userId;
        _partyAccountId = accounts.first.id;
        _foundPartyName = displayName.isNotEmpty ? displayName : email;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _emailError = 'Lỗi tìm kiếm: $e';
        _isSearching = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = int.parse(_amountController.text);
      final interestRate = _interestRateController.text.isEmpty
          ? null
          : double.tryParse(_interestRateController.text);

      if (widget.debt == null) {
        final isLinked = _partyInputMode == PartyInputMode.emailLookup && _partyUserId != null;

        if (isLinked) {
          if (_type == DebtType.lend) {
            await _service.choVayLienKet(
              partyUserId: _partyUserId!,
              partyAccountId: _partyAccountId!,
              partyName: _foundPartyName!,
              amount: amount,
              walletId: _walletId,
              dueDate: _dueDate,
              interestRate: interestRate,
              description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
            );
          } else {
            await _service.vayMuonLienKet(
              partyUserId: _partyUserId!,
              partyAccountId: _partyAccountId!,
              partyName: _foundPartyName!,
              amount: amount,
              walletId: _walletId,
              dueDate: _dueDate,
              interestRate: interestRate,
              description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
            );
          }
        } else {
          if (_type == DebtType.lend) {
            await _service.choVay(
              partyName: _partyNameController.text,
              amount: amount,
              contact: _contactController.text.isEmpty ? null : _contactController.text,
              walletId: _walletId,
              dueDate: _dueDate,
              interestRate: interestRate,
              description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
            );
          } else {
            await _service.vayMuon(
              partyName: _partyNameController.text,
              amount: amount,
              contact: _contactController.text.isEmpty ? null : _contactController.text,
              walletId: _walletId,
              dueDate: _dueDate,
              interestRate: interestRate,
              description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
            );
          }
        }
      } else {
        await _service.updateDebt(
          widget.debt!.id,
          partyName: _partyNameController.text,
          partyContact: _contactController.text.isEmpty ? null : _contactController.text,
          totalAmount: amount,
          dueDate: _dueDate,
          interestRate: interestRate,
          description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
          walletId: _walletId,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.of(context, 'error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
