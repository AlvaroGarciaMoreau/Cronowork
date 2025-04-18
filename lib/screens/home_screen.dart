import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cronowork/models/category.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isRunning = false;
  Duration _elapsedTime = Duration.zero;
  DateTime? _startTime;
  Timer? _timer;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String? _selectedCategoryId;
  Duration _totalElapsedTime = Duration.zero;

  final user = FirebaseAuth.instance.currentUser!;

  Future<void> _showNewSessionDialog() async {
    final descriptionController = TextEditingController();
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();
    String? selectedCategoryId;
    DateTime? selectedStartTime;
    DateTime? selectedEndTime;

    // Obtener categorías
    List<QueryDocumentSnapshot> categories = [];
    try {
      final snapshot =
          await _firestore
              .collection('categories')
              .where('userId', isEqualTo: user.uid)
              .get();
      categories = snapshot.docs;
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nueva Sesión'),
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
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategoryId,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          categories.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(data['name']),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategoryId = value;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: startTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha/hora inicio',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (!context.mounted) return;
                        if (picked != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(DateTime.now()),
                          );
                          if (!context.mounted) return;
                          if (time != null) {
                            final dt = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              time.hour,
                              time.minute,
                            );
                            setState(() {
                              selectedStartTime = dt;
                              startTimeController.text = dt.toString();
                            });
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: endTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha/hora fin (opcional)',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedStartTime ?? DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (!context.mounted) return;
                        if (picked != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(DateTime.now()),
                          );
                          if (!context.mounted) return;
                          if (time != null) {
                            final dt = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              time.hour,
                              time.minute,
                            );
                            setState(() {
                              selectedEndTime = dt;
                              endTimeController.text = dt.toString();
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
                ElevatedButton(
                  onPressed: () async {
                    if (descriptionController.text.isEmpty ||
                        selectedCategoryId == null ||
                        startTimeController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Completa todos los campos obligatorios',
                          ),
                        ),
                      );
                      return;
                    }
                    if (selectedStartTime == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Selecciona fecha/hora de inicio'),
                        ),
                      );
                      return;
                    }
                    int? durationSeconds;
                    if (selectedEndTime != null) {
                      durationSeconds =
                          selectedEndTime!
                              .difference(selectedStartTime!)
                              .inSeconds;
                      if (durationSeconds <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'La fecha/hora de fin debe ser posterior a la de inicio',
                            ),
                          ),
                        );
                        return;
                      }
                    }
                    try {
                      final sessionData = {
                        'userId': user.uid,
                        'categoryId': selectedCategoryId,
                        'description': descriptionController.text,
                        'startTime': Timestamp.fromDate(selectedStartTime!),
                        if (durationSeconds != null)
                          'duration': durationSeconds,
                        if (selectedEndTime != null)
                          'endTime': Timestamp.fromDate(selectedEndTime!),
                      };
                      await _firestore.collection('sessions').add(sessionData);

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sesión guardada')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error al añadir sesión: ${e.toString()}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (!_isRunning) {
      setState(() {
        _startTime = DateTime.now();
        _isRunning = true;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (_startTime != null) {
            setState(() {
              _elapsedTime = DateTime.now().difference(_startTime!);
            });
          }
        });
      });
    }
  }

  void _pauseTimer() {
    if (_isRunning) {
      setState(() {
        _isRunning = false;
        _timer?.cancel();
        _totalElapsedTime += _elapsedTime;
        _elapsedTime = Duration.zero;
      });
    }
  }

  void _cancelTimer() {
    if (_isRunning) {
      setState(() {
        _isRunning = false;
        _timer?.cancel();
        _elapsedTime = Duration.zero;
        _totalElapsedTime = Duration.zero;
        _startTime = null;
      });
    }
  }

  void _saveSession() {
    if (_isRunning) {
      setState(() {
        _isRunning = false;
        _timer?.cancel();
        _totalElapsedTime += _elapsedTime;
        _elapsedTime = Duration.zero;
      });
    }

    if (_totalElapsedTime > Duration.zero) {
      _showDescriptionDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay tiempo acumulado para guardar')),
      );
    }
  }

  Future<String?> _showNewCategoryDialog() async {
    final categoryController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Nueva Categoría'),
            content: TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                hintText: 'Nombre de la categoría',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (categoryController.text.isNotEmpty) {
                    final capitalizedText =
                        categoryController.text[0].toUpperCase() +
                        (categoryController.text.length > 1
                            ? categoryController.text.substring(1)
                            : '');
                    Navigator.pop(context, capitalizedText);
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
    );

    return result;
  }

  Future<void> _saveCategory(String name) async {
    try {
      final category = Category(id: '', name: name, userId: user.uid);

      await _firestore.collection('categories').add(category.toMap());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoría creada correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear categoría: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDescriptionDialog() async {
    final descriptionController = TextEditingController();

    String? selectedCategoryId = _selectedCategoryId;

    // Check if still mounted before showing dialog
    if (!mounted) return;

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: const Text(
                    'Descripción de la sesión',
                    style: TextStyle(fontSize: 20),
                  ),
                  content: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: descriptionController,
                          decoration: const InputDecoration(
                            hintText: 'Describe lo que has trabajado',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 16),
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              _firestore
                                  .collection('categories')
                                  .where('userId', isEqualTo: user.uid)
                                  .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
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

                            if (categories.isEmpty) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'No hay categorías creadas',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Por favor, crea una categoría',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text('Crear categoría'),
                                    onPressed: () async {
                                      final newCategory =
                                          await _showNewCategoryDialog();
                                      if (newCategory != null) {
                                        await _saveCategory(newCategory);
                                      }
                                    },
                                  ),
                                ],
                              );
                            }

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DropdownButtonFormField<String>(
                                  value: selectedCategoryId,
                                  decoration: const InputDecoration(
                                    labelText: 'Categoría',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  items:
                                      categories.map((doc) {
                                        return DropdownMenuItem<String>(
                                          value: doc.id,
                                          child: Text(doc.name),
                                        );
                                      }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedCategoryId = value;
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        TextButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Crear nueva categoría'),
                          onPressed: () async {
                            final newCategory = await _showNewCategoryDialog();
                            try {
                              if (newCategory != null) {
                                await _saveCategory(newCategory);
                              }
                            } catch (e) {
                              debugPrint('Widget might have been disposed: $e');
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
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          _firestore
                              .collection('categories')
                              .where('userId', isEqualTo: user.uid)
                              .snapshots(),
                      builder: (context, snapshot) {
                        return ElevatedButton(
                          onPressed: () {
                            if (descriptionController.text.isNotEmpty &&
                                selectedCategoryId != null) {
                              final capitalizedText =
                                  descriptionController.text[0].toUpperCase() +
                                  (descriptionController.text.length > 1
                                      ? descriptionController.text.substring(1)
                                      : '');
                              Navigator.pop(context, {
                                'description': capitalizedText,
                                'categoryId': selectedCategoryId!,
                              });
                            }
                          },
                          child: const Text('Guardar'),
                        );
                      },
                    ),
                  ],
                ),
          ),
    );

    if (result != null) {
      setState(() {
        _selectedCategoryId = result['categoryId'];
      });
      await _saveSessionToFirestore(
        result['description']!,
        result['categoryId']!,
      );
    }
  }

  Future<void> _saveSessionToFirestore(
    String description,
    String categoryId,
  ) async {
    try {
      if (_startTime == null) {
        return;
      }

      final sessionData = {
        'userId': user.uid,
        'startTime': Timestamp.fromDate(_startTime!),
        'endTime': Timestamp.fromDate(DateTime.now()),
        'duration': _totalElapsedTime.inSeconds,
        'description': description,
        'categoryId': categoryId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('sessions').add(sessionData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión guardada correctamente')),
        );
      }

      setState(() {
        _elapsedTime = Duration.zero;
        _totalElapsedTime = Duration.zero;
        _startTime = null;
        _selectedCategoryId = null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Error al cerrar sesión')));
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('CronoWork'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(icon: const Icon(Icons.logout), onPressed: _signOut),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _formatDuration(_totalElapsedTime + _elapsedTime),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _isRunning ? null : _startTimer,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Iniciar'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _isRunning ? _pauseTimer : null,
                        icon: const Icon(Icons.pause),
                        label: const Text('Pausar'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 32),
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _saveSession,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _isRunning ? _cancelTimer : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('Cancelar'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        floatingActionButton: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'addSession',
                  onPressed: _showNewSessionDialog,
                  child: const Icon(Icons.event_note),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Añadir sesión',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  heroTag: 'addCategory',
                  onPressed: () async {
                    final newCategory = await _showNewCategoryDialog();
                    if (newCategory != null) {
                      await _saveCategory(newCategory);
                    }
                  },
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Añadir categoría',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContentWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Contenido de la pantalla principal'));
  }
}

class ReportsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Contenido de la pantalla de informes'));
  }
}
