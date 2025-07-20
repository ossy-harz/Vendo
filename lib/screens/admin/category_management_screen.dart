import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/category_service.dart';
import '../../widgets/custom_button.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();
  String _selectedType = 'product';
  int _selectedOrder = 1;
  Category? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _nameController.clear();
      _iconController.clear();
      _selectedType = 'product';
      _selectedOrder = 1;
      _selectedCategory = null;
    });
  }

  void _editCategory(Category category) {
    setState(() {
      _selectedCategory = category;
      _nameController.text = category.name;
      _iconController.text = category.icon;
      _selectedType = category.type;
      _selectedOrder = category.order;
    });
  }

  Future<void> _saveCategory() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a category name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final categoryService = Provider.of<CategoryService>(context, listen: false);
      
      if (_selectedCategory == null) {
        // Create new category
        final category = Category(
          id: '',
          name: _nameController.text.trim(),
          icon: _iconController.text.trim(),
          type: _selectedType,
          order: _selectedOrder,
        );
        
        await categoryService.createCategory(category);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _resetForm();
        }
      } else {
        // Update existing category
        final category = Category(
          id: _selectedCategory!.id,
          name: _nameController.text.trim(),
          icon: _iconController.text.trim(),
          type: _selectedType,
          order: _selectedOrder,
        );
        
        await categoryService.updateCategory(category);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _resetForm();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving category: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCategory(String categoryId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure you want to delete this category? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final categoryService = Provider.of<CategoryService>(context, listen: false);
      await categoryService.deleteCategory(categoryId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting category: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Categories'),
            Tab(text: 'Add/Edit'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Categories list tab
          _buildCategoriesList(),
          
          // Add/Edit tab
          _buildAddEditForm(),
        ],
      ),
    );
  }

  Widget _buildCategoriesList() {
    return StreamBuilder<List<Category>>(
      stream: Provider.of<CategoryService>(context).getCategories(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        
        final categories = snapshot.data ?? [];
        
        if (categories.isEmpty) {
          return const Center(
            child: Text('No categories found'),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(_getIconData(category.icon)),
                title: Text(category.name),
                subtitle: Text('Type: ${category.type}, Order: ${category.order}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _editCategory(category);
                        _tabController.animateTo(1);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deleteCategory(category.id),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAddEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedCategory == null ? 'Add New Category' : 'Edit Category',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          // Name
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Category Name',
              hintText: 'Enter category name',
            ),
          ),
          const SizedBox(height: 16),
          
          // Icon
          TextFormField(
            controller: _iconController,
            decoration: const InputDecoration(
              labelText: 'Icon Name',
              hintText: 'Enter icon name (e.g., shopping_bag)',
            ),
          ),
          const SizedBox(height: 16),
          
          // Type
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Category Type',
            ),
            value: _selectedType,
            items: const [
              DropdownMenuItem(
                value: 'product',
                child: Text('Product'),
              ),
              DropdownMenuItem(
                value: 'service',
                child: Text('Service'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedType = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          
          // Order
          Row(
            children: [
              const Text('Display Order:'),
              const SizedBox(width: 16),
              Expanded(
                child: Slider(
                  value: _selectedOrder.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _selectedOrder.toString(),
                  onChanged: (value) {
                    setState(() {
                      _selectedOrder = value.toInt();
                    });
                  },
                ),
              ),
              Text(_selectedOrder.toString()),
            ],
          ),
          const SizedBox(height: 24),
          
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetForm,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: _selectedCategory == null ? 'Add Category' : 'Update Category',
                  isLoading: _isLoading,
                  onPressed: _saveCategory,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'devices':
        return Icons.devices;
      case 'chair':
        return Icons.chair;
      case 'checkroom':
        return Icons.checkroom;
      case 'handyman':
        return Icons.handyman;
      case 'directions_car':
        return Icons.directions_car;
      case 'yard':
        return Icons.yard;
      case 'cleaning_services':
        return Icons.cleaning_services;
      case 'school':
        return Icons.school;
      case 'spa':
        return Icons.spa;
      case 'local_taxi':
        return Icons.local_taxi;
      default:
        return Icons.category;
    }
  }
}

