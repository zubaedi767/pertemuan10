import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import '../model/Product.dart';

class ApiService {
  static const String baseUrl = 'http://10.19.75.224/rest-api/public/api';
  static const String storageUrl = 'http://10.19.75.224/rest-api/public/storage';

  // ✅ FIXED: getImageUrl
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';

    // Membersihkan Path
    String cleanPath = imagePath;

    // Hapus 'public/' jika ada
    if (cleanPath.startsWith('public/')) {
      cleanPath = cleanPath.substring(7);
    }

    // Hapus 'products/' berlebih (jika ada double)
    while (cleanPath.contains('products/products/')) {
      cleanPath = cleanPath.replaceAll('products/products/', 'products/');
    }

    // Pastikan path tidak memiliki double slash
    cleanPath = cleanPath.replaceAll('//', '/');

    // Jika path dimulai dengan '/', hapus
    if (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }

    // Jika path tidak dimulai dengan 'products/', tambahkan
    if (!cleanPath.startsWith('products/')) {
      cleanPath = 'products/$cleanPath';
    }

    final String finalUrl = '$storageUrl/$cleanPath';

    print('🖼️ Image URL Debug:');
    print('  Original: $imagePath');
    print('  Cleaned: $cleanPath');
    print('  Final URL: $finalUrl');

