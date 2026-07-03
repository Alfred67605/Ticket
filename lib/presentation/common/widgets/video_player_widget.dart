import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import '../../../core/constants/app_colors.dart';

/// Widget que muestra un overlay con botón de play sobre la imagen del evento.
/// Al tocar play, abre un reproductor de video en pantalla completa aislado
/// del árbol de widgets principal para evitar crashes de null-check en MediaTek.
class VideoPlayerWidget extends StatelessWidget {
  final String videoUrl;
  final bool isMuted;

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.isMuted = true,
  });

  @override
  Widget build(BuildContext context) {
    if (videoUrl.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => _FullscreenVideoPlayer(videoUrl: videoUrl),
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }
}

/// Reproductor de video en pantalla completa, aislado del árbol principal.
class _FullscreenVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const _FullscreenVideoPlayer({required this.videoUrl});

  @override
  State<_FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<_FullscreenVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    try {
      if (widget.videoUrl.startsWith('http')) {
        final uri = Uri.parse(widget.videoUrl);
        _controller = VideoPlayerController.networkUrl(uri);
      } else if (kIsWeb) {
        setState(() => _hasError = true);
        return;
      } else {
        final file = File(widget.videoUrl);
        if (!file.existsSync()) {
          setState(() => _hasError = true);
          return;
        }
        _controller = VideoPlayerController.file(file);
      }

      _controller!.initialize().then((_) {
        if (!mounted) return;
        _controller!.setLooping(true);
        _controller!.setVolume(1.0);
        _controller!.play();
        setState(() => _isInitialized = true);
      }).catchError((error) {
        debugPrint('VideoPlayer error: $error');
        if (mounted) setState(() => _hasError = true);
      });
    } catch (e) {
      debugPrint('VideoPlayer init error: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  void dispose() {
    try { _controller?.dispose(); } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            // Video
            if (_isInitialized && _controller != null)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio > 0
                      ? _controller!.value.aspectRatio
                      : 16 / 9,
                  child: VideoPlayer(_controller!),
                ),
              ),

            // Loading
            if (!_isInitialized && !_hasError)
              const Center(
                child: CircularProgressIndicator(color: AppColors.primaryLight),
              ),

            // Error
            if (_hasError)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white54, size: 48),
                    const SizedBox(height: 12),
                    const Text(
                      'No se pudo cargar el video',
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Volver'),
                    ),
                  ],
                ),
              ),

            // Controles
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
                        ),
                        const Spacer(),
                        if (_isInitialized && _controller != null)
                          IconButton(
                            onPressed: () {
                              setState(() {
                                if (_controller!.value.isPlaying) {
                                  _controller!.pause();
                                } else {
                                  _controller!.play();
                                }
                              });
                            },
                            icon: Icon(
                              _controller!.value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
