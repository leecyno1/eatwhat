import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/core/services/offline_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncItem', () {
    test('应该能创建SyncItem', () {
      final item = SyncItem(
        id: 'item_001',
        type: 'food',
        data: {'name': '番茄鸡蛋面', 'price': 15.0},
      );

      expect(item.id, equals('item_001'));
      expect(item.type, equals('food'));
      expect(item.data['name'], equals('番茄鸡蛋面'));
      expect(item.retryCount, equals(0));
    });

    test('应该能检查是否可以重试', () {
      final item = SyncItem(
        id: 'item_001',
        type: 'food',
        data: {},
        retryCount: 2,
      );

      expect(item.canRetry, equals(true));

      item.retryCount = 3;
      expect(item.canRetry, equals(false));
    });

    test('应该能转换为Map', () {
      final item = SyncItem(
        id: 'item_001',
        type: 'food',
        data: {'name': 'test'},
      );

      final map = item.toMap();
      expect(map['id'], equals('item_001'));
      expect(map['type'], equals('food'));
      expect(map['data']['name'], equals('test'));
    });

    test('应该能从Map创建', () {
      final map = {
        'id': 'item_001',
        'type': 'food',
        'data': {'name': 'test'},
        'created_at': DateTime.now().toIso8601String(),
        'retry_count': 1,
      };

      final item = SyncItem.fromMap(map);
      expect(item.id, equals('item_001'));
      expect(item.type, equals('food'));
      expect(item.retryCount, equals(1));
    });

    test('应该有最大重试次数限制', () {
      expect(SyncItem.maxRetries, equals(3));
    });
  });

  group('OfflineSyncService', () {
    late OfflineSyncService service;

    setUp(() {
      service = OfflineSyncService();
      service.clearQueue();
    });

    tearDown(() {
      service.clearQueue();
    });

    test('应该能初始化服务', () async {
      // 跳过需要平台通道的测试
    }, skip: '需要平台通道支持');

    test('应该能添加同步项', () {
      final item = SyncItem(
        id: 'item_001',
        type: 'food',
        data: {'name': 'test'},
      );

      service.addSyncItem(item);
      expect(service.pendingCount, equals(1));
    });

    test('应该能获取同步队列', () {
      final item1 = SyncItem(id: 'item_001', type: 'food', data: {});
      final item2 = SyncItem(id: 'item_002', type: 'food', data: {});

      service.addSyncItem(item1);
      service.addSyncItem(item2);

      final queue = service.getSyncQueue();
      expect(queue.length, equals(2));
    });

    test('应该能清空同步队列', () {
      final item = SyncItem(id: 'item_001', type: 'food', data: {});
      service.addSyncItem(item);

      expect(service.pendingCount, equals(1));

      service.clearQueue();
      expect(service.pendingCount, equals(0));
    });

    test('应该能获取当前同步状态', () {
      expect(service.currentStatus, isA<SyncStatus>());
    });

    test('应该能获取在线状态', () {
      expect(service.isOnline, isA<bool>());
    });

    test('应该能获取待同步项数量', () {
      expect(service.pendingCount, equals(0));

      service.addSyncItem(SyncItem(id: '1', type: 'test', data: {}));
      expect(service.pendingCount, equals(1));

      service.addSyncItem(SyncItem(id: '2', type: 'test', data: {}));
      expect(service.pendingCount, equals(2));
    });

    test('应该能监听同步状态变化', () async {
      // 跳过需要平台通道的测试
    }, skip: '需要平台通道支持');

    test('应该能同步所有项目', () async {
      // 跳过需要平台通道的测试
    }, skip: '需要平台通道支持');

    test('离线时不应该同步', () async {
      // 跳过需要平台通道的测试
    }, skip: '需要平台通道支持');

    test('应该能释放资源', () {
      service.dispose();
      // 释放后不应该崩溃
    });
  });

  group('SyncStatus', () {
    test('应该包含所有同步状态', () {
      expect(SyncStatus.values.length, equals(4));
      expect(SyncStatus.values, contains(SyncStatus.idle));
      expect(SyncStatus.values, contains(SyncStatus.syncing));
      expect(SyncStatus.values, contains(SyncStatus.success));
      expect(SyncStatus.values, contains(SyncStatus.failed));
    });
  });
}