    return finalUrl;
  }

  // ✅ FIXED: GET PRODUCTS
  static Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('📦 Get Products - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        
        // Handle response format yang berbeda
        if (decoded is List) {
          print('  Response adalah List dengan ${decoded.length} item');
          return decoded.map((json) => Product.fromJson(json)).toList();
        } 
        else if (decoded is Map<String, dynamic>) {
          print('  Response adalah Map dengan keys: ${decoded.keys}');

          // Cek berbagai kemungkinan wrapper
          if (decoded.containsKey('data') && decoded['data'] is List) {
            return (decoded['data'] as List)
                .map((json) => Product.fromJson(json))
                .toList();
          }
          else if (decoded.containsKey('products') && decoded['products'] is List) {
            return (decoded['products'] as List)
                .map((json) => Product.fromJson(json))
                .toList();
          }
          else if (decoded.containsKey('result') && decoded['result'] is List) {
            return (decoded['result'] as List)
                .map((json) => Product.fromJson(json))
                .toList();
          }
          else {
            // Jika hanya object tunggal, bungkus dalam list
            print('  Response adalah object tunggal, membungkus ke dalam list');
            return [Product.fromJson(decoded)];
          }
        }
        else {
          throw Exception('Format response tidak dikenali: ${decoded.runtimeType}');
        }
      } 
      else if (response.statusCode == 404) {
        throw Exception('Endpoint tidak ditemukan: $baseUrl/products');
      } 
      else {
        throw Exception('Gagal memuat produk: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getProducts: $e');
      return [];
    }
  }

  // ✅ FIXED: GET PRODUCT BY ID
  static Future<Product> getProductById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('🔍 Get Product By ID - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        if (decoded is Map<String, dynamic>) {
          // Cek apakah ada wrapper 'data'
          if (decoded.containsKey('data') && decoded['data'] is Map) {
            return Product.fromJson(decoded['data']);
          }
          // Cek apakah ada wrapper 'product'
          else if (decoded.containsKey('product') && decoded['product'] is Map) {
            return Product.fromJson(decoded['product']);
          }
          return Product.fromJson(decoded);
        } else {
          throw Exception('Format response tidak dikenali');
        }
      } else if (response.statusCode == 404) {
        throw Exception('Produk tidak ditemukan');
      } else {
        throw Exception('Gagal memuat produk: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error getProductById: $e');
      throw Exception('Error: $e');
    }
  }

  // ✅ FIXED: REDUCE STOCK
  static Future<Product> reduceStock(int productId, int quantity) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/products/$productId/reduce-stock'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'quantity': quantity}),
      ).timeout(const Duration(seconds: 30));

      print('📉 Reduce Stock - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') && decoded['data'] is Map) {
            return Product.fromJson(decoded['data']);
          }
          return Product.fromJson(decoded);
        }
        throw Exception('Format response tidak dikenali');
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Stok tidak mencukupi');
      } else {
        throw Exception('Gagal mengurangi stok: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error reduceStock: $e');
      throw Exception('Error: $e');
    }
  }

  // ✅ FIXED: DELETE PRODUCT
  static Future<void> deleteProduct(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      print('🗑️ Delete Product - Status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Gagal menghapus produk: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleteProduct: $e');
      throw Exception('Error: $e');
    }
  }

  // ✅ FIXED: CREATE PRODUCT
  static Future<Product> createProduct({
    required String name,
    required String descriptions,
    required int price,
    required int stock,
    Uint8List? imageBytes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'descriptions': descriptions,
          'price': price,
          'stock': stock,
        }),
      ).timeout(const Duration(seconds: 30));

      print('➕ Create Product - Status: ${response.statusCode}');
      print('  Response: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          Product product;
          if (decoded.containsKey('data') && decoded['data'] is Map) {
            product = Product.fromJson(decoded['data']);
          } else {
            product = Product.fromJson(decoded);
          }

          // Jika ada image, upload setelah produk dibuat
          if (imageBytes != null && imageBytes.isNotEmpty) {
            try {
              await uploadImage(product.id!, imageBytes);
              // Refresh product untuk mendapatkan image URL terbaru
              return await getProductById(product.id!);
            } catch (e) {
              print('⚠️ Image upload failed but product created: $e');
              return product;
            }
          }
          return product;
        }
        throw Exception('Format response tidak dikenali');
      } else {
        try {
          final error = json.decode(response.body);
          throw Exception(error['message'] ?? 'Gagal membuat produk');
        } catch (e) {
          throw Exception('Gagal membuat produk: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ Error createProduct: $e');
      throw Exception('Error: $e');
    }
  }

  // ✅ FIXED: UPDATE PRODUCT
  static Future<Product> updateProduct({
    required int id,
    String? name,
    String? descriptions,
    int? price,
    int? stock,
    Uint8List? imageBytes,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/products/$id'),
      );

      // Tambahkan _method untuk PUT
      request.fields['_method'] = 'PUT';

      // Tambahkan field hanya jika ada
      if (name != null && name.isNotEmpty) {
        request.fields['name'] = name;
      }
      if (descriptions != null && descriptions.isNotEmpty) {
        request.fields['descriptions'] = descriptions;
      }
      if (price != null) {
        request.fields['price'] = price.toString();
      }
      if (stock != null) {
        request.fields['stock'] = stock.toString();
      }

      // Tambahkan image jika ada
      if (imageBytes != null && imageBytes.isNotEmpty) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('✏️ Update Product - Status: ${response.statusCode}');
      print('  Response: $responseBody');

      if (response.statusCode == 200) {
        final decoded = json.decode(responseBody);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') && decoded['data'] is Map) {
            return Product.fromJson(decoded['data']);
          }
          return Product.fromJson(decoded);
        }
        throw Exception('Format response tidak dikenali');
      } else {
        try {
          final error = json.decode(responseBody);
          throw Exception(error['message'] ?? 'Gagal update produk');
        } catch (e) {
          throw Exception('Gagal update produk: ${response.statusCode}');
        }
      }
    } catch (e) {
      print('❌ Error updateProduct: $e');
      throw Exception('Error: $e');
    }
  }

  // ✅ FIXED: UPLOAD IMAGE
  static Future<String> uploadImage(int productId, Uint8List imageBytes) async {
    try {
      print('📤 Upload Image - Product ID: $productId');
      print('  File size: ${imageBytes.length} bytes (${(imageBytes.length / 1024).toStringAsFixed(2)} KB)');

      if (imageBytes.length > 2 * 1024 * 1024) {
        throw Exception('File terlalu besar (max 2MB)');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/products/$productId/upload-image'),
      );

      request.headers['Accept'] = 'application/json';

      // Add image file
      var multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('  Response Status: ${response.statusCode}');
      print('  Response Body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = json.decode(responseBody);
        if (decoded.containsKey('image_url')) {
          return decoded['image_url'];
        } else if (decoded.containsKey('data') && decoded['data'] is Map) {
          return decoded['data']['image_url'] ?? '';
        } else if (decoded.containsKey('url')) {
          return decoded['url'];
        }
        return '';
      } else {
        throw Exception('Upload gagal: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error uploadImage: $e');
      throw Exception('Gagal upload gambar: $e');
    }
  }

  // ✅ FIXED: UPLOAD IMAGE FROM FILE (Convenience method)
  static Future<String> uploadImageFromFile(int productId, File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('File tidak ditemukan');
      }

      final bytes = await imageFile.readAsBytes();
      return await uploadImage(productId, bytes);
    } catch (e) {
      print('❌ Error uploadImageFromFile: $e');
      throw Exception('Gagal upload gambar: $e');
    }
  }

  // ✅ DEBUG: Test API Response
  static Future<void> testApiResponse() async {
    try {
      print('🔬 Testing API Response...');
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
      ).timeout(const Duration(seconds: 10));

      print('  Status Code: ${response.statusCode}');
      print('  Response Type: ${response.runtimeType}');

      final decoded = json.decode(response.body);
      print('  Decoded Type: ${decoded.runtimeType}');

      if (decoded is List) {
        print('  ✅ Response adalah List dengan ${decoded.length} item');
        if (decoded.isNotEmpty) {
          print('  Sample item: ${decoded[0]}');
        }
      } else if (decoded is Map) {
        print('  ✅ Response adalah Map dengan keys: ${decoded.keys}');
        if (decoded.containsKey('data')) {
          print('  Key "data" ditemukan dengan tipe: ${decoded['data'].runtimeType}');
          if (decoded['data'] is List) {
            print('  Data adalah List dengan ${(decoded['data'] as List).length} item');
          }
        }
        if (decoded.containsKey('products')) {
          print('  Key "products" ditemukan dengan tipe: ${decoded['products'].runtimeType}');
          if (decoded['products'] is List) {
            print('  Products adalah List dengan ${(decoded['products'] as List).length} item');
          }
        }
        if (decoded.containsKey('result')) {
          print('  Key "result" ditemukan dengan tipe: ${decoded['result'].runtimeType}');
          if (decoded['result'] is List) {
            print('  Result adalah List dengan ${(decoded['result'] as List).length} item');
          }
        }
      }
      print('📝 Full Response: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');
    } catch (e) {
      print('❌ Error testing API: $e');
    }
  }
}