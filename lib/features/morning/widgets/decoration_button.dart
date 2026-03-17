import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../common/widgets/room_action_button.dart';
import '../../../core/localization/app_localizations.dart';

class DecorationButton extends StatelessWidget {
  const DecorationButton({super.key});


  @override
  Widget build(BuildContext context) {
    return RoomActionButton(
      iconPath: 'assets/icons/Ggumim_Icon.png',
      label:
          AppLocalizations.of(context)?.get('decorateRoom') ?? 'Decorate Room',
      size: 56, // StoreButton과 크기 통일하여 정렬 일치시킴
      onTap: () {
        context.push('/decoration');
      },
    );
  }
}
