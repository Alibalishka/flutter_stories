import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/story_item.dart';
import '../story_presenter/story_view.dart';
import '../utils/story_utils.dart';
import '../utils/video_utils.dart';

/// A widget that displays a video story view, supporting different video sources
/// (network, file, asset) and optional thumbnail and error widgets.
class VideoStoryView extends StatefulWidget {
  final StoryItem storyItem;
  final OnVideoLoad? onVideoLoad;
  final bool? looping;

  const VideoStoryView({
    required this.storyItem,
    this.onVideoLoad,
    this.looping,
    super.key,
  });

  @override
  State<VideoStoryView> createState() => _VideoStoryViewState();
}

class _VideoStoryViewState extends State<VideoStoryView> {
  VideoPlayerController? videoPlayerController;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      final storyItem = widget.storyItem;

      if (storyItem.storyItemSource.isNetwork) {
        videoPlayerController =
            await VideoUtils.instance.videoControllerFromUrl(
          url: storyItem.url!,
          cacheFile: storyItem.videoConfig?.cacheVideo,
          videoPlayerOptions: storyItem.videoConfig?.videoPlayerOptions,
        );
      } else if (storyItem.storyItemSource.isFile) {
        videoPlayerController = VideoUtils.instance.videoControllerFromFile(
          file: File(storyItem.url!),
          videoPlayerOptions: storyItem.videoConfig?.videoPlayerOptions,
        );
      } else {
        videoPlayerController = VideoUtils.instance.videoControllerFromAsset(
          assetPath: storyItem.url!,
          videoPlayerOptions: storyItem.videoConfig?.videoPlayerOptions,
        );
      }

      await videoPlayerController?.initialize();

      await videoPlayerController?.setLooping(widget.looping ?? false);
      await videoPlayerController?.setVolume(storyItem.isMuteByDefault ? 0 : 1);

      if (!mounted) return;

