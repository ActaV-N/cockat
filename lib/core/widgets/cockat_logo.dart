import 'package:flutter/material.dart';

/// 로고 크기 프리셋
enum LogoSize {
  /// 헤더용 (120px)
  header(120),

  /// 중간 크기 (80px) - Empty state 등
  medium(80),

  /// 소형 (48px) - Profile, About 등
  small(48),

  /// 아이콘 크기 (32px)
  icon(32);

  final double height;
  const LogoSize(this.height);
}

/// Cockat 로고 위젯
///
/// 앱 전체에서 일관된 로고 표시를 위한 공통 컴포넌트
class CockatLogo extends StatelessWidget {
  /// 로고 높이 (너비는 자동 조절)
  final double? height;

  /// 프리셋 크기
  final LogoSize? size;

  /// 투명 배경 로고 사용 여부
  final bool transparent;

  /// 불투명도 (워터마크용)
  final double opacity;

  /// 색상 필터 (브랜드 컬러 적용시)
  final Color? color;

  const CockatLogo({
    super.key,
    this.height,
    this.size,
    this.transparent = true,
    this.opacity = 1.0,
    this.color,
  });

  /// 헤더용 로고
  const CockatLogo.header({super.key})
      : height = null,
        size = LogoSize.header,
        transparent = true,
        opacity = 1.0,
        color = null;

  /// Empty state용 subtle 로고
  const CockatLogo.watermark({super.key})
      : height = null,
        size = LogoSize.medium,
        transparent = true,
        opacity = 0.15,
        color = null;

  /// 소형 로고
  const CockatLogo.small({super.key})
      : height = null,
        size = LogoSize.small,
        transparent = true,
        opacity = 1.0,
        color = null;

  @override
  Widget build(BuildContext context) {
    final logoHeight = height ?? size?.height ?? LogoSize.medium.height;
    final assetPath = transparent
        ? 'assets/logos/cockat-transparent.png'
        : 'assets/logos/cockat.png';

    Widget logo = Image.asset(
      assetPath,
      height: logoHeight,
      fit: BoxFit.contain,
      color: color,
      colorBlendMode: color != null ? BlendMode.srcIn : null,
    );

    if (opacity < 1.0) {
      logo = Opacity(opacity: opacity, child: logo);
    }

    return logo;
  }
}

/// 로고와 앱 이름을 함께 표시하는 위젯
class CockatLogoWithText extends StatelessWidget {
  final LogoSize size;
  final bool showTagline;

  const CockatLogoWithText({
    super.key,
    this.size = LogoSize.header,
    this.showTagline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CockatLogo(size: size),
        if (showTagline) ...[
          const SizedBox(height: 8),
          Text(
            'Your Personal Bartender',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
