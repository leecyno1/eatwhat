import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _productionServerEntrypoints = <String>[
  'scripts/eatwhat_auth_server.dart',
  'scripts/payment_server.dart',
  'scripts/execution_proxy_server.dart',
  'scripts/meituan_delivery_adapter_server.dart',
];

const _existingContractFiles = <String>[
  'lib/core/contracts/alipay_payment_contract.dart',
  'lib/core/contracts/auth_session_contract.dart',
];

void main() {
  test('production server entrypoints do not import or export each other', () {
    final root = Directory.current;
    for (final path in _productionServerEntrypoints) {
      expect(
        _repoFile(root, path).existsSync(),
        isTrue,
        reason: 'Missing production server entrypoint: $path',
      );
    }

    final violations = _serverBoundaryViolations(root);
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('core contracts remain pure DTO contracts', () {
    final root = Directory.current;
    final contracts = _repoDirectory(root, 'lib/core/contracts');
    expect(
      contracts.existsSync(),
      isTrue,
      reason: 'Missing DTO contract directory: ${contracts.path}',
    );
    if (!contracts.existsSync()) return;

    final contractPaths = _dartFiles(
      contracts,
    ).map((file) => _relativePath(root, file)).toList();
    expect(
      contractPaths,
      containsAll(_existingContractFiles),
      reason: 'The architecture gate must cover the existing DTO contracts.',
    );

    final violations = _contractViolations(root);
    expect(violations, isEmpty, reason: violations.join('\n'));
  });

  test('scanner reports server and forbidden contract fixture dependencies',
      () {
    final root = Directory.systemTemp.createTempSync(
      'eatwhat_backend_boundary_',
    );
    addTearDown(() => root.deleteSync(recursive: true));

    for (final path in _productionServerEntrypoints.skip(1)) {
      _writeFixture(root, path, '');
    }
    _writeFixture(root, _productionServerEntrypoints.first, '''
import 'payment_server.dart';
export 'execution_proxy_server.dart';
''');
    _writeFixture(root, 'lib/core/contracts/bad_contract.dart', '''
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:eatwhat_app/v2/features/home/home_page.dart';
export 'package:eatwhat_app/app/app_dependencies.dart';
''');

    final violations = _scanArchitecture(root);

    expect(violations, hasLength(5), reason: violations.join('\n'));
    expect(
      violations,
      containsAll([
        'scripts/eatwhat_auth_server.dart imports scripts/payment_server.dart',
        'scripts/eatwhat_auth_server.dart exports scripts/execution_proxy_server.dart',
        'lib/core/contracts/bad_contract.dart imports forbidden package:flutter/material.dart',
        'lib/core/contracts/bad_contract.dart imports forbidden package:eatwhat_app/v2/features/home/home_page.dart',
        'lib/core/contracts/bad_contract.dart exports forbidden package:eatwhat_app/app/app_dependencies.dart',
      ]),
      reason: violations.join('\n'),
    );
  });
}

List<String> _scanArchitecture(Directory root) {
  return [
    ..._serverBoundaryViolations(root),
    ..._contractViolations(root),
  ];
}

List<String> _serverBoundaryViolations(Directory root) {
  const entrypoints = _productionServerEntrypoints;
  final entrypointSet = entrypoints.toSet();
  final violations = <String>[];

  for (final sourcePath in entrypoints) {
    final source = _repoFile(root, sourcePath);
    if (!source.existsSync()) continue;

    for (final dependency in _dependencies(root, source)) {
      final targetPath = dependency.repoPath;
      if (targetPath == null ||
          targetPath == sourcePath ||
          !entrypointSet.contains(targetPath)) {
        continue;
      }
      violations.add(
        '$sourcePath ${dependency.directive}s $targetPath',
      );
    }
  }

  return violations;
}

List<String> _contractViolations(Directory root) {
  final contracts = _repoDirectory(root, 'lib/core/contracts');
  if (!contracts.existsSync()) return const <String>[];

  final violations = <String>[];
  for (final source in _dartFiles(contracts)) {
    final sourcePath = _relativePath(root, source);
    for (final dependency in _dependencies(root, source)) {
      if (_isForbiddenContractDependency(dependency)) {
        violations.add(
          '$sourcePath ${dependency.directive}s forbidden ${dependency.uri}',
        );
      }
    }
  }
  return violations;
}

typedef _SourceDependency = ({
  String directive,
  String uri,
  String? repoPath,
});

Iterable<_SourceDependency> _dependencies(
  Directory root,
  File source,
) sync* {
  final directivePattern = RegExp(
    r"""^\s*(import|export)\s+['"]([^'"]+)['"]""",
    multiLine: true,
  );
  for (final match in directivePattern.allMatches(
    source.readAsStringSync(),
  )) {
    final uri = match.group(2)!;
    yield (
      directive: match.group(1)!,
      uri: uri,
      repoPath: _resolveRepoPath(root, source, uri),
    );
  }
}

String? _resolveRepoPath(Directory root, File source, String uri) {
  const packagePrefix = 'package:eatwhat_app/';
  if (uri.startsWith(packagePrefix)) {
    final packagePath = uri.substring(packagePrefix.length);
    return p.posix.normalize(p.posix.join('lib', packagePath));
  }
  if (uri.startsWith('package:') || uri.startsWith('dart:')) return null;

  final parsed = Uri.tryParse(uri);
  if (parsed == null || parsed.hasScheme) return null;
  final resolved = p.normalize(
    p.join(p.dirname(source.path), parsed.path),
  );
  if (!p.isWithin(root.path, resolved)) return null;
  return p.posix.joinAll(p.split(p.relative(resolved, from: root.path)));
}

bool _isForbiddenContractDependency(_SourceDependency dependency) {
  final uri = dependency.uri;
  if (uri == 'dart:ui' ||
      uri == 'package:flutter' ||
      uri.startsWith('package:flutter/') ||
      uri.startsWith('package:flutter_')) {
    return true;
  }

  final path = dependency.repoPath;
  if (path == null) return false;
  if (path == 'lib/main.dart' ||
      path == 'lib/app.dart' ||
      path.startsWith('lib/app/') ||
      path == 'lib/v2/app_v2.dart' ||
      path == 'lib/v2/core/navigation/app_v2_router.dart') {
    return true;
  }

  final segments = p.posix.split(path);
  if (segments.contains('features') ||
      segments.contains('services') ||
      segments.contains('scripts') ||
      segments.contains('server') ||
      segments.contains('servers')) {
    return true;
  }

  final basename = p.posix.basename(path);
  return basename == 'server.dart' || basename.endsWith('_server.dart');
}

Iterable<File> _dartFiles(Directory directory) {
  return directory
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'));
}

File _repoFile(Directory root, String path) {
  return File(p.joinAll([root.path, ...p.posix.split(path)]));
}

Directory _repoDirectory(Directory root, String path) {
  return Directory(p.joinAll([root.path, ...p.posix.split(path)]));
}

String _relativePath(Directory root, File file) {
  return p.posix.joinAll(p.split(p.relative(file.path, from: root.path)));
}

void _writeFixture(Directory root, String path, String contents) {
  _repoFile(root, path)
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
}
