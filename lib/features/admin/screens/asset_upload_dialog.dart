import 'dart:typed_data';
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

  // Controllers
  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _nameKoController;
  late TextEditingController _nameEnController;
  late TextEditingController _priceController;

  bool _isLoading = false;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;

  // Form Fields
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
    _idController = TextEditingController();
    _nameController = TextEditingController();
    _nameKoController = TextEditingController();
    _nameEnController = TextEditingController();
    _priceController = TextEditingController(text: '100');

    if (widget.itemToEdit != null) {
      final item = widget.itemToEdit;
      _idController.text = item.id;
      _nameController.text = item.name;
      _nameKoController.text = item.nameKo ?? '';
      _nameEnController.text = item.nameEn ?? '';
      _priceController.text = item.price.toString();
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

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _nameKoController.dispose();
    _nameEnController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
        _selectedImageName = pickedFile.name;

        // 이미지 선택 시 이름과 ID 자동 제안
        final filename = pickedFile.name.split('.').first;
        if (_idController.text.isEmpty) {
          // 파일명을 소문자_언더바로 변환하여 ID 제안
          _idController.text =
              filename.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_').toLowerCase();

          // ID의 접두어가 카테고리가 아니면 붙여줌
          if (!_idController.text.startsWith(_category)) {
            // _idController.text = '${_category}_${_idController.text}';
          }
        }

        if (_nameController.text.isEmpty) {
          _nameController.text = filename;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.itemToEdit == null && _selectedImageBytes == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('이미지를 선택해주세요.')));
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      if (widget.itemToEdit == null) {
        await _assetService.addNewAsset(
          id: _idController.text.trim(),
          name: _nameController.text.trim(),
          nameKo: _nameKoController.text.trim(),
          nameEn: _nameEnController.text.trim(),
          price: int.parse(_priceController.text.trim()),
          category: _category,
          imageBytes: _selectedImageBytes!,
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
          name: _nameController.text.trim(),
          nameKo: _nameKoController.text.trim(),
          nameEn: _nameEnController.text.trim(),
          price: int.parse(_priceController.text.trim()),
          category: _category,
          imageBytes: _selectedImageBytes,
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
    // 화면 넓이에 따라 다이얼로그 크기 조절 (PC 작업 대응)
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 800 ? 700.0 : double.infinity;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: dialogWidth,
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.itemToEdit == null ? '🛍️ 신규 아이템 등록' : '✏️ 아이템 수정',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 32),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // 이미지 선택기 (더 크게, 더 강조)
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: _selectedImageBytes == null &&
                                  widget.itemToEdit?.imagePath == null
                              ? Colors.blue.withOpacity(0.05)
                              : Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedImageBytes == null &&
                                    widget.itemToEdit?.imagePath == null
                                ? Colors.blue
                                : Colors.grey[300]!,
                            width: 2,
                            style: _selectedImageBytes == null
                                ? BorderStyle.solid
                                : BorderStyle.solid,
                          ),
                        ),
                        child: _selectedImageBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.memory(_selectedImageBytes!,
                                    fit: BoxFit.contain),
                              )
                            : (widget.itemToEdit?.imagePath != null
                                ? NetworkOrAssetImage(
                                    imagePath: widget.itemToEdit!.imagePath!,
                                    fit: BoxFit.contain)
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cloud_upload_outlined,
                                          size: 60, color: Colors.blue[400]),
                                      const SizedBox(height: 12),
                                      const Text('여기를 클릭하여 이미지 업로드',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          )),
                                      const SizedBox(height: 4),
                                      Text('배경이 투명한 PNG 파일을 권장합니다.',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13)),
                                    ],
                                  )),
                      ),
                    ),
                    if (_selectedImageName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('파일명: $_selectedImageName',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ),
                    const SizedBox(height: 24),

                    // 카테고리 선택
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                          labelText: '📦 카테고리',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Color(0xFFF9F9F9)),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(c.toUpperCase())))
                          .toList(),
                      onChanged: (val) => setState(() => _category = val!),
                      onSaved: (value) => _category = value!,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _idController,
                            decoration: const InputDecoration(
                                labelText: '🆔 고유 ID (e.g. wall_lamp_01)',
                                hintText: '영문 소문자, 언더바만 사용',
                                border: OutlineInputBorder()),
                            enabled: widget.itemToEdit == null,
                            validator: (value) => value == null || value.isEmpty
                                ? 'ID를 입력하세요'
                                : null,
                          ),
                        ),
                        if (widget.itemToEdit == null)
                          IconButton(
                            onPressed: () {
                              _idController.clear();
                            },
                            icon: const Icon(Icons.refresh),
                            tooltip: '초기화',
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          labelText: '🏷️ 아이템 이름',
                          border: OutlineInputBorder()),
                      validator: (value) =>
                          value == null || value.isEmpty ? '이름을 입력하세요' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nameKoController,
                            decoration: const InputDecoration(
                                labelText: '🇰🇷 한국어 이름 (선택)',
                                border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _nameEnController,
                            decoration: const InputDecoration(
                                labelText: '🇺🇸 영어 이름 (선택)',
                                border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          controller: _priceController,
                          decoration: const InputDecoration(
                              labelText: '💰 가격 (가지 수)',
                              border: OutlineInputBorder(),
                              suffixText: '가지'),
                          keyboardType: TextInputType.number,
                          validator: (value) =>
                              int.tryParse(value ?? '') == null
                                  ? '숫자를 입력하세요'
                                  : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _priceChip(50),
                            const SizedBox(width: 8),
                            _priceChip(100),
                            const SizedBox(width: 8),
                            _priceChip(200),
                            const SizedBox(width: 8),
                            _priceChip(300),
                            const SizedBox(width: 8),
                            _priceChip(500),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 세부 속성들
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('⚙️ 고급 설정 (크기 및 속성)',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                      labelText: '크기 비율 (기본 1.0)',
                                      isDense: true,
                                      border: OutlineInputBorder()),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  initialValue: _sizeMultiplier.toString(),
                                  onSaved: (value) => _sizeMultiplier =
                                      double.tryParse(value ?? '1.0') ?? 1.0,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                      labelText: '종횡비 (기본 1.0)',
                                      isDense: true,
                                      border: OutlineInputBorder()),
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
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('벽걸이 아이템'),
                            value: _isWallMounted,
                            onChanged: (val) =>
                                setState(() => _isWallMounted = val),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('그림자 없앰'),
                            value: _noShadow,
                            onChanged: (val) => setState(() => _noShadow = val),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('빛 방출 (램프 등)'),
                            value: _isLight,
                            onChanged: (val) => setState(() => _isLight = val),
                          ),
                          if (_isLight)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextFormField(
                                decoration: const InputDecoration(
                                    labelText: '빛 밝기 강도 (기본 1.0)',
                                    isDense: true,
                                    border: OutlineInputBorder()),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                initialValue: _lightIntensity.toString(),
                                onSaved: (value) => _lightIntensity =
                                    double.tryParse(value ?? '1.0') ?? 1.0,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (widget.itemToEdit != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _showDeleteConfirm,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('삭제'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                if (widget.itemToEdit != null) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submit,
                    icon: _isLoading
                        ? const SizedBox.shrink()
                        : Icon(widget.itemToEdit == null
                            ? Icons.add_circle
                            : Icons.save),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    label: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(
                            widget.itemToEdit == null
                                ? '서버에 등록 및 출시'
                                : '수정 사항 저장',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceChip(int price) {
    return ActionChip(
      label: Text('$price'),
      onPressed: () {
        _priceController.text = price.toString();
      },
      backgroundColor: Colors.blue.withOpacity(0.05),
      labelStyle: const TextStyle(fontSize: 12),
      padding: EdgeInsets.zero,
    );
  }

  Future<void> _showDeleteConfirm() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('아이템 삭제'),
        content: const Text('정말로 이 아이템을 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('취소')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _assetService.deleteAsset(widget.itemToEdit!.id, _category);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('삭제되었습니다.')));
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
