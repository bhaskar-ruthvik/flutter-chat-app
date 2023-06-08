import 'dart:io';

import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() {
    return _AuthScreenState();
  }
}

class _AuthScreenState extends State<AuthScreen> {
  @override
  void setState(VoidCallback fn) {
    if(mounted){
super.setState(fn);
    }
    
  }
  String _username = '';
  String _email = '';
  String _password = '';
  File? _image;
  final formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  var _isUploading = false;
  void _submitForm() async {
    final isValid = formKey.currentState!.validate();
    if(!isValid || (!_isLogin && _image==null)){
      return;
    }


    formKey.currentState!.save();
    try{
      setState(() {
        _isUploading = true;
      });
    if(_isLogin){
        final userCredentials = await _firebase.signInWithEmailAndPassword(email: _email, password: _password);
    }else{
     final userCredentials =  await _firebase.createUserWithEmailAndPassword(email: _email, password: _password);

     final storageRef = FirebaseStorage.instance.ref().child('user_images').child('${userCredentials.user!.uid}.jpg');
      
     await storageRef.putFile(_image!);
     setState(() {
       _isUploading = false;
     });
     final downloadUrl = await storageRef.getDownloadURL();
     FirebaseFirestore.instance.collection('users').doc('${userCredentials.user!.uid}').set({
      'username' : _username,
      'email' : _email,
      'image_url' : downloadUrl
     });
    }
     } on FirebaseAuthException catch(error){
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Authentication failed.')));
      }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: Center(
          child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(
                  top: 30, bottom: 20, left: 20, right: 20),
              width: 200,
              child: Image.asset('assets/images/chat.png'),
            ),
            Card(
              margin: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: formKey,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if(!_isLogin) UserImagePicker(onPickImage: (image){
                        setState(() {
                          _image = image;
                        });
                      }),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        validator: (value){
                          if(value == null || value.trim().isEmpty || !value.contains('@')){
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                        onSaved: (value){
                          _email = value!;
                        },
                      ),
                      if(!_isLogin) TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Username'
                        ),
                        validator: (value) {
                          if(value==null || value.isEmpty || value.trim().length<4){
                            return 'Please enter atleast 4 characters';
                          }
                          return null;
                        },
                        enableSuggestions: false,
                        onSaved: (value){
                            _username = value!;
                        },
                      ),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                        obscureText: true,
                        validator: (value){
                          if(value == null || value.trim().length < 6){
                            return 'Please enter a valid password';
                          }
                          return null;
                        },
                        onSaved: (value){
                          _password = value!;

                        },
                      ),
                      const SizedBox(height: 12),
                      if(_isUploading) CircularProgressIndicator(),
                      if(!_isUploading) ElevatedButton(
                      
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer
                        ),
                        onPressed: _submitForm,
                        child: Text(_isLogin ? 'Login' :'Signup'),
                      ),
                      if(!_isUploading) TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(_isLogin ? 'Create an account' : 'I already have an account.'),
                      )
                    ]),
                  ),
                ),
              ),
            )
          ],
        ),
      )),
    );
  }
}
