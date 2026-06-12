import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'home_screen.dart';
import 'Help page.dart';
import 'package:smart_constuction_hub/splash_screen.dart';

class CostEstimationPage extends StatefulWidget {
  const CostEstimationPage({super.key});

  @override
  State<CostEstimationPage> createState() => _CostEstimationPageState();
}

class _CostEstimationPageState extends State<CostEstimationPage> {
  // ---------------- USER SELECTIONS ----------------
  int? selectedArea;
  int? selectedBedrooms;
  int? selectedLivingRooms;
  int? selectedWashrooms;
  int? selectedKitchens;
  String? selectedStorey;

  // ---------------- RESULT DATA ----------------
  double autoTotalCost = 0;
  bool showResult = false;

  // ---------------- ROOM VALIDATION (LDA PRACTICAL LIMITS) ----------------
  bool _validateRooms() {
    if (selectedArea == null) return true;

    int maxBedrooms = 1;
    int maxLiving = 1;
    int maxWashrooms = 1;
    int maxKitchens = 1;

    if (selectedArea! >= 4 && selectedArea! <= 5) {
      maxBedrooms = 2;
      maxWashrooms = 2;
    } else if (selectedArea! >= 6 && selectedArea! <= 10) {
      maxBedrooms = 4;
      maxLiving = 2;
      maxWashrooms = 4;
      maxKitchens = 2;
    } else if (selectedArea! >= 11) {
      maxBedrooms = 6;
      maxLiving = 3;
      maxWashrooms = 6;
      maxKitchens = 2;
    }

    if ((selectedBedrooms ?? 0) > maxBedrooms ||
        (selectedLivingRooms ?? 0) > maxLiving ||
        (selectedWashrooms ?? 0) > maxWashrooms ||
        (selectedKitchens ?? 0) > maxKitchens) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selected rooms exceed LDA planning limits for $selectedArea Marla',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    return true;
  }

  // ---------------- COST CALCULATION ----------------
  void _calculateCost({bool fromDropdown = false}) {
    if (!fromDropdown &&
        (selectedArea == null ||
            selectedBedrooms == null ||
            selectedLivingRooms == null ||
            selectedWashrooms == null ||
            selectedKitchens == null ||
            selectedStorey == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (selectedArea == null ||
        selectedBedrooms == null ||
        selectedLivingRooms == null ||
        selectedWashrooms == null ||
        selectedKitchens == null ||
        selectedStorey == null) {
      return;
    }

    if (!_validateRooms()) return;

    // 🔹 LDA Avenue Updated Price
    const double baseCostPerMarla = 4080000;

    autoTotalCost = selectedArea! * baseCostPerMarla;

    double storeyMultiplier = 1.0;
    if (selectedStorey == 'Double') storeyMultiplier = 1.35;
    if (selectedStorey == 'Triple') storeyMultiplier = 1.6;

    autoTotalCost *= storeyMultiplier;

    setState(() {
      showResult = true;
    });
  }

  // ---------------- SAVE BUDGET ----------------
  void _saveBudget() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Budget saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ---------------- EXPORT PDF ----------------
  Future<void> _exportPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'House Cost Estimation',
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Area Size: $selectedArea Marla'),
            pw.Text('Bedrooms: $selectedBedrooms'),
            pw.Text('Living Rooms: $selectedLivingRooms'),
            pw.Text('Washrooms: $selectedWashrooms'),
            pw.Text('Kitchens: $selectedKitchens'),
            pw.Text('Storey: $selectedStorey'),
            pw.Divider(),
            pw.Text(
              'Total Budget: PKR ${autoTotalCost.toStringAsFixed(0)}',
            ),
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF302F2F),
      appBar: AppBar(
        title: Text(
          "Labour Hiring",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: const Color(0xFFFFBC3A),
        actions: [
          IconButton(
            icon: const Icon(Icons.home, size: 25, color: Color(0xFF302F2F)),
            tooltip: "Home",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SplashScreen(nextPage: HomePage()),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.help, size: 25, color: Color(0xFF302F2F)),
            tooltip: "Help",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SplashScreen(nextPage: ChatBot()),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/estimating.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown<int>(
                                label: 'Area Size (Marla)',
                                value: selectedArea,
                                items: List.generate(20, (i) => i + 1),
                                onChanged: (val) {
                                  selectedArea = val;
                                  if (showResult)
                                    _calculateCost(fromDropdown: true);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown<String>(
                                label: 'Storey',
                                value: selectedStorey,
                                items: ['Single', 'Double', 'Triple'],
                                onChanged: (val) {
                                  selectedStorey = val;
                                  if (showResult)
                                    _calculateCost(fromDropdown: true);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown<int>(
                                label: 'Bedrooms',
                                value: selectedBedrooms,
                                items: [1, 2, 3, 4, 5, 6],
                                onChanged: (val) {
                                  selectedBedrooms = val;
                                  if (showResult)
                                    _calculateCost(fromDropdown: true);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown<int>(
                                label: 'Living Rooms',
                                value: selectedLivingRooms,
                                items: [1, 2, 3],
                                onChanged: (val) {
                                  selectedLivingRooms = val;
                                  if (showResult)
                                    _calculateCost(fromDropdown: true);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildDropdown<int>(
                                label: 'Washrooms',
                                value: selectedWashrooms,
                                items: [1, 2, 3, 4, 5, 6],
                                onChanged: (val) {
                                  selectedWashrooms = val;
                                  if (showResult)
                                    _calculateCost(fromDropdown: true);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDropdown<int>(
                                label: 'Kitchen',
                                value: selectedKitchens,
                                items: [1, 2],
                                onChanged: (val) {
                                  selectedKitchens = val;
                                  if (showResult)
                                    _calculateCost(fromDropdown: true);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: SizedBox(
                            width: 150,
                            child: ElevatedButton(
                              onPressed: () => _calculateCost(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                              ),
                              child: const Text(
                                'Calculate',
                                style: TextStyle(color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showResult) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.deepPurple.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '🏠 Total Budget: PKR ${autoTotalCost.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: const Text('Please select field'),
      items: items
          .map(
            (item) => DropdownMenuItem(
          value: item,
          child: Text(item.toString()),
        ),
      )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
    );
  }
}
