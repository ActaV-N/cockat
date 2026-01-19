import 'package:flutter/foundation.dart';

/// A specific product/bottle that maps to an ingredient type
@immutable
class Product {
  final String id;
  final String name;
  final String? brand;
  final String? ingredientId; // Maps to ingredient type

  // Product info
  final String? description;
  final String? country;
  final int? volumeMl;
  final double? abv;

  // Images
  final String? imageUrl;
  final String? thumbnailUrl;

  // Metadata
  final String? barcode;
  final String? externalId;
  final String dataSource;

  const Product({
    required this.id,
    required this.name,
    this.brand,
    this.ingredientId,
    this.description,
    this.country,
    this.volumeMl,
    this.abv,
    this.imageUrl,
    this.thumbnailUrl,
    this.barcode,
    this.externalId,
    this.dataSource = 'manual',
  });

  factory Product.fromSupabase(Map<String, dynamic> row) {
    return Product(
      id: row['id'] as String,
      name: row['name'] as String,
      brand: row['brand'] as String?,
      ingredientId: row['ingredient_id'] as String?,
      description: row['description'] as String?,
      country: row['country'] as String?,
      volumeMl: row['volume_ml'] as int?,
      abv: (row['abv'] as num?)?.toDouble(),
      imageUrl: row['image_url'] as String?,
      thumbnailUrl: row['thumbnail_url'] as String?,
      barcode: row['barcode'] as String?,
      externalId: row['external_id'] as String?,
      dataSource: row['data_source'] as String? ?? 'manual',
    );
  }

  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'ingredient_id': ingredientId,
      'description': description,
      'country': country,
      'volume_ml': volumeMl,
      'abv': abv,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'barcode': barcode,
      'external_id': externalId,
      'data_source': dataSource,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    String? brand,
    String? ingredientId,
    String? description,
    String? country,
    int? volumeMl,
    double? abv,
    String? imageUrl,
    String? thumbnailUrl,
    String? barcode,
    String? externalId,
    String? dataSource,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      ingredientId: ingredientId ?? this.ingredientId,
      description: description ?? this.description,
      country: country ?? this.country,
      volumeMl: volumeMl ?? this.volumeMl,
      abv: abv ?? this.abv,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      barcode: barcode ?? this.barcode,
      externalId: externalId ?? this.externalId,
      dataSource: dataSource ?? this.dataSource,
    );
  }

  /// Display name with brand
  String get displayName {
    if (brand != null && !name.toLowerCase().startsWith(brand!.toLowerCase())) {
      return '$brand $name';
    }
    return name;
  }

  /// Formatted volume
  String? get formattedVolume {
    if (volumeMl == null) return null;
    if (volumeMl! >= 1000) {
      return '${(volumeMl! / 1000).toStringAsFixed(1)}L';
    }
    return '${volumeMl}ml';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
