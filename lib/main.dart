import 'package:flutter/material.dart';
import 'views/login.dart';

void main() => runApp(MaterialApp(
  home: AnimalShelterLoginForm(
    emailController: TextEditingController(),
    passwordController: TextEditingController(),
    isPasswordVisible: false,
    isLoading: false,
    rememberMe: false,
    onTogglePasswordVisibility: () {},
    onToggleRememberMe: () {},
    onForgotPassword: () {},
    onSubmit: () {},
  ),
));
