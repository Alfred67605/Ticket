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
        if (mounted) setState(() => _hasError = true);
        return;
      }

      if (widget.videoUrl.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
      } else if (kIsWeb) {
        if (mounted) setState(() => _hasError = true);
        return;
      } else {
        final file = File(widget.videoUrl);
        if (!file.existsSync()) {
          debugPrint('VideoPlayer: file does not exist: ${widget.videoUrl}');
          if (mounted) setState(() => _hasError = true);
          return;
        }
        _controller = VideoPlayerController.file(file);
      }

      _controller!.initialize().then((_) {
        if (!mounted || _disposed) return;
        
        _controller!.setLooping(true);
        _controller!.setVolume(widget.isMuted ? 0.0 : 1.0);
        _controller!.play();
        
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
      if (mounted) setState(() => _hasError = true);
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
    } else if (oldWidget.isMuted != widget.isMuted) {
      _controller?.setVolume(widget.isMuted ? 0.0 : 1.0);
    }
  }

  void _disposeController() {
    final c = _controller;
    _controller = null;
    if (c != null) {
      try {
        c.pause();
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

    if (!_isInitialized || _controller == null) {
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

    final size = _controller!.value.size;
    final hasValidSize = size.width > 0 && size.height > 0;

    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: hasValidSize ? size.width : 160,
          height: hasValidSize ? size.height : 100,
          child: VideoPlayer(_controller!),
        ),
      ),
    );
  }
}
