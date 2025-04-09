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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    setState(() {
      if (!_isRunning) {
        _startTime = DateTime.now();
        _isRunning = true;
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _elapsedTime = DateTime.now().difference(_startTime!);
          });
        });
      } else {
        _isRunning = false;
        _timer?.cancel();
        _showDescriptionDialog();
      }
    });
  }

  Future<void> _showNewCategoryDialog() async {
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

    if (result != null) {
      await _saveCategory(result);
    }
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

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Descripción de la sesión'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    hintText: 'Describe lo que has trabajado',
                    border: OutlineInputBorder(),
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

                    if (categories.isEmpty) {
                      return Column(
                        children: [
                          const SizedBox(height: 8),
                          const Text(
                            'No hay categorías creadas',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Por favor, crea una categoría usando el botón +',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showNewCategoryDialog();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Crear categoría'),
                          ),
                        ],
                      );
                    }

                    return DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
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
                          _selectedCategoryId = value;
                        });
                      },
                    );
                  },
                ),
              ],
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
                          _selectedCategoryId != null) {
                        final capitalizedText =
                            descriptionController.text[0].toUpperCase() +
                            (descriptionController.text.length > 1
                                ? descriptionController.text.substring(1)
                                : '');
                        Navigator.pop(context, {
                          'description': capitalizedText,
                          'categoryId': _selectedCategoryId!,
                        });
                      }
                    },
                    child: const Text('Guardar'),
                  );
                },
              ),
            ],
          ),
    );

    if (result != null) {
      await _saveSession(result['description']!, result['categoryId']!);
    }
  }

  Future<void> _saveSession(String description, String categoryId) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return;
      }

      final sessionData = {
        'userId': user.uid,
        'startTime': Timestamp.fromDate(_startTime!),
        'endTime': Timestamp.fromDate(DateTime.now()),
        'duration': _elapsedTime.inSeconds,
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
                _formatDuration(_elapsedTime),
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _toggleTimer,
                icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                label: Text(_isRunning ? 'Pausar' : 'Iniciar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showNewCategoryDialog,
          child: const Icon(Icons.add),
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
