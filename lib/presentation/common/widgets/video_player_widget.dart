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

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    try {
      final uri = Uri.parse(widget.videoUrl);
      if (widget.videoUrl.startsWith('http')) {
        _controller = VideoPlayerController.networkUrl(uri);
      } else if (kIsWeb) {
        // En Web no se puede usar File de dart:io
        setState(() {
          _hasError = true;
        });
        return;
      } else {
        _controller = VideoPlayerController.file(File(widget.videoUrl));
      }

      _controller!.initialize().then((_) {
        if (mounted) {
          _controller!.addListener(_videoListener);
          setState(() {
            _isInitialized = true;
          });
          _controller!.setLooping(true);
          _controller!.setVolume(widget.isMuted ? 0.0 : 1.0);
          _controller!.play();
        }
      }).catchError((error) {
        debugPrint('VideoPlayer error: $error');
        if (mounted) {
          setState(() {
            _hasError = true;
          });
        }
      });
    } catch (e) {
      debugPrint('VideoPlayer initialization error: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      if (_controller != null) {
        _controller!.removeListener(_videoListener);
        _controller!.dispose();
      }
      _isInitialized = false;
      _hasError = false;
      _initController();
    }
  }

  @override
  void dispose() {
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      _controller!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _controller == null) {
      return const SizedBox.shrink(); // Fallback so image layer can show
    }
    if (_isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      );
    } else {
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
  }
}

