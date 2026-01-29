import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/image_upload_service.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';

class CreateUserCocktailScreen extends ConsumerStatefulWidget {
  final UserCocktail? cocktailToEdit;

  const CreateUserCocktailScreen({super.key, this.cocktailToEdit});

  @override
  ConsumerState<CreateUserCocktailScreen> createState() =>
      _CreateUserCocktailScreenState();
}

class _CreateUserCocktailScreenState
    extends ConsumerState<CreateUserCocktailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _garnishController = TextEditingController();

  String? _selectedGlass;
  String? _selectedMethod;
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;

  final List<_IngredientEntry> _ingredients = [];

  bool get _isEditing => widget.cocktailToEdit != null;

  static const List<String> _glassOptions = [
    'Coupe',
    'Highball',
    'Rocks',
    'Martini',
    'Collins',
    'Flute',
    'Wine',
    'Mug',
    'Shot',
    'Hurricane',
  ];

  static const List<String> _methodOptions = [
    'Shake',
    'Stir',
    'Build',
    'Blend',
    'Muddle',
    'Layer',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final cocktail = widget.cocktailToEdit!;
      _nameController.text = cocktail.name;
      _descriptionController.text = cocktail.description ?? '';
      _instructionsController.text = cocktail.instructions;
      _garnishController.text = cocktail.garnish ?? '';
      _selectedGlass = cocktail.glass;
      _selectedMethod = cocktail.method;
      _existingImageUrl = cocktail.imageUrl;

      // 기존 재료 로드
      _loadExistingIngredients();
    }
  }

  Future<void> _loadExistingIngredients() async {
    if (widget.cocktailToEdit == null) return;

    final ingredients = await ref
        .read(userCocktailIngredientsProvider(widget.cocktailToEdit!.id).future);

    setState(() {
      _ingredients.clear();
      for (final ing in ingredients) {
        _ingredients.add(_IngredientEntry(
          ingredientId: ing.ingredientId,
          customName: ing.customIngredientName,
          amount: ing.amount?.toString() ?? '',
          units: ing.units ?? '',
          isOptional: ing.isOptional,
        ));
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    _garnishController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final imageService = ref.read(imageUploadServiceProvider);
    final File? image;

    if (source == ImageSource.gallery) {
      image = await imageService.pickImageFromGallery();
    } else {
      image = await imageService.pickImageFromCamera();
    }

    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _showImagePicker() {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: Text(l10n.takePhoto),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(l10n.chooseFromGallery),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImage != null || _existingImageUrl != null)
              ListTile(
                leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                title: Text(
                  l10n.removePhoto,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                    _existingImageUrl = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(_IngredientEntry());
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
  }

  Future<void> _saveCocktail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final l10n = AppLocalizations.of(context)!;
      final cocktailService = ref.read(userCocktailServiceProvider);
      final imageService = ref.read(imageUploadServiceProvider);

      // 이미지 업로드
      String? imageUrl = _existingImageUrl;
      if (_selectedImage != null) {
        imageUrl = await imageService.uploadCocktailImage(_selectedImage!);
      }

      // 재료 데이터 준비
      final ingredients = _ingredients
          .where((ing) =>
              (ing.ingredientId != null && ing.ingredientId!.isNotEmpty) ||
              (ing.customName != null && ing.customName!.isNotEmpty))
          .toList()
          .asMap()
          .entries
          .map((entry) => UserCocktailIngredient(
                userCocktailId: '', // 서비스에서 설정됨
                ingredientId: entry.value.ingredientId,
                customIngredientName: entry.value.customName,
                amount: double.tryParse(entry.value.amount),
                units: entry.value.units.isNotEmpty ? entry.value.units : null,
                sortOrder: entry.key,
                isOptional: entry.value.isOptional,
              ))
          .toList();

      if (_isEditing) {
        // 수정
        final success = await cocktailService.updateCocktail(
          cocktailId: widget.cocktailToEdit!.id,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          instructions: _instructionsController.text.trim(),
          garnish: _garnishController.text.trim().isNotEmpty
              ? _garnishController.text.trim()
              : null,
          glass: _selectedGlass,
          method: _selectedMethod,
          imageUrl: imageUrl,
        );

        if (success) {
          // 재료 업데이트
          await cocktailService.updateIngredients(
            cocktailId: widget.cocktailToEdit!.id,
            ingredients: ingredients,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.cocktailSaved)),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        // 생성
        final cocktailId = await cocktailService.createCocktail(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
          instructions: _instructionsController.text.trim(),
          garnish: _garnishController.text.trim().isNotEmpty
              ? _garnishController.text.trim()
              : null,
          glass: _selectedGlass,
          method: _selectedMethod,
          imageUrl: imageUrl,
          ingredients: ingredients,
        );

        if (mounted) {
          if (cocktailId != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.cocktailSaved)),
            );
            Navigator.of(context).pop(true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.errorOccurred)),
            );
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? l10n.editCocktail : l10n.createCocktail),
        backgroundColor: colors.background,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCocktail,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.saveCocktail),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          children: [
            // 이미지 섹션
            _buildImageSection(l10n, colors),
            const SizedBox(height: AppTheme.spacingLg),

            // 기본 정보
            _buildBasicInfoSection(l10n, colors),
            const SizedBox(height: AppTheme.spacingLg),

            // 재료 섹션
            _buildIngredientsSection(l10n, colors),
            const SizedBox(height: AppTheme.spacingLg),

            // 만드는 방법
            _buildInstructionsSection(l10n, colors),
            const SizedBox(height: AppTheme.spacingLg),

            // 추가 정보
            _buildAdditionalInfoSection(l10n, colors),
            const SizedBox(height: 100), // FAB 공간
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(AppLocalizations l10n, AppColorsExtension colors) {
    return GestureDetector(
      onTap: _showImagePicker,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: colors.divider,
            width: 1,
          ),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : _existingImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                    child: Image.network(
                      _existingImageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 48,
                        color: colors.textSecondary,
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        l10n.addPhoto,
                        style: TextStyle(color: colors.textSecondary),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildBasicInfoSection(AppLocalizations l10n, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.cocktailName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: l10n.cocktailNameHint,
            border: const OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.cocktailNameRequired;
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacingMd),
        Text(
          l10n.cocktailDescription,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            hintText: l10n.cocktailDescriptionHint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildIngredientsSection(AppLocalizations l10n, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.ingredients,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            TextButton.icon(
              onPressed: _addIngredient,
              icon: const Icon(Icons.add),
              label: Text(l10n.addIngredient),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        ..._ingredients.asMap().entries.map((entry) {
          final index = entry.key;
          final ingredient = entry.value;
          return _IngredientRow(
            key: ValueKey(index),
            ingredient: ingredient,
            onRemove: () => _removeIngredient(index),
            onChanged: (updated) {
              setState(() {
                _ingredients[index] = updated;
              });
            },
          );
        }),
        if (_ingredients.isEmpty)
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: colors.divider),
            ),
            child: Center(
              child: Text(
                l10n.addIngredient,
                style: TextStyle(color: colors.textSecondary),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInstructionsSection(AppLocalizations l10n, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.cocktailInstructions,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        TextFormField(
          controller: _instructionsController,
          decoration: InputDecoration(
            hintText: l10n.cocktailInstructionsHint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 5,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.cocktailInstructionsRequired;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAdditionalInfoSection(AppLocalizations l10n, AppColorsExtension colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 글라스
        Text(
          l10n.glass,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        DropdownButtonFormField<String>(
          value: _selectedGlass,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          hint: Text(l10n.selectIngredient),
          items: _glassOptions
              .map((glass) => DropdownMenuItem(
                    value: glass,
                    child: Text(glass),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedGlass = value;
            });
          },
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // 기법
        Text(
          l10n.method,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        DropdownButtonFormField<String>(
          value: _selectedMethod,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          hint: Text(l10n.selectIngredient),
          items: _methodOptions
              .map((method) => DropdownMenuItem(
                    value: method,
                    child: Text(method),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedMethod = value;
            });
          },
        ),
        const SizedBox(height: AppTheme.spacingMd),

        // 가니쉬
        Text(
          l10n.garnish,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        TextFormField(
          controller: _garnishController,
          decoration: InputDecoration(
            hintText: l10n.garnish,
            border: const OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

// 재료 입력 행
class _IngredientEntry {
  String? ingredientId;
  String? customName;
  String amount;
  String units;
  bool isOptional;

  _IngredientEntry({
    this.ingredientId,
    this.customName,
    this.amount = '',
    this.units = '',
    this.isOptional = false,
  });
}

class _IngredientRow extends StatelessWidget {
  final _IngredientEntry ingredient;
  final VoidCallback onRemove;
  final ValueChanged<_IngredientEntry> onChanged;

  const _IngredientRow({
    super.key,
    required this.ingredient,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingSm),
        child: Column(
          children: [
            Row(
              children: [
                // 재료 이름
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    initialValue: ingredient.customName ?? ingredient.ingredientId,
                    decoration: InputDecoration(
                      labelText: l10n.ingredientName,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      onChanged(_IngredientEntry(
                        customName: value.isNotEmpty ? value : null,
                        amount: ingredient.amount,
                        units: ingredient.units,
                        isOptional: ingredient.isOptional,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // 양
                Expanded(
                  child: TextFormField(
                    initialValue: ingredient.amount,
                    decoration: InputDecoration(
                      labelText: l10n.ingredientAmount,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      onChanged(_IngredientEntry(
                        ingredientId: ingredient.ingredientId,
                        customName: ingredient.customName,
                        amount: value,
                        units: ingredient.units,
                        isOptional: ingredient.isOptional,
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // 단위
                Expanded(
                  child: TextFormField(
                    initialValue: ingredient.units,
                    decoration: InputDecoration(
                      labelText: l10n.ingredientUnit,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      onChanged(_IngredientEntry(
                        ingredientId: ingredient.ingredientId,
                        customName: ingredient.customName,
                        amount: ingredient.amount,
                        units: value,
                        isOptional: ingredient.isOptional,
                      ));
                    },
                  ),
                ),
                // 삭제 버튼
                IconButton(
                  icon: Icon(Icons.remove_circle, color: colors.textSecondary),
                  onPressed: onRemove,
                ),
              ],
            ),
            // 옵션 체크박스
            Row(
              children: [
                Checkbox(
                  value: ingredient.isOptional,
                  onChanged: (value) {
                    onChanged(_IngredientEntry(
                      ingredientId: ingredient.ingredientId,
                      customName: ingredient.customName,
                      amount: ingredient.amount,
                      units: ingredient.units,
                      isOptional: value ?? false,
                    ));
                  },
                ),
                Text(l10n.optional),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

enum ImageSource { gallery, camera }
