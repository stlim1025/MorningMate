import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/admin_controller.dart';
import '../../../data/models/version_model.dart';

class AdminVersionTab extends StatefulWidget {
  const AdminVersionTab({super.key});

  @override
  State<AdminVersionTab> createState() => _AdminVersionTabState();
}

class _AdminVersionTabState extends State<AdminVersionTab> {
  final _latestController = TextEditingController();
  final _minimumController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isForceUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVersionInfo();
    });
  }

  Future<void> _loadVersionInfo() async {
    final adminController = context.read<AdminController>();
    await adminController.fetchVersionInfo();
    final info = adminController.versionInfo;
    if (info != null) {
      setState(() {
        _latestController.text = info.latestVersion;
        _minimumController.text = info.minimumVersion;
        _titleController.text = info.updateTitle;
        _bodyController.text = info.updateBody;
        _isForceUpdate = info.isForceUpdate;
      });
    }
  }

  @override
  void dispose() {
    _latestController.dispose();
    _minimumController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adminController = context.watch<AdminController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(),
          const SizedBox(height: 32),
          _buildSettingForm(adminController),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text(
                '버전 관리 가이드',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildGuideItem('Latest Version', '현재 스토어에 출시된 최신 버전입니다.'),
          _buildGuideItem('Minimum Version', '앱이 작동하기 위한 최소 버전입니다. 현재 버전이 이보다 낮으면 강제 업데이트가 실행됩니다.'),
          _buildGuideItem('Force Update?', '체크 시 X(닫기) 버튼이 없는 강제 업데이트 팝업이 노출됩니다.'),
        ],
      ),
    );
  }

  Widget _buildGuideItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $title: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(desc)),
        ],
      ),
    );
  }

  Widget _buildSettingForm(AdminController adminController) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.black12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '앱 버전 설정',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: '최신 버전 (Latest Version)',
                    hint: '예: 1.1.0',
                    controller: _latestController,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildTextField(
                    label: '최소 버전 (Minimum Version)',
                    hint: '예: 1.0.5',
                    controller: _minimumController,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: '팝업 제목',
              hint: '예: 새로운 버전을 이용해 보세요!',
              controller: _titleController,
            ),
            const SizedBox(height: 24),
            _buildTextField(
              label: '팝업 내용',
              hint: '예: 더 안정적이고 새로운 기능을 위해 업데이트가 필요합니다.',
              controller: _bodyController,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  '강제 업데이트 여부',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _isForceUpdate,
                  onChanged: (val) => setState(() => _isForceUpdate = val),
                  activeColor: Colors.blue,
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: adminController.isLoading ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: adminController.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: const Text('설정 저장하기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      isForceUpdate: _isForceUpdate,
    );

    await context.read<AdminController>().updateVersionInfo(info);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('버전 정보가 업데이트되었습니다.')),
      );
    }
  }
}
