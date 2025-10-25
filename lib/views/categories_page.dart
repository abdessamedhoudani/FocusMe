import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../services/category_service.dart';
import '../services/translation_service.dart';
import '../services/language_service.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final categories = await _categoryService.getAllCategories();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.getTranslation(context, 'categories')),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showAddCategoryDialog,
            icon: const Icon(Icons.add),
            tooltip: TranslationService.getTranslation(context, 'addCategory'),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              TranslationService.getTranslation(context, 'error'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCategories,
              child: Text(TranslationService.getTranslation(context, 'retry')),
            ),
          ],
        ),
      );
    }

    if (_categories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              TranslationService.getTranslation(context, 'noCategories'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              TranslationService.getTranslation(context, 'noCategoriesMessage'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddCategoryDialog,
              icon: const Icon(Icons.add),
              label: Text(TranslationService.getTranslation(context, 'addFirstCategory')),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(Category category) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: category.color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: category.color,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.category,
            color: category.color,
            size: 20,
          ),
        ),
        title: Text(
          category.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: category.description != null && category.description!.isNotEmpty
            ? Text(
                category.description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              )
            : null,
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleCategoryAction(value, category),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(TranslationService.getTranslation(context, 'edit')),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: colorScheme.error),
                  const SizedBox(width: 8),
                  Text(TranslationService.getTranslation(context, 'delete')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleCategoryAction(String action, Category category) {
    switch (action) {
      case 'edit':
        _showEditCategoryDialog(category);
        break;
      case 'delete':
        _showDeleteCategoryDialog(category);
        break;
    }
  }

  void _showAddCategoryDialog() {
    _showCategoryDialog();
  }

  void _showEditCategoryDialog(Category category) {
    _showCategoryDialog(category: category);
  }

  void _showCategoryDialog({Category? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(text: category?.description ?? '');
    Color selectedColor = category?.color ?? CategoryService.predefinedColors.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            isEditing
                ? TranslationService.getTranslation(context, 'editCategory')
                : TranslationService.getTranslation(context, 'addCategory'),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom de la catégorie
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: TranslationService.getTranslation(context, 'categoryName'),
                    hintText: TranslationService.getTranslation(context, 'categoryNameHint'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLength: 50,
                ),
                const SizedBox(height: 16),
                
                // Description
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: TranslationService.getTranslation(context, 'categoryDescription'),
                    hintText: TranslationService.getTranslation(context, 'categoryDescriptionHint'),
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  maxLength: 200,
                ),
                const SizedBox(height: 16),
                
                // Sélection de couleur
                Text(
                  TranslationService.getTranslation(context, 'categoryColor'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CategoryService.predefinedColors.map((color) {
                    final isSelected = color == selectedColor;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.transparent,
                            width: 3,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(TranslationService.getTranslation(context, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () => _saveCategory(
                nameController.text.trim(),
                descriptionController.text.trim(),
                selectedColor,
                category,
              ),
              child: Text(
                isEditing
                    ? TranslationService.getTranslation(context, 'save')
                    : TranslationService.getTranslation(context, 'add'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCategory(String name, String description, Color color, Category? existingCategory) async {
    // Obtenir la langue actuelle
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final currentLanguage = languageService.currentLocale.languageCode;
    
    // Valider le nom avec la langue actuelle
    final validationError = await _categoryService.validateCategoryName(
      name, 
      excludeId: existingCategory?.id,
      language: currentLanguage,
    );
    
    if (validationError != null) {
      _showErrorSnackBar(validationError);
      return;
    }

    try {
      if (existingCategory != null) {
        // Modifier la catégorie existante
        final updatedCategory = existingCategory.copyWith(
          name: name,
          description: description.isEmpty ? null : description,
          color: color,
        );
        
        final success = await _categoryService.updateCategory(updatedCategory);
        if (success) {
          Navigator.of(context).pop();
          _loadCategories();
          _showSuccessSnackBar(TranslationService.getTranslation(context, 'categoryUpdated'));
        } else {
          _showErrorSnackBar(TranslationService.getTranslation(context, 'categoryUpdateFailed'));
        }
      } else {
        // Créer une nouvelle catégorie
        await _categoryService.createCategory(
          name: name,
          color: color,
          description: description.isEmpty ? null : description,
        );
        
        Navigator.of(context).pop();
        _loadCategories();
        _showSuccessSnackBar(TranslationService.getTranslation(context, 'categoryCreated'));
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _showDeleteCategoryDialog(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.getTranslation(context, 'deleteCategory')),
        content: Text(
          TranslationService.getTranslation(context, 'deleteCategoryMessage')
              .replaceAll('{name}', category.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.getTranslation(context, 'cancel')),
          ),
          ElevatedButton(
            onPressed: () => _deleteCategory(category),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(TranslationService.getTranslation(context, 'delete')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    try {
      final success = await _categoryService.deleteCategory(category.id);
      if (success) {
        Navigator.of(context).pop();
        _loadCategories();
        _showSuccessSnackBar(TranslationService.getTranslation(context, 'categoryDeleted'));
      } else {
        _showErrorSnackBar(TranslationService.getTranslation(context, 'categoryDeleteFailed'));
      }
    } catch (e) {
      _showErrorSnackBar(e.toString());
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
