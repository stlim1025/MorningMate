import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../common/widgets/room_action_button.dart';

class StoreButton extends StatelessWidget {
  const StoreButton({super.key});

  @override
  Widget build(BuildContext context) {
    return RoomActionButton(
      iconPath: 'assets/icons/Store_Icon.png',
      label: '상점',
      onTap: () {
        context.push('/shop');
      },
    );
  }
}