      widget.onVideoLoad?.call(videoPlayerController!);
      await videoPlayerController?.play();
    } catch (e, stack) {
      debugPrint('Video initialization error: $e\n$stack');
      if (mounted) {
        setState(() => hasError = true);
      }
    }

    if (mounted) {
      setState(() {}); // Обновляем состояние только если виджет еще на экране
    }
  }

  @override
  void dispose() {
    videoPlayerController?.dispose();
    super.dispose();
  }

  BoxFit get _fit => widget.storyItem.videoConfig?.fit ?? BoxFit.cover;

  Widget _buildVideoPlayer() {
    if (videoPlayerController == null ||
        !videoPlayerController!.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final config = widget.storyItem.videoConfig;
    final useAspectRatio = config?.useVideoAspectRatio ?? false;

    if (useAspectRatio) {
      return AspectRatio(
        aspectRatio: videoPlayerController!.value.aspectRatio,
        child: VideoPlayer(videoPlayerController!),
      );
    } else {
      return ClipRect(
        child: FittedBox(
          fit: _fit,
          alignment: Alignment.center,
          child: SizedBox(
            width: videoPlayerController!.value.size.width,
            height: videoPlayerController!.value.size.height,
            child: VideoPlayer(videoPlayerController!),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.storyItem.videoConfig;
    final padding = MediaQuery.of(context).padding;

    return Padding(
      padding: EdgeInsets.only(
        left: padding.left,
        right: padding.right,
        top: config?.safeAreaTop == true ? padding.top : 0,
        bottom: 0,
      ).add(config?.padding ?? EdgeInsets.zero),
      child: Padding(
        padding: config?.padding ?? EdgeInsets.zero,
        child: Stack(
          alignment:
              (_fit == BoxFit.cover) ? Alignment.topCenter : Alignment.center,
          fit: (_fit == BoxFit.cover) ? StackFit.expand : StackFit.loose,
          children: [
            if (config?.loadingWidget != null)
              config!.loadingWidget!
            else if (widget.storyItem.thumbnail != null)
              widget.storyItem.thumbnail!,
            if (hasError && widget.storyItem.errorWidget != null)
              widget.storyItem.errorWidget!,
            _buildVideoPlayer(),
          ],
        ),
      ),
    );
  }
}

// class VideoStoryView extends StatefulWidget {
//   /// The story item containing video data and configuration.
//   final StoryItem storyItem;

//   /// Callback function to notify when the video is loaded.
//   final OnVideoLoad? onVideoLoad;

//   /// In case of single video story
//   final bool? looping;

//   /// Creates a [VideoStoryView] widget.
//   const VideoStoryView({
//     required this.storyItem,
//     this.onVideoLoad,
//     this.looping,
//     super.key,
//   });

//   @override
//   State<VideoStoryView> createState() => _VideoStoryViewState();
// }

// class _VideoStoryViewState extends State<VideoStoryView> {
//   VideoPlayerController? videoPlayerController;
//   bool hasError = false;

//   @override
//   void initState() {
//     _initialiseVideoPlayer();
//     super.initState();
//   }

//   /// Initializes the video player controller based on the source of the video.
//   Future<void> _initialiseVideoPlayer() async {
//     try {
//       final storyItem = widget.storyItem;
//       if (storyItem.storyItemSource.isNetwork) {
//         // Initialize video controller for network source.
//         videoPlayerController =
//             await VideoUtils.instance.videoControllerFromUrl(
//           url: storyItem.url!,
//           cacheFile: storyItem.videoConfig?.cacheVideo,
//           videoPlayerOptions: storyItem.videoConfig?.videoPlayerOptions,
//         );
//       } else if (storyItem.storyItemSource.isFile) {
//         // Initialize video controller for file source.
//         videoPlayerController = VideoUtils.instance.videoControllerFromFile(
//           file: File(storyItem.url!),
//           videoPlayerOptions: storyItem.videoConfig?.videoPlayerOptions,
//         );
//       } else {
//         // Initialize video controller for asset source.
//         videoPlayerController = VideoUtils.instance.videoControllerFromAsset(
//           assetPath: storyItem.url!,
//           videoPlayerOptions: storyItem.videoConfig?.videoPlayerOptions,
//         );
//       }
//       await videoPlayerController?.initialize();
//       widget.onVideoLoad?.call(videoPlayerController!);
//       await videoPlayerController?.play();
//       await videoPlayerController?.setLooping(widget.looping ?? false);
//       await videoPlayerController?.setVolume(storyItem.isMuteByDefault ? 0 : 1);
//     } catch (e) {
//       hasError = true;
//       debugPrint('$e');
//     }
//     setState(() {});
//   }

//   BoxFit get fit => widget.storyItem.videoConfig?.fit ?? BoxFit.cover;

//   @override
//   void dispose() {
//     videoPlayerController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       top: widget.storyItem.videoConfig?.safeAreaTop ?? false,
//       bottom: true,
//       // widget.storyItem.videoConfig?.safeAreaBottom ?? false,
//       left: true,
//       right: true,
//       child: Padding(
//         padding: widget.storyItem.videoConfig?.padding ?? EdgeInsets.zero,
//         child: Stack(
//           alignment:
//               (fit == BoxFit.cover) ? Alignment.topCenter : Alignment.center,
//           fit: (fit == BoxFit.cover) ? StackFit.expand : StackFit.loose,
//           children: [
//             if (widget.storyItem.videoConfig?.loadingWidget != null) ...{
//               widget.storyItem.videoConfig!.loadingWidget!,
//             } else if (widget.storyItem.thumbnail != null) ...{
//               // Display the thumbnail if provided.
//               widget.storyItem.thumbnail!,
//             },
//             if (widget.storyItem.errorWidget != null && hasError) ...{
//               // Display the error widget if an error occurred.
//               widget.storyItem.errorWidget!,
//             },
//             if (videoPlayerController != null) ...{
//               if (widget.storyItem.videoConfig?.useVideoAspectRatio ??
//                   false) ...{
//                 // Display the video with aspect ratio if specified.
//                 AspectRatio(
//                   aspectRatio: videoPlayerController!.value.aspectRatio,
//                   child: VideoPlayer(
//                     videoPlayerController!,
//                   ),
//                 )
//               } else ...{
//                 // Display the video fitted to the screen.
//                 FittedBox(
//                   fit: widget.storyItem.videoConfig?.fit ?? BoxFit.cover,
//                   alignment: Alignment.center,
//                   child: SizedBox(
//                     width: widget.storyItem.videoConfig?.width ??
//                         videoPlayerController!.value.size.width,
//                     height: widget.storyItem.videoConfig?.height ??
//                         videoPlayerController!.value.size.height,
//                     child: VideoPlayer(videoPlayerController!),
//                   ),
//                 )
//               },
//             }
//           ],
//         ),
//       ),
//     );
//   }
// }
