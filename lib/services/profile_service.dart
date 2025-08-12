import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:ksrtc_users/models/user_model.dart';

class ProfileService {
  final Client client;
  late Account account;
  late Storage storage;
  late Databases databases;

  // Constants
  static const String databaseId = 'default';
  static const String usersCollectionId = 'users';
  static const String profileBucketId = 'profile_images';

  ProfileService(this.client) {
    account = Account(client);
    storage = Storage(client);
    databases = Databases(client);
  }

  // Get current user profile
  Future<UserModel> getCurrentUser() async {
    try {
      // Get account info
      final models.User accountInfo = await account.get();

      // Try to get extended user info from database
      try {
        final models.Document userDoc = await databases.getDocument(
          databaseId: databaseId,
          collectionId: usersCollectionId,
          documentId: accountInfo.$id,
        );

        // Combine account info with database info
        final Map<String, dynamic> userData = {
          'id': accountInfo.$id,
          'name': accountInfo.name,
          'email': accountInfo.email,
          ...userDoc.data,
        };

        return UserModel.fromJson(userData);
      } catch (e) {
        // If user document doesn't exist yet, create one with basic info
        final Map<String, dynamic> userData = {
          'id': accountInfo.$id,
          'name': accountInfo.name,
          'email': accountInfo.email,
          'phone': '',
        };

        return UserModel.fromJson(userData);
      }
    } catch (e) {
      debugPrint('Error getting user: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<UserModel> updateUserProfile(UserModel user) async {
    try {
      // Update account name if changed
      await account.updateName(name: user.name);

      // Update or create user document in database
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: user.id,
        data: {
          'phone': user.phone,
          'address': user.address,
          'preferredPaymentMethod': user.preferredPaymentMethod,
          'favoriteRoutes': user.favoriteRoutes,
          'preferences': user.preferences,
        },
      );

      // Get updated user
      return await getCurrentUser();
    } catch (e) {
      // If document doesn't exist, create it
      if (e is AppwriteException && e.code == 404) {
        await databases.createDocument(
          databaseId: databaseId,
          collectionId: usersCollectionId,
          documentId: user.id,
          data: {
            'phone': user.phone,
            'address': user.address,
            'preferredPaymentMethod': user.preferredPaymentMethod,
            'favoriteRoutes': user.favoriteRoutes,
            'preferences': user.preferences,
          },
        );

        return await getCurrentUser();
      }

      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  // Upload profile image
  Future<String> uploadProfileImage(String filePath, String userId) async {
    try {
      final models.File file = await storage.createFile(
        bucketId: profileBucketId,
        fileId: 'profile_$userId',
        file: InputFile.fromPath(path: filePath),
      );

      // Construct the proper URL for the image
      // Using the Appwrite endpoint and file ID to create a direct URL to the image
      final String imageUrl =
          '${client.endPoint}/storage/buckets/$profileBucketId/files/${file.$id}/view';

      // Update user profile with new image URL
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: usersCollectionId,
        documentId: userId,
        data: {'profileImageUrl': imageUrl},
      );

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      rethrow;
    }
  }

  // Change password
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await account.updatePassword(
        password: newPassword,
        oldPassword: oldPassword,
      );
    } catch (e) {
      debugPrint('Error changing password: $e');
      rethrow;
    }
  }

  // Logout user
  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } catch (e) {
      debugPrint('Error logging out: $e');
      rethrow;
    }
  }
}
