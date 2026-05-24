import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/game_data.dart';
import 'app_widgets.dart';

class CharacterScreen extends StatefulWidget {
  const CharacterScreen({super.key});

  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  int _previewIndex = 0;

  @override
  void initState() {
    super.initState();
    _previewIndex = GameData().selectedCharacter;
  }

  @override
  Widget build(BuildContext context) {
    final gd = GameData();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              AppHeader(
                title: 'CHARACTERS',
                trailing: AppCoinBadge(value: '${gd.coins}'),
              ),

              // Large character preview
              Expanded(
                flex: 3,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(120, 190),
                          painter: _CharDetailPainter(
                            GameData.characterBodyColors[_previewIndex],
                            GameData.characterSkinColors[_previewIndex],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          GameData.characterNames[_previewIndex],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (gd.selectedCharacter == _previewIndex)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.greenBtn,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'SELECTED',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          )
                        else if (gd.unlockedCharacters[_previewIndex])
                          GestureDetector(
                            onTap: () {
                              setState(() =>
                                  gd.selectedCharacter = _previewIndex);
                              gd.save();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.blueBtn,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'SELECT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () {
                              final bought = gd.buyCharacter(_previewIndex);
                              if (bought) {
                                setState(() {});
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text('Not enough coins!')),
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.yellowBtn,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${GameData.characterCosts[_previewIndex]}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Character grid
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    itemCount: GameData.characterNames.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.75,
                    ),
                    itemBuilder: (_, i) {
                      final isSelected = _previewIndex == i;
                      final isEquipped = gd.selectedCharacter == i;
                      final unlocked = gd.unlockedCharacters[i];
                      return GestureDetector(
                        onTap: () => setState(() => _previewIndex = i),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.panelLight
                                : AppColors.panelMid,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isEquipped
                                  ? AppColors.green
                                  : isSelected
                                      ? AppColors.lightBlue
                                      : AppColors.cardBorder,
                              width: isSelected || isEquipped ? 2 : 1,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomPaint(
                                    size: const Size(36, 54),
                                    painter: _CharDetailPainter(
                                      GameData.characterBodyColors[i],
                                      GameData.characterSkinColors[i],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    GameData.characterNames[i],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (!unlocked)
                                    Text(
                                      '${GameData.characterCosts[i]}',
                                      style: const TextStyle(
                                        color: AppColors.gold,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                              if (!unlocked)
                                const Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Icon(
                                    Icons.lock,
                                    color: Colors.white54,
                                    size: 14,
                                  ),
                                ),
                              if (isEquipped)
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      color: AppColors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharDetailPainter extends CustomPainter {
  final Color bodyColor;
  final Color skinColor;

  const _CharDetailPainter(this.bodyColor, this.skinColor);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final skin = Paint()..color = skinColor;
    final body = Paint()..color = bodyColor;
    final pants = Paint()..color = const Color(0xFF1565C0);
    final shoes = Paint()..color = const Color(0xFF212121);
    final hair = Paint()..color = const Color(0xFF4A2800);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, size.height - 4),
        width: size.width * 0.8,
        height: size.height * 0.07,
      ),
      Paint()
        ..color = Colors.black26
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Shoes
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center:
              Offset(cx - size.width * 0.18, size.height - size.height * 0.07),
          width: size.width * 0.34,
          height: size.height * 0.09,
        ),
        const Radius.circular(4),
      ),
      shoes,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center:
              Offset(cx + size.width * 0.18, size.height - size.height * 0.07),
          width: size.width * 0.34,
          height: size.height * 0.09,
        ),
        const Radius.circular(4),
      ),
      shoes,
    );

    // Legs
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center:
              Offset(cx - size.width * 0.14, size.height - size.height * 0.25),
          width: size.width * 0.28,
          height: size.height * 0.3,
        ),
        const Radius.circular(5),
      ),
      pants,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center:
              Offset(cx + size.width * 0.14, size.height - size.height * 0.25),
          width: size.width * 0.28,
          height: size.height * 0.3,
        ),
        const Radius.circular(5),
      ),
      pants,
    );

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, size.height - size.height * 0.5),
          width: size.width * 0.7,
          height: size.height * 0.32,
        ),
        const Radius.circular(8),
      ),
      body,
    );

    // Arms
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center:
              Offset(cx - size.width * 0.42, size.height - size.height * 0.51),
          width: size.width * 0.2,
          height: size.height * 0.26,
        ),
        const Radius.circular(5),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center:
              Offset(cx + size.width * 0.42, size.height - size.height * 0.51),
          width: size.width * 0.2,
          height: size.height * 0.26,
        ),
        const Radius.circular(5),
      ),
      body,
    );

    // Neck
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(cx, size.height - size.height * 0.67),
        width: size.width * 0.18,
        height: size.height * 0.07,
      ),
      skin,
    );

    // Head
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, size.height - size.height * 0.79),
          width: size.width * 0.54,
          height: size.height * 0.22,
        ),
        const Radius.circular(10),
      ),
      skin,
    );

    // Hair
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - size.width * 0.27,
          size.height - size.height * 0.92,
          size.width * 0.54,
          size.height * 0.15,
        ),
        const Radius.circular(8),
      ),
      hair,
    );
    final spike = Path()
      ..moveTo(cx - size.width * 0.06, size.height - size.height * 0.92)
      ..lineTo(cx + size.width * 0.02, size.height - size.height * 0.99)
      ..lineTo(cx + size.width * 0.1, size.height - size.height * 0.92)
      ..close();
    canvas.drawPath(spike, hair);

    // Eyes
    canvas.drawCircle(
      Offset(cx - size.width * 0.13, size.height - size.height * 0.79),
      size.width * 0.07,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(cx + size.width * 0.13, size.height - size.height * 0.79),
      size.width * 0.07,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(cx - size.width * 0.11, size.height - size.height * 0.79),
      size.width * 0.04,
      Paint()..color = Colors.black87,
    );
    canvas.drawCircle(
      Offset(cx + size.width * 0.15, size.height - size.height * 0.79),
      size.width * 0.04,
      Paint()..color = Colors.black87,
    );

    // Smile
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, size.height - size.height * 0.73),
        width: size.width * 0.22,
        height: size.height * 0.07,
      ),
      0,
      3.14,
      false,
      Paint()
        ..color = const Color(0xFFCC8866)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_CharDetailPainter old) =>
      old.bodyColor != bodyColor || old.skinColor != skinColor;
}
