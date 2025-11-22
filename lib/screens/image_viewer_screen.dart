import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_view/photo_view.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/constants.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class ImageViewerScreen extends StatelessWidget {
  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
    this.imageName,
  });

  final String imageUrl;
  final String? imageName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          imageName ?? 'Image',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () async {
              try {
                final dir = await StorageService.getDownloadDirectory();
                final fileName = imageName ?? 'image.jpg';
                final savePath = '${dir.path}/$fileName';
                
                // Use API service for download (handles both ESP32 and cloud)
                final apiService = ApiService();
                await apiService.downloadFile(imageUrl, savePath);
                
                if (!context.mounted) return;
                
                // Share the file
                await Share.shareXFiles(
                  [XFile(savePath)],
                  text: imageName ?? 'Shared image',
                );
              } catch (e) {
                debugPrint('Share image error: $e');
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Share failed: ${e.toString()}')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download',
            onPressed: () async {
              try {
                final dir = await StorageService.getDownloadDirectory();
                final fileName = imageName ?? 'image.jpg';
                final savePath = '${dir.path}/$fileName';
                
                // Use API service for download (handles both ESP32 and cloud)
                final apiService = ApiService();
                await apiService.downloadFile(imageUrl, savePath);
                
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Downloaded to $savePath')),
                );
              } catch (e) {
                debugPrint('Download image error: $e');
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Download failed: ${e.toString()}')),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: PhotoView(
          imageProvider: NetworkImage(imageUrl),
          minScale: PhotoViewComputedScale.contained,
          maxScale: PhotoViewComputedScale.covered * 2,
          backgroundDecoration: const BoxDecoration(color: Colors.black),
          loadingBuilder: (context, event) => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 64, color: Colors.white),
                SizedBox(height: 16),
                Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
