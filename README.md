# consul_kv_dart

Dart client for the Consul KV-store.

Wraps Consul's simple [key/value](https://www.consul.io/api/kv.html) store API.
Client uses HTTP requests to communicate with Consul.
Each method has optional parameters that are described in Consul API docs.

You might want to wrap responses into some kind of handler 
(check status codes, encode\convert values, etc.) - result is a flexible [`Response`](https://www.dartdocs.org/documentation/http/0.11.3%2B16/http/Response-class.html) object.

Each method return [`Future`](https://api.dartlang.org/stable/1.24.3/dart-async/Future-class.html) which is used to get result.

## Usage

A simple usage example:

```dart
Future main() async {
  var consul = new ConsulKV(port: 5579, defaultHeaders: {'X-Consul-Token': 'bcd1234'});
  var newKey = await consul.put('foo', 'bar');
  var foundKey = await consul.get('foo');
  var insertIfNotExists = await consul.put('foo', 'bar', cas: 1);
  var deleteKey = await consul.delete('foo');
  var keyNotExists = await consul.get('foo');

  print(newKey.body); // true
  print(newKey.statusCode); // 200

  print(foundKey.body); // [{"LockIndex":0,"Key":"foo","Value":"YmFy",
                        // "CreateIndex":208877,"ModifyIndex":208877}]
  print(foundKey.statusCode);  // 200

  print(insertIfNotExists.body); // false
  print(insertIfNotExists.statusCode); // 200

  print(deleteKey.body); // true
  print(deleteKey.statusCode); // 200

  print(keyNotExists.statusCode); // 404

  consul.close();

}
```

