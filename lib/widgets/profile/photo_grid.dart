import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/network/api_client.dart';
import '../../core/constants/app_constants.dart';
import 'package:dio/dio.dart';
import '../../state/app_state.dart';
import 'package:provider/provider.dart';

class PhotoGrid extends StatefulWidget {
  const PhotoGrid({super.key});

  @override
  State<PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<PhotoGrid> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUploadPhoto() async {
    final state = context.read<AppState>();
    if ((state.currentUser.images.length) >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 photos allowed.')),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // Crop Image
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: image.path,
      aspectRatio: const CropAspectRatio(ratioX: 4, ratioY: 5),
      compressQuality: 80,
      maxWidth: 1080,
      maxHeight: 1350,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.ratio4x3,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
        ),
      ],
    );

    if (croppedFile == null) return;

    setState(() => _isUploading = true);
    try {
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(croppedFile.path)
      });
      final response = await apiClient.post('/users/me/photos', data: formData);
      if (response.statusCode == 200) {
        final newImages = List<String>.from(response.data['images']);
        String newAvatar = newImages.isNotEmpty ? newImages.first : '';
        if (newAvatar.isNotEmpty && !newAvatar.startsWith('http')) {
           newAvatar = AppConstants.apiBaseUrl.replaceAll('/api', '') + newAvatar;
        }
        final updatedProfile = state.currentUser.copyWith(
          images: newImages,
          avatarUrl: newAvatar,
        );
        state.updateUserProfile(updatedProfile);
      } else {
        throw Exception(response.data['error'] ?? 'Upload failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading photo: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deletePhoto(String url) async {
    final state = context.read<AppState>();
    if (state.currentUser.images.length <= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum 2 photos required.')),
      );
      return;
    }

    try {
      final response = await apiClient.delete('/users/me/photos', data: {'url': url});
      if (response.statusCode == 200) {
        final newImages = List<String>.from(response.data['images']);
        String newAvatar = newImages.isNotEmpty ? newImages.first : '';
        if (newAvatar.isNotEmpty && !newAvatar.startsWith('http')) {
           newAvatar = AppConstants.apiBaseUrl.replaceAll('/api', '') + newAvatar;
        }
        state.updateUserProfile(state.currentUser.copyWith(
          images: newImages,
          avatarUrl: newAvatar,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting photo: $e')),
      );
    }
  }

  Future<void> _reorderPhotos(int oldIndex, int newIndex) async {
    final state = context.read<AppState>();
    final images = List<String>.from(state.currentUser.images);
    
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final String item = images.removeAt(oldIndex);
    images.insert(newIndex, item);

    // Optimistic update
    final originalImages = state.currentUser.images;
    final originalAvatar = state.currentUser.avatarUrl;
    
    String newAvatar = images.isNotEmpty ? images.first : '';
    if (newAvatar.isNotEmpty && !newAvatar.startsWith('http')) {
       newAvatar = AppConstants.apiBaseUrl.replaceAll('/api', '') + newAvatar;
    }
    
    state.updateUserProfile(state.currentUser.copyWith(
      images: images,
      avatarUrl: newAvatar,
    ));

    try {
      final response = await apiClient.put('/users/me/photos/order', data: {'images': images});
      if (response.statusCode != 200) throw Exception('Reorder failed');
    } catch (e) {
      // Revert
      state.updateUserProfile(state.currentUser.copyWith(
        images: originalImages,
        avatarUrl: originalAvatar,
      ));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save photo order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    final images = user.images;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Photos (Drag to reorder)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 4/5,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            if (index < images.length) {
              return _buildDraggablePhoto(index, images[index]);
            } else {
              return _buildEmptySlot();
            }
          },
        ),
      ],
    );
  }

  Widget _buildDraggablePhoto(int index, String url) {
    return LongPressDraggable<int>(
      data: index,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 100, height: 125,
            child: Image.network(AppConstants.apiBaseUrl.replaceAll('/api', '') + url, fit: BoxFit.cover),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildPhotoContainer(url, index),
      ),
      child: DragTarget<int>(
        onWillAccept: (fromIndex) => fromIndex != null && fromIndex != index,
        onAccept: (fromIndex) => _reorderPhotos(fromIndex, index),
        builder: (context, candidateData, rejectedData) {
          return Stack(
            children: [
              _buildPhotoContainer(url, index),
              Positioned(
                bottom: 4, right: 4,
                child: GestureDetector(
                  onTap: () => _deletePhoto(url),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 16, color: Colors.red),
                  ),
                ),
              ),
              if (index == 0)
                Positioned(
                  top: 4, left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                    child: const Text('MAIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPhotoContainer(String url, int index) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: index == 0 ? AppColors.primary : Colors.transparent, width: 2),
        image: DecorationImage(
          image: NetworkImage(AppConstants.apiBaseUrl.replaceAll('/api', '') + url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return GestureDetector(
      onTap: _isUploading ? null : _pickAndUploadPhoto,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.cardBorder, style: BorderStyle.solid),
        ),
        child: Center(
          child: _isUploading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.add, color: AppColors.textSecondary, size: 32),
        ),
      ),
    );
  }
}
