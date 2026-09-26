import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vhsfin/features/auth/model/server_address.dart';
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
  void initState() {
    super.initState();
    final session = ref.read(sessionProvider).value;
    _serverController.text = session?.serverUrl ?? '';
    _userController.text = session?.userName ?? '';
  }

  @override
  void dispose() {
    _serverController.dispose();
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final candidates = serverAddressCandidates(
        _serverController.text,
        httpsOnly: kIsWeb && Uri.base.scheme == 'https',
      );
      for (var i = 0; i < candidates.length; i++) {
        try {
          await ref
              .read(sessionProvider.notifier)
              .signIn(
                serverUrl: candidates[i],
                username: _userController.text.trim(),
                password: _passwordController.text,
              );
          break;
        } on DioException catch (error) {
          // Only move on when nothing answered; a reply (like a wrong
          // password) means this address is the server.
          final unreachable = error.response == null;
          if (!unreachable || i == candidates.length - 1) rethrow;
        }
      }
      if (!mounted) return;
      TextInput.finishAutofillContext();
      ref.invalidate(shelvesProvider);
      ref.invalidate(librariesProvider);
      if (mounted) context.go('/libraries');
    } catch (error) {
      if (mounted) setState(() => _error = userFacingError(error));
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
      onBack: () => context.canPop() ? context.pop() : context.go('/'),
    );
  }
}
