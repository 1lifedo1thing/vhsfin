import 'package:flutter/material.dart';
import 'package:vhsfin/constants/feedback.dart';
import 'package:vhsfin/constants/theme.dart';
import 'package:vhsfin/features/auth/model/server_address.dart';
import 'package:vhsfin/features/living_room/widgets/deck_panel.dart';

/// Local form state stays in the view; the page owns authentication.
class ConnectView extends StatefulWidget {
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
  State<ConnectView> createState() => _ConnectViewState();
}

class _ConnectViewState extends State<ConnectView> {
  final _formKey = GlobalKey<FormState>();
  bool _showPassword = false;

  void _submit() {
    if (widget.busy || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VhsColors.room,
      appBar: AppBar(
        title: const Text('WELCOME HOME'),
        leading: IconButton(
          tooltip: 'Back to the living room',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: widget.busy
              ? null
              : () {
                  DeckFeedback.tap();
                  widget.onBack();
                },
        ),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.65),
            radius: 1.3,
            colors: [VhsColors.roomGlow, VhsColors.room, Color(0xFF030404)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                child: AutofillGroup(
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: VhsBrandIcon(size: 112)),
                        const SizedBox(height: 20),
                        Text(
                          'MOVIE NIGHT,\nREWOUND.',
                          textAlign: TextAlign.center,
                          style: vhsBrandStyle(size: 30),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your favorites. A shelf full of tapes. Just press play.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: VhsColors.ink.withValues(alpha: 0.72),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 26),
                        const Row(
                          children: [
                            _SetupStep(
                              number: '01',
                              label: 'CONNECT',
                              active: true,
                            ),
                            SizedBox(width: 12),
                            _SetupStep(number: '02', label: 'PICK SHELVES'),
                            SizedBox(width: 12),
                            _SetupStep(number: '03', label: 'PLAY'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        DeckPanel(
                          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Connect your Jellyfin',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Sign in with an existing Jellyfin account.\nYour server brings the movies; we bring the nostalgia.',
                                style: TextStyle(
                                  color: VhsColors.ink.withValues(alpha: 0.65),
                                  height: 1.5,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 22),
                              TextFormField(
                                controller: widget.serverController,
                                enabled: !widget.busy,
                                decoration: const InputDecoration(
                                  labelText: 'Server address',
                                  hintText: 'jellyfin.local:8096',
                                  prefixIcon: Icon(Icons.dns_outlined),
                                  helperText: 'Name or IP and port — https:// is tried first',
                                  errorMaxLines: 3,
                                ),
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                enableSuggestions: false,
                                validator: (value) {
                                  try {
                                    serverAddressCandidates(value ?? '');
                                    return null;
                                  } on FormatException catch (error) {
                                    return error.message;
                                  }
                                },
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: widget.userController,
                                enabled: !widget.busy,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                  ),
                                ),
                                autofillHints: const [AutofillHints.username],
                                autocorrect: false,
                                enableSuggestions: false,
                                textInputAction: TextInputAction.next,
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Enter your Jellyfin username.'
                                    : null,
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: widget.passwordController,
                                enabled: !widget.busy,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                  ),
                                  suffixIcon: IconButton(
                                    tooltip: _showPassword
                                        ? 'Hide password'
                                        : 'Show password',
                                    onPressed: () {
                                      DeckFeedback.tap();
                                      setState(
                                        () => _showPassword = !_showPassword,
                                      );
                                    },
                                    icon: Icon(
                                      _showPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                autofillHints: const [AutofillHints.password],
                                autocorrect: false,
                                enableSuggestions: false,
                                obscureText: !_showPassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              if (widget.error != null) ...[
                                const SizedBox(height: 18),
                                Semantics(
                                  liveRegion: true,
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: VhsColors.recordWash,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      widget.error!,
                                      style: const TextStyle(
                                        color: Color(0xFFFFC4AF),
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 22),
                              DeckHardKey(
                                tone: DeckKeyTone.record,
                                label: widget.busy
                                    ? 'CONNECTING…'
                                    : 'CONNECT & CHOOSE SHELVES',
                                onPressed: widget.busy ? null : _submit,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _ConnectionHelp(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.number,
    required this.label,
    this.active = false,
  });
  final String number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 2,
          color: active
              ? VhsColors.accent
              : VhsColors.ink.withValues(alpha: 0.16),
        ),
        const SizedBox(height: 8),
        Text(
          '$number  $label',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: active
                ? VhsColors.accent
                : VhsColors.ink.withValues(alpha: 0.5),
          ),
        ),
      ],
    ),
  );
}

class _ConnectionHelp extends StatelessWidget {
  const _ConnectionHelp();

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
    child: ExpansionTile(
      onExpansionChanged: (_) => DeckFeedback.tap(),
      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
      title: const Text(
        'First time here?',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      leading: const Icon(Icons.help_outline_rounded, size: 20),
      childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
      children: [
        const Text(
          'VHSFin plays the movies and shows on your own Jellyfin server. '
          'It does not include movies or create Jellyfin accounts. Ask the person who manages your server for its address and your login.\n\n'
          'At home, join the same Wi-Fi as your server. Use the server’s base address, not a /web page. '
          'A browser opened over HTTPS also needs an HTTPS server.\n\n'
          'For little viewers, use a Jellyfin account with access only to their libraries. '
          'Shelf selection is a display preference, not a parental lock.',
          style: TextStyle(fontSize: 13, height: 1.6, color: VhsColors.ink),
        ),
      ],
    ),
  );
}
