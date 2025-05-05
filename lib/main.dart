import 'dart:typed_data';
import 'dart:io' as io;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(MyApp());
}

class Medication {
  final String name;
  final int morning;
  final int afternoon;
  final int night;
  final Uint8List imageBytes;

  Medication({
    required this.name,
    required this.morning,
    required this.afternoon,
    required this.night,
    required this.imageBytes,
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medicações',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MedicationListScreen(),
    );
  }
}

class MedicationListScreen extends StatefulWidget {
  @override
  _MedicationListScreenState createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen> {
  final List<Medication> medications = [];

  void _addMedication(Medication medication) {
    setState(() {
      medications.add(medication);
    });
  }

  void _openForm() async {
    final nameController = TextEditingController();
    final morningController = TextEditingController();
    final afternoonController = TextEditingController();
    final nightController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        Uint8List? selectedImageBytes;

        return StatefulBuilder(
          builder:
              (context, setModalState) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            labelText: 'Nome do medicamento',
                          ),
                        ),
                        TextField(
                          controller: morningController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Manhã'),
                        ),
                        TextField(
                          controller: afternoonController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Tarde'),
                        ),
                        TextField(
                          controller: nightController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Noite'),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (picked != null) {
                              selectedImageBytes = await picked.readAsBytes();
                              setModalState(() {});
                            }
                          },
                          child: Text('Escolher imagem da galeria'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                            );
                            if (result != null) {
                              if (result.files.single.bytes != null) {
                                selectedImageBytes = result.files.single.bytes!;
                              } else if (result.files.single.path != null) {
                                if (kIsWeb) {
                                  // No suporte para leitura por path no Web
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Erro ao carregar imagem no Web.',
                                      ),
                                    ),
                                  );
                                } else {
                                  final file = io.File(
                                    result.files.single.path!,
                                  );
                                  selectedImageBytes = await file.readAsBytes();
                                }
                              }
                              setModalState(() {});
                            }
                          },
                          child: Text('Escolher imagem via File Picker'),
                        ),
                        if (selectedImageBytes != null)
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.memory(
                              selectedImageBytes!,
                              height: 100,
                            ),
                          ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (selectedImageBytes != null) {
                              final medication = Medication(
                                name: nameController.text,
                                morning:
                                    int.tryParse(morningController.text) ?? 0,
                                afternoon:
                                    int.tryParse(afternoonController.text) ?? 0,
                                night: int.tryParse(nightController.text) ?? 0,
                                imageBytes: selectedImageBytes!,
                              );
                              _addMedication(medication);
                              Navigator.of(context).pop();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Selecione uma imagem antes de salvar.',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text('Salvar'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        );
      },
    );
  }

  Widget _buildTimeWidget(IconData icon, int count) {
    return Column(
      children: [
        Icon(icon),
        SizedBox(height: 4),
        Row(
          children: List.generate(
            count,
            (_) => Container(
              margin: EdgeInsets.symmetric(horizontal: 2),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.lightBlueAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationItem(Medication med) {
    return Card(
      margin: EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.memory(
              med.imageBytes,
              width: double.infinity,
              height: 150,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 8),
            Text(
              med.name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTimeWidget(Icons.wb_sunny, med.morning),
                _buildTimeWidget(Icons.wb_cloudy, med.afternoon),
                _buildTimeWidget(Icons.nightlight_round, med.night),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _buildPdf() async {
    final pdf = pw.Document();

    final emojiFont = pw.Font.ttf(
      await rootBundle.load('lib/assets/NotoEmoji-VariableFont_wght.ttf'),
    );

    final helvetica = pw.Font.helvetica();

    for (var med in medications) {
      final image = pw.MemoryImage(med.imageBytes);

      pw.Widget buildLine(String emoji, String label, int count) {
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              emoji,
              style: pw.TextStyle(font: emojiFont, fontSize: 28 * 1.15),
            ),
            pw.SizedBox(width: 8),
            pw.Text(
              '$label: ',
              style: pw.TextStyle(font: helvetica, fontSize: 16 * 1.15),
            ),
            pw.Text(
              '$count ',
              style: pw.TextStyle(font: helvetica, fontSize: 16 * 1.15),
            ),
            pw.Wrap(
              spacing: 4,
              children: List.generate(
                count,
                (_) => pw.Text(
                  '💊',
                  style: pw.TextStyle(font: emojiFont, fontSize: 22 * 1.1),
                ),
              ),
            ),
          ],
        );
      }

      pdf.addPage(
        pw.Page(
          margin: pw.EdgeInsets.all(24),
          build:
              (context) => pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Nome: ${med.name}',
                    style: pw.TextStyle(fontSize: 18),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Center(
                    child: pw.Image(image, height: 150, fit: pw.BoxFit.cover),
                  ),
                  pw.SizedBox(height: 20),
                  buildLine('☀️', 'Manhã', med.morning),
                  pw.SizedBox(height: 8),
                  buildLine('🌤', 'Tarde', med.afternoon),
                  pw.SizedBox(height: 8),
                  buildLine('🌙', 'Noite', med.night),
                ],
              ),
        ),
      );
    }

    return pdf.save();
  }

  void _generatePdfAndShow() async {
    final pdfBytes = await _buildPdf();
    await Printing.layoutPdf(onLayout: (format) => pdfBytes);
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Informações'),
            content: Text(
              'App ainda em desenvolvimento que pode conter erros e bugs. '
              'Quaisquer comentários, contactar gilsonoliveira007@outlook.com',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Medicações'),
        actions: [
          IconButton(icon: Icon(Icons.info), onPressed: _showInfoDialog),
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: _generatePdfAndShow,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: medications.length,
        itemBuilder: (ctx, i) => _buildMedicationItem(medications[i]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        child: Icon(Icons.add),
      ),
    );
  }
}
