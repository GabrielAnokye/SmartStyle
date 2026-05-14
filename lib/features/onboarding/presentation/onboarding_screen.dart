import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smartstyle/features/onboarding/data/onboarding_repository.dart';
import 'package:permission_handler/permission_handler.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = <_OnboardPage>[
    _OnboardPage(
      icon: Icons.checkroom,
      title: 'Your closet, quantified.',
      body: 'SmartStyle tracks what you own, what you wear, and what\'s worth the shelf space.',
    ),
    _OnboardPage(
      icon: Icons.camera_alt_outlined,
      title: 'Snap to add.',
      body: 'Photograph an item once — we handle the background, colour, and category.',
      permission: _PrimerPermission.camera,
    ),
    _OnboardPage(
      icon: Icons.location_on_outlined,
      title: 'Outfits that match the weather.',
      body: 'Local forecast dials in warmth; you can set the city manually any time.',
      permission: _PrimerPermission.location,
    ),
    _OnboardPage(
      icon: Icons.event_available,
      title: 'A glance at your day.',
      body: 'With permission, we peek at today\'s calendar on-device to suggest work, workout, or casual looks. Nothing leaves your phone.',
      permission: _PrimerPermission.calendar,
    ),
    _OnboardPage(
      icon: Icons.auto_awesome,
      title: 'Ready when you are.',
      body: 'Add a few items to your closet and we\'ll start recommending outfits today.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish({bool goAdd = false}) async {
    await ref.read(onboardingProvider.notifier).complete();
    if (!mounted) return;
    context.go(goAdd ? '/add' : '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => _finish(),
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: _pages.length,
              itemBuilder: (_, i) => _pages[i],
            ),
          ),
          _Dots(count: _pages.length, current: _page),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                if (_page > 0)
                  TextButton(
                    onPressed: () => _controller.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOut,
                    ),
                    child: const Text('Back'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    if (isLast) {
                      _finish(goAdd: true);
                    } else {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    }
                  },
                  child: Text(isLast ? 'Add my first item' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _PrimerPermission { camera, location, calendar }

class _OnboardPage extends StatefulWidget {
  final IconData icon;
  final String title;
  final String body;
  final _PrimerPermission? permission;

  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.body,
    this.permission,
  });

  @override
  State<_OnboardPage> createState() => _OnboardPageState();
}

class _OnboardPageState extends State<_OnboardPage> {
  bool _requesting = false;
  bool _granted = false;

  Future<void> _request() async {
    if (widget.permission == null || _requesting || _granted) return;
    setState(() => _requesting = true);
    try {
      PermissionStatus status;
      switch (widget.permission!) {
        case _PrimerPermission.camera:
          status = await Permission.camera.request();
        case _PrimerPermission.location:
          status = await Permission.locationWhenInUse.request();
        case _PrimerPermission.calendar:
          // On iOS 17+ `calendarFullAccess` is the proper scope; older iOS
          // falls back to the legacy permission name under the hood.
          status = await Permission.calendarFullAccess.request();
      }
      setState(() => _granted = status.isGranted || status.isLimited);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icon, size: 96, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 32),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.body,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 15,
              height: 1.4,
            ),
          ),
          if (widget.permission != null) ...[
            const SizedBox(height: 28),
            FilledButton.tonalIcon(
              onPressed: _request,
              icon: _granted
                  ? const Icon(Icons.check)
                  : const Icon(Icons.lock_open_outlined),
              label: Text(_granted ? 'Allowed' : 'Allow'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int current;
  const _Dots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 20 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
