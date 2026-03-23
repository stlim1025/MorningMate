import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/localization/app_localizations.dart';

class TermsSelectionScreen extends StatelessWidget {
  const TermsSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Image.asset(
            'assets/icons/X_Button.png',
            width: 40,
            height: 40,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          l10n?.get('termsAndPrivacy') ?? '이용약관 및 정책',
          style: TextStyle(
            color: colorScheme.textPrimary,
            fontFamily: l10n?.mainFontFamily ?? 'BMJUA',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/Diary_Background.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildOptionArea(
                  context,
                  children: [
                    _buildSettingsTile(
                      context,
                      colorScheme,
                      icon: Icons.description,
                      title: l10n?.get('termsOfService') ?? '이용약관',
                      onTap: () => context.pushNamed('termsOfServiceDetail'),
                    ),
                    _buildDivider(colorScheme),
                    _buildSettingsTile(
                      context,
                      colorScheme,
                      icon: Icons.privacy_tip,
                      title: l10n?.get('privacyPolicy') ?? '개인정보 처리방침',
                      onTap: () => context.pushNamed('privacyPolicyDetail'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionArea(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/Option_Area.png'),
          fit: BoxFit.fill,
        ),
      ),
      padding: const EdgeInsets.only(top: 32, bottom: 15),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    AppColorScheme colorScheme, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.iconPrimary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.iconPrimary, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: colorScheme.textPrimary,
          fontFamily: l10n?.mainFontFamily ?? 'BMJUA',
          fontSize: 16,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: colorScheme.textSecondary.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider(AppColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 3.0;
          const dashHeight = 1.0;
          final dashCount = (boxWidth / (2 * dashWidth)).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: dashHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4E342E).withOpacity(0.2),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
