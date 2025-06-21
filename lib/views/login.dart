import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../viewmodels/login_viewmodel.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (viewModel.isAuthenticated) {
            Navigator.of(context).pushReplacementNamed('/menu');
          }
          // Forzar validación si hay error
          if (viewModel.hasError) {
            formKey.currentState?.validate();
          }
        });
        return _LoginView(
          loginError: viewModel.hasError ? viewModel.errorMessage : null,
          formKey: formKey,
        );
      },
    );
  }
}

class _LoginView extends StatefulWidget {
  final String? loginError;
  final GlobalKey<FormState> formKey;
  const _LoginView({this.loginError, required this.formKey});

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearLoginError);
    _passwordController.addListener(_clearLoginError);
  }

  void _clearLoginError() {
    // Solo limpiar el error si el usuario ya empezó a escribir después de un error
    if (widget.loginError != null && (_emailController.text.isNotEmpty || _passwordController.text.isNotEmpty)) {
      final viewModel = Provider.of<LoginViewModel>(context, listen: false);
      viewModel.clearError();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _LoginView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el error de login cambia y hay un error, forzar la validación del formulario
    if (widget.loginError != null && widget.loginError != oldWidget.loginError) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.formKey.currentState?.validate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightPastelBlue,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            height:
                MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top,
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 50),
                _buildFormCard(context),
                const Spacer(),
                _buildFooter(),
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
          appTitle,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          loginPanelTitle,
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
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
      child: Form(
        key: widget.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEmailField(),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 30),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      autofillHints: const [AutofillHints.email],
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return loginErrorEmptyEmail;
        }
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
          return loginErrorInvalidEmail;
        }
        if (widget.loginError != null) {
          // Mostrar mensaje de error también en el campo de correo
          return loginErrorInvalidCredentials;
        }
        return null;
      },
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
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      autofillHints: const [AutofillHints.password],
      textInputAction: TextInputAction.done,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return loginErrorEmptyPassword;
        }
        if (widget.loginError != null) {
          // Mostrar mensaje genérico si el login falló
          return loginErrorInvalidCredentials;
        }
        return null;
      },
      onFieldSubmitted: (_) => _handleLogin(),
      decoration: InputDecoration(
        labelText: loginPasswordLabel,
        labelStyle: const TextStyle(color: labelTextColor),
        floatingLabelStyle: const TextStyle(color: labelTextColor),
        prefixIcon: const Icon(Icons.lock_outline, color: accentBlue),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: accentBlue,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
          tooltip: _isPasswordVisible
              ? 'Ocultar contraseña'
              : 'Mostrar contraseña',
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
    );
  }

  Widget _buildSubmitButton() {
    return Consumer<LoginViewModel>(
      builder: (context, viewModel, child) {
        return ElevatedButton(
          onPressed: viewModel.isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
          ),
          child: viewModel.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text(
                  loginButtonText,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.hasData ? snapshot.data!.version : '1.0.0';
        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                '$appVersionPrefix ${version.isNotEmpty ? version : '1.0.0'}',
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleLogin() {
    if (widget.formKey.currentState?.validate() ?? false) {
      final viewModel = Provider.of<LoginViewModel>(context, listen: false);
      viewModel
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );
      // viewModel.clearError(); // Eliminar esta línea para que el error se muestre
    }
  }
}
