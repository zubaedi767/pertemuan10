// lib/screens/add_product_screen.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pertemuan_9service/api_service.dart';
import 'package:flutter_application_1/model/Product.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  File? imageFile;
  Uint8List? _webImageBytes;
  bool _isLoading = false;
  bool _isImageChanged = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.descriptions;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            imageFile = null;
            _isImageChanged = true;
          });
        } else {
          setState(() {
            imageFile = File(image.path);
            _webImageBytes = null;
            _isImageChanged = true;
          });
        }
        _showSnackBar('Gambar berhasil dipilih', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Gagal memilih gambar: $e', Colors.red);
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            imageFile = null;
            _isImageChanged = true;
          });
        } else {
          setState(() {
            imageFile = File(image.path);
            _webImageBytes = null;
            _isImageChanged = true;
          });
        }
        _showSnackBar('Foto berhasil diambil', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Gagal mengambil foto: $e', Colors.red);
    }
  }

  void _removeImage() {
    setState(() {
      imageFile = null;
      _webImageBytes = null;
      _isImageChanged = true;
    });
    _showSnackBar('Gambar dihapus', Colors.orange);
  }

  Widget _buildImagePreview() {
    // Gambar baru yang dipilih (Web)
    if (kIsWeb && _webImageBytes != null) {
      return Image.memory(
        _webImageBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Gambar baru yang dipilih (Mobile)
    if (imageFile != null) {
      return Image.file(
        imageFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    // Gambar lama dari server (saat edit)
    if (!_isImageChanged && widget.product?.imageUrl != null && widget.product!.imageUrl!.isNotEmpty) {
      return Image.network(
        widget.product!.imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 50, color: Colors.grey),
              SizedBox(height: 8),
              Text('Gagal memuat gambar', style: TextStyle(color: Colors.grey)),
            ],
          );
        },
      );
    }

    // Placeholder jika tidak ada gambar
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey[600]),
        const SizedBox(height: 8),
        Text(
          'Tap untuk pilih gambar',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          'Format: JPG, PNG',
          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
        ),
      ],
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (imageFile != null || _webImageBytes != null || 
                (widget.product?.imageUrl != null && widget.product!.imageUrl!.isNotEmpty))
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus Gambar', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final int price = int.parse(_priceController.text);
      final int stock = int.parse(_stockController.text);
      final String name = _nameController.text.trim();
      final String descriptions = _descriptionController.text.trim().isEmpty
          ? ''
          : _descriptionController.text.trim();

      if (widget.product == null) {
        // CREATE NEW PRODUCT
        final newProduct = await ApiService.createProduct(
          name: name,
          descriptions: descriptions,
          price: price,
          stock: stock,
        );

        // Upload image jika ada
        if (_webImageBytes != null && kIsWeb) {
          await ApiService.uploadImage(newProduct.id!, _webImageBytes!);
        } else if (imageFile != null && !kIsWeb) {
          await ApiService.uploadImageFromFile(newProduct.id!, imageFile!);
        }

        if (mounted) {
          _showSnackBar('Produk berhasil ditambahkan', Colors.green);
          Navigator.pop(context, true);
        }
      } else {
        // UPDATE EXISTING PRODUCT
        Uint8List? imageBytes;
        
        // Prepare image data based on platform
        if (kIsWeb && _isImageChanged && _webImageBytes != null) {
          imageBytes = _webImageBytes;
        } else if (!kIsWeb && _isImageChanged && imageFile != null) {
          imageBytes = await imageFile!.readAsBytes();
        }

        await apiservice.updateProduct(
          id: widget.product!.id,
          name: name,
          descriptions: descriptions,
          price: price,
          stock: stock,
          imageBytes: imageBytes,
        );

        if (mounted) {
          _showSnackBar('Produk berhasil diperbarui', Colors.green);
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      _showSnackBar('Gagal menyimpan produk: $e', Colors.red);
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
    final isEdit = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Image Picker Area
                    Center(
                      child: GestureDetector(
                        onTap: _showImagePickerDialog,
                        child: Container(
                          height: 170,
                          width: 170,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[400]!,
                              width: 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            children: [
                              _buildImagePreview(),
                              // Hapus icon close karena sudah ada di dialog
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Tap untuk mengubah gambar',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Produk *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label),
                        hintText: 'Contoh: Baju Batik Modern',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama produk tidak boleh kosong';
                        }
                        if (value.trim().length < 3) {
                          return 'Nama produk minimal 3 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description Field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        hintText: 'Deskripsi produk (opsional)',
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      maxLength: 500,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                        return Text(
                          '$currentLength/$maxLength',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Price Field
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Harga *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        prefixText: 'Rp ',
                        hintText: 'Contoh: 50000',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harga tidak boleh kosong';
                        }
                        final price = int.tryParse(value);
                        if (price == null) {
                          return 'Masukkan angka yang valid';
                        }
                        if (price < 0) {
                          return 'Harga tidak boleh negatif';
                        }
                        if (price == 0) {
                          return 'Harga tidak boleh 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Stock Field
                    TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stok *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory),
                        hintText: 'Contoh: 10',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Stok tidak boleh kosong';
                        }
                        final stock = int.tryParse(value);
                        if (stock == null) {
                          return 'Masukkan angka yang valid';
                        }
                        if (stock < 0) {
                          return 'Stok tidak boleh negatif';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Save/Update Button
                    ElevatedButton(
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      child: Text(
                        isEdit ? 'Perbarui Produk' : 'Simpan Produk',
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}