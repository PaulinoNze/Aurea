import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// GlassCard — Contenedor semi-transparente estilo glass
// ---------------------------------------------------------------------------

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.borderRadius = 16,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceContainerLow.withOpacity(0.85),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: AppColors.onSurface.withOpacity(0.06),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CategoryIcon — Ícono circular de categoría
// ---------------------------------------------------------------------------

class CategoryIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double size;
  final bool isActive;

  const CategoryIcon({
    super.key,
    required this.icon,
    this.color = AppColors.onSecondaryContainer,
    this.backgroundColor = AppColors.secondaryContainer,
    this.size = 40,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: isActive
            ? Border.all(color: color, width: 1.5)
            : null,
      ),
      child: Center(
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// ProgressRing — Anillo de progreso SVG circular (CustomPainter)
// ---------------------------------------------------------------------------

class ProgressRing extends StatefulWidget {
  final double progress; // 0.0 – 1.0
  final Color color;
  final Color backgroundColor;
  final double size;
  final String label;
  final TextStyle? labelStyle;

  const ProgressRing({
    super.key,
    required this.progress,
    required this.color,
    this.backgroundColor = AppColors.surfaceVariant,
    this.size = 64,
    this.label = '',
    this.labelStyle,
  });

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, _) => CustomPaint(
          painter: _RingPainter(
            progress: _animation.value,
            color: widget.color,
            backgroundColor: widget.backgroundColor,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: widget.labelStyle ??
                  TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: widget.size * 0.18,
                    fontWeight: FontWeight.w500,
                    color: widget.color,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.10;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - strokeWidth / 2,
    );

    // Background ring
    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -1.5708, 6.2832, false, bgPaint);

    // Progress ring
    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -1.5708, 6.2832 * progress, false, fgPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ---------------------------------------------------------------------------
// LinearProgressBar — Barra de progreso estilizada
// ---------------------------------------------------------------------------

class LinearProgressBar extends StatefulWidget {
  final double progress; // 0.0 – 1.0
  final Color color;
  final Color backgroundColor;
  final double height;
  final BorderRadius? borderRadius;

  const LinearProgressBar({
    super.key,
    required this.progress,
    this.color = AppColors.secondary,
    this.backgroundColor = AppColors.surfaceContainerHigh,
    this.height = 6,
    this.borderRadius,
  });

  @override
  State<LinearProgressBar> createState() => _LinearProgressBarState();
}

class _LinearProgressBarState extends State<LinearProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final br = widget.borderRadius ?? BorderRadius.circular(999);
    return ClipRRect(
      borderRadius: br,
      child: Container(
        height: widget.height,
        color: widget.backgroundColor,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, _) => FractionallySizedBox(
            widthFactor: _animation.value.clamp(0.0, 1.0),
            alignment: Alignment.centerLeft,
            child: Container(
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: br,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SectionHeader — Cabecera de sección con título y acción opcional
// ---------------------------------------------------------------------------

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
        if (actionLabel != null)
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.add, size: 16, color: AppColors.tertiary),
            label: Text(
              actionLabel!,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.tertiary,
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// AmountText — Texto financiero con signo coloreado
// ---------------------------------------------------------------------------

class AmountText extends StatelessWidget {
  final double amount;
  final bool isIncome;
  final double fontSize;
  final FontWeight fontWeight;

  const AmountText({
    super.key,
    required this.amount,
    required this.isIncome,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w600,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.secondary : AppColors.onSurface;
    final prefix = isIncome ? '+' : '-';
    return Text(
      '$prefix\$${amount.toStringAsFixed(2)}',
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// AureaAppBar — AppBar consistente con el diseño
// ---------------------------------------------------------------------------

class AureaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showSyncBadge;

  const AureaAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.showSyncBadge = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: leading ??
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.account_balance_wallet, color: AppColors.primary),
          ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
      ),
      centerTitle: true,
      actions: actions ??
          [
            if (showSyncBadge)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.cloud_done_outlined,
                      color: AppColors.secondary),
                  onPressed: () {},
                ),
              ),
          ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: AppColors.outlineVariant.withOpacity(0.2),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// FadeSlideIn — Animación de entrada para widgets
// ---------------------------------------------------------------------------

class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Offset beginOffset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.beginOffset = const Offset(0, 0.08),
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: widget.beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
