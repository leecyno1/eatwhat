import 'package:flame_forge2d/flame_forge2d.dart';

class WallBody extends BodyComponent {
  final Vector2 start;
  final Vector2 end;

  WallBody(this.start, this.end);

  @override
  Body createBody() {
    final shape = EdgeShape()..set(start, end);
    final fixtureDef = FixtureDef(shape)
      ..friction = 0.62
      ..restitution = 0.0;
    final bodyDef = BodyDef(
      position: Vector2.zero(),
      type: BodyType.static,
    );

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}
