import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:breakpoint/presentation/login/viewmodel/auth_viewmodel.dart';
import 'package:breakpoint/routes/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;

  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _regEmailCtrl = TextEditingController();
  final TextEditingController _regPassCtrl = TextEditingController();
  final TextEditingController _regPass2Ctrl = TextEditingController();

  InputDecoration _inputStyle(String label, {String? hint}) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black54, width: 1),
        ),
      );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _regEmailCtrl.dispose();
    _regPassCtrl.dispose();
    _regPass2Ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F2FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          _isLogin ? 'Inicio de sesión' : 'Crear cuenta',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _TogglePill(
                      label: 'Login',
                      selected: _isLogin,
                      onTap: () => setState(() => _isLogin = true),
                    ),
                    _TogglePill(
                      label: 'Register',
                      selected: !_isLogin,
                      onTap: () => setState(() => _isLogin = false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isLogin
                  ? _LoginForm(
                      formKey: _loginFormKey,
                      vm: vm,
                      inputStyle: _inputStyle,
                    )
                  : _RegisterForm(
                      formKey: _registerFormKey,
                      nameCtrl: _nameCtrl,
                      emailCtrl: _regEmailCtrl,
                      passCtrl: _regPassCtrl,
                      pass2Ctrl: _regPass2Ctrl,
                      inputStyle: _inputStyle,
                      onSubmit: _onRegister,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Acción de “Crear cuenta”: ahora redirige según rol
  Future<void> _onRegister(String roleValue) async {
    if (!_registerFormKey.currentState!.validate()) return;

    final vm = context.read<AuthViewModel>();

    final ok = await vm.register(
      email: _regEmailCtrl.text.trim(),
      password: _regPassCtrl.text,
      role: roleValue,
      name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      autoLogin: true,
    );

    if (ok && context.mounted) {
      // 🔹 Redirección según el rol
      if (roleValue == 'Host') {
        Navigator.pushReplacementNamed(context, AppRouter.hostSpaces);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.explore);
      }
    } else {
      if (!mounted) return;
      final msg = vm.errorMessage ?? 'Error al registrar usuario';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }
}

class _TogglePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TogglePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF5C1B6C) : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Formulario de Login
class _LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final AuthViewModel vm;
  final InputDecoration Function(String label, {String? hint}) inputStyle;

  const _LoginForm({
    required this.formKey,
    required this.vm,
    required this.inputStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Usuario', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: vm.emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: inputStyle('Ingresa tu usuario'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),

          const Text('Contraseña', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: vm.passCtrl,
            obscureText: true,
            decoration: inputStyle('Ingresa tu contraseña'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 20),

          if (vm.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                vm.errorMessage!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: vm.isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final ok = await vm.login();

                      if (ok && context.mounted) {
                        final role = vm.userRole ?? 'Student';
                        // 🔹 Redirección según rol al iniciar sesión
                        if (role == 'Host') {
                          Navigator.pushReplacementNamed(
                              context, AppRouter.hostSpaces);
                        } else {
                          Navigator.pushReplacementNamed(
                              context, AppRouter.explore);
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(vm.errorMessage ??
                                'Error de inicio de sesión'),
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C1B6C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: vm.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Iniciar sesión',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Formulario de Register con selector de Rol
class _RegisterForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController pass2Ctrl;
  final InputDecoration Function(String label, {String? hint}) inputStyle;
  final void Function(String roleValue) onSubmit;

  const _RegisterForm({
    required this.formKey,
    required this.nameCtrl,
    required this.emailCtrl,
    required this.passCtrl,
    required this.pass2Ctrl,
    required this.inputStyle,
    required this.onSubmit,
    super.key,
  });

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  String _roleValue = 'Student';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nombre', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: widget.nameCtrl,
            decoration: widget.inputStyle('Tu nombre'),
          ),
          const SizedBox(height: 16),

          const Text('Email', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: widget.emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: widget.inputStyle('Ingresa tu email'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Requerido';
              return null;
            },
          ),
          const SizedBox(height: 16),

          const Text('Contraseña', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: widget.passCtrl,
            obscureText: true,
            decoration: widget.inputStyle('Ingresa tu contraseña'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Requerido' : null,
          ),
          const SizedBox(height: 16),

          const Text('Confirmar contraseña', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: widget.pass2Ctrl,
            obscureText: true,
            decoration: widget.inputStyle('Repite tu contraseña'),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Requerido';
              if (v != widget.passCtrl.text) return 'No coincide';
              return null;
            },
          ),
          const SizedBox(height: 16),

          const Text('Rol', style: TextStyle(fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _roleValue,
            decoration: widget.inputStyle('Selecciona tu rol'),
            items: const [
              DropdownMenuItem(value: 'Student', child: Text('Estudiante')),
              DropdownMenuItem(value: 'Host', child: Text('Arrendador')),
            ],
            onChanged: (v) => setState(() => _roleValue = v ?? 'Student'),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 48,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (!widget.formKey.currentState!.validate()) return;
                widget.onSubmit(_roleValue);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C1B6C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                elevation: 0,
              ),
              child: const Text('Crear cuenta',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
