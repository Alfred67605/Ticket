import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool isMuted;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.isMuted = true,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    try {
      if (widget.videoUrl.isEmpty) {
        _hasError = true;
        return;
      }

      if (widget.videoUrl.startsWith('http')) {
        final uri = Uri.parse(widget.videoUrl);
        _controller = VideoPlayerController.networkUrl(uri);
      } else if (kIsWeb) {
        _hasError = true;
        return;
      } else {
        final file = File(widget.videoUrl);
        if (!file.existsSync()) {
          debugPrint('VideoPlayer: archivo no existe: ${widget.videoUrl}');
          _hasError = true;
          return;
        }
        _controller = VideoPlayerController.file(file);
      }

      _controller!.addListener(_onControllerUpdate);

      _controller!.initialize().then((_) {
        if (!mounted || _disposed) return;
        setState(() {
          _isInitialized = true;
        });
        _controller?.setLooping(true);
        _controller?.setVolume(widget.isMuted ? 0.0 : 1.0);
        _controller?.play();
      }).catchError((error) {
        debugPrint('VideoPlayer init error: $error');
        if (mounted && !_disposed) {
          setState(() {
            _hasError = true;
          });
        }
      });
    } catch (e) {
      debugPrint('VideoPlayer initialization error: $e');
      _hasError = true;
    }
  }

  void _onControllerUpdate() {
    // Solo rebuild si montado y no disposed
    if (mounted && !_disposed) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _isInitialized = false;
      _hasError = false;
      _initController();
    }
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    if (c != null) {
      try {
        c.removeListener(_onControllerUpdate);
        c.dispose();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return const SizedBox.shrink();
    }

    final controller = _controller;
    if (controller == null || !_isInitialized) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            color: AppColors.primaryLight,
          ),
        ),
      );
    }

    try {
      final size = controller.value.size;
      final hasValidSize = size.width > 0 && size.height > 0;

      if (hasValidSize) {
        // Usar FittedBox con las dimensiones reales del video
        return SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: VideoPlayer(controller),
            ),
          ),
        );
      } else {
        // Tamaño aún no disponible: renderizar directamente sin FittedBox
        return SizedBox.expand(
          child: VideoPlayer(controller),
        );
      }
    } catch (e) {
      debugPrint('VideoPlayer build error: $e');
      return const SizedBox.shrink();
    }
  }
}
