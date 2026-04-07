import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/shimmer_placeholder.dart';
import 'package:vintage_ledger/common/widgets/ledger_card.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/features/transfer/models/transfer.dart';
import 'package:vintage_ledger/features/transfer/services/transfer_service.dart';
import 'package:vintage_ledger/features/wallet/models/wallet.dart';
import 'package:vintage_ledger/features/wallet/services/wallet_service.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = TransferService();
  final _walletService = WalletService();
  
  TransferType _type = TransferType.internal;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String? _sourceWalletId;
  String? _destWalletId;
  List<Wallet> _wallets = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final wallets = await _walletService.getWallets();
    setState(() {
      _wallets = wallets;
      if (wallets.isNotEmpty) {
        _sourceWalletId = wallets.first.id;
        if (wallets.length > 1) {
          _destWalletId = wallets[1].id;
        }
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: S.of(context, 'transferTitle'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _buildTypeSelector(),
            const SizedBox(height: AppSpacing.lg),
            _buildWalletSelectors(),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _amountController,
              label: S.of(context, 'amount'),
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
            _buildTextField(
              controller: _noteController,
              label: '${S.of(context, 'note')} (tùy chọn)',
              hint: S.of(context, 'noteHint'),
              icon: Icons.note,
              maxLines: 2,
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildTransferButton(),
            const SizedBox(height: AppSpacing.lg),
            _buildShortcuts(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context, 'transferType'), style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildTypeOption(
                type: TransferType.internal,
                label: S.of(context, 'transferInternal'),
                icon: Icons.swap_horiz,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildTypeOption(
                type: TransferType.funding,
                label: S.of(context, 'transferFunding'),
                icon: Icons.family_restroom,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required TransferType type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusLg),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTextStyles.bodyBold.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSelectors() {
    if (_wallets.isEmpty) {
      return const ShimmerPlaceholder();
    }

    return LedgerCard(
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _sourceWalletId,
            decoration: InputDecoration(
              labelText: S.of(context, 'fromWalletLabel'),
              prefixIcon: Icon(Icons.account_balance_wallet),
            ),
            items: _wallets.map((wallet) {
              return DropdownMenuItem(
                value: wallet.id,
                child: Text(wallet.name),
              );
            }).toList(),
            onChanged: (value) => setState(() => _sourceWalletId = value),
            validator: (v) => v == null ? S.of(context, 'selectSourceWallet') : null,
          ),
          const SizedBox(height: AppSpacing.md),
          const Icon(Icons.arrow_downward, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue: _destWalletId,
            decoration: InputDecoration(
              labelText: _type == TransferType.funding ? S.of(context, 'toFamilyWalletLabel') : S.of(context, 'toWalletLabel'),
              prefixIcon: const Icon(Icons.account_balance_wallet),
            ),
            items: _wallets
                .where((w) => w.id != _sourceWalletId)
                .map((wallet) {
              return DropdownMenuItem(
                value: wallet.id,
                child: Text(wallet.name),
              );
            }).toList(),
            onChanged: (value) => setState(() => _destWalletId = value),
            validator: (v) => v == null ? S.of(context, 'selectDestWallet') : null,
          ),
        ],
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

  Widget _buildTransferButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _transfer,
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(S.of(context, 'transferButton')),
      ),
    );
  }

  Widget _buildShortcuts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(S.of(context, 'shortcuts'), style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.md),
        StreamBuilder<List<TransferShortcut>>(
          stream: _service.watchShortcuts(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return LedgerCard(
                child: Center(
                  child: Text(S.of(context, 'noShortcuts'), style: AppTextStyles.hint),
                ),
              );
            }

            return Column(
              children: snapshot.data!.map((s) => _buildShortcutItem(s)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildShortcutItem(TransferShortcut shortcut) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: LedgerCard(
        child: ListTile(
          leading: const Icon(Icons.flash_on, color: AppColors.primary),
          title: Text(shortcut.name, style: AppTextStyles.bodyBold),
          subtitle: Text(shortcut.type.displayName, style: AppTextStyles.caption),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: AppColors.error),
            onPressed: () => _service.deleteShortcut(shortcut.id),
          ),
          onTap: () => _useShortcut(shortcut),
        ),
      ),
    );
  }

  Future<void> _transfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sourceWalletId == null || _destWalletId == null) return;

    setState(() => _isLoading = true);

    try {
      final amount = int.parse(_amountController.text);
      final note = _noteController.text.isEmpty ? null : _noteController.text;

      if (_type == TransferType.internal) {
        await _service.chuyenGiuaCacVi(
          fromWalletId: _sourceWalletId!,
          toWalletId: _destWalletId!,
          amount: amount,
          note: note,
        );
      } else {
        await _service.napVaoViGiaDinh(
          personalWalletId: _sourceWalletId!,
          familyWalletId: _destWalletId!,
          amount: amount,
          note: note,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context, 'transferSuccess'))),
        );
        _amountController.clear();
        _noteController.clear();
      }
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

  void _useShortcut(TransferShortcut shortcut) {
    setState(() {
      _type = shortcut.type;
      _sourceWalletId = shortcut.sourceWalletId;
      _destWalletId = shortcut.destWalletId;
      if (shortcut.defaultAmount != null) {
        _amountController.text = shortcut.defaultAmount.toString();
      }
    });
  }
}
