import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../services/asset_service.dart';

import '../../../../core/widgets/network_or_asset_image.dart';

class AssetUploadDialog extends StatefulWidget {
  final dynamic itemToEdit;

  const AssetUploadDialog({super.key, this.itemToEdit});

  @override
  State<AssetUploadDialog> createState() => _AssetUploadDialogState();
}

class _AssetUploadDialogState extends State<AssetUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _assetService = AssetService();
  final _picker = ImagePicker();

  bool _isLoading = false;
  File? _selectedImage;

  // Form Fields
  String _id = '';
  String _name = '';
  int _price = 100;
  String _category = 'prop';
  double _sizeMultiplier = 1.0;
  double _aspectRatio = 1.0;
  bool _isWallMounted = false;
  bool _noShadow = false;
  double _shadowDyCorrection = 0.0;
  bool _isLight = false;
  double _lightIntensity = 1.0;

  final List<String> _categories = [
    'prop',
    'emoticon',
    'wallpaper',
    'background',
    'floor',
    'characterItem'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.itemToEdit != null) {
      final item = widget.itemToEdit;
      _id = item.id;
      _name = item.name;
      _price = item.price;
      _category = item.category ?? 'prop';
      _sizeMultiplier = item.sizeMultiplier;
      _aspectRatio = item.aspectRatio;
      _isWallMounted = item.isWallMounted;
      _noShadow = item.noShadow;
      _shadowDyCorrection = item.shadowDyCorrection;
      _isLight = item.isLight;
      _lightIntensity = item.lightIntensity;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.itemToEdit == null && _selectedImage == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('이미지를 선택해주세요.')));
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      if (widget.itemToEdit == null) {
        await _assetService.addNewAsset(
          id: _id,
          name: _name,
          price: _price,
          category: _category,
          imageFile: _selectedImage!,
          sizeMultiplier: _sizeMultiplier,
          aspectRatio: _aspectRatio,
          isWallMounted: _isWallMounted,
          noShadow: _noShadow,
          shadowDyCorrection: _shadowDyCorrection,
          isLight: _isLight,
          lightIntensity: _lightIntensity,
        );
      } else {
        await _assetService.updateAsset(
          id: widget.itemToEdit!.id,
          name: _name,
          price: _price,
          category: _category,
          imageFile: _selectedImage,
          existingImageUrl: widget.itemToEdit!.imagePath ?? '',
          sizeMultiplier: _sizeMultiplier,
          aspectRatio: _aspectRatio,
          isWallMounted: _isWallMounted,
          noShadow: _noShadow,
          shadowDyCorrection: _shadowDyCorrection,
          isLight: _isLight,
          lightIntensity: _lightIntensity,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(widget.itemToEdit == null
                ? '아이템이 성공적으로 업로드되었습니다.'
                : '아이템이 수정되었습니다.')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('업로드 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.itemToEdit == null ? '신규 아이템 등록' : '아이템 수정',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      // 이미지 선택기
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(_selectedImage!,
                                      fit: BoxFit.contain),
                                )
                              : (widget.itemToEdit?.imagePath != null
                                  ? NetworkOrAssetImage(
                                      imagePath: widget.itemToEdit!.imagePath!,
                                      fit: BoxFit.contain)
                                  : const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate,
                                            size: 50, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('이미지 선택 (투명 PNG 권장)',
                                            style:
                                                TextStyle(color: Colors.grey)),
                                      ],
                                    )),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: '고유 ID (영어소문자, 언더바) e.g. prop_lamp_01',
                            border: OutlineInputBorder()),
                        initialValue: _id,
                        enabled: widget.itemToEdit == null, // ID 수정 불가
                        validator: (value) =>
                            value == null || value.isEmpty ? 'ID를 입력하세요' : null,
                        onSaved: (value) => _id = value!,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: '아이템 이름', border: OutlineInputBorder()),
                        initialValue: _name,
                        validator: (value) =>
                            value == null || value.isEmpty ? '이름을 입력하세요' : null,
                        onSaved: (value) => _name = value!,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: '가격 (가지 수)',
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        initialValue: _price.toString(),
                        validator: (value) => int.tryParse(value ?? '') == null
                            ? '숫자를 입력하세요'
                            : null,
                        onSaved: (value) => _price = int.parse(value!),
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        value: _category,
                        decoration: const InputDecoration(
                            labelText: '카테고리', border: OutlineInputBorder()),
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                value: c, child: Text(c.toUpperCase())))
                            .toList(),
                        onChanged: (val) => setState(() => _category = val!),
                        onSaved: (value) => _category = value!,
                      ),
                      const SizedBox(height: 12),

                      // 세부 속성들
                      const Text('고급 설정 (크기 및 속성)',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                  labelText: '크기 비율 (기본 1.0)', isDense: true),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              initialValue: _sizeMultiplier.toString(),
                              onSaved: (value) => _sizeMultiplier =
                                  double.tryParse(value ?? '1.0') ?? 1.0,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                  labelText: '종횡비 (가로/세로, 기본 1.0)',
                                  isDense: true),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              initialValue: _aspectRatio.toString(),
                              onSaved: (value) => _aspectRatio =
                                  double.tryParse(value ?? '1.0') ?? 1.0,
                            ),
                          ),
                        ],
                      ),

                      SwitchListTile(
                        title: const Text('벽걸이 아이템'),
                        value: _isWallMounted,
                        onChanged: (val) =>
                            setState(() => _isWallMounted = val),
                      ),
                      SwitchListTile(
                        title: const Text('그림자 없앰'),
                        value: _noShadow,
                        onChanged: (val) => setState(() => _noShadow = val),
                      ),
                      SwitchListTile(
                        title: const Text('빛 방출 (램프 등)'),
                        value: _isLight,
                        onChanged: (val) => setState(() => _isLight = val),
                      ),

                      if (_isLight)
                        TextFormField(
                          decoration: const InputDecoration(
                              labelText: '빛 밝기 강도 (기본 1.0)', isDense: true),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          initialValue: _lightIntensity.toString(),
                          onSaved: (value) => _lightIntensity =
                              double.tryParse(value ?? '1.0') ?? 1.0,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : Text(
                          widget.itemToEdit == null
                              ? '서버에 등록 및 즉시 출시'
                              : '수정 사항 저장',
                          style: const TextStyle(fontSize: 16)),
                ),
              ),
              if (widget.itemToEdit != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('삭제 경고'),
                                content: const Text(
                                    '정말로 이 아이템을 상점과 유저 기록에서 삭제하시겠습니까?'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('취소')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('삭제'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              setState(() => _isLoading = true);
                              try {
                                await _assetService.deleteAsset(_id, _category);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('아이템이 삭제되었습니다.')));
                                  Navigator.pop(context, true);
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('삭제 실패: $e')));
                                }
                              } finally {
                                if (mounted) setState(() => _isLoading = false);
                              }
                            }
                          },
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: Colors.red),
                    child:
                        const Text('이 아이템 삭제', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
