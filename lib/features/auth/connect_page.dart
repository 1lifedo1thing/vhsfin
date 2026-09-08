import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vhsfin/features/auth/state/session_notifier.dart';
import 'package:vhsfin/features/auth/views/connect_view.dart';
import 'package:vhsfin/features/library/state/tape_library.dart';
import 'package:vhsfin/user_facing_error.dart';

class ConnectPage extends ConsumerStatefulWidget {
  const ConnectPage({super.key});

  @override
  ConsumerState<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends ConsumerState<ConnectPage> {
  final _serverController = TextEditingController();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _serverController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(sessionProvider.notifier)
          .signIn(
            serverUrl: _serverController.text,
            username: _userController.text,
            password: _passwordController.text,
          );
      ref.invalidate(shelvesProvider);
      ref.invalidate(librariesProvider);
      if (mounted) context.go('/libraries');
    } catch (error) {
      setState(() => _error = userFacingError(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ConnectView(
      serverController: _serverController,
      userController: _userController,
      passwordController: _passwordController,
      busy: _busy,
      error: _error,
      onSubmit: _submit,
      onBack: () => context.pop(),
    );
  }
}
