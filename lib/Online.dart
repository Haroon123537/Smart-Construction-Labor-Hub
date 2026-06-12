import 'package:flutter/material.dart';
import 'payment_method.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class OnlinePurchasingPage extends StatefulWidget {
  @override
  _OnlinePurchasingPageState createState() => _OnlinePurchasingPageState();
}

class _OnlinePurchasingPageState extends State<OnlinePurchasingPage> {
  String searchQuery = '';
  String selectedCategory = 'All';
  String selectedLocation = 'All';
  List<Map<String, dynamic>> cart = [];
  List<Map<String, dynamic>> materials = [];


  final DatabaseReference materialsRef =
  FirebaseDatabase.instance.ref("material_prices");

  @override
  @override
  void initState() {
    super.initState();

    materialsRef.onValue.listen((event) {
      final raw = event.snapshot.value;
      if (raw == null || raw is! Map) return;

      List<Map<String, dynamic>> temp = [];

      (raw as Map).forEach((categoryName, categoryItems) {
        if (categoryItems is! Map) return;
        (categoryItems as Map).forEach((materialKey, materialData) {
          Map<String, dynamic> mat = {};

          if (materialData is Map) {
            mat = Map<String, dynamic>.from(materialData);
          } else if (materialData is String) {
            mat = {'description': materialData};
          } else {
            return;
          }

          mat['name'] = mat['name'] ?? (materialData is Map ? materialData['name'] ?? materialKey : materialKey);
          // fallback to key
          mat['category'] = categoryName;
          mat['unit'] = mat['unit'] ?? '';
          mat['price'] =
              mat['price'] ?? mat['price_min'] ?? mat['price_max'] ?? 0;

          temp.add(mat);
        });
      });

      setState(() => materials = temp);
    });
  }

  double parsePrice(dynamic value) {
    if (value == null) return 0; // null fallback
    if (value is num) return value.toDouble(); // already number
    if (value is String) {
      // remove commas and parse
      return double.tryParse(value.replaceAll(',', '')) ?? 0;
    }
    return 0; // any other type fallback
  }

  double getMaterialPrice(Map<String, dynamic> material, {String? priceType}) {
    // For bricks, priceType can be: "per_brick", "per_1000", "per_3000"
    if (material['category'] == 'bricks') {
      switch (priceType) {
        case 'per_1000':
          return parsePrice(material['price_per_1000']);
        case 'per_3000':
          return parsePrice(material['price_per_3000']);
        case 'per_brick':
        default:
          return parsePrice(material['price_per_brick']);
      }
    }

    // fallback for other materials
    if (material.containsKey('price')) return parsePrice(material['price']);
    if (material.containsKey('price_min')) return parsePrice(material['price_min']);
    if (material.containsKey('price_max')) return parsePrice(material['price_max']);
    return 0;
  }





  double calculateTotal(Map<String, dynamic> material, int quantity, {String? priceType}) {
    double price = getMaterialPrice(material, priceType: priceType);
    return price * quantity;
  }


