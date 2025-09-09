import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';
import '../constants.dart';

class MediaViewer extends StatefulWidget {
  final MessageModel message;

  const MediaViewer({super.key, required this.message});

  @override
  State<MediaViewer> createState() => _MediaViewerState();
}

class _MediaViewerState extends State<MediaViewer> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isPlaying = false;
  bool _showControls = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.message.isVideoMessage && widget.message.mediaUrl != null) {
      _initializeVideoPlayer();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.message.mediaUrl!),
    );

    await _videoController!.initialize();

    _videoController!.addListener(() {
      if (mounted) {
        setState(() {
          _isPlaying = _videoController!.value.isPlaying;
        });
      }
    });

    if (mounted) {
      setState(() {
        _isVideoInitialized = true;
      });
    }
  }

  void _togglePlayPause() {
    if (_videoController != null && _isVideoInitialized) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    }
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  Future<void> _saveToGallery() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Request storage permission
      if (!await Gal.hasAccess()) {
        final hasAccess = await Gal.requestAccess();
        if (!hasAccess) {
          _showSnackBar('Storage permission denied');
          return;
        }
      }

      // Download and save the media
      final response = await http.get(Uri.parse(widget.message.mediaUrl!));

      if (response.statusCode == 200) {
        // Save to gallery using Gal package
        await Gal.putImageBytes(
          response.bodyBytes,
          name:
              widget.message.fileName ??
              'chatkaro_media_${DateTime.now().millisecondsSinceEpoch}',
        );

        _showSnackBar('Media saved to gallery');
      } else {
        _showSnackBar('Failed to download media');
      }
    } catch (e) {
      _showSnackBar('Error saving media: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.message.fileName ?? 'Media',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveToGallery,
            icon:
                _isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Icon(Icons.download, color: Colors.white),
          ),
        ],
      ),
      body:
          widget.message.isImageMessage
              ? _buildImageViewer()
              : widget.message.isVideoMessage
              ? _buildVideoViewer()
              : const Center(
                child: Text(
                  'Unsupported media type',
                  style: TextStyle(color: Colors.white),
                ),
              ),
    );
  }

  Widget _buildImageViewer() {
    return PhotoView(
      imageProvider: CachedNetworkImageProvider(widget.message.mediaUrl!),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      heroAttributes: PhotoViewHeroAttributes(tag: widget.message.id),
      loadingBuilder:
          (context, event) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
      errorBuilder:
          (context, error, stackTrace) => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.white, size: 64),
                SizedBox(height: 16),
                Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildVideoViewer() {
    if (!_isVideoInitialized || _videoController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
          if (_showControls) _buildVideoControls(),
        ],
      ),
    );
  }

  Widget _buildVideoControls() {
    return Positioned.fill(
      child: Container(
        color: Colors.black26,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Play/Pause button
            GestureDetector(
              onTap: _togglePlayPause,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const Spacer(),
            // Video progress bar
            Container(
              margin: const EdgeInsets.all(16),
              child: VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: AppColors.primaryBlue,
                  bufferedColor: Colors.grey,
                  backgroundColor: Colors.white24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
