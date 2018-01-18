/// Implementation of key-value storage client for Consul.
import 'dart:async';

import 'package:http/http.dart' as http;

/// A class that wraps HTTP requests for Consul KV API.
///
/// `http://localhost:8500` is used as default URI when no parameters
/// passed to the constructor.
class ConsulKV {
  /// Host where Consul API is running, defaults to `localhost`.
  String host;

  /// Port where Consul API is running, defaults to `8500`.
  int port;

  /// Scheme for connection, defaults to `http`.
  String scheme;

  /// Consul api version - `v1`.
  String _apiVersion = '/v1';

  /// Endpoint for Consul KV API - `/kv/`.
  String _path = '/kv/';

  /// HTTP Client to perform calls to the API.
  http.Client _client = new http.Client();

  /// headers to use in each request, default to `null`.
  Map<String, String> defaultHeaders;

  /// Creates new instance of Consul KV client.
  ConsulKV(
      {this.host = 'localhost',
      this.port = 8500,
      this.scheme = 'http',
      this.defaultHeaders});

  /// Current [http.Client] of this [ConsulKV].
  http.Client get currentClient => this._client;

  /// New [http.Client] for this [ConsulKV].
  void set switchClient(http.Client client) => this._client = client;

  /// Invokes `close` method from [http.Client] to close connection.
  ///
  ///     var consul = new ConsulKV();
  ///     // do stuff
  ///     consul.close();
  void close() => this._client.close();

  /// Deletes key from KV.
  ///
  /// Parameter [key] is the only required parameter.
  /// Other parameters are optional.
  /// You can read when to use parameters here:
  /// [delete key](https://www.consul.io/api/kv.html#delete-key).
  ///
  ///     var consul = new ConsulKV();
  ///     var deleteKey = await consul.delete('foo');
  ///     print(deleteKey.body); // true
  ///     print(deleteKey.statusCode); // 200
  Future<http.Response> delete(String key,
      {bool recurse, int cas, Map<String, String> headers}) async {
    var params = <String, dynamic>{};
    headers = this._setHeaders(headers);
    if (recurse != null) {
      params['recurse'] = '';
    }
    if (cas != null) {
      params['cas'] = cas.toString();
    }

    var uri = this._buildUri(key, params);
    return (await this._client.delete(uri, headers: headers));
  }

  /// Reads key from KV.
  ///
  /// Parameter [key] is the only required parameter.
  /// Other parameters are optional.
  /// You can read when to use parameters here:
  /// [read key](https://www.consul.io/api/kv.html#read-key).
  ///
  ///     var consul = new ConsulKV();
  ///     var foundKey = await consul.get('foo');
  ///     print(foundKey.body); // [{"LockIndex":0,"Key":"foo","Value":"YmFy",
  ///                             // "CreateIndex":208877,"ModifyIndex":208877}]
  ///     print(foundKey.statusCode);  // 200
  Future<http.Response> get(String key,
      {String dc,
      bool recurse,
      bool raw,
      bool keys,
      String separator = '/',
      Map<String, String> headers}) async {
    var params = <String, String>{};
    headers = this._setHeaders(headers);
    if (dc != null) {
      params['dc'] = dc;
    }
    if (recurse != null) {
      params['recurse'] = '';
    }
    if (raw != null) {
      params['raw'] = '';
    }
    if (keys != null) {
      params['keys'] = '';
    }
    params['separator'] = separator;
    var uri = this._buildUri(key, params);

    return (await this._client.get(uri, headers: headers));
  }

  /// Creates/Updates key from KV.
  ///
  /// Parameter [key] and [value] are the only required parameters.
  /// Other parameters are optional.
  /// You can read when to use parameters here:
  /// [create/update key](https://www.consul.io/api/kv.html#create-update-key).
  ///
  ///     var consul = new ConsulKV();
  ///     var newKey = await consul.put('foo', 'bar');
  ///     var insertIfNotExists = await consul.put('foo', 'bar', cas: 1);
  ///     print(newKey.body); // true
  ///     print(newKey.statusCode); // 200
  ///     print(insertIfNotExists.body); // false
  ///     print(insertIfNotExists.statusCode); // 200
  Future<http.Response> put(String key, String value,
      {String dc,
      int flags,
      int cas,
      String acquire,
      String release,
      Map<String, String> headers}) async {
    var params = <String, dynamic>{};
    headers = this._setHeaders(headers);
    if (dc != null) {
      params['dc'] = dc;
    }
    if (flags != null) {
      params['flags'] = flags.toString();
    }
    if (cas != null) {
      params['cas'] = cas.toString();
    }
    if (acquire != null) {
      params['acquire'] = acquire;
    }
    if (release != null) {
      params['release'] = release;
    }

    var uri = this._buildUri(key, params);

    return (await this._client.put(uri, body: value, headers: headers));
  }

  /// Build URI for request.
  ///
  /// Creates endpoint for request and passes query parameters for [Uri].
  Uri _buildUri(String resource, Map<String, dynamic> params) {
    var uri = new Uri(
        scheme: this.scheme,
        host: this.host,
        port: this.port,
        path: this._apiVersion + this._path + resource,
        queryParameters: params);
    return uri;
  }

  /// Sets header for request.
  ///
  /// Checks if they are present in parameters and combines them with
  /// [defaultHeaders] (if they are present).
  Map<String, String> _setHeaders(Map<String, String> headers) {
    if (headers == null) {
      headers = {};
    }
    if (this.defaultHeaders == null) {
      return headers;
    }
    headers.addAll(this.defaultHeaders);
    return headers;
  }
}