  double get totalAmount {
    double sum = 0;

    for (var item in cart) {
      sum += (item['total'] ?? 0);
    }

    return sum;
  }



  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: Text('Construction Marketplace', style: TextStyle(color: Colors.white,fontSize: 16, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(Icons.shopping_bag_outlined, color: Colors.white),
              onPressed: _showCart,
            )
          ],
        ),
        body: Column(
          children: [
            _buildFilters(),
            Expanded(child: _buildProductList()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Search material',
              labelStyle: TextStyle(color: Colors.white),
              filled: true,
              fillColor: Colors.white12,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              prefixIcon: Icon(Icons.search, color: Colors.white54),
            ),
            onChanged: (val) => setState(() => searchQuery = val),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildDropdown('Category', ['All', 'cement', 'steel', 'bricks', 'tiles'], selectedCategory, (val) => setState(() => selectedCategory = val!))),
              SizedBox(width: 15),
              Expanded(child: _buildDropdown('Location', ['All', 'Lahore', 'Karachi', 'Islamabad'], selectedLocation, (val) => setState(() => selectedLocation = val!,))),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String value, ValueChanged<String?> onChanged) {
    return Container(
      alignment: Alignment.centerLeft, // Force left alignment of the whole dropdown
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true, // Helps align everything nicely in LTR
        onChanged: onChanged,
        dropdownColor: Colors.grey[900],
        decoration: InputDecoration(
          alignLabelWithHint: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          labelText: label,
          labelStyle: TextStyle(color: Colors.white),
          filled: true,
          fillColor: Colors.white12,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        style: TextStyle(color: Colors.white),
        items: items.map((item) => DropdownMenuItem<String>(
          value: item,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(item),
          ),
        )).toList(),
      ),
    );
  }





  Widget _buildProductList() {
    var filtered = materials.where((material) {
      final name = (material['name'] ?? '').toString().toLowerCase();
      final category = (material['category'] ?? '').toString().toLowerCase();
      final location = (material['location'] ?? '').toString().toLowerCase();
      return name.contains(searchQuery.toLowerCase()) &&
          (selectedCategory.toLowerCase() == 'all' ||
              category == selectedCategory.toLowerCase()) &&
          (selectedLocation.toLowerCase() == 'all' ||
              location == selectedLocation.toLowerCase());

    }).toList();

    return ListView.builder(
      padding: EdgeInsets.all(10),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildMaterialCard(filtered[index]),
    );
  }

  Widget _buildMaterialCard(Map<String, dynamic> material) {
    int quantity = 1;
    TextEditingController qtyController = TextEditingController(text: quantity.toString());
    String selectedPriceType = 'per_brick'; // default price type

    double getPrice() {
      switch (selectedPriceType) {
        case 'per_1000':
          return (material['price_per_1000'] ?? 0) / 1000;
        case 'per_3000':
          return (material['price_per_3000'] ?? 0) / 3000;
        case 'per_brick':
        default:
          return material['price_per_brick']?.toDouble() ?? 0;
      }
    }

    return StatefulBuilder(
      builder: (context, setQty) {
        double price = getPrice();
        double total = price * quantity;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 10),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material['name'] ?? 'Unnamed',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    material['description'] ?? '',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 8),

                  // If this is a brick, show the price type dropdown
                  if (material['category'] == 'bricks') ...[
                    DropdownButton<String>(
                      value: selectedPriceType,
                      items: [
                        DropdownMenuItem(value: 'per_brick', child: Text("Per Piece")),
                        DropdownMenuItem(value: 'per_1000', child: Text("Per 1000")),
                        DropdownMenuItem(value: 'per_3000', child: Text("Per 3000")),
                      ],
                      onChanged: (val) {
                        setQty(() => selectedPriceType = val!);
                      },
                    ),
                  ],

                  Text(
                    'PKR ${price.toStringAsFixed(0)} per ${selectedPriceType.replaceAll('_', ' ')}',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 80,
                        child: TextField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white12,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) {
                            int newQty = int.tryParse(val) ?? 1;
                            setQty(() => quantity = newQty);
                          },
                        ),
                      ),
                      Text(
                        "Total: PKR ${total.toStringAsFixed(0)}",
                        style: TextStyle(color: Colors.white70),
                      ),
                      ElevatedButton.icon(
                        icon: Icon(Icons.add_shopping_cart),
                        label: Text("Add"),
                        onPressed: () => _addToCart(material, quantity),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _addToCart(Map<String, dynamic> material, int quantity, {String? priceType})
  {
    final item = {
      'name': material['name'] ?? 'Unnamed',
      'price': getMaterialPrice(material, priceType: priceType),
      'quantity': quantity,
      'total': calculateTotal(material, quantity, priceType: priceType), };
    setState(() => cart.add(item)); }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Your Cart", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ...cart.map((item) => ListTile(
              title: Text(item['name'], style: TextStyle(color: Colors.white)),
              subtitle: Text("Qty: ${item['quantity']} • PKR ${item['total']}", style: TextStyle(color: Colors.white54)),
              trailing: IconButton(
                icon: Icon(Icons.remove_shopping_cart, color: Colors.redAccent),
                onPressed: () {
                  setState(() => cart.remove(item));
                  Navigator.pop(context);
                  _showCart();
                },
              ),
            )),
            SizedBox(height: 10),
            ElevatedButton(
              child: Text("Checkout (Manual)"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentMethod(),
                  ),
                ).then((_) {
                  setState(() => cart.clear()); // clear cart after return (optional)
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
