import 'package:flutter/material.dart';
import 'package:vhsfin/constants/theme.dart';

/// Dumb connect form — page owns controllers and submit.
class ConnectView extends StatelessWidget {
  const ConnectView({
    super.key,
    required this.serverController,
    required this.userController,
    required this.passwordController,
    required this.busy,
    required this.onSubmit,
    required this.onBack,
    this.error,
  });

  final TextEditingController serverController;
  final TextEditingController userController;
  final TextEditingController passwordController;
  final bool busy;
  final String? error;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONNECT'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [VhsColors.woodMid, VhsColors.woodDeep],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('JELLYFIN', style: vhsBrandStyle(size: 28)),
                  const SizedBox(height: 8),
                  Text(
                    'Point VHSFin at your server. Keep the kids account simple.',
                    style: TextStyle(
                      color: VhsColors.brand.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: serverController,
                    decoration: const InputDecoration(
                      labelText: 'Server URL',
                      hintText: 'http://jellyfin.local:8096',
                    ),
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: userController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    onSubmitted: (_) => onSubmit(),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      style: const TextStyle(color: VhsColors.accent),
                    ),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: busy ? null : onSubmit,
                    child: Text(busy ? 'TUNING…' : 'POWER ON'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
