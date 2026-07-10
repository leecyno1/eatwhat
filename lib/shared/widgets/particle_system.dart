import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 粒子类型
enum ParticleType {
  star, // 星星
  bubble, // 气泡
  heart, // 爱心
  spark, // 火花
  food, // 食物图标
}

/// 单个粒子
class Particle {
  Offset position;
  Offset velocity;
  double size;
  double life;
  double maxLife;
  Color color;
  double rotation;
  double rotationSpeed;
  ParticleType type;
  double opacity;

  Particle({
    required this.position,
    required this.velocity,
    required this.size,
    required this.life,
    required this.maxLife,
    required this.color,
    this.rotation = 0.0,
    this.rotationSpeed = 0.0,
    required this.type,
    this.opacity = 1.0,
  });

  /// 更新粒子状态
  void update(double deltaTime) {
    // 更新位置
    position = Offset(
      position.dx + velocity.dx * deltaTime,
      position.dy + velocity.dy * deltaTime,
    );

    // 更新旋转
    rotation += rotationSpeed * deltaTime;

    // 更新生命值
    life -= deltaTime;

    // 更新透明度（基于生命值）
    opacity = (life / maxLife).clamp(0.0, 1.0);

    // 添加重力效果（部分粒子类型）
    if (type == ParticleType.bubble || type == ParticleType.food) {
      velocity = Offset(velocity.dx, velocity.dy + 50 * deltaTime);
    }
  }

  /// 检查粒子是否仍然存活
  bool get isAlive => life > 0;
}

/// 粒子系统管理器
class ParticleSystemManager {
  final List<Particle> _particles = [];
  final math.Random _random = math.Random();

  // 系统配置
  int maxParticles;
  Size containerSize;

  ParticleSystemManager({
    this.maxParticles = 100,
    this.containerSize = const Size(400, 600),
  });

  /// 添加爆炸效果
  void addExplosion({
    required Offset center,
    required ParticleType type,
    int count = 20,
    Color? color,
  }) {
    for (int i = 0; i < count; i++) {
      if (_particles.length >= maxParticles) break;

      final angle = (_random.nextDouble() * 2 * math.pi);
      final speed = 100 + _random.nextDouble() * 200;
      final velocity = Offset(
        math.cos(angle) * speed,
        math.sin(angle) * speed,
      );

      _particles.add(Particle(
        position: center,
        velocity: velocity,
        size: 3 + _random.nextDouble() * 6,
        life: 1.0 + _random.nextDouble() * 2.0,
        maxLife: 1.0 + _random.nextDouble() * 2.0,
        color: color ?? _getRandomColor(type),
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 4,
        type: type,
      ));
    }
  }

  /// 添加持续发射效果
  void addContinuousEmission({
    required Offset source,
    required ParticleType type,
    int particlesPerSecond = 10,
    Color? color,
  }) {
    // 根据帧率计算每帧应该产生的粒子数
    final particlesThisFrame = particlesPerSecond / 60;

    if (_random.nextDouble() < particlesThisFrame) {
      if (_particles.length >= maxParticles) return;

      final angle = _random.nextDouble() * 2 * math.pi;
      final speed = 50 + _random.nextDouble() * 100;
      final velocity = Offset(
        math.cos(angle) * speed,
        math.sin(angle) * speed,
      );

      _particles.add(Particle(
        position: source +
            Offset(
              (_random.nextDouble() - 0.5) * 20,
              (_random.nextDouble() - 0.5) * 20,
            ),
        velocity: velocity,
        size: 2 + _random.nextDouble() * 4,
        life: 2.0 + _random.nextDouble() * 3.0,
        maxLife: 2.0 + _random.nextDouble() * 3.0,
        color: color ?? _getRandomColor(type),
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 2,
        type: type,
      ));
    }
  }

