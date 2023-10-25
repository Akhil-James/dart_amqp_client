import 'package:dart_amqp_client/dart_amqp_client.dart';

void main() {
  // Create a ConnectionSettings instance with your AMQP server details.
  ConnectionSettings connectionSettings = ConnectionSettings(
    host: 'localhost',
    port: 5672,
    maxConnectionAttempts: 5, // Set the maximum connection attempts
  );

  // Create an instance of the AMQP service.
  AmqpService(connectionSettings);

  // Set callback functions for connection events.
  AmqpService.onConnected(() {
    print('Connected to AMQP server.');
    // Use the service to establish an AMQP connection.
    Client client = AmqpService.getClient();

    // ... Perform AMQP operations with the client and channel ...

    String consumeTag = "hello";
    String msg = "Hello World!";

    client.channel().then((Channel channel) {
      return channel.queue(consumeTag, durable: false);
    }).then((Queue queue) {
      queue.publish(msg);
      print(" [x] Sent $msg");
      client.close();
    });

    String queueTag = "hello";
    Channel? channel = AmqpService.getChannel();
    channel!.queue(queueTag, durable: false).then((Queue queue) {
      print(" [*] Waiting for messages in $queueTag. To Exit press CTRL+C");
      return queue.consume(consumerTag: queueTag, noAck: true);
    }).then((Consumer consumer) {
      consumer.listen((AmqpMessage event) {
        print(" [x] Received ${event.payloadAsString}");
      });
    });
  });

  AmqpService.onDisconnected(() {
    print('Disconnected from AMQP server.');
  });

  AmqpService.onError((Exception error) {
    print('An error occurred: $error');
  });
}
