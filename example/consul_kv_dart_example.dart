import 'dart:async';
import 'package:consul_kv_dart/consul_kv_dart.dart';

Future main() async {
  var consul = new ConsulKV(defaultHeaders: {'X-Consul-Token': 'bcd1234'});
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
