import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MediaPreviewWidget extends StatefulWidget {
  final String type;
  final String url;

  const MediaPreviewWidget({
    super.key,
    required this.type,
    required this.url,
  });

  @override
  State<MediaPreviewWidget> createState() => _MediaPreviewWidgetState();
}

class _MediaPreviewWidgetState extends State<MediaPreviewWidget> {
  VideoPlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();

    if (widget.type == 'video') {
      _videoController = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
      )..initialize().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.url,
          width: 220,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: 220,
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Image load failed'),
            );
          },
        ),
      );
    }

    if (widget.type == 'video') {
      if (_videoController == null || !_videoController!.value.isInitialized) {
        return const SizedBox(
          height: 180,
          child: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      return SizedBox(
        width: 220,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: VideoPlayer(_videoController!),
              ),
            ),
            const SizedBox(height: 6),
            IconButton(
              onPressed: () {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
                setState(() {});
              },
              icon: Icon(
                _videoController!.value.isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.type == 'audio') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black12,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () async {
                if (isPlaying) {
                  await _audioPlayer.stop();
                  setState(() => isPlaying = false);
                } else {
                  await _audioPlayer.play(UrlSource(widget.url));
                  setState(() => isPlaying = true);
                }
              },
              icon: Icon(
                isPlaying ? Icons.stop : Icons.play_arrow,
              ),
            ),
            const Text('Audio message'),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}