import 'package:dart_amqp_client/dart_amqp_client.dart';
import 'package:test/test.dart';

void main() {
  group('A group of tests for AmqpSevice', () {
    AmqpService(ConnectionSettings());

    setUp(() {
      AmqpService.connect();
    });

    test('First Test', () {
      expect(AmqpService.getClient(), isNotNull);
    });
  });
}
