import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_storage/firebase_storage.dart';

class NetworkOrAssetImage extends StatelessWidget {
  final String imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Color? color;
  final BlendMode? colorBlendMode;

  const NetworkOrAssetImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('http')) {
      if (kIsWeb) {
        // Firebase Storage URL인 경우, SDK를 통해 바이트 다운로드 (CORS 우회)
        if (imagePath.contains('firebasestorage.googleapis.com')) {
          return _FirebaseStorageImage(
            url: imagePath,
            fit: fit,
            width: width,
            height: height,
            color: color,
            colorBlendMode: colorBlendMode,
          );
        }
        // 일반 URL은 Image.network 사용
        return Image.network(
          imagePath,
          fit: fit,
          width: width,
          height: height,
          color: color,
          colorBlendMode: colorBlendMode,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.broken_image_outlined,
            size: width ?? height ?? 24,
            color: Colors.grey[400],
          ),
        );
      }
      return Image(
        image: CachedNetworkImageProvider(imagePath),
        fit: fit,
        width: width,
        height: height,
        color: color,
        colorBlendMode: colorBlendMode,
        errorBuilder: (context, error, stackTrace) => const SizedBox(),
      );
    } else if (imagePath.endsWith('.svg')) {
      return SvgPicture.asset(
        imagePath,
        fit: fit,
        width: width,
        height: height,
        colorFilter: color != null
            ? ColorFilter.mode(color!, colorBlendMode ?? BlendMode.srcIn)
            : null,
      );
    } else {
      return Image.asset(
        imagePath,
        fit: fit,
        width: width,
        height: height,
        color: color,
        colorBlendMode: colorBlendMode,
      );
    }
  }
}

/// Firebase Storage URL에서 SDK를 통해 바이트를 다운로드하여 이미지를 표시하는 위젯
class _FirebaseStorageImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Color? color;
  final BlendMode? colorBlendMode;

  const _FirebaseStorageImage({
    required this.url,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
  });

  @override
  State<_FirebaseStorageImage> createState() => _FirebaseStorageImageState();
}

class _FirebaseStorageImageState extends State<_FirebaseStorageImage> {
  Uint8List? _imageBytes;
  String? _downloadUrl;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    // 방법 1: Firebase SDK getData()로 직접 바이트 다운로드
    try {
      final ref = FirebaseStorage.instance.refFromURL(widget.url);
      final data = await ref.getData(10 * 1024 * 1024); // 최대 10MB
      if (mounted && data != null) {
        setState(() => _imageBytes = data);
        return; // 성공하면 바로 리턴
      }
    } catch (e) {
      debugPrint('Firebase Storage getData 실패, getDownloadURL 시도: $e');
    }

    // 방법 2: getDownloadURL()로 URL을 새로 받아서 Image.network로 시도
    try {
      final ref = FirebaseStorage.instance.refFromURL(widget.url);
      final freshUrl = await ref.getDownloadURL();
      if (mounted) {
        setState(() => _downloadUrl = freshUrl);
      }
    } catch (e) {
      debugPrint('Firebase Storage getDownloadURL도 실패: $e');
      if (mounted) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 방법 1 성공: 바이트로 표시
    if (_imageBytes != null) {
      return Image.memory(
        _imageBytes!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        color: widget.color,
        colorBlendMode: widget.colorBlendMode,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.broken_image_outlined,
          size: widget.width ?? widget.height ?? 24,
          color: Colors.grey[400],
        ),
      );
    }

    // 방법 2 성공: getDownloadURL로 받은 URL로 표시
    if (_downloadUrl != null) {
      return Image.network(
        _downloadUrl!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        color: widget.color,
        colorBlendMode: widget.colorBlendMode,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.broken_image_outlined,
          size: widget.width ?? widget.height ?? 24,
          color: Colors.grey[400],
        ),
      );
    }

    if (_hasError) {
      // 폴백: Image.network 시도
      return Image.network(
        widget.url,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        color: widget.color,
        colorBlendMode: widget.colorBlendMode,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.broken_image_outlined,
          size: widget.width ?? widget.height ?? 24,
          color: Colors.grey[400],
        ),
      );
    }

    // 로딩 중
    return SizedBox(
      width: widget.width ?? 24,
      height: widget.height ?? 24,
      child: const Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
