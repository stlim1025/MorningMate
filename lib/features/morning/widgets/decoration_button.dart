import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../common/widgets/room_action_button.dart';

class DecorationButton extends StatelessWidget {
  const DecorationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return RoomActionButton(
      iconPath: 'assets/icons/Ggumim_Icon.png',
      label: '방 꾸미기',
      size: 53, // 원래 width가 53이었음
      onTap: () {
        context.push('/decoration');
      },
    );
  }
}
