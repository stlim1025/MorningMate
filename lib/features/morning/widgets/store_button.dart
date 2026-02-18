import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../common/widgets/room_action_button.dart';
import '../../../core/localization/app_localizations.dart';

class StoreButton extends StatelessWidget {
  const StoreButton({super.key});

  @override
  Widget build(BuildContext context) {
    return RoomActionButton(
      iconPath: 'assets/icons/Store_Icon.png',
      label: AppLocalizations.of(context)?.get('shop') ?? 'Shop',
      onTap: () {
        context.push('/shop');
      },
    );
  }
}
