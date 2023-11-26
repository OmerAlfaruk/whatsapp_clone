import 'dart:html';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:whatsapp_clone_app/features/app/const/app_const.dart';
import 'package:whatsapp_clone_app/features/app/const/firebase_collection_const.dart';
import 'package:whatsapp_clone_app/features/user/data/data_sources/remote/user_remote_data_source.dart';
import 'package:whatsapp_clone_app/features/user/data/models/user_model.dart';
import 'package:whatsapp_clone_app/features/user/domain/entities/contact_entity.dart';
import 'package:whatsapp_clone_app/features/user/domain/entities/user_entity.dart';

class UserRemoteDatasourceImpl implements UserRemoteDataSource {
  final FirebaseFirestore fireStore;
  final FirebaseAuth auth;
  String _verificationId = '';

  UserRemoteDatasourceImpl(this.fireStore, this.auth);
  @override
  Future<void> createUser(UserEntity user) async {
    final userCollection = fireStore.collection(FirebaseCollectionConst.users);
    final uid = await getCurrentUID();
    final newUser = UserModel(
            username: user.username,
            uid: uid,
            status: user.status,
            phoneNumber: user.phoneNumber,
            profileUrl: user.profileUrl,
            isOnline: user.isOnline,
            email: user.email)
        .toDocument();
    try {
      userCollection.doc(uid).get().then((userDoc) {
        if (!userDoc.exists) {
          userCollection.doc(uid).set(newUser);
        } else {
          userCollection.doc(uid).update(newUser);
        }
      });
    } catch (e) {}
  }

  @override
  Stream<List<UserEntity>> getAllUsers() {
    final userCollection = fireStore.collection(FirebaseCollectionConst.users);
    return userCollection.snapshots().map((querySnapshot) =>
        querySnapshot.docs.map((e) => UserModel.fromSnapshot(e)).toList());
  }

  @override
  Future<String> getCurrentUID() async => auth.currentUser!.uid;

  @override
  Future<List<ContactEntity>> getDeviceNumber() async {
    List<ContactEntity> contact = [];
    final getContactData = await ContactsService.getContacts();
    getContactData.forEach((myContact) {
      myContact.phones!.forEach((phoneData) {
        contact.add(ContactEntity(
            phoneNumber: phoneData.value,
            label: myContact.displayName,
            userProfile: myContact.avatar));
      });
    });
    return contact;
  }

  @override
  Stream<List<UserEntity>> getSingleUser(String uid) {
    final userCollection = fireStore
        .collection(FirebaseCollectionConst.users)
        .where('uid', isEqualTo: uid);
    return userCollection.snapshots().map((querySnapshot) =>
        querySnapshot.docs.map((e) => UserModel.fromSnapshot(e)).toList());
  }

  @override
  Future<bool> isSignIn() async => auth.currentUser?.uid != null;

  @override
  Future<void> signInWithPhoneNumber(String smsPinCode) async {
    try {
      AuthCredential credential = PhoneAuthProvider.credential(
          verificationId: _verificationId, smsCode: smsPinCode);
      await auth.signInWithCredential(credential);
    }on FirebaseAuthException catch (e) {
      if(e.code=='invalid-verification-code'){
        toast('invalid verification code');
      }
      if(e.code=='quota exceeded'){
        toast('SMS quota exceeded');
      }

    }
    catch(e){
      toast('unKnown Exception');
    }
  }

  @override
  Future<void> signOut() async => auth.signOut();

  @override
  Future<void> updateUser(UserEntity user) async {
    final userCollection = fireStore.collection(FirebaseCollectionConst.users);
    Map<String, dynamic> userInfo = {};
    if (user.username != '' && user.username != null) {
      userInfo['username'] = user.username;
    }
    if (user.profileUrl != '' && user.profileUrl != null) {
      userInfo['profileUrl'] = user.profileUrl;
    }
    if (user.isOnline != '' && user.isOnline != null) {
      userInfo['isOnline'] = user.isOnline;
    }
    userCollection.doc(user.uid).update(userInfo);
  }

  @override
  Future<void> verifyPhoneNumber(String phoneNumber) async {
    phoneVerificationCompleted(AuthCredential authCredential) {
      print(
          "phone Verified : Token ${authCredential.token} ${authCredential.signInMethod}");
    }

    phoneVerificationFailed(FirebaseAuthException firebaseAuthException) {
      print(
          "phone Verified : Token ${firebaseAuthException.message} ${firebaseAuthException.code}");
    }

    phoneCodeAutoRetrievalTimeOut(String verificationId) {
      _verificationId = verificationId;
      print("Time Out $verificationId");
    }

    phoneCodeSent(String verificationId, int? forceResendingToken) {
      _verificationId = verificationId;
    }

    await auth.verifyPhoneNumber(
        verificationCompleted: phoneVerificationCompleted,
        verificationFailed: phoneVerificationFailed,
        codeSent: phoneCodeSent,
        codeAutoRetrievalTimeout: phoneCodeAutoRetrievalTimeOut);
  }
}
