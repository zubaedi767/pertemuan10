// lib/model/Product.dart
import 'package:flutter/material.dart';
import 'package:flutter_application_1/service/api_service.dart';

class Product {
  final int id;
  final String name;
  final String descriptions;
  final int price;
  final int stock;
  final String? image;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.descriptions,
    required this.price,
    required this.stock,
    this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle berbagai format field name
    final String? imageValue = json['image'] ?? json['image_url'] ?? json['imageUrl'];
    
    return Product(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['product_name'] ?? '',
      descriptions: json['descriptions'] ?? json['description'] ?? json['desc'] ?? '',
      price: json['price'] ?? 0,
      stock: json['stock'] ?? 0,
      image: imageValue,
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'descriptions': descriptions,
      'price': price,
      'stock': stock,
      'image': image,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Getter untuk URL gambar
  String get imageUrl {
    if (image == null || image!.isEmpty) return '';
    return ApiService.getImageUrl(image);
  }

  // Getter untuk mengetahui apakah produk memiliki gambar
  bool get hasImage => image != null && image!.isNotEmpty;

  // Helper untuk format harga dengan format Indonesia
  String get formattedPrice {
    if (price <= 0) return 'Rp 0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  // Helper untuk format harga pendek (tanpa Rp)
  String get formattedPriceShort {
    if (price <= 0) return '0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    return formatter.format(price).trim();
  }

  // Helper untuk status stok
  String get stockStatus {
    if (stock <= 0) return 'Stok Habis';
    if (stock < 10) return 'Stok Terbatas: $stock';
    return 'Tersedia: $stock';
  }

  // Helper untuk warna status stok
  Color get stockColor {
    if (stock <= 0) return Colors.red;
    if (stock < 10) return Colors.orange;
    return Colors.green;
  }

  // Helper untuk ikon status stok
  IconData get stockIcon {
    if (stock <= 0) return Icons.inventory_2_outlined;
    if (stock < 10) return Icons.inventory;
    return Icons.check_circle_outline;
  }

  // Helper untuk status apakah stok tersedia
  bool get isInStock => stock > 0;

  // Helper untuk status apakah stok menipis
  bool get isLowStock => stock > 0 && stock < 10;

  // Helper untuk format deskripsi pendek
  String get shortDescription {
    if (descriptions.isEmpty) return '';
    if (descriptions.length <= 100) return descriptions;
    return '${descriptions.substring(0, 100)}...';
  }

  // Helper untuk membuat copy dengan data baru
  Product copyWith({
    int? id,
    String? name,
    String? descriptions,
    int? price,
    int? stock,
    String? image,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      descriptions: descriptions ?? this.descriptions,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      image: image ?? this.image,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Product(id: $id, name: $name, price: $price, stock: $stock, hasImage: $hasImage)';
  }
}

// Import tambahan untuk NumberFormat
import 'package:intl/intl.dart';