import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/config/app_config.dart';
import '../domain/meal.dart';

/// User-scoped meal persistence. Firestore rules must enforce the same UID boundary.
/// In demo mode the repository uses an in-memory store; it is intentionally not presented
/// as durable cloud storage.
class MealRepository {
  MealRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore,
        _auth = auth;

  final FirebaseFirestore? _firestore;
  final FirebaseAuth? _auth;
  static final Map<String, Meal> _demoMeals = <String, Meal>{};

  String? get _uid => (_auth ?? (AppConfig.firebaseReady ? FirebaseAuth.instance : null))
      ?.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _collection {
    if (!AppConfig.firebaseReady || _uid == null) return null;
    return (_firestore ?? FirebaseFirestore.instance)
        .collection('users').doc(_uid).collection('meals');
  }

  Future<void> save(Meal meal) async {
    final collection = _collection;
    if (collection == null) {
      _demoMeals[meal.id] = meal;
      return;
    }
    await collection.doc(meal.id).set(meal.toMap(), SetOptions(merge: false));
  }

  Stream<List<Meal>> watchMeals() {
    final collection = _collection;
    if (collection == null) {
      final values = _demoMeals.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return Stream<List<Meal>>.value(values);
    }
    return collection.orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => Meal.fromMap({...doc.data(), 'id': doc.id})).toList(),
    );
  }

  Future<void> delete(String id) async {
    final collection = _collection;
    if (collection == null) {
      _demoMeals.remove(id);
      return;
    }
    await collection.doc(id).delete();
  }
}
