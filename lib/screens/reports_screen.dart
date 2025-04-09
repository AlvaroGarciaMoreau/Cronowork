import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cronowork/models/category.dart';

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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No hay usuario autenticado')),
      );
    }

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
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('categories')
                          .where('userId', isEqualTo: user.uid)
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
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
                      value: _selectedCategoryId,
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
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('sessions')
                      .where('userId', isEqualTo: user.uid)
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
                      .where('categoryId', isEqualTo: _selectedCategoryId ?? '')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sessions = snapshot.data?.docs ?? [];

                if (sessions.isEmpty) {
                  return const Center(
                    child: Text('No hay sesiones registradas'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session =
                        sessions[index].data() as Map<String, dynamic>;
                    final startTime =
                        (session['startTime'] as Timestamp).toDate();
                    final endTime = (session['endTime'] as Timestamp).toDate();
                    final duration = session['duration'] as int;
                    final description = session['description'] as String;
                    final categoryId = session['categoryId'] as String;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      color: Colors.grey[50],
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(startTime),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '${DateFormat('HH:mm:ss').format(startTime)} - ${DateFormat('HH:mm:ss').format(endTime)}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            StreamBuilder<DocumentSnapshot>(
                              stream:
                                  FirebaseFirestore.instance
                                      .collection('categories')
                                      .doc(categoryId)
                                      .snapshots(),
                              builder: (context, categorySnapshot) {
                                if (categorySnapshot.hasData) {
                                  final category = Category.fromMap(
                                    categoryId,
                                    categorySnapshot.data!.data()
                                        as Map<String, dynamic>,
                                  );
                                  return Text(
                                    'Categoría: ${category.name}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue,
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Duración: ${_formatDuration(duration)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: const TextStyle(fontSize: 14),
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
    );
  }
}
