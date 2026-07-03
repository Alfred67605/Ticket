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

      _controller!.initialize().then((_) {
        if (!mounted || _disposed) return;
        _controller?.setLooping(true);
        _controller?.setVolume(widget.isMuted ? 0.0 : 1.0);
        _controller?.play();
        setState(() {
          _isInitialized = true;
        });
      }).catchError((error) {
        debugPrint('VideoPlayer init error: $error');
        if (mounted && !_disposed) {
          setState(() => _hasError = true);
        }
      });
    } catch (e) {
      debugPrint('VideoPlayer initialization error: $e');
      _hasError = true;
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
      try { c.dispose(); } catch (_) {}
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

    // Usar Texture directamente en vez del widget VideoPlayer del paquete
    // para evitar el crash interno "Null check operator used on a null value"
    // que ocurre en chipsets MediaTek dentro de _VideoPlayerWithRotation.
    final textureId = controller.textureId;
    if (textureId == null) {
      return const SizedBox.shrink();
    }

    return SizedBox.expand(
      child: ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.size.width > 0
                ? controller.value.size.width
                : MediaQuery.of(context).size.width,
            height: controller.value.size.height > 0
                ? controller.value.size.height
                : MediaQuery.of(context).size.height,
            child: Texture(textureId: textureId),
          ),
        ),
      ),
    );
  }
}
