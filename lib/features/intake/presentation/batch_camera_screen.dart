import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smartstyle/features/intake/domain/intake_draft.dart';
import 'package:smartstyle/features/intake/presentation/review_deck_screen.dart';
import 'package:uuid/uuid.dart';

class BatchCameraScreen extends ConsumerStatefulWidget {
  const BatchCameraScreen({super.key});

  @override
  ConsumerState<BatchCameraScreen> createState() => _BatchCameraScreenState();
}

class _BatchCameraScreenState extends ConsumerState<BatchCameraScreen> {
  CameraController? _controller;
  Future<void>? _initFuture;
  final List<IntakeDraft> _drafts = [];
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initFuture = _init();
  }

  Future<void> _init() async {
    try {
      final cams = await availableCameras();
      if (cams.isEmpty) {
        setState(() => _error = 'No camera available on this device.');
        return;
      }
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      final ctrl = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await ctrl.initialize();
      if (!mounted) return;
      setState(() => _controller = ctrl);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Camera failed: $e');
    }
  }

  Future<void> _capture() async {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized || _busy) return;
    setState(() => _busy = true);
    try {
      final file = await ctrl.takePicture();
      final dir = await getTemporaryDirectory();
      final id = const Uuid().v4();
      final stable = File('${dir.path}/capture_$id.jpg');
      await File(file.path).copy(stable.path);
      _drafts.add(IntakeDraft(id: id, rawImagePath: stable.path));
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _removeLast() {
    if (_drafts.isEmpty) return;
    setState(() => _drafts.removeLast());
  }

  void _done() {
    if (_drafts.isEmpty) {
      context.pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ReviewDeckScreen(drafts: _drafts)),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Batch Camera')),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!))),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Batch (${_drafts.length})'),
        actions: [
          TextButton(
            onPressed: _drafts.isEmpty ? null : _done,
            child: const Text('Done', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _initFuture,
        builder: (context, snap) {
          if (_controller == null || !_controller!.value.isInitialized) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Expanded(child: CameraPreview(_controller!)),
              Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  children: [
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _drafts.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final d = _drafts[i];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(File(d.rawImagePath), width: 72, height: 72, fit: BoxFit.cover),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.undo, color: Colors.white),
                          onPressed: _drafts.isEmpty ? null : _removeLast,
                        ),
                        GestureDetector(
                          onTap: _capture,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: Colors.grey, width: 4),
                            ),
                            child: _busy
                                ? const Padding(
                                    padding: EdgeInsets.all(18),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : null,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.white),
                          onPressed: _drafts.isEmpty ? null : _done,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
