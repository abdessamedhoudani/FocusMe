import 'package:flutter/material.dart';
import '../models/category.dart';
import 'db_service.dart';
import 'translation_service.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final DatabaseService _dbService = DatabaseService();

  // Couleurs prédéfinies pour les catégories
  static const List<Color> predefinedColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  // Créer une nouvelle catégorie
  Future<String> createCategory({
    required String name,
    required Color color,
    String? description,
  }) async {
    final category = Category.create(
      name: name,
      color: color,
      description: description,
    );
    
    return await _dbService.insertCategory(category);
  }

  // Obtenir toutes les catégories
  Future<List<Category>> getAllCategories() async {
    return await _dbService.getAllCategories();
  }

  // Obtenir une catégorie par ID
  Future<Category?> getCategoryById(String id) async {
    return await _dbService.getCategoryById(id);
  }

  // Mettre à jour une catégorie
  Future<bool> updateCategory(Category category) async {
    try {
      final result = await _dbService.updateCategory(category);
      return result > 0;
    } catch (e) {
      print('Erreur lors de la mise à jour de la catégorie: $e');
      return false;
    }
  }

  // Supprimer une catégorie
  Future<bool> deleteCategory(String id) async {
    try {
      final result = await _dbService.deleteCategory(id);
      return result > 0;
    } catch (e) {
      print('Erreur lors de la suppression de la catégorie: $e');
      return false;
    }
  }

  // Vérifier si une catégorie est utilisée
  Future<bool> isCategoryInUse(String categoryId) async {
    return await _dbService.isCategoryInUse(categoryId);
  }

  // Créer des catégories par défaut
  Future<void> createDefaultCategories({String language = 'fr'}) async {
    final existingCategories = await getAllCategories();
    if (existingCategories.isNotEmpty) return; // Déjà initialisées

    final defaultCategories = _getDefaultCategories(language);

    for (final categoryData in defaultCategories) {
      await createCategory(
        name: categoryData['name'] as String,
        color: categoryData['color'] as Color,
        description: categoryData['description'] as String,
      );
    }
  }

  // Obtenir les catégories par défaut selon la langue
  List<Map<String, dynamic>> _getDefaultCategories(String language) {
    switch (language) {
      case 'en':
        return [
          {'name': 'Work', 'color': Colors.blue, 'description': 'Professional tasks'},
          {'name': 'Personal', 'color': Colors.green, 'description': 'Personal tasks'},
          {'name': 'Health', 'color': Colors.red, 'description': 'Health-related tasks'},
          {'name': 'Sport', 'color': Colors.orange, 'description': 'Sports activities'},
          {'name': 'Study', 'color': Colors.purple, 'description': 'Learning tasks'},
        ];
      case 'ar':
        return [
          {'name': 'عمل', 'color': Colors.blue, 'description': 'مهام مهنية'},
          {'name': 'شخصي', 'color': Colors.green, 'description': 'مهام شخصية'},
          {'name': 'صحة', 'color': Colors.red, 'description': 'مهام متعلقة بالصحة'},
          {'name': 'رياضة', 'color': Colors.orange, 'description': 'أنشطة رياضية'},
          {'name': 'دراسة', 'color': Colors.purple, 'description': 'مهام تعليمية'},
        ];
      case 'fr':
      default:
        return [
          {'name': 'Travail', 'color': Colors.blue, 'description': 'Tâches professionnelles'},
          {'name': 'Personnel', 'color': Colors.green, 'description': 'Tâches personnelles'},
          {'name': 'Santé', 'color': Colors.red, 'description': 'Tâches liées à la santé'},
          {'name': 'Sport', 'color': Colors.orange, 'description': 'Activités sportives'},
          {'name': 'Études', 'color': Colors.purple, 'description': 'Tâches d\'apprentissage'},
        ];
    }
  }

  // Valider le nom d'une catégorie
  Future<String?> validateCategoryName(String name, {String? excludeId, String language = 'fr'}) async {
    if (name.trim().isEmpty) {
      return TranslationService.translate('categoryNameEmpty', language);
    }

    if (name.trim().length < 2) {
      return TranslationService.translate('categoryNameTooShort', language);
    }

    if (name.trim().length > 50) {
      return TranslationService.translate('categoryNameTooLong', language);
    }

    // Vérifier l'unicité du nom
    final categories = await getAllCategories();
    final existingCategory = categories.firstWhere(
      (cat) => cat.name.toLowerCase() == name.trim().toLowerCase() && cat.id != excludeId,
      orElse: () => Category.create(name: '', color: Colors.grey),
    );

    if (existingCategory.name.isNotEmpty) {
      return TranslationService.translate('categoryNameExists', language);
    }

    return null;
  }

  // Obtenir une couleur aléatoire pour une nouvelle catégorie
  Color getRandomColor() {
    final random = DateTime.now().millisecondsSinceEpoch % predefinedColors.length;
    return predefinedColors[random];
  }

  // Obtenir la couleur suivante dans la liste
  Color getNextColor(Color currentColor) {
    final currentIndex = predefinedColors.indexOf(currentColor);
    if (currentIndex == -1 || currentIndex == predefinedColors.length - 1) {
      return predefinedColors.first;
    }
    return predefinedColors[currentIndex + 1];
  }
}
