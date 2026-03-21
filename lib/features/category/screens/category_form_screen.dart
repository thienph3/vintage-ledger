import 'package:flutter/material.dart';
import 'package:vintage_ledger/core/l10n/s.dart';
import 'package:vintage_ledger/features/category/models/category.dart';
import 'package:vintage_ledger/features/category/services/category_service.dart';
import 'package:vintage_ledger/common/widgets/app_scaffold.dart';
import 'package:vintage_ledger/core/theme/app_colors.dart';
import 'package:vintage_ledger/core/theme/app_text_styles.dart';
import 'package:vintage_ledger/core/constants/category_icons.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category;
  final String? initialType;

  const CategoryFormScreen({super.key, this.category, this.initialType});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final CategoryService categoryService = CategoryService();
  final TextEditingController nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isEdit = false;
  String _type = 'expense';
  int? selectedCodePoint;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      isEdit = true;
      nameController.text = widget.category!.name;
      _type = widget.category!.type ?? 'expense';
      selectedCodePoint = widget.category!.icon;
    } else {
      _type = widget.initialType ?? 'expense';
    }
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = nameController.text.trim();

    if (isEdit) {
      await categoryService.updateCategory(
        widget.category!.id!,
        name,
        type: _type,
        icon: selectedCodePoint,
      );
    } else {
      await categoryService.createCategory(name,
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
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Type selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    _typeButton('income', S.of(context, 'income')),
                    const SizedBox(width: 4),
                    _typeButton('expense', S.of(context, 'expense')),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: S.of(context, 'categoryName'),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return S.of(context, 'categoryNameRequired');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(S.of(context, 'selectIcon'), style: AppTextStyles.bodyBold),
              const SizedBox(height: 8),
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: save,
                  child: Text(S.of(context, 'save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeButton(String value, String label) {
    final selected = _type == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _type = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.inkBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: selected ? Colors.white : AppColors.inkBlue,
            ),
          ),
        ),
      ),
    );
  }
}
