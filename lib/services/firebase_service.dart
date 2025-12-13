import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/product_model.dart';
import '../models/shopping_list_model.dart';
import '../models/beacon_model.dart';
import 'credentials_service.dart';

class FirebaseService {
  // Singleton pattern
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============================================================================
  // AUTHENTICATION METHODS
  // ============================================================================

  /// Sign up new user
  Future<User?> signUp({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    try {
      // Create authentication account
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? user = credential.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(displayName);

        // Create user profile in Firestore
        final userModel = UserModel(
          userId: user.uid,
          email: email,
          displayName: displayName,
          phoneNumber: phoneNumber,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          preferences: UserPreferences.defaultPreferences(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toJson());

        return user;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  /// Sign in existing user
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;
      if (user != null) {
        final userDocRef = _firestore.collection('users').doc(user.uid);
        final userDoc = await userDocRef.get();

        if (userDoc.exists) {
          // Update last login timestamp
          await userDocRef.update({'lastLoginAt': Timestamp.now()});
        } else {
          // Create missing user profile
          final userModel = UserModel(
            userId: user.uid,
            email: email,
            displayName: user.displayName ?? 'User',
            phoneNumber: user.phoneNumber,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            preferences: UserPreferences.defaultPreferences(),
          );

          await userDocRef.set(userModel.toJson());
        }
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      // Clear saved credentials on logout
      await CredentialsService().clearCredentials();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to reset password: $e');
    }
  }

  /// Re-authenticate user (required before sensitive operations like password change)
  Future<UserCredential> reauthenticateUser({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      // Create credential for re-authentication
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      // Re-authenticate
      return await user.reauthenticateWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Failed to re-authenticate: $e');
    }
  }

  /// Get current user profile
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Update user profile (creates if doesn't exist)
  Future<void> updateUserProfile(UserModel user) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.userId);
      final docSnapshot = await userDoc.get();
      
      if (docSnapshot.exists) {
        // Update existing profile
        await userDoc.update(user.toJson());
      } else {
        // Create new profile if it doesn't exist
        await userDoc.set(user.toJson());
      }
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // ============================================================================
  // SHOPPING LIST METHODS
  // ============================================================================

  /// Create new shopping list
  Future<String> createShoppingList({
    required String userId,
    required String listName,
  }) async {
    try {
      final docRef = _firestore.collection('shopping_lists').doc();
      final listId = docRef.id;

      final shoppingList = ShoppingListModel(
        listId: listId,
        userId: userId,
        listName: listName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [],
        isActive: true,
        totalItems: 0,
        completedItems: 0,
      );

      await docRef.set(shoppingList.toJson());
      return listId;
    } catch (e) {
      throw Exception('Failed to create shopping list: $e');
    }
  }

  /// Get user's shopping lists
  Stream<List<ShoppingListModel>> getUserShoppingLists(String userId) {
    try {
      return _firestore
          .collection('shopping_lists')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
            // Filter out inactive lists on client side
            return snapshot.docs
                .map((doc) => ShoppingListModel.fromJson(doc.data()))
                .where((list) => list.isActive)
                .toList();
          });
    } catch (e) {
      throw Exception('Failed to get shopping lists: $e');
    }
  }

  /// Get specific shopping list
  Future<ShoppingListModel?> getShoppingList(String listId) async {
    try {
      final doc = await _firestore
          .collection('shopping_lists')
          .doc(listId)
          .get();
      if (doc.exists && doc.data() != null) {
        return ShoppingListModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get shopping list: $e');
    }
  }

  /// Update shopping list name
  Future<void> updateShoppingListName({
    required String listId,
    required String listName,
  }) async {
    try {
      await _firestore.collection('shopping_lists').doc(listId).update({
        'listName': listName,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update list name: $e');
    }
  }

  /// Add item to shopping list
  Future<void> addItemToList({
    required String listId,
    required ShoppingItem item,
  }) async {
    try {
      final listDoc = _firestore.collection('shopping_lists').doc(listId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(listDoc);
        if (!snapshot.exists) {
          throw Exception('Shopping list not found');
        }

        final data = snapshot.data()!;
        final items = (data['items'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();

        items.add(item.toJson());

        transaction.update(listDoc, {
          'items': items,
          'totalItems': items.length,
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      throw Exception('Failed to add item: $e');
    }
  }

  /// Add multiple items to shopping list in a single batch operation (more efficient)
  Future<void> addItemsToListBatch({
    required String listId,
    required List<ShoppingItem> items,
  }) async {
    try {
      if (items.isEmpty) return;

      final listDoc = _firestore.collection('shopping_lists').doc(listId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(listDoc);
        if (!snapshot.exists) {
          throw Exception('Shopping list not found');
        }

        final data = snapshot.data()!;
        final existingItems = (data['items'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();

        // Add all new items at once
        for (final item in items) {
          existingItems.add(item.toJson());
        }

        transaction.update(listDoc, {
          'items': existingItems,
          'totalItems': existingItems.length,
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      throw Exception('Failed to add items: $e');
    }
  }

  /// Update item status (completed/incomplete)
  Future<void> updateItemStatus({
    required String listId,
    required String itemId,
    required bool isCompleted,
  }) async {
    try {
      final listDoc = _firestore.collection('shopping_lists').doc(listId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(listDoc);
        if (!snapshot.exists) {
          throw Exception('Shopping list not found');
        }

        final data = snapshot.data()!;
        final items = (data['items'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();

        // Find and update the item
        final itemIndex = items.indexWhere((item) => item['itemId'] == itemId);
        if (itemIndex != -1) {
          items[itemIndex]['isCompleted'] = isCompleted;
        }

        // Calculate completed count
        final completedCount = items
            .where((item) => item['isCompleted'] == true)
            .length;

        transaction.update(listDoc, {
          'items': items,
          'completedItems': completedCount,
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      throw Exception('Failed to update item status: $e');
    }
  }

  /// Delete item from shopping list
  Future<void> deleteItem({
    required String listId,
    required String itemId,
  }) async {
    try {
      final listDoc = _firestore.collection('shopping_lists').doc(listId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(listDoc);
        if (!snapshot.exists) {
          throw Exception('Shopping list not found');
        }

        final data = snapshot.data()!;
        final items = (data['items'] as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();

        // Remove the item
        items.removeWhere((item) => item['itemId'] == itemId);

        // Recalculate counts
        final completedCount = items
            .where((item) => item['isCompleted'] == true)
            .length;

        transaction.update(listDoc, {
          'items': items,
          'totalItems': items.length,
          'completedItems': completedCount,
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      throw Exception('Failed to delete item: $e');
    }
  }

  /// Update all items in shopping list (replaces entire items array)
  Future<void> updateShoppingListItems({
    required String listId,
    required List<ShoppingItem> items,
  }) async {
    try {
      final listDoc = _firestore.collection('shopping_lists').doc(listId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(listDoc);
        if (!snapshot.exists) {
          throw Exception('Shopping list not found');
        }

        // Calculate counts
        final completedCount = items
            .where((item) => item.isCompleted)
            .length;

        transaction.update(listDoc, {
          'items': items.map((item) => item.toJson()).toList(),
          'totalItems': items.length,
          'completedItems': completedCount,
          'updatedAt': Timestamp.now(),
        });
      });
    } catch (e) {
      throw Exception('Failed to update list items: $e');
    }
  }

  /// Delete entire shopping list
  Future<void> deleteShoppingList(String listId) async {
    try {
      await _firestore.collection('shopping_lists').doc(listId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to delete shopping list: $e');
    }
  }

  // ============================================================================
  // PRODUCT METHODS
  // ============================================================================

  /// Get all products
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  /// Get products by category
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('category', isEqualTo: category)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products by category: $e');
    }
  }

  /// Search products by name
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .orderBy('name')
          .get();

      // Filter on client side for case-insensitive search
      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data()))
          .where(
            (product) =>
                product.name.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  /// Get product by ID
  Future<ProductModel?> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (doc.exists && doc.data() != null) {
        return ProductModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product: $e');
    }
  }

  /// Get products by aisle
  Future<List<ProductModel>> getProductsByAisle(String aisle) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('location.aisle', isEqualTo: aisle)
          .orderBy('name')
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get products by aisle: $e');
    }
  }

  // ============================================================================
  // BEACON METHODS
  // ============================================================================

  /// Create new beacon
  Future<String> createBeacon(BeaconModel beacon) async {
    try {
      await _firestore
          .collection('beacons')
          .doc(beacon.beaconId)
          .set(beacon.toJson());
      return beacon.beaconId;
    } catch (e) {
      throw Exception('Failed to create beacon: $e');
    }
  }

  /// Get single beacon by ID
  Future<BeaconModel?> getBeacon(String beaconId) async {
    try {
      final doc = await _firestore.collection('beacons').doc(beaconId).get();
      if (doc.exists && doc.data() != null) {
        return BeaconModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get beacon: $e');
    }
  }

  /// Get all beacons
  Future<List<BeaconModel>> getAllBeacons({bool activeOnly = false}) async {
    try {
      Query query = _firestore.collection('beacons');
      
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
        // Don't use orderBy with where clause to avoid index requirement
        // We'll sort in memory instead
      } else {
        query = query.orderBy('createdAt', descending: false);
      }
      
      final snapshot = await query.get();
      
      final beacons = snapshot.docs
          .map((doc) => BeaconModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      // Sort in memory if we filtered by activeOnly
      if (activeOnly) {
        beacons.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      }
      
      return beacons;
    } catch (e) {
      throw Exception('Failed to get beacons: $e');
    }
  }

  /// Update beacon fields
  Future<void> updateBeacon(
    String beaconId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updatedAt'] = Timestamp.now();
      await _firestore.collection('beacons').doc(beaconId).update(updates);
    } catch (e) {
      throw Exception('Failed to update beacon: $e');
    }
  }

  /// Delete beacon
  Future<void> deleteBeacon(String beaconId) async {
    try {
      await _firestore.collection('beacons').doc(beaconId).delete();
    } catch (e) {
      throw Exception('Failed to delete beacon: $e');
    }
  }

  /// Get real-time stream of beacons
  Stream<List<BeaconModel>> getBeaconsStream({bool activeOnly = false}) {
    try {
      Query query = _firestore.collection('beacons');
      
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
        // Don't use orderBy with where clause to avoid index requirement
        // We'll sort in memory instead
      } else {
        query = query.orderBy('createdAt', descending: false);
      }
      
      return query.snapshots().map((snapshot) {
        final beacons = snapshot.docs
            .map((doc) => BeaconModel.fromJson(doc.data() as Map<String, dynamic>))
            .toList();
        
        // Sort in memory if we filtered by activeOnly
        if (activeOnly) {
          beacons.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        }
        
        return beacons;
      });
    } catch (e) {
      throw Exception('Failed to get beacons stream: $e');
    }
  }

  /// Update beacon last seen timestamp
  Future<void> updateBeaconLastSeen(String beaconId) async {
    try {
      await _firestore.collection('beacons').doc(beaconId).update({
        'lastSeen': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      // Silently fail - this is not critical
      debugPrint('Failed to update beacon last seen: $e');
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        // Check for the specific configuration error message
        if (e.message?.contains('supplied auth credential') == true) {
          return 'System configuration error. Please check your settings.';
        }
        return 'Authentication error: ${e.message}';
    }
  }
}
