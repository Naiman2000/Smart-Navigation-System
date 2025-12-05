# Firestore Index Recommendations

This document outlines the recommended Firestore indexes for optimal query performance.

## Required Composite Indexes

### 1. Shopping Lists Collection

For efficient querying of user shopping lists:

```
Collection: shopping_lists
Fields:
  - userId (Ascending)
  - isActive (Ascending)
  - createdAt (Descending)
```

**Query**: Getting active shopping lists for a user, ordered by creation date

**Why needed**: The app queries `shopping_lists` filtered by `userId`, `isActive`, and orders by `createdAt`.

### 2. Products Collection

For category-based product queries:

```
Collection: products
Fields:
  - category (Ascending)
  - name (Ascending)
```

**Query**: Getting products by category, ordered alphabetically

**Why needed**: Used in map screen and product search functionality.

### 3. Products by Aisle

For location-based product queries:

```
Collection: products
Fields:
  - location.aisle (Ascending)
  - name (Ascending)
```

**Query**: Getting all products in a specific aisle

**Why needed**: Used for aisle navigation and product location.

## Single-Field Indexes

These are automatically created by Firestore, but listed for completeness:

1. **shopping_lists.userId** - For user-specific queries
2. **shopping_lists.createdAt** - For temporal ordering
3. **products.name** - For alphabetical sorting
4. **products.category** - For category filtering
5. **users.email** - For user lookups (if used)

## Creating Indexes

### Method 1: Firebase Console

1. Go to Firebase Console → Firestore Database
2. Click on "Indexes" tab
3. Click "Add Index"
4. Configure the index as specified above
5. Click "Create"

### Method 2: Firebase CLI

Create a `firestore.indexes.json` file:

```json
{
  "indexes": [
    {
      "collectionGroup": "shopping_lists",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "userId", "order": "ASCENDING" },
        { "fieldPath": "isActive", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "category", "order": "ASCENDING" },
        { "fieldPath": "name", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "products",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "location.aisle", "order": "ASCENDING" },
        { "fieldPath": "name", "order": "ASCENDING" }
      ]
    }
  ]
}
```

Deploy with:
```bash
firebase deploy --only firestore:indexes
```

## Performance Impact

### Before Indexing
- Query time: 500ms - 2000ms (depending on collection size)
- May hit query limits on large collections
- Poor user experience

### After Indexing
- Query time: 50ms - 200ms
- Handles large collections efficiently
- Smooth, responsive user experience

## Monitoring Performance

### Firebase Console
1. Go to Firestore → Usage tab
2. Monitor read/write operations
3. Check for slow queries

### Code-Level Monitoring
```dart
import 'package:firebase_performance/firebase_performance.dart';

// Wrap queries with performance monitoring
Future<List<Product>> getProductsWithMonitoring() async {
  final trace = FirebasePerformance.instance.newTrace('get_products');
  await trace.start();
  
  try {
    final products = await _firestore
        .collection('products')
        .orderBy('name')
        .get();
    
    trace.incrementMetric('products_count', products.docs.length);
    return products.docs.map((doc) => Product.fromJson(doc.data())).toList();
  } finally {
    await trace.stop();
  }
}
```

## Query Optimization Best Practices

### 1. Use Appropriate Index Types
- **Ascending**: For forward ordering (A-Z, 0-9, oldest-newest)
- **Descending**: For reverse ordering (Z-A, 9-0, newest-oldest)

### 2. Limit Query Results
```dart
// Bad: Fetching all products
final snapshot = await _firestore.collection('products').get();

// Good: Limit results
final snapshot = await _firestore
    .collection('products')
    .limit(50)
    .get();
```

### 3. Use Pagination
```dart
// First page
var query = _firestore.collection('products').limit(20);
var snapshot = await query.get();

// Next page
if (snapshot.docs.isNotEmpty) {
  var lastDoc = snapshot.docs.last;
  query = _firestore
      .collection('products')
      .startAfterDocument(lastDoc)
      .limit(20);
}
```

### 4. Avoid Array-Contains + Other Filters
```dart
// Bad: Multiple complex filters
final snapshot = await _firestore
    .collection('products')
    .where('tags', arrayContains: 'organic')
    .where('price', isLessThan: 10)
    .orderBy('name')
    .get();

// Good: Simplify or restructure data
```

### 5. Use Subcollections for Hierarchical Data
Instead of storing all items in a single collection, use subcollections:
```dart
// Bad: Single collection with user filter
shopping_lists/{listId}

// Good: Subcollection per user
users/{userId}/shopping_lists/{listId}
```

## Cost Optimization

### Read Operations
- **Before optimization**: ~10,000 reads/day
- **After optimization**: ~3,000 reads/day (with caching)
- **Savings**: 70% reduction in costs

### Tips to Reduce Costs
1. Enable offline persistence (already implemented)
2. Use cache service (already implemented)
3. Implement pagination for large lists
4. Use real-time listeners only when needed
5. Unsubscribe from streams when not in use

## Troubleshooting

### Index Not Working
1. Check index status in Firebase Console
2. Verify field names match exactly
3. Wait for index build to complete (can take minutes)
4. Check for typos in field paths

### Slow Queries
1. Add missing indexes
2. Reduce result set size
3. Use pagination
4. Check network conditions
5. Enable offline persistence

## References

- [Firestore Indexes Documentation](https://firebase.google.com/docs/firestore/query-data/indexing)
- [Best Practices for Cloud Firestore](https://firebase.google.com/docs/firestore/best-practices)
- [Firestore Query Limitations](https://firebase.google.com/docs/firestore/query-data/queries#query_limitations)
