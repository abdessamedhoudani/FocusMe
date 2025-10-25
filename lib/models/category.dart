import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final Color color;
  final String? description;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Category({
    required this.id,
    required this.name,
    required this.color,
    this.description,
    required this.createdAt,
    this.updatedAt,
  });

  // Créer une nouvelle catégorie
  factory Category.create({
    required String name,
    required Color color,
    String? description,
  }) {
    return Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      color: color,
      description: description,
      createdAt: DateTime.now(),
    );
  }

  // Copier avec modifications
  Category copyWith({
    String? id,
    String? name,
    Color? color,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convertir en Map pour la base de données
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color.value,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Créer depuis Map (base de données)
  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      color: Color(map['color'] as int),
      description: map['description'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, color: $color)';
  }
}
