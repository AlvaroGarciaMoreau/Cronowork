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
      final user = _auth.currentUser;
      if (user == null) return;

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
    final user = _auth.currentUser;
    if (user == null) return;

    String? selectedCategoryId = _selectedCategoryId;

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
                                ),
                                const SizedBox(height: 16),
                                TextButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Crear nueva categoría'),
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
      final user = _auth.currentUser;

      if (user == null || _startTime == null) {
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
    return PopScope(
      canPop: false,
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
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: _showNewCategoryDialog,
              child: const Icon(Icons.add),
            ),
            const SizedBox(height: 4),
            const Text(
              'Añadir categoría',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Informes',
            ),
          ],
          onTap: (index) {
            if (index == 1) {
              Navigator.pushNamed(context, '/reports');
            }
          },
        ),
      ),
    );
  }
}
