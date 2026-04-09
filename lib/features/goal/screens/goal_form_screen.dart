import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/goal/models/goal.dart';
import 'package:vintage_ledger/features/goal/services/goal_service.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/wallet/services/wallet_service.dart';

class GoalFormScreen extends StatefulWidget {
  final Goal? goal;

  const GoalFormScreen({super.key, this.goal});

  @override
  State<GoalFormScreen> createState() => _GoalFormScreenState();
}

class _GoalFormScreenState extends State<GoalFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = GoalService();
  final _walletService = WalletService();
  
  late GoalCategory _category;
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  DateTime? _targetDate;
  String? _selectedWalletId;
  List<Wallet> _wallets = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _category = widget.goal?.category ?? GoalCategory.vacation;
    if (widget.goal != null) {
      _nameController.text = widget.goal!.name;
      _targetAmountController.text = widget.goal!.targetAmount.toString();
      _targetDate = widget.goal!.targetDate;
      _selectedWalletId = widget.goal!.fundingWalletId;
    }
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final wallets = await _walletService.getWallets();
    setState(() {
      _wallets = wallets.where((w) => w.type == WalletType.saving).toList();
      if (_selectedWalletId == null && _wallets.isNotEmpty) {
        _selectedWalletId = _wallets.first.id;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: widget.goal == null ? S.of(context, 'createGoal') : S.of(context, 'updateGoal'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildCategorySelector(),
            const SizedBox(height: AppSpacing.lg),
            _buildTextField(
              controller: _nameController,
              label: S.of(context, 'goalName'),
              hint: S.of(context, 'goalNameRequired'),
              icon: Icons.flag,
              validator: (v) => v?.isEmpty ?? true ? S.of(context, 'goalNameRequired') : null,
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _targetAmountController,
              label: S.of(context, 'targetAmount'),
              hint: S.of(context, 'enterAmount'),
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v?.isEmpty ?? true) return S.of(context, 'enterAmount');
                if (int.tryParse(v!) == null) return S.of(context, 'amountMustBePositive');
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _buildDateField(),
            const SizedBox(height: AppSpacing.md),
            _buildWalletSelector(),
            const SizedBox(height: AppSpacing.xl),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context, 'goalCategory'), style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: GoalCategory.values.map((cat) => _buildCategoryChip(cat)).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(GoalCategory category) {
    final isSelected = _category == category;
    return GestureDetector(
      onTap: () => setState(() => _category = category),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg + 8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji, style: AppTextStyles.emoji),
            const SizedBox(width: AppSpacing.xs),
            Text(
              category.displayName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
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
      validator: validator,
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDate,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '${S.of(context, 'goalTargetDate')} (tùy chọn)',
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          _targetDate == null ? 'Chọn ngày' : _formatDate(_targetDate!),
          style: _targetDate == null ? AppTextStyles.hint : AppTextStyles.body,
        ),
      ),
    );
  }

  Widget _buildWalletSelector() {
    if (_wallets.isEmpty) {
      return const ShimmerPlaceholder();
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedWalletId,
      decoration: InputDecoration(
        labelText: S.of(context, 'goalWallet'),
        prefixIcon: Icon(Icons.account_balance_wallet),
      ),
      items: _wallets.map((wallet) {
        return DropdownMenuItem(
          value: wallet.id,
          child: Text(wallet.name),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedWalletId = value),
      validator: (v) => v == null ? S.of(context, 'selectWalletRequired') : null,
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
            : Text(widget.goal == null ? S.of(context, 'createGoal') : S.of(context, 'updateGoal')),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date != null) {
      setState(() => _targetDate = date);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWalletId == null) return;

    setState(() => _isLoading = true);

    try {
      final targetAmount = int.parse(_targetAmountController.text);

      if (widget.goal == null) {
        await _service.taoMucTieu(
          name: _nameController.text,
          category: _category,
          targetAmount: targetAmount,
          fundingWalletId: _selectedWalletId!,
          targetDate: _targetDate,
        );
      } else {
        await _service.updateGoal(
          widget.goal!.id,
          name: _nameController.text,
          targetAmount: targetAmount,
          targetDate: _targetDate,
          fundingWalletId: _selectedWalletId,
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