  /// 添加轨迹效果
  void addTrail({
    required Offset start,
    required Offset end,
    required ParticleType type,
    int count = 15,
    Color? color,
  }) {
    for (int i = 0; i < count; i++) {
      if (_particles.length >= maxParticles) break;

      final t = i / (count - 1);
      final position = Offset.lerp(start, end, t)!;

      _particles.add(Particle(
        position: position +
            Offset(
              (_random.nextDouble() - 0.5) * 10,
              (_random.nextDouble() - 0.5) * 10,
            ),
        velocity: Offset(
          (_random.nextDouble() - 0.5) * 50,
          (_random.nextDouble() - 0.5) * 50,
        ),
        size: 1 + _random.nextDouble() * 3,
        life: 0.5 + _random.nextDouble() * 1.0,
        maxLife: 0.5 + _random.nextDouble() * 1.0,
        color: color ?? _getRandomColor(type),
        rotation: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: (_random.nextDouble() - 0.5) * 3,
        type: type,
      ));
    }
  }

  /// 更新所有粒子
  void update(double deltaTime) {
    // 更新现有粒子
    for (final particle in _particles) {
      particle.update(deltaTime);
    }

    // 移除死亡的粒子
    _particles.removeWhere((particle) => !particle.isAlive);

    // 边界检查 - 移除超出边界的粒子
    _particles.removeWhere((particle) {
      return particle.position.dx < -50 ||
          particle.position.dx > containerSize.width + 50 ||
          particle.position.dy < -50 ||
          particle.position.dy > containerSize.height + 50;
    });
  }

  /// 获取所有存活的粒子
  List<Particle> get particles => List.unmodifiable(_particles);

  /// 清空所有粒子
  void clear() {
    _particles.clear();
  }

  /// 获取粒子数量
  int get particleCount => _particles.length;

  /// 根据类型获取随机颜色
  Color _getRandomColor(ParticleType type) {
    switch (type) {
      case ParticleType.star:
        return [Colors.yellow, Colors.orange, Colors.white][_random.nextInt(3)];
      case ParticleType.bubble:
        return [Colors.blue, Colors.cyan, Colors.lightBlue][_random.nextInt(3)];
      case ParticleType.heart:
        return [Colors.red, Colors.pink, Colors.redAccent][_random.nextInt(3)];
      case ParticleType.spark:
        return [Colors.orange, Colors.red, Colors.yellow][_random.nextInt(3)];
      case ParticleType.food:
        return [Colors.green, Colors.orange, Colors.brown][_random.nextInt(3)];
    }
  }
}

/// 粒子系统渲染组件
class ParticleSystemWidget extends StatefulWidget {
  final ParticleSystemManager manager;
  final Widget? child;

  const ParticleSystemWidget({
    super.key,
    required this.manager,
    this.child,
  });

  @override
  State<ParticleSystemWidget> createState() => _ParticleSystemWidgetState();
}

class _ParticleSystemWidgetState extends State<ParticleSystemWidget> with TickerProviderStateMixin {
  late AnimationController _controller;
  DateTime? _lastFrameTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(days: 365), // 长时间运行
      vsync: this,
    );
    _controller.addListener(_updateParticles);
    _controller.forward();
  }

  void _updateParticles() {
    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final deltaTime = now.difference(_lastFrameTime!).inMicroseconds / 1000000.0;
      widget.manager.update(deltaTime);
    }
    _lastFrameTime = now;

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (widget.child != null) widget.child!,
        Positioned.fill(
          child: CustomPaint(
            painter: ParticlePainter(widget.manager.particles),
          ),
        ),
      ],
    );
  }
}

