import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/localization/app_localizations.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  late List<bool> _isOpen;

  @override
  void initState() {
    super.initState();
    // 초기화는 build에서 faqs 길이를 알게 된 후 혹은 고정값으로 처리
    _isOpen = List.filled(20, false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).extension<AppColorScheme>()!;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final isJapanese = locale.languageCode.startsWith('ja');
    final isEnglish = locale.languageCode.startsWith('en');

    final faqs = _getFaqs(isJapanese, isEnglish);

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
          l10n?.get('faq') ?? '자주 묻는 질문',
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
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: faqs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildFaqItem(faqs[index], index, colorScheme, l10n);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(Map<String, String> faq, int index, AppColorScheme colorScheme, AppLocalizations? l10n) {
    if (index >= _isOpen.length) return const SizedBox.shrink();
    final isOpen = _isOpen[index];

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _isOpen[index] = !isOpen;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              image: const DecorationImage(
                image: AssetImage('assets/images/TextBox_Background.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    faq['q']!,
                    style: TextStyle(
                      color: const Color(0xFF4E342E),
                      fontFamily: l10n?.mainFontFamily ?? 'BMJUA',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Icon(
                  isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: const Color(0xFF4E342E),
                ),
              ],
            ),
          ),
        ),
        if (isOpen)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4E342E).withOpacity(0.1)),
            ),
            child: Text(
              faq['a']!,
              style: TextStyle(
                color: const Color(0xFF5D4037),
                fontFamily: l10n?.mainFontFamily ?? 'BMJUA',
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
      ],
    );
  }

  List<Map<String, String>> _getFaqs(bool isJapanese, bool isEnglish) {
    if (isJapanese) {
      return [
        {'q': '日記はいつ書けますか？', 'a': '毎朝、目が覚めたらすぐに書くのが一番いいですよ！'},
        {'q': 'キャラクターの成長段階について教えてください。', 'a': '日記をコツコツ書くことで経験値が貯まり、卵からヒナ、そして成鳥へと進化していきます。レベルが上がるごとにキャラクターの「羽根」が美しく変化していきます。'},
        {'q': 'ブランチ（枝）はどうすれば集まりますか？', 'a': '1. 日記作成：基本20個 + (連続日数 * 2) を獲得でき、さらに「ネスト」のレベルに応じたボーナスが追加されます。\n2. 広告視聴：ショップで広告を視聴すると、1回につき20個、1日に合計5回（最大100個）獲得できます。\n3. 今日の一言：ネストに「今日の一言」を投稿すると、10個獲得できます。'},
        {'q': '友達を「起こす」とどうなりますか？', 'a': '友達を「起こす」と、その友達にプッシュ通知が届きます。お互いに起こし合って、活気ある一日を始めましょう！'},
        {'q': '退会するとデータはどうなりますか？', 'a': '退会すると、これまでに書いた日記の内容や購入したアイテムを含むすべてのデータが永久に削除され、復元することはできません。'},
        {'q': 'ショップのアイテムはいつ変わりますか？', 'a': 'ショップでは毎日ランダムに6つのアイテムが表示されます。もし気に入ったアイテムがなければ、一日に一度無料でリストを更新でき、広告を視聴することで一日最大3回まで追加でリセットが可能です。'},
        {'q': '「ネスト」のアップグレードはどんなメリットがありますか？', 'a': 'ネストをアップグレードすると、ネストの見た目がより豪華に変化し、メンバー全員が「ブランチボーナス」を受け取れるようになります！'},
        {'q': '過去に書いた日記をもう一度見たいです。', 'a': '「記録」タブから、これまでに作成したすべての予定や日記の内容をいつでも確認・修正することができます。'},
        {'q': '友達の部屋にはどうやって行けますか？', 'a': '下の「友達」タブで友達を選択すると、その友達の部屋に遊びに行くことができます。'},
        {'q': '機種変更をしてもデータは維持されますか？', 'a': 'Google, Apple, Kakao Accountでログインしていれば、新しい端末でも同じアカウントでログインするだけで全てのデータが同期されます。'},
      ];
    } else if (isEnglish) {
      return [
        {'q': 'When can I write a diary?', 'a': 'It\'s best to write right after you wake up every morning!'},
        {'q': 'How does my character evolve?', 'a': 'As you write diaries consistently, your character evolves from an egg to a chick, and finally a majestic bird. Your character\'s "wings" will change as it levels up.'},
        {'q': 'How do I collect branches?', 'a': '1. Write Diary: Earn 20 base branches + (Streak * 2), plus a Nest bonus.\n2. Watch Ads: Watch ads in the shop to earn 20 branches each, up to 5 times (total 100) per day.\n3. Today\'s Word: Earn 10 branches by writing "Today\'s Word" in your Nest.'},
        {'q': 'What happens when I "Wake Up" a friend?', 'a': 'When you tap "Wake Up," a push notification is sent to that friend to help them start their day!'},
        {'q': 'What happens to my data if I delete my account?', 'a': 'If you delete your account, all your data—including diary entries and purchased items—will be permanently erased and cannot be recovered.'},
        {'q': 'When do shop items refresh?', 'a': 'The shop shows 6 random items every day. You can refresh once for free daily, and watch ads to refresh up to 3 more times per day.'},
        {'q': 'What are the benefits of upgrading a Nest?', 'a': 'Upgrading your Nest changes its appearance and provides a "Bonus Branch" benefit to all members!'},
        {'q': 'Can I read or edit my past diaries?', 'a': 'In the "Records" tab, you can view and edit all your previous diary entries at any time.'},
        {'q': 'How can I visit a friend\'s room?', 'a': 'Go to the "Friends" tab and tap on a friend to visit their room.'},
        {'q': 'Is my data safe if I change phones?', 'a': 'Yes! Simply log in with the same social account to restore your data automatically.'},
      ];
    } else {
      return [
        {'q': '일기는 언제 쓸 수 있나요?', 'a': '매일 아침 눈을 뜨자마자 쓰는 것이 가장 좋아요!'},
        {'q': '캐릭터 성장 단계가 궁금해요!', 'a': '일기를 꾸준히 쓰면 경험치가 쌓여 알에서 병아리, 그리고 성체 새로 진화하게 됩니다. 레벨이 오를 때마다 캐릭터의 "날개"가 멋지게 변해간답니다.'},
        {'q': '가지는 어떻게 얻나요?', 'a': '1. 일기 작성: 기본 20개 + (연속 일수 * 2) 만큼 얻을 수 있고, 여기에 둥지 보너스만큼 추가 획득이 가능합니다.\n2. 광고 시청: 상점에서 광고를 보면 회당 20개씩, 하루 총 5번(최대 100개) 획득할 수 있습니다.\n3. 오늘의 한마디: 둥지에 "오늘의 한마디"를 작성하면 보상으로 10개를 획득할 수 있습니다.'},
        {'q': '친구를 "깨우면" 어떻게 되나요?', 'a': '친구를 깨우면 해당 친구에게 푸시 알림이 전송됩니다. 서로를 깨워주며 활기차게 하루를 시작해 보세요!'},
        {'q': '회원탈퇴를 하면 데이터는 어떻게 되나요?', 'a': '회원탈퇴를 하시면 지금까지 작성한 일기 내용과 구매한 아이템을 포함한 모든 데이터가 영구적으로 삭제되며, 다시 복구할 수 없습니다.'},
        {'q': '상점 아이템은 언제 바뀌나요?', 'a': '상점에서는 매일 6개의 아이템이 랜덤으로 새롭게 보여집니다. 만약 마음에 드는 아이템이 없다면 하루에 한 번 무료로 리스트를 리셋할 수 있고, 광고를 시청하여 하루 최대 3번까지 추가 리셋이 가능합니다.'},
        {'q': '둥지 업그레이드를 하면 무엇이 좋나요?', 'a': '둥지를 업그레이드하면 둥지 이미지가 더 멋지게 변경되고, 멤버 전원이 "가지 보너스" 혜택을 받을 수 있게 됩니다!'},
        {'q': '예전에 쓴 일기를 다시 보고 싶어요.', 'a': '"기록" 탭에서 지금까지 작성한 모든 일기 내용을 언제든지 조회하고 수정할 수 있습니다.'},
        {'q': '가지는 어떻게 모으나요?', 'a': '매일 일기를 쓰거나, 친구에게 응원을 보내거나, 광고를 시청하여 획득할 수 있어요.'},
        {'q': '친구 방에는 어떻게 가나요?', 'a': '하단 "친구" 탭에서 친구를 누르면 해당 친구의 방으로 놀러 갈 수 있어요.'},
        {'q': '기기를 변경해도 데이터가 유지되나요?', 'a': '구글/애플/카카오 계정으로 로그인되어 있다면, 새 기기에서도 같은 계정으로 로그인만 하면 모든 데이터가 자동으로 동기화됩니다.'},
      ];
    }
  }
}
