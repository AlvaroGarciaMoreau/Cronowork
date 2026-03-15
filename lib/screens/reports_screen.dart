import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cronowork/models/category.dart';
import 'package:cronowork/models/session.dart';
import 'package:cronowork/services/auth_service.dart';
import 'package:cronowork/services/database_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  int _totalSeconds = 0;
  String? _selectedCategoryId;
  final _databaseService = DatabaseService();
  final _authService = AuthService();

  String _formatDuration(int seconds) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(seconds ~/ 3600);
    final minutes = twoDigits((seconds % 3600) ~/ 60);
    final remainingSeconds = twoDigits(seconds % 60);
    return '$hours:$minutes:$remainingSeconds';
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStartDate
              ? (_startDate ?? DateTime.now())
              : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _deleteSession(String sessionId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: const Text(
              '¿Estás seguro de que deseas eliminar esta sesión?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(sessionId)
          .delete();
    }
  }

  Future<void> _editSession(Session session) async {
    final descriptionController = TextEditingController(
      text: session.description,
    );
    String? selectedCategoryId = session.categoryId;

    DateTime? selectedStart = session.startTime;
    DateTime? selectedEnd = session.endTime;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar sesión'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          FirebaseFirestore.instance
                              .collection('categories')
                              .where(
                                'userId',
                                isEqualTo:
                                    FirebaseAuth.instance.currentUser!.uid,
                              )
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final categories =
                            snapshot.data!.docs
                                .map(
                                  (doc) => Category.fromMap(
                                    doc.id,
                                    doc.data() as Map<String, dynamic>,
                                  ),
                                )
                                .toList();
                        return DropdownButtonFormField<String>(
                          initialValue: selectedCategoryId,
                          decoration: const InputDecoration(
                            labelText: 'Categoría',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              categories.map((category) {
                                return DropdownMenuItem<String>(
                                  value: category.id,
                                  child: Text(category.name),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategoryId = value;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(
                        selectedStart != null
                            ? 'Inicio: ${DateFormat('dd/MM/yyyy HH:mm').format(selectedStart!)}'
                            : 'Seleccionar fecha/hora de inicio',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedStart ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          locale: const Locale('es', 'ES'), // Español
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                              selectedStart ?? DateTime.now(),
                            ),
                            builder: (context, child) {
                              return Localizations.override(
                                context: context,
                                locale: const Locale('es', 'ES'),
                                child: child,
                              );
                            },
                          );
                          if (time != null) {
                            setState(() {
                              selectedStart = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                    ListTile(
                      title: Text(
                        selectedEnd != null
                            ? 'Fin: ${DateFormat('dd/MM/yyyy HH:mm').format(selectedEnd!)}'
                            : 'Seleccionar fecha/hora de fin (opcional)',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              selectedEnd ?? selectedStart ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          locale: const Locale('es', 'ES'), // Español
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                              selectedEnd ?? DateTime.now(),
                            ),
                            builder: (context, child) {
                              return Localizations.override(
                                context: context,
                                locale: const Locale('es', 'ES'),
                                child: child,
                              );
                            },
                          );
                          if (time != null) {
                            setState(() {
                              selectedEnd = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed:
                      () => Navigator.pop(context, {
                        'description': descriptionController.text,
                        'categoryId': selectedCategoryId,
                        'startTime': selectedStart,
                        'endTime': selectedEnd,
                      }),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      final updates = {
        'description': result['description'],
        'categoryId': result['categoryId'],
        'startTime': Timestamp.fromDate(result['startTime']),
        'endTime':
            result['endTime'] != null
                ? Timestamp.fromDate(result['endTime'])
                : null,
        'duration':
            result['endTime'] != null
                ? (result['endTime'] as DateTime)
                    .difference(result['startTime'] as DateTime)
                    .inSeconds
                : session.duration,
      };
      // Elimina el campo endTime si es null
      if (updates['endTime'] == null) updates.remove('endTime');
      await FirebaseFirestore.instance
          .collection('sessions')
          .doc(session.id)
          .update(updates);
    }
  }

  Future<void> _generatePdfReport(
    List<Session> sessions,
    List<Category> categories,
  ) async {
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoría para generar el informe'),
        ),
      );
      return;
    }

    final pdf = pw.Document();
    final category = categories.firstWhere((c) => c.id == _selectedCategoryId);

    int totalSeconds = sessions.fold(0, (acc, s) => acc + s.duration);
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    final totalEuros = (totalSeconds / 3600 * 10).toStringAsFixed(2);

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Text(
                'Informe de trabajos realizados',
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Categoría: ${category.name}',
                style: pw.TextStyle(fontSize: 18),
              ),
              pw.Text(
                'Desde: ${_startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : '-'}  '
                'Hasta: ${_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : '-'}',
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                'Total de horas: ${hours}h ${minutes}m ${seconds}s',
                style: pw.TextStyle(fontSize: 16),
              ),
              pw.Text(
                'Total a pagar: $totalEuros Euros',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.TableHelper.fromTextArray(
                headers: [
                  'Descripción',
                  'Fecha',
                  'Hora inicio',
                  'Hora fin',
                  'Duración',
                ],
                data:
                    sessions
                        .map(
                          (s) => [
                            s.description,
                            DateFormat('dd/MM/yyyy').format(s.startTime),
                            DateFormat('HH:mm:ss').format(s.startTime),
                            s.endTime != null
                                ? DateFormat('HH:mm:ss').format(s.endTime!)
                                : 'En curso',
                            _formatDuration(s.duration),
                          ],
                        )
                        .toList(),
              ),
            ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'informe_${category.name}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Informes')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _selectDate(true),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _startDate == null
                              ? 'Fecha inicio'
                              : DateFormat('dd/MM/yyyy').format(_startDate!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _selectDate(false),
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          _endDate == null
                              ? 'Fecha fin'
                              : DateFormat('dd/MM/yyyy').format(_endDate!),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<Category>>(
                  stream: _databaseService.getCategories(user!.uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final categories = snapshot.data!;

                    return DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Filtrar por categoría',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todas las categorías'),
                        ),
                        ...categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          if (_startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        _selectedCategoryId == null
                            ? 'Total de horas trabajadas:'
                            : 'Total de horas por categoría:',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<QuerySnapshot>(
                        stream:
                            FirebaseFirestore.instance
                                .collection('sessions')
                                .where('userId', isEqualTo: user.uid)
                                .where(
                                  'startTime',
                                  isGreaterThanOrEqualTo: Timestamp.fromDate(
                                    _startDate!,
                                  ),
                                )
                                .where(
                                  'startTime',
                                  isLessThanOrEqualTo: Timestamp.fromDate(
                                    _endDate!.add(const Duration(days: 1)),
                                  ),
                                )
                                .where(
                                  'categoryId',
                                  isEqualTo: _selectedCategoryId ?? '',
                                )
                                .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            _totalSeconds = 0;
                            for (var doc in snapshot.data!.docs) {
                              final session =
                                  doc.data() as Map<String, dynamic>;
                              _totalSeconds += session['duration'] as int;
                            }
                            return Column(
                              children: [
                                Text(
                                  _formatDuration(_totalSeconds),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                if (_selectedCategoryId != null)
                                  StreamBuilder<DocumentSnapshot>(
                                    stream:
                                        FirebaseFirestore.instance
                                            .collection('categories')
                                            .doc(_selectedCategoryId)
                                            .snapshots(),
                                    builder: (context, categorySnapshot) {
                                      if (categorySnapshot.hasData) {
                                        final category = Category.fromMap(
                                          _selectedCategoryId!,
                                          categorySnapshot.data!.data()
                                              as Map<String, dynamic>,
                                        );
                                        return Text(
                                          'Categoría: ${category.name}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            color: Colors.blue,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                              ],
                            );
                          }
                          return const CircularProgressIndicator();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<Session>>(
              stream: _databaseService.getSessions(user.uid, orderByDate: true),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sessions = snapshot.data!
                    .where((s) =>
                        (_selectedCategoryId == null ||
                            s.categoryId == _selectedCategoryId) &&
                        (_startDate == null ||
                            s.startTime.isAfter(_startDate!)) &&
                        (_endDate == null ||
                            s.startTime.isBefore(
                                _endDate!.add(const Duration(days: 1)))))
                    .toList();

                return ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      child: ListTile(
                        title: Text(session.description),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fecha: ${DateFormat('dd/MM/yyyy').format(session.startTime)}',
                            ),
                            Text(
                              'Hora: ${DateFormat('HH:mm:ss').format(session.startTime)} - ${session.endTime != null ? DateFormat('HH:mm:ss').format(session.endTime!) : 'En curso'}',
                            ),
                            Text(
                              'Duración: ${_formatDuration(session.duration)}',
                            ),
                            StreamBuilder<DocumentSnapshot>(
                              stream:
                                  FirebaseFirestore.instance
                                      .collection('categories')
                                      .doc(session.categoryId)
                                      .snapshots(),
                              builder: (context, categorySnapshot) {
                                if (categorySnapshot.hasData) {
                                  final category = Category.fromMap(
                                    session.categoryId,
                                    categorySnapshot.data!.data()
                                        as Map<String, dynamic>,
                                  );
                                  return Text('Categoría: ${category.name}');
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editSession(session),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteSession(session.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('sessions')
                .where('userId', isEqualTo: user.uid)
                .where('categoryId', isEqualTo: _selectedCategoryId ?? '')
                .where(
                  'startTime',
                  isGreaterThanOrEqualTo:
                      _startDate != null
                          ? Timestamp.fromDate(_startDate!)
                          : null,
                )
                .where(
                  'startTime',
                  isLessThanOrEqualTo:
                      _endDate != null
                          ? Timestamp.fromDate(
                            _endDate!.add(const Duration(days: 1)),
                          )
                          : null,
                )
                .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final sessions =
              snapshot.data!.docs
                  .map(
                    (doc) => Session.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList();

          return StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('categories')
                    .where('userId', isEqualTo: user.uid)
                    .snapshots(),
            builder: (context, catSnapshot) {
              if (!catSnapshot.hasData) return const SizedBox.shrink();
              final categories =
                  catSnapshot.data!.docs
                      .map(
                        (doc) => Category.fromMap(
                          doc.id,
                          doc.data() as Map<String, dynamic>,
                        ),
                      )
                      .toList();

              return FloatingActionButton.extended(
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Generar informe'),
                onPressed: () => _generatePdfReport(sessions, categories),
              );
            },
          );
        },
      ),
    );
  }
}
