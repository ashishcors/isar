import 'package:isar/isar.dart';
import 'package:isar_test/isar_test_context.dart';
import 'package:test/test.dart';

import 'isar.g.dart';
import 'models/message_model.dart';

void run(IsarTestContext context) {
  group('Watcher', () {
    late Isar isar;
    late IsarCollection<Message> col;
    late List<Message> messages;

    setUp(() async {
      isar = await context.openIsar();
      col = isar.messages;

      messages = [
        Message()..message = 'How are you?',
        Message()..message = 'Good, thanks!',
        Message()..message = 'Third message',
        Message()..message = 'Good, thanks!',
      ];
      await isar.writeTxn((isar) async {
        await col.putAll(messages);
      });
    });

    tearDown(() async {
      await isar.close();
    });

    context.test('Collection', () async {
      var changeRegistered = false;
      col.watch().listen((event) {
        changeRegistered = true;
      });

      expect(changeRegistered, false);
      await isar.writeTxn((isar) => col.delete(messages[0].id!));
      expect(changeRegistered, true);

      changeRegistered = false;
      await isar.writeTxn((isar) => col.delete(5));
      expect(changeRegistered, false);

      await isar.writeTxn((isar) => col.where().deleteFirst());
      expect(changeRegistered, true);
    });

    context.test('Object lazy', () async {
      var changeRegistered = false;
      Message? event;
      col.watch(id: messages[1].id).listen((e) {
        changeRegistered = true;
        event = e;
      });

      expect(changeRegistered, false);
      expect(event, null);
      await isar.writeTxn(
        (isar) => col.delete(messages[0].id!),
      );
      expect(changeRegistered, false);
      expect(event, null);

      await isar.writeTxn((isar) {
        return col.put(messages[1]);
      });
      expect(changeRegistered, true);
      expect(event, null);

      changeRegistered = false;
      await isar.writeTxn(
          (isar) => col.where().messageEqualTo('Good, thanks!').deleteFirst());
      expect(changeRegistered, true);
      expect(event, null);
    });

    context.test('Object', () async {
      var changeRegistered = false;
      Message? event;
      col.watch(id: messages[1].id, lazy: false).listen((e) {
        changeRegistered = true;
        event = e;
      });

      expect(changeRegistered, false);
      expect(event, null);
      await isar.writeTxn((isar) => col.delete(messages[0].id!));
      await Future.delayed(Duration(seconds: 1));
      expect(changeRegistered, false);
      expect(event, null);

      messages[1].message = 'New message';
      await isar.writeTxn((isar) {
        return col.put(messages[1]);
      });
      await Future.delayed(Duration(seconds: 1));
      expect(changeRegistered, true);
      expect(event, messages[1]);

      changeRegistered = false;
      await isar.writeTxn(
          (isar) => col.where().messageEqualTo('New message').deleteFirst());
      await Future.delayed(Duration(seconds: 1));
      expect(changeRegistered, true);
      expect(event, null);
    });

    context.test('Query lazy', () async {
      final query =
          col.where().filter().messageEqualTo(messages[1].message).build();

      var changeRegistered = false;
      List<Message>? event;
      query.watch().listen((e) {
        changeRegistered = true;
        event = e;
      });

      expect(changeRegistered, false);
      expect(event, null);
      await isar.writeTxn(
        (isar) => col.delete(messages[0].id!),
      );
      expect(changeRegistered, false);
      expect(event, null);

      await isar.writeTxn((isar) {
        return col.put(messages[1]);
      });
      expect(changeRegistered, true);
      expect(event, null);

      changeRegistered = false;
      await isar.writeTxn((isar) => query.deleteFirst());

      expect(changeRegistered, true);
      expect(event, null);
    });

    /*context.test('Query', () async {
      final query =
          col.where().filter().messageEqualTo(messages[1].message).build();

      var changeRegistered = false;
      List<Message>? event;
      query.watch(lazy: false).listen((e) {
        changeRegistered = true;
        event = e;
      });

      expect(changeRegistered, false);
      expect(event, null);
      await isar.writeTxn(
        (isar) => col.delete(messages[0].id!),
      );
      await Future.delayed(Duration(seconds: 1));
      expect(changeRegistered, false);
      expect(event, null);

      await isar.writeTxn((isar) {
        return col.put(messages[1]);
      });
      await Future.delayed(Duration(seconds: 1));
      expect(changeRegistered, true);
      expect(event, [messages[1], messages[3]]);

      changeRegistered = false;
      await isar.writeTxn((isar) => query.deleteFirst());
      await Future.delayed(Duration(seconds: 1));
      expect(changeRegistered, true);
      expect(event, [messages[3]]);
    });*/
  });
}
