import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('V2 core 不依赖任何 feature 页面', () {
    final violations = <String>[];
    for (final file in _dartFiles(Directory('lib/v2/core'))) {
      for (final dependency in _dependencyPaths(file)) {
        if (_isFeatureDependency(dependency)) {
          violations.add('${file.path} -> $dependency');
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('feature 页面不依赖路由组合根', () {
    final violations = <String>[];
    for (final file in _dartFiles(Directory('lib/v2/features'))) {
      for (final dependency in _dependencyPaths(file)) {
        if (_isCompositionRootDependency(dependency)) {
          violations.add('${file.path} -> $dependency');
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('路由契约不依赖页面或组合根', () {
    final contract = File('lib/v2/core/navigation/app_v2_routes.dart');
    expect(contract.existsSync(), isTrue);
    if (!contract.existsSync()) return;

    final violations = _dependencyPaths(contract).where((dependency) {
      return _isFeatureDependency(dependency) ||
          _isCompositionRootDependency(dependency);
    }).toList();
    expect(violations, isEmpty);
  });

  test('架构扫描识别 export、相对路径与组合根依赖', () {
    final directory = Directory.systemTemp.createTempSync('eatwhat_arch_');
    addTearDown(() => directory.deleteSync(recursive: true));
    final file = File(
      p.join(directory.path, 'lib/v2/core/navigation/contract.dart'),
    )
      ..createSync(recursive: true)
      ..writeAsStringSync('''
import 'package:eatwhat_app/app/app_demo_routes.dart';
export 'package:eatwhat_app/app/app_dependencies.dart';
export '../../features/result/result_page.dart';
import '../../../app/app_router.dart';
import "package:eatwhat_app/v2/features/home/home_page.dart";
''');

    final dependencies = _dependencyPaths(file).toList();

    expect(
      dependencies,
      containsAll([
        'app/app_demo_routes.dart',
        'app/app_dependencies.dart',
        'app/app_router.dart',
        'v2/features/result/result_page.dart',
        'v2/features/home/home_page.dart',
      ]),
    );
    expect(
      dependencies.where(_isCompositionRootDependency),
      containsAll([
        'app/app_demo_routes.dart',
        'app/app_dependencies.dart',
        'app/app_router.dart',
      ]),
    );
    expect(
      dependencies.where(_isFeatureDependency),
      containsAll([
        'v2/features/result/result_page.dart',
        'v2/features/home/home_page.dart',
      ]),
    );
  });
}

Iterable<File> _dartFiles(Directory directory) {
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

bool _isFeatureDependency(String dependency) {
  return dependency.startsWith('v2/features/') ||
      dependency.startsWith('features/');
}

bool _isCompositionRootDependency(String dependency) {
  return dependency.startsWith('app/') ||
      dependency == 'v2/core/navigation/app_v2_router.dart';
}

Iterable<String> _dependencyPaths(File file) sync* {
  final pattern = RegExp(
    r"""^\s*(?:import|export)\s+['"]([^'"]+)['"]""",
    multiLine: true,
  );
  for (final match in pattern.allMatches(file.readAsStringSync())) {
    final uri = match.group(1)!;
    if (uri.startsWith('package:eatwhat_app/')) {
      yield uri.substring('package:eatwhat_app/'.length);
      continue;
    }
    if (uri.startsWith('package:') || uri.startsWith('dart:')) continue;

    final normalized = p.posix.normalize(
      p.posix.join(p.posix.dirname(file.path), uri),
    );
    if (normalized.startsWith('lib/')) {
      yield normalized.substring('lib/'.length);
      continue;
    }
    const marker = '/lib/';
    final markerIndex = normalized.indexOf(marker);
    if (markerIndex >= 0) {
      yield normalized.substring(markerIndex + marker.length);
    }
  }
}