/// 粒子绘制器
class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      _paintParticle(canvas, particle);
    }
  }

  void _paintParticle(Canvas canvas, Particle particle) {
    final paint = Paint()
      ..color = particle.color.withValues(alpha: particle.opacity)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(particle.position.dx, particle.position.dy);
    canvas.rotate(particle.rotation);

    switch (particle.type) {
      case ParticleType.star:
        _drawStar(canvas, paint, particle.size);
        break;
      case ParticleType.bubble:
        _drawBubble(canvas, paint, particle.size);
        break;
      case ParticleType.heart:
        _drawHeart(canvas, paint, particle.size);
        break;
      case ParticleType.spark:
        _drawSpark(canvas, paint, particle.size);
        break;
      case ParticleType.food:
        _drawFood(canvas, paint, particle.size);
        break;
    }

    canvas.restore();
  }

  void _drawStar(Canvas canvas, Paint paint, double size) {
    final path = Path();
    const points = 5;
    const outerRadius = 1.0;
    const innerRadius = 0.4;

    for (int i = 0; i < points * 2; i++) {
      final angle = (i * math.pi) / points;
      final radius = (i % 2 == 0) ? outerRadius : innerRadius;
      final x = math.cos(angle) * radius * size;
      final y = math.sin(angle) * radius * size;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawBubble(Canvas canvas, Paint paint, double size) {
    // 外圈
    canvas.drawCircle(Offset.zero, size, paint);

    // 高光
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(-size * 0.3, -size * 0.3), size * 0.3, highlightPaint);
  }

  void _drawHeart(Canvas canvas, Paint paint, double size) {
    final path = Path();

    // 简化的心形
    path.moveTo(0, size * 0.3);
    path.cubicTo(-size * 0.5, -size * 0.2, -size * 0.8, size * 0.2, 0, size);
    path.cubicTo(size * 0.8, size * 0.2, size * 0.5, -size * 0.2, 0, size * 0.3);

    canvas.drawPath(path, paint);
  }

  void _drawSpark(Canvas canvas, Paint paint, double size) {
    // 十字形火花
    final strokePaint = Paint()
      ..color = paint.color
      ..strokeWidth = size * 0.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(-size, 0), Offset(size, 0), strokePaint);
    canvas.drawLine(Offset(0, -size), Offset(0, size), strokePaint);
  }

  void _drawFood(Canvas canvas, Paint paint, double size) {
    // 简单的圆形食物图标
    canvas.drawCircle(Offset.zero, size, paint);

    // 添加一些细节
    final detailPaint = Paint()
      ..color = paint.color.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size * 0.3, 0), size * 0.3, detailPaint);
    canvas.drawCircle(Offset(-size * 0.2, size * 0.2), size * 0.2, detailPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

/// 预设粒子效果
class ParticleEffects {
  static void bubbleSelection(ParticleSystemManager manager, Offset position) {
    manager.addExplosion(
      center: position,
      type: ParticleType.star,
      count: 12,
      color: Colors.yellow,
    );
  }

  static void foodRecommendation(ParticleSystemManager manager, Offset position) {
    manager.addExplosion(
      center: position,
      type: ParticleType.food,
      count: 15,
      color: Colors.orange,
    );
  }

  static void likeAction(ParticleSystemManager manager, Offset position) {
    manager.addExplosion(
      center: position,
      type: ParticleType.heart,
      count: 8,
      color: Colors.red,
    );
  }

  static void swipeDownAction(ParticleSystemManager manager, Offset position) {
    manager.addExplosion(
      center: position,
      type: ParticleType.spark,
      count: 10,
      color: Colors.orange,
    );
  }

  static void dislikeAction(ParticleSystemManager manager, Offset position) {
    manager.addExplosion(
      center: position,
      type: ParticleType.spark,
      count: 15,
      color: Colors.grey,
    );
  }

  static void celebrationEffect(ParticleSystemManager manager, Size containerSize) {
    for (int i = 0; i < 5; i++) {
      manager.addExplosion(
        center: Offset(
          math.Random().nextDouble() * containerSize.width,
          math.Random().nextDouble() * containerSize.height * 0.3,
        ),
        type: ParticleType.star,
        count: 20,
        color: [Colors.yellow, Colors.orange, Colors.red][i % 3],
      );
    }
  }

  static void ambientBubbles(ParticleSystemManager manager, Size containerSize) {
    manager.addContinuousEmission(
      source: Offset(
        math.Random().nextDouble() * containerSize.width,
        containerSize.height + 20,
      ),
      type: ParticleType.bubble,
      particlesPerSecond: 3,
      color: Colors.blue.withValues(alpha: 0.3),
    );
  }
}
