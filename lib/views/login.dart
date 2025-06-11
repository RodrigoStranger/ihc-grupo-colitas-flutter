import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../widgets/base_form.dart';
import '../core/colors.dart';
import '../core/strings.dart';

class AnimalShelterLoginForm extends BaseForm {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isPasswordVisible;
  final bool isLoading;
  final bool rememberMe;
  final VoidCallback onTogglePasswordVisibility;
  final VoidCallback onToggleRememberMe;
  final VoidCallback onForgotPassword;

  const AnimalShelterLoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.isPasswordVisible,
    required this.isLoading,
    required this.rememberMe,
    required this.onTogglePasswordVisibility,
    required this.onToggleRememberMe,
    required this.onForgotPassword,
    required super.onSubmit,
  }) : super(
          title: appTitle,
          fields: const [], // Se sobrescribe en _buildFields()
          submitButtonText: loginButtonText,
        );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPastelBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Header con logo
                _buildHeader(),
                const SizedBox(height: 50),
                // Formulario
                _buildFormCard(context),
                const Spacer(),
                // Footer
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.hasData ? snapshot.data!.version : '';
                    return _buildFooter(version);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 160,
          height: 160,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: primaryPastelBlue.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/grupo_colitas.png',
              width: 160,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          loginPanelTitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryPastelBlue.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._buildFields(),
          const SizedBox(height: 30),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  List<Widget> _buildFields() {
    return [
      // Campo de email
      TextFormField(
        controller: emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: loginEmailLabel,
          labelStyle: const TextStyle(color: labelTextColor),
          floatingLabelStyle: const TextStyle(color: labelTextColor),
          prefixIcon: const Icon(Icons.email_outlined, color: accentBlue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryPastelBlue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentBlue, width: 2),
          ),
          filled: true,
          fillColor: lightPastelBlue.withValues(alpha: 0.3),
        ),
      ),
      const SizedBox(height: 20),
      
      // Campo de contraseña
      TextFormField(
        controller: passwordController,
        obscureText: !isPasswordVisible,
        decoration: InputDecoration(
          labelText: loginPasswordLabel,
          labelStyle: const TextStyle(color: labelTextColor),
          floatingLabelStyle: const TextStyle(color: labelTextColor),
          prefixIcon: const Icon(Icons.lock_outline, color: accentBlue),
          suffixIcon: IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: accentBlue,
            ),
            onPressed: onTogglePasswordVisibility,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryPastelBlue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: accentBlue, width: 2),
          ),
          filled: true,
          fillColor: lightPastelBlue.withValues(alpha: 0.3),
        ),
      ),
    ];
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: isLoading ? null : onSubmit,
      style: ElevatedButton.styleFrom(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              submitButtonText,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildFooter(String version) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            '$loginVersionPrefix ${version.isNotEmpty ? version : '1.0.0'}',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}