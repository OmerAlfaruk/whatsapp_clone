import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:whatsapp_clone_app/features/user/domain/entities/user_entity.dart';

class UserModel extends UserEntity{
  final String? username;
  final String? email;
  final String? phoneNumber;
  final bool? isOnline;
  final String? uid;
  final String? status;
  final String? profileUrl;

  const UserModel({
    this.username,
    this.email,
    this.phoneNumber,
    this.isOnline,
    this.uid,
    this.status,
    this.profileUrl,
  }):super(
    username: username,
    email: email,
    uid: uid,
    phoneNumber: phoneNumber,
    isOnline: isOnline,
    status: status,
    profileUrl: profileUrl
  );
  factory UserModel.fromSnapshot(DocumentSnapshot snapshot){
    final snap=snapshot.data() as Map<String,dynamic>;
    return UserModel(
      username: snap['username'],
      email: snap['email'],
      uid: snap['uid'],
      phoneNumber: snap['phoneNumber'],
      profileUrl: snap['profileUrl'],
      isOnline: snap['isOnline'],
      status: snap['status']
    );
  }
  Map<String,dynamic> toDocument()=>{
    'username':username,
    'email':email,
    'uid':uid,
    'phoneNumber':phoneNumber,
    'profileUrl':profileUrl,
    'isOnline':isOnline,
    'status':status
  };

}