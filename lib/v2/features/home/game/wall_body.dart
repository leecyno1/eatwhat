import 'package:flame_forge2d/flame_forge2d.dart';

class WallBody extends BodyComponent {

  WallBody(this.start, this.end);
  final Vector2 start;
  final Vector2 end;

  @override
  Body createBody() {
    final shape = EdgeShape()..set(start, end);
    final fixtureDef = FixtureDef(shape)
      ..friction = 0.62
      ..restitution = 0.0;
    final bodyDef = BodyDef(
      position: Vector2.zero(),
    );

    return world.createBody(bodyDef)..createFixture(fixtureDef);
  }
}
