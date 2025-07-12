import 'dart:async';
import 'dart:io';
import 'package:dart_appwrite/dart_appwrite.dart';

// This Appwrite function will be executed when a new user is created (users.*.create event)
Future<dynamic> main(final context) async {
  // Initialize Appwrite client
  final client = Client()
    .setEndpoint(Platform.environment['APPWRITE_FUNCTION_API_ENDPOINT'] ?? '')
    .setProject(Platform.environment['APPWRITE_FUNCTION_PROJECT_ID'] ?? '')
    .setKey(context.req.headers['x-appwrite-key'] ?? 
            Platform.environment['APPWRITE_FUNCTION_API_KEY'] ?? '');

  // Initialize services
  final databases = Databases(client);

  // Get environment variables
  final databaseId = Platform.environment['DATABASE_ID'] ?? '';
  final streaksCollectionId = Platform.environment['STREAKS_COLLECTION_ID'] ?? '';

  try {
    // Parse the event data to get user information
    final eventData = context.req.body;
    context.log('Event data received: $eventData');

    // Extract user ID from the event data
    String? userId;
    if (eventData is Map && eventData.containsKey('\$id')) {
      userId = eventData['\$id'];
    }

    if (userId == null || userId.isEmpty) {
      context.error('No user ID found in event data');
      return context.res.json({
        'success': false,
        'error': 'No user ID found in event data'
      });
    }

    context.log('Creating streak document for user: $userId');

    // Create initial streak document for the new user
    final streakDocument = await databases.createDocument(
      databaseId: databaseId,
      collectionId: streaksCollectionId,
      documentId: userId, // Use user ID as document ID
      data: {
        'userId': userId,
        'maxStreakCount': 1,
        'currentStreakCount': 1,
        'currentStreakStartDate': DateTime.now().toIso8601String(),
        'lastLogin': DateTime.now().toIso8601String(),
      },
    );

    context.log('Streak document created successfully: ${streakDocument.$id}');

    return context.res.json({
      'success': true,
      'message': 'Streak document created successfully',
      'userId': userId,
      'streakDocumentId': streakDocument.$id,
      'data': streakDocument.data,
    });

  } catch (e) {
    context.error('Error creating streak document: $e');
    return context.res.json({
      'success': false,
      'error': 'Failed to create streak document: $e',
    });
  }
}
