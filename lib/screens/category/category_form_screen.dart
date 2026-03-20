import 'package:flutter/material.dart';
import '../../l10n/s.dart';
import '../../models/category.dart';
import '../../services/category_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/ledger_header.dart';
import '../../theme/app_colors.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final CategoryService categoryService = CategoryService();
  final TextEditingController nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isEdit = false;
  int? selectedIconIndex;

  final List<IconData> iconOptions = [
    Icons.fastfood,
    Icons.directions_car,
    Icons.shopping_cart,
    Icons.home,
    Icons.sports_soccer,
    Icons.movie,
    Icons.local_cafe,
    Icons.health_and_safety,
    Icons.phone_iphone,
    Icons.school,
    Icons.pets,
    Icons.flight,
    Icons.music_note,
    Icons.local_hospital,
  ];

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      isEdit = true;
      nameController.text = widget.category!.name;

      if (widget.category!.icon != null) {
        final cp = widget.category!.icon!;
        final idx = iconOptions.indexWhere((icon) => icon.codePoint == cp);
        selectedIconIndex = idx >= 0 ? idx : null;
      }
    }
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;
    final name = nameController.text.trim();

    final iconCodePoint = selectedIconIndex;
    if (isEdit) {
      await categoryService.updateCategory(
        widget.category!.id!,
        name,
        icon: iconCodePoint,
      );
    } else {
      await categoryService.createCategory(
        name,
        icon: iconCodePoint,
      );
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: "",
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LedgerHeader(
                title: isEdit ? S.of(context, 'editCategory') : S.of(context, 'addNewCategory'),
                showBackButton: true,
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
              Text(
                S.of(context, 'selectIcon'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
                  itemCount: iconOptions.length,
                  itemBuilder: (context, index) {
                    final iconData = iconOptions[index];
                    final isSelected = selectedIconIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIconIndex = index;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.inkBlue : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.inkBlue : AppColors.divider,
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
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    S.of(context, 'save'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
