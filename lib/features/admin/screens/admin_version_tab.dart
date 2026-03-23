import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../controllers/admin_controller.dart';
import '../../../data/models/version_model.dart';
import 'package:translator/translator.dart';

class AdminVersionTab extends StatefulWidget {
  const AdminVersionTab({super.key});

  @override
  State<AdminVersionTab> createState() => _AdminVersionTabState();
}

class _AdminVersionTabState extends State<AdminVersionTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _latestController = TextEditingController();
  final _minimumController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _titleEnController = TextEditingController();
  final _bodyEnController = TextEditingController();
  final _titleJaController = TextEditingController();
  final _bodyJaController = TextEditingController();
  bool _isForceUpdate = false;
  bool _isTranslating = false;
  String _currentAppVersion = '';
  String _currentBuildNumber = '';
  final _translator = GoogleTranslator();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVersionInfo();
    });
  }

  void _handleTabSelection() {
    if (!_tabController.indexIsChanging) {
      _updateFieldsFromController();
    }
  }

  Future<void> _loadVersionInfo() async {
    final adminController = context.read<AdminController>();
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _currentAppVersion = packageInfo.version;
        _currentBuildNumber = packageInfo.buildNumber;
      });
    }
    await adminController.fetchVersionInfo();
    _updateFieldsFromController();
  }

  void _updateFieldsFromController({int? index}) {
    final adminController = context.read<AdminController>();
    final targetIndex = index ?? _tabController.index;
    final info = targetIndex == 0
        ? adminController.androidVersionInfo
        : adminController.iosVersionInfo;

    if (info != null && mounted) {
      setState(() {
        _latestController.text = info.latestVersion;
        _minimumController.text = info.minimumVersion;
        _titleController.text = info.updateTitle;
        _bodyController.text = info.updateBody;
        _titleEnController.text = info.updateTitleEn ?? '';
        _bodyEnController.text = info.updateBodyEn ?? '';
        _titleJaController.text = info.updateTitleJa ?? '';
        _bodyJaController.text = info.updateBodyJa ?? '';
        _isForceUpdate = info.isForceUpdate;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    _latestController.dispose();
    _minimumController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _titleEnController.dispose();
    _bodyEnController.dispose();
    _titleJaController.dispose();
    _bodyJaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminController = context.watch<AdminController>();
    final platformName = _tabController.index == 0 ? 'Android' : 'iOS';

    return Column(
      children: [
        // ── Header with tab ──
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildPlatformTab(0, Icons.android_rounded, 'Android',
                      const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  _buildPlatformTab(
                      1, Icons.apple_rounded, 'iOS', const Color(0xFF64748B)),
                  const Spacer(),
                  // Current App Version info
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(6),
                      border:
                          Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 14, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 6),
                        Text(
                          '현재 앱: v$_currentAppVersion ($_currentBuildNumber)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE2E8F0)),

        // ── Content ──
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left: Settings Form ──
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$platformName 버전 설정',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Version Inputs
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                label: '최신 버전 (Latest)',
                                hint: '예: 1.1.0',
                                controller: _latestController,
                                trailing: TextButton(
                                  onPressed: () => setState(() =>
                                      _latestController.text =
                                          _currentAppVersion),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    '현재 버전으로',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF6366F1)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildInputField(
                                label: '최소 버전 (Minimum)',
                                hint: '예: 1.0.5',
                                controller: _minimumController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _buildInputField(
                          label: '업데이트 팝업 제목',
                          hint: '예: 새로운 버전을 이용해 보세요!',
                          controller: _titleController,
                        ),
                        const SizedBox(height: 20),

                        _buildInputField(
                          label: '업데이트 팝업 내용',
                          hint: '예: 더 안정적이고 새로운 기능을 위해 업데이트가 필요합니다.',
                          controller: _bodyController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Text(
                              'Global Localization',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6366F1),
                              ),
                            ),
                            const Spacer(),
                            if (_isTranslating)
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF6366F1),
                                ),
                              )
                            else
                              TextButton.icon(
                                onPressed: _autoTranslate,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  backgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.08),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                icon: const Icon(Icons.translate_rounded,
                                    size: 14, color: Color(0xFF6366F1)),
                                label: const Text(
                                  '일괄 자동 번역 (EN/JA)',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFF6366F1)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'Update Popup Title (EN)',
                          hint: 'e.g. New Version Available!',
                          controller: _titleEnController,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          label: 'Update Popup Body (EN)',
                          hint: 'e.g. Please update for new features and bug fixes.',
                          controller: _bodyEnController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 20),
                        const Text(
                          'Japanese Localization',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF5252),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInputField(
                          label: 'Update Popup Title (JA)',
                          hint: '例: 新しいバージョンが利用可能です！',
                          controller: _titleJaController,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          label: 'Update Popup Body (JA)',
                          hint: '例: 新しい機能と安定性の向上のためにアップデートをお願いします。',
                          controller: _bodyJaController,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),

                        // Force Update Toggle + Save
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '강제 업데이트',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isForceUpdate
                                        ? '닫기 버튼이 없는 강제 업데이트 팝업이 노출됩니다.'
                                        : '사용자가 나중에 하기를 선택할 수 있습니다.',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Switch(
                                value: _isForceUpdate,
                                onChanged: (val) =>
                                    setState(() => _isForceUpdate = val),
                                activeThumbColor: const Color(0xFF6366F1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: adminController.isLoading
                                ? null
                                : _saveSettings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6366F1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            icon: adminController.isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white),
                                  )
                                : const Icon(Icons.save_rounded,
                                    size: 18),
                            label: Text('$platformName 설정 저장'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 24),

                // ── Right: Guide Panel ──
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.help_outline_rounded,
                                size: 18, color: Color(0xFF6366F1)),
                            SizedBox(width: 8),
                            Text(
                              '버전 관리 가이드',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildGuideItem(
                          'Latest Version',
                          '현재 스토어에 출시된 최신 버전입니다.',
                          Icons.new_releases_outlined,
                        ),
                        const SizedBox(height: 16),
                        _buildGuideItem(
                          'Minimum Version',
                          '앱이 작동하기 위한 최소 버전입니다. 현재 버전이 이보다 낮으면 강제 업데이트가 실행됩니다.',
                          Icons.warning_amber_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildGuideItem(
                          'Force Update',
                          '체크 시 X(닫기) 버튼이 없는 강제 업데이트 팝업이 노출됩니다.',
                          Icons.block_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformTab(
      int index, IconData icon, String label, Color color) {
    final isSelected = _tabController.index == index;
    return InkWell(
      onTap: () {
        _tabController.animateTo(index);
        _updateFieldsFromController(index: index); // 전달받은 인덱스로 즉시 업데이트
        setState(() {});
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: color.withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? color : const Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            if (trailing != null) ...[
              const Spacer(),
              trailing,
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: Color(0xFFCBD5E1), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF6366F1), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _autoTranslate() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty && body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('번역할 한글 내용이 없습니다.')),
      );
      return;
    }

    setState(() => _isTranslating = true);

    try {
      // Translate to English
      if (title.isNotEmpty) {
        final translatedTitleEn =
            await _translator.translate(title, from: 'ko', to: 'en');
        _titleEnController.text = translatedTitleEn.text;
      }
      if (body.isNotEmpty) {
        final translatedBodyEn =
            await _translator.translate(body, from: 'ko', to: 'en');
        _bodyEnController.text = translatedBodyEn.text;
      }

      // Translate to Japanese
      if (title.isNotEmpty) {
        final translatedTitleJa =
            await _translator.translate(title, from: 'ko', to: 'ja');
        _titleJaController.text = translatedTitleJa.text;
      }
      if (body.isNotEmpty) {
        final translatedBodyJa =
            await _translator.translate(body, from: 'ko', to: 'ja');
        _bodyJaController.text = translatedBodyJa.text;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('영어 및 일본어 번역이 완료되었습니다.')),
        );
      }
    } catch (e) {
      debugPrint('Translation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('번역 중 오류가 발생했습니다.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTranslating = false);
      }
    }
  }

  Widget _buildGuideItem(String title, String desc, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                    fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _saveSettings() async {
    final info = VersionModel(
      latestVersion: _latestController.text.trim(),
      minimumVersion: _minimumController.text.trim(),
      updateTitle: _titleController.text.trim(),
      updateBody: _bodyController.text.trim(),
      updateTitleEn: _titleEnController.text.trim().isEmpty ? null : _titleEnController.text.trim(),
      updateBodyEn: _bodyEnController.text.trim().isEmpty ? null : _bodyEnController.text.trim(),
      updateTitleJa: _titleJaController.text.trim().isEmpty ? null : _titleJaController.text.trim(),
      updateBodyJa: _bodyJaController.text.trim().isEmpty ? null : _bodyJaController.text.trim(),
      isForceUpdate: _isForceUpdate,
    );

    final platform = _tabController.index == 0 ? 'android' : 'ios';
    await context.read<AdminController>().updateVersionInfo(info, platform);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${platform.toUpperCase()} 버전 정보가 업데이트되었습니다.')),
      );
    }
  }
}
