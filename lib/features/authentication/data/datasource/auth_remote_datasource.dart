import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_mate/core/constants/firestore_constants.dart';
import 'package:expense_mate/features/authentication/data/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Remote data source for Firebase Authentication and user profile storage.
class AuthRemoteDataSource {
  AuthRemoteDataSource({
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firestore,
    required GoogleSignIn googleSignIn,
  })  : _auth = firebaseAuth,
        _firestore = firestore,
        _googleSignIn = googleSignIn;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentFirebaseUser => _auth.currentUser;

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    return _mapFirebaseUser(credential.user!);
  }

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    await credential.user!.updateDisplayName(displayName.trim());
    await credential.user!.sendEmailVerification();

    final userModel = _mapFirebaseUser(credential.user!)
        .copyWith(displayName: displayName.trim());

    await _createUserDocument(userModel);
    return userModel;
  }

  Future<UserModel> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign-in-cancelled',
        message: 'Google sign-in was cancelled.',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final userModel = _mapFirebaseUser(userCredential.user!);

    final doc = await _firestore
        .collection(FirestoreConstants.users)
        .doc(userModel.id)
        .get();

    if (!doc.exists) {
      await _createUserDocument(userModel);
    }

    return userModel;
  }

  Future<UserModel> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);
    final user = userCredential.user!;

    final displayName = [
      appleCredential.givenName,
      appleCredential.familyName,
    ].where((n) => n != null && n.isNotEmpty).join(' ');

    if (displayName.isNotEmpty) {
      await user.updateDisplayName(displayName);
    }

    final userModel = _mapFirebaseUser(user).copyWith(
      displayName: displayName.isNotEmpty ? displayName : user.displayName,
    );

    final doc = await _firestore
        .collection(FirestoreConstants.users)
        .doc(userModel.id)
        .get();

    if (!doc.exists) {
      await _createUserDocument(userModel);
    }

    return userModel;
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection(FirestoreConstants.users)
        .doc(user.uid)
        .update({FirestoreConstants.isDeleted: true});

    await user.delete();
  }

  Future<UserModel> updateProfile({
    String? displayName,
    String? photoUrl,
    String? phoneNumber,
  }) async {
    final user = _auth.currentUser!;
    if (displayName != null) {
      await user.updateDisplayName(displayName);
    }
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }

    await user.reload();
    final updated = _mapFirebaseUser(_auth.currentUser!);

    await _firestore.collection(FirestoreConstants.users).doc(user.uid).update({
      if (displayName != null) 'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
    });

    return updated.copyWith(
      displayName: displayName ?? updated.displayName,
      photoUrl: photoUrl ?? updated.photoUrl,
      phoneNumber: phoneNumber ?? updated.phoneNumber,
    );
  }

  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser!;
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }

  Future<void> _createUserDocument(UserModel user) {
    return _firestore.collection(FirestoreConstants.users).doc(user.id).set({
      'email': user.email,
      'displayName': user.displayName,
      'photoUrl': user.photoUrl,
      'phoneNumber': user.phoneNumber,
      'isEmailVerified': user.isEmailVerified,
      FirestoreConstants.createdAt: FieldValue.serverTimestamp(),
      FirestoreConstants.updatedAt: FieldValue.serverTimestamp(),
      FirestoreConstants.isDeleted: false,
    });
  }

  UserModel _mapFirebaseUser(User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      phoneNumber: user.phoneNumber,
      isEmailVerified: user.emailVerified,
      createdAt: user.metadata.creationTime,
      updatedAt: user.metadata.lastSignInTime,
    );
  }
}
