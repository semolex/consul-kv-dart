import 'package:consul_kv_dart/consul_kv_dart.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('Consul KV client', () {
    ConsulKV client;
    MockClient mockClient;
    Map<String, String> respHeaders;
    var getResponse =
        '[{"LockIndex":0,"Key":"dpg/user/display_limits/bar_chart","Flags":0,"Value":"MTAwMA==","CreateIndex":191430,"ModifyIndex":191430}]';

    setUp(() {
      respHeaders = {
        "content-type": "application/json",
        "date": "Wed, 17 Jan 2018 10:40:48 GMT",
        "x-consul-knownleader": "true",
        "x-consul-index": "191430",
        "x-consul-lastcontact": "0"
      };
      client = new ConsulKV(
          host: '127.0.0.1', defaultHeaders: {'X-Consul-Token': 'bcd1234'});
      mockClient = new MockClient((request) async {
        if (request.method == 'GET' && request.url.path == '/v1/kv/testkey') {
          return new Response(getResponse, 200, headers: respHeaders);
        }
        ;
        if (request.method == 'GET' &&
            request.url.path != '/v1/kv/testkey' &&
            request.url.path != '/v1/kv/') {
          return new Response('', 401, headers: respHeaders);
        }
        ;
        if (request.method == 'GET' && request.url.path == '/v1/kv/') {
          return new Response('Missing key name', 400, headers: respHeaders);
        }
        ;
        if (request.method == 'PUT' &&
            request.url.path == '/v1/kv/testkey' &&
            !request.url.queryParameters.containsKey('cas')) {
          return new Response('true', 200, headers: respHeaders);
        }
        ;
        if (request.method == 'PUT' &&
            request.url.path == '/v1/kv/testkey' &&
            request.url.queryParameters['cas'] == '1') {
          return new Response('false', 200, headers: respHeaders);
        }
        ;
        if (request.method == 'DELETE' &&
            request.url.path == '/v1/kv/testkey' &&
            !request.url.queryParameters.containsKey('cas')) {
          return new Response('true', 200, headers: respHeaders);
        }
        ;
        if (request.method == 'DELETE' &&
            request.url.path == '/v1/kv/testkey' &&
            request.url.queryParameters['cas'] == '1') {
          return new Response('false', 200, headers: respHeaders);
        }
        ;
        return new Response("", 400, headers: respHeaders);
      });
      client.switchClient = mockClient;
    });
    test('Checks that optional params are present in GET method', () async {
      var resultOne = await client
          .get('testkey', headers: {"content-type": "application/json"});
      var resultTwo = await client.get('testkey', recurse: true);
      var resultThree = await client.get('testkey', keys: true);
      var resultFour = await client.get('testkey', dc: 'dc1');
      var resultFive = await client.get('testkey', separator: ':');
      var resultSix = await client.get('testkey',
          separator: ':', recurse: true, keys: true, dc: 'dc1');
      expect(resultOne.request.url.toString(),
          equals('http://127.0.0.1:8500/v1/kv/testkey?separator=%2F'));
      expect(resultOne.request.url.queryParameters, equals({'separator': '/'}));
      expect(
          resultOne.request.headers,
          equals({
            'content-type': 'application/json',
            'X-Consul-Token': 'bcd1234'
          }));

      expect(resultTwo.request.url.toString(),
          equals('http://127.0.0.1:8500/v1/kv/testkey?recurse&separator=%2F'));
      expect(resultTwo.request.url.queryParameters,
          equals({'separator': '/', 'recurse': ''}));

      expect(resultThree.request.url.toString(),
          equals('http://127.0.0.1:8500/v1/kv/testkey?keys&separator=%2F'));
      expect(resultThree.request.url.queryParameters,
          equals({'separator': '/', 'keys': ''}));

      expect(resultFour.request.url.toString(),
          equals('http://127.0.0.1:8500/v1/kv/testkey?dc=dc1&separator=%2F'));
      expect(resultFour.request.url.queryParameters,
          equals({'separator': '/', 'dc': 'dc1'}));

      expect(resultFive.request.url.toString(),
          equals('http://127.0.0.1:8500/v1/kv/testkey?separator=%3A'));
      expect(
          resultFive.request.url.queryParameters, equals({'separator': ':'}));

      expect(
          resultSix.request.url.toString(),
          equals(
              'http://127.0.0.1:8500/v1/kv/testkey?dc=dc1&recurse&keys&separator=%3A'));
      expect(resultSix.request.url.queryParameters,
          equals({'dc': 'dc1', 'recurse': '', 'keys': '', 'separator': ':'}));
    });
    test('Attempts to get key from Consul with different params', () async {
      var result = await client.get('testkey');
      expect(result.request.url.path, equals('/v1/kv/testkey'));
      expect(result.request.url.toString(),
          equals('http://127.0.0.1:8500/v1/kv/testkey?separator=%2F'));
      expect(result.request.headers, equals({'X-Consul-Token': 'bcd1234'}));
      expect(result.headers, equals(respHeaders));
      expect(result.body, equals(getResponse));
    });
    test('Attempts to get not existing key returns proper response', () async {
      var result = await client.get('notexistingkey');
      expect(result.request.url.path, equals('/v1/kv/notexistingkey'));
      expect(result.request.url.toString(),
          equals('http://127.0.0.1:8500/v1/kv/notexistingkey?separator=%2F'));
      expect(result.request.headers, equals({'X-Consul-Token': 'bcd1234'}));
      expect(result.headers, equals(respHeaders));
      expect(result.statusCode, equals(401));
    });
    test('Attempts to get key with no params returns proper response',
        () async {
      var result = await client.get('');
      expect(result.request.url.path, equals('/v1/kv/'));
      expect(result.request.url.toString(),
          equals('http://127.0.0.1:8500/v1/kv/?separator=%2F'));
      expect(result.request.headers, equals({'X-Consul-Token': 'bcd1234'}));
      expect(result.headers, equals(respHeaders));
      expect(result.body, equals('Missing key name'));
      expect(result.statusCode, equals(400));
    });
    test('Checks that optional params are present in PUT method', () async {
      var resultOne = await client.put('testkey', 'testvalue');
      var resultTwo = await client.put('testkey', 'testvalue',
          headers: {'content-type': 'application/json'});
      var resultThree = await client.put('testkey', 'testvalue', dc: 'dc1');
      var resultFour = await client.put('testkey', 'testvalue', flags: 1);
      var resultFive = await client.put('testkey', 'testvalue', cas: 1);
      var resultSix = await client.put('testkey', 'testvalue', acquire: "test");
      var resultSeven =
          await client.put('testkey', 'testvalue', release: "test");

      expect(resultOne.request.url.path, equals('/v1/kv/testkey'));
      expect(resultOne.request.url.toString(),
          equals('http://127.0.0.1:8500/v1/kv/testkey?'));
      expect(
          resultOne.request.headers,
          equals({
            'X-Consul-Token': 'bcd1234',
            'content-type': 'text/plain; charset=utf-8'
          }));

      expect(
          resultTwo.request.headers,
          equals({
            'content-type': 'application/json; charset=utf-8',
            'X-Consul-Token': 'bcd1234'
          }));

      expect(resultThree.request.url.queryParameters, equals({'dc': 'dc1'}));

      expect(resultFour.request.url.queryParameters, equals({'flags': '1'}));

      expect(resultFive.request.url.queryParameters, equals({'cas': '1'}));

      expect(
          resultSix.request.url.queryParameters, equals({'acquire': 'test'}));

      expect(
          resultSeven.request.url.queryParameters, equals({'release': 'test'}));
    });
    test('Attempts to put key returns proper response', () async {
      var resultOne = await client.put('testkey', 'testvalue');
      var resultTwo = await client.put('testkey', 'testvalue', cas: 1);
      expect(resultOne.request.url.path, equals('/v1/kv/testkey'));
      expect(resultOne.request.url.toString(),
          equals('http://127.0.0.1:8500/v1/kv/testkey?'));
      expect(resultOne.statusCode, equals(200));
      expect(
          resultOne.request.headers,
          equals({
            'X-Consul-Token': 'bcd1234',
            'content-type': 'text/plain; charset=utf-8'
          }));
      expect(resultOne.body, equals('true'));
      expect(resultOne.headers, equals(respHeaders));

      expect(resultTwo.request.url.path, equals('/v1/kv/testkey'));
      expect(resultTwo.request.url.toString(),
          equals('http://127.0.0.1:8500/v1/kv/testkey?cas=1'));
      expect(resultTwo.statusCode, equals(200));
      expect(
          resultTwo.request.headers,
          equals({
            'X-Consul-Token': 'bcd1234',
            'content-type': 'text/plain; charset=utf-8'
          }));
      expect(resultTwo.body, equals('false'));
      expect(resultTwo.headers, equals(respHeaders));
      expect(resultTwo.request.url.queryParameters, equals({'cas': '1'}));
    });
    test('Checks that optional params are present in DELETE method', () async {
      var resultOne = await client.delete('testkey');
      var resultTwo = await client
          .delete('testkey', headers: {'content-type': 'application/json'});
      var resultThree = await client.delete('testkey', recurse: true);
      var resultFour = await client.delete('testkey', cas: 1);

      expect(resultOne.request.url.path, equals('/v1/kv/testkey'));
      expect(resultOne.request.url.toString(),
          equals('http://127.0.0.1:8500/v1/kv/testkey?'));
      expect(resultOne.request.headers, equals({'X-Consul-Token': 'bcd1234'}));

      expect(
          resultTwo.request.headers,
          equals({
            'content-type': 'application/json',
            'X-Consul-Token': 'bcd1234'
          }));

      expect(resultThree.request.url.queryParameters, equals({'recurse': ''}));

      expect(resultFour.request.url.queryParameters, equals({'cas': '1'}));
    });
    test('Attempts to delete key returns proper response', () async {
      var resultOne = await client.delete('testkey');
      var resultTwo = await client.put('testkey', 'testvalue', cas: 1);
      expect(resultOne.request.url.path, equals('/v1/kv/testkey'));
      expect(resultOne.request.url.toString(),
          equals('http://127.0.0.1:8500/v1/kv/testkey?'));
      expect(resultOne.statusCode, equals(200));
      expect(resultOne.request.headers, equals({'X-Consul-Token': 'bcd1234'}));
      expect(resultOne.body, equals('true'));
      expect(resultOne.headers, equals(respHeaders));

      expect(resultTwo.request.url.path, equals('/v1/kv/testkey'));
      expect(resultTwo.request.url.toString(),
          equals('http://127.0.0.1:8500/v1/kv/testkey?cas=1'));
      expect(resultTwo.statusCode, equals(200));
      expect(
          resultTwo.request.headers,
          equals({
            'X-Consul-Token': 'bcd1234',
            'content-type': 'text/plain; charset=utf-8'
          }));
      expect(resultTwo.body, equals('false'));
      expect(resultTwo.headers, equals(respHeaders));
      expect(resultTwo.request.url.queryParameters, equals({'cas': '1'}));
    });
    test('Checks that getClient() getter returns current HTTP Client',
        () async {
      var newClient = new Client();
      var currentClient = client.currentClient;
      expect((currentClient.hashCode == newClient.hashCode), equals(false));
      expect(currentClient.hashCode, equals(mockClient.hashCode));
    });
    test(
        'Checks that switchClient() setter replaces current HTTP Client with new one',
        () async {
      var newClient = new Client();
      var currentClient = client.currentClient;
      expect((currentClient.hashCode == newClient.hashCode), equals(false));
      expect(currentClient.hashCode, equals(mockClient.hashCode));
      client.switchClient = newClient;
      currentClient = client.currentClient;
      expect(currentClient.hashCode, equals(newClient.hashCode));
    });
  });
}
