import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cronowork/models/category.dart';
import 'package:cronowork/models/session.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Categorías
  Stream<List<Category>> getCategories(String userId) {
    return _db
        .collection('categories')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<void> addCategory(Category category) async {
    await _db.collection('categories').add(category.toMap());
  }

  // Sesiones
  Stream<List<Session>> getSessions(String userId, {bool orderByDate = false}) {
    Query query = _db.collection('sessions').where('userId', isEqualTo: userId);
    
    if (orderByDate) {
      query = query.orderBy('startTime', descending: true);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Session.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList());
  }

  Future<void> addSession(Map<String, dynamic> sessionData) async {
    await _db.collection('sessions').add(sessionData);
  }
}
