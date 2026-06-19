// lib/screens/product_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/model/Product.dart';
import 'package:flutter_application_1/produk/add_product.dart';
import 'package:flutter_application_1/produk/detail_product.dart';
import 'package:package:intl/intl.dart';
import 'package:flutter_application_1/service/api_service.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> _products = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final products = await ApiService.getProducts(); // Ganti ke getProducts
      setState(() {
        _products = products;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isRefreshing = true;
    });
    await _fetchProducts();
  }

  Future<void> _deleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ), // TextButton
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ), // TextButton
        ],
      ), // AlertDialog
    );

    if (confirm == true) {
      if (confirm == true) {
      // Tampilkan loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ), // SizedBox
              SizedBox(width: 12),
              Text("Menghapus produk..."),
            ],
          ), // Row
          duration: Duration(seconds: 2),
        ), // SnackBar
      );

      try {
        await ApiService.deleteProduct(product.id);

        // Hapus dari list lokal
        setState(() {
          _products.removeWhere((p) => p.id == product.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Produk berhasil dihapus'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ), // SnackBar
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ), // SnackBar
          );
        }
      }
    }
  }

  String _formatPrice(int price) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(price);
  }

  Color _getStockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock < 10) return Colors.orange;
    return Colors.green;
  }

  String _getStockText(int stock) {
    if (stock <= 0) return 'Habis';
    if (stock < 10) return 'Terbatas';
    return 'Tersedia';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      title: const Text('Daftar Produk'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      actions: [
        // Tombol refresh
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _isLoading ? null : _fetchProducts,
          tooltip: 'Refresh',
        ), // IconButton
        // Tombol info total produk
        if (_products.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_products.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ), // Text
            ), // Center
          ), // Padding
      ],
    ), // AppBar
    body: _buildBody(),
    floatingActionButton: FloatingActionButton(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddProductScreen()),
        );
        if (result == true) {
          _fetchProducts();
        }
      },
      child: const Icon(Icons.add),
      tooltip: 'Tambah Produk',
    ), // FloatingActionButton
  ); // Scaffold
}

Widget _buildBody() {
  if (_isLoading) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Memuat daftar produk...'),
        ],
      ), // Column
    ); // Center
  }

  if (_errorMessage != null) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            'Terjadi Kesalahan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[700]),
          ), // Text
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ), // Text
          ), // Padding
          const SizedBox(height: 16),
          _buildProductImage(product),
        const SizedBox(width: 12),

        // Informasi produk
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ), // TextStyle
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ), // Text
              const SizedBox(height: 4),
              Text(
                _formatPrice(product.price),
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ), // TextStyle
              ), // Text
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ), // EdgeInsets.symmetric
                    decoration: BoxDecoration(
                      color: _getStockColor(product.stock).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ), // BoxDecoration
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory,
                          size: 14,
                          color: _getStockColor(product.stock),
                        ), // Icon
                        const SizedBox(width: 4),
                        Text(
                          '${_getStockText(product.stock)}: ${product.stock}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStockColor(product.stock),
                            fontWeight: FontWeight.w500,
                          ), // TextStyle
                        ), // Text
                      ],
                    ), // Row
                  ), // Container
                ],
              ), // Row
            ],
          ), // Column
        ), // Expanded

        // Tombol aksi
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddProductScreen(product: product),
            ), // MaterialPageRoute
          );
          if (result == true) {
            _fetchProducts();
          }
        },
        tooltip: 'Edit produk',
        constraints: const BoxConstraints(),
        padding: EdgeInsets.zero,
        splashRadius: 20,
      ), // IconButton
      const SizedBox(height: 4),
      IconButton(
        icon: const Icon(Icons.delete, color: Colors.red, size: 22),
        onPressed: () => _deleteProduct(product),
        tooltip: 'Hapus produk',
        constraints: const BoxConstraints(),
        padding: EdgeInsets.zero,
        splashRadius: 20,
      ), // IconButton
    ],
  ), // Column
],
          ), // Row
        ), // Padding
      ), // InkWell
    ), // Card
  );
}

Widget _buildProductImage(Product product) {
  // Cek apakah ada URL gambar
  if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: product.imageUrl!,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ), // BoxDecoration
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ), // SizedBox
          ), // Center
        ), // Container
        errorWidget: (context, url, error) => Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ), // BoxDecoration
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 30, color: Colors.grey[400]),
              const SizedBox(height: 4),
              Text(
                'Error',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ), // Text
            ],
          ), // Column
        ), // Container
      ), // CachedNetworkImage
    ); // ClipRRect
  }
  ); // ClipRRect
  } else {
    // Placeholder jika tidak ada gambar
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ), // BoxDecoration
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported, size: 35, color: Colors.grey[400]),
          const SizedBox(height: 4),
          Text(
            'No image',
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ), // Text
        ],
      ), // Column
    ); // Container
  }
}