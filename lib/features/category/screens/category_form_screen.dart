import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/core/service_locator.dart';
import 'package:vintage_ledger/core/enums/transaction_type.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/common/widgets/form_save_button.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_spacing.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';
import 'package:vintage_ledger/common/widgets/type_selector.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category;
  final TransactionType? initialType;

  const CategoryFormScreen({super.key, this.category, this.initialType});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final TextEditingController nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isEdit = false;
  TransactionType _type = TransactionType.expense;
  int? selectedCodePoint;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      isEdit = true;
      nameController.text = widget.category!.name;
      _type = widget.category!.type ?? TransactionType.expense;
      selectedCodePoint = widget.category!.icon;
    } else {
      _type = widget.initialType ?? TransactionType.expense;
    }
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = nameController.text.trim();

    if (isEdit) {
      await sl.categoryService.updateCategory(
        widget.category!.id!,
        name,
        type: _type,
        icon: selectedCodePoint,
      );
    } else {
      await sl.categoryService.createCategory(name,
          type: _type, icon: selectedCodePoint);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: isEdit
          ? S.of(context, 'editCategory')
          : S.of(context, 'addNewCategory'),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.md),

              TypeSelector(
                value: _type.value,
                onChanged: (v) => setState(() => _type = TransactionType.fromString(v)),
              ),

              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: S.of(context, 'categoryName'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return S.of(context, 'categoryNameRequired');
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text(S.of(context, 'selectIcon'), style: AppTextStyles.titleSmall),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 120,
                child: GridView.builder(
                  scrollDirection: Axis.horizontal,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: kCategoryIcons.length,
                  itemBuilder: (context, index) {
                    final iconData = kCategoryIcons[index];
                    final isSelected = selectedCodePoint == iconData.codePoint;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCodePoint = iconData.codePoint;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.inkBlue : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.inkBlue
                                : AppColors.divider,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          iconData,
                          size: 32,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FormSaveButton(isEdit: isEdit, onPressed: save),
            ],
          ),
        ),
      ),
    );
  }
}
