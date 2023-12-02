import 'dart:ffi';
import 'dart:convert';

import 'package:cw_zano/api/convert_utf8_to_string.dart';
import 'package:cw_zano/api/model.dart';
import 'package:cw_zano/api/model/get_recent_txs_and_info_params.dart';
import 'package:cw_zano/api/model/transfer_params.dart';
import 'package:cw_zano/api/zano_api.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

final _asyncCallNative = zanoApi
    .lookup<NativeFunction<_async_call>>('async_call')
    .asFunction<_AsyncCall>();
typedef _async_call = Pointer<Utf8> Function(
    Pointer<Utf8>, Int64, Pointer<Utf8>);
typedef _AsyncCall = Pointer<Utf8> Function(
    Pointer<Utf8> methodName, int hWallet, Pointer<Utf8> params);

// get_wallet_status
final _getWalletStatusNative = zanoApi
    .lookup<NativeFunction<_get_wallet_status>>('get_wallet_status')
    .asFunction<_GetWalletStatus>();
typedef _get_wallet_status = Pointer<Utf8> Function(Int64);
typedef _GetWalletStatus = Pointer<Utf8> Function(int hWallet);

// get_wallet_info
final _getWalletInfoNative = zanoApi
    .lookup<NativeFunction<_get_wallet_info>>('get_wallet_info')
    .asFunction<_GetWalletInfo>();
typedef _get_wallet_info = Pointer<Utf8> Function(Int64);
typedef _GetWalletInfo = Pointer<Utf8> Function(int hWallet);

// get_connectivity_status
final _getConnectivityStatusNative = zanoApi
    .lookup<NativeFunction<_get_connectivity_status>>('get_connectivity_status')
    .asFunction<_GetConnectivityStatus>();
typedef _get_connectivity_status = Pointer<Utf8> Function();
typedef _GetConnectivityStatus = Pointer<Utf8> Function();

// get_version
final _getVersionNative = zanoApi
    .lookup<NativeFunction<_get_version>>('get_version')
    .asFunction<_GetVersion>();
typedef _get_version = Pointer<Utf8> Function();
typedef _GetVersion = Pointer<Utf8> Function();

// load_wallet
final _loadWalletNative = zanoApi
    .lookup<NativeFunction<_load_wallet>>('load_wallet')
    .asFunction<_LoadWallet>();
typedef _load_wallet = Pointer<Utf8> Function(
    Pointer<Utf8>, Pointer<Utf8>, Int8);
typedef _LoadWallet = Pointer<Utf8> Function(Pointer<Utf8>, Pointer<Utf8>, int);

// try_pull_result
final _tryPullResultNative = zanoApi
    .lookup<NativeFunction<_try_pull_result>>('try_pull_result')
    .asFunction<_TryPullResult>();
typedef _try_pull_result = Pointer<Utf8> Function(Int64);
typedef _TryPullResult = Pointer<Utf8> Function(int hWallet);

// close_wallet
final _closeWalletNative = zanoApi
    .lookup<NativeFunction<_close_wallet>>('close_wallet')
    .asFunction<_closeWalletStatus>();
typedef _close_wallet = Void Function(Int64);
typedef _closeWalletStatus = void Function(int hWallet);

// get_current_tx_fee
final _getCurrentTxFeeNative = zanoApi
    .lookup<NativeFunction<_get_current_tx_fee>>('get_current_tx_fee')
    .asFunction<_getCurrentTxFee>();
typedef _get_current_tx_fee = Int64 Function(Int64);
typedef _getCurrentTxFee = int Function(int priority);

final _restoreWalletFromSeedNative = zanoApi
    .lookup<NativeFunction<_restore_wallet_from_seed>>(
        'restore_wallet_from_seed')
    .asFunction<_RestoreWalletFromSeed>();
typedef _restore_wallet_from_seed = Pointer<Utf8> Function(
    Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32, Int64, Pointer<Utf8>);
typedef _RestoreWalletFromSeed = Pointer<Utf8> Function(
    Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, int, int, Pointer<Utf8>);

String doAsyncCall(
    {required String methodName,
    required int hWallet,
    required String params}) {
  final methodNamePointer = methodName.toNativeUtf8();
  final paramsPointer = params.toNativeUtf8();

  debugPrint(
      'async_call method_name $methodName hWallet $hWallet params $params');
  final result = convertUTF8ToString(
      pointer: _asyncCallNative(methodNamePointer, hWallet, paramsPointer));

  calloc.free(methodNamePointer);
  calloc.free(paramsPointer);

  return result;
}

Future<String> invokeMethod(
    int hWallet, String methodName, String params) async {
  debugPrint('invoke method $methodName params $params');
  final invokeResult = doAsyncCall(
      methodName: 'invoke',
      hWallet: hWallet,
      params: json.encode({
        'method': methodName,
        'params': params,
      }));
  debugPrint('invoke result $invokeResult');
  final map = json.decode(invokeResult);
  if (map['job_id'] != null) {
    await Future.delayed(Duration(seconds: 3));
    final result = tryPullResult(map['job_id'] as int);
    return result;
  }
  return invokeResult;
}

Future<String> store(int hWallet) async {
  return await invokeMethod(hWallet, 'store', '{}');
}

Future<String> transfer(int hWallet, TransferParams params) async {
  final invokeResult = await doAsyncCall(
    methodName: 'invoke',
    hWallet: hWallet,
    params: '{"method": "transfer","params": ${jsonEncode(params)}}',
  );
  debugPrint('invoke result $invokeResult');
  var map = json.decode(invokeResult);
  if (map['job_id'] != null) {
    await Future.delayed(Duration(seconds: 3));
    final result = tryPullResult(map['job_id'] as int);
    return result;
  }
  return invokeResult;
}

Future<String> getRecentTxsAndInfo(
    {required int hWallet,
    required int offset,
    required int count,
    bool updateProvisionInfo = true}) async {
  return await invokeMethod(
    hWallet,
    'get_recent_txs_and_info',
    json.encode(
      GetRecentTxsAndInfoParams(
          offset: offset,
          count: count,
          updateProvisionInfo: updateProvisionInfo),
    ),
  );
}

String getWalletStatus(int hWallet) {
  debugPrint('get_wallet_status hWallet $hWallet');
  final result = convertUTF8ToString(pointer: _getWalletStatusNative(hWallet));
  debugPrint('get_wallet_status result $result');
  return result;
}

void closeWallet(int hWallet) {
  debugPrint('close_wallet hWallet $hWallet');
  _closeWalletNative(hWallet);
}

int getCurrentTxFee(int priority) {
  debugPrint('get_current_tx_fee priority $priority');
  final result = _getCurrentTxFeeNative(priority);
  debugPrint('get_current_tx_fee result $result');
  return result;
}

String getWalletInfo(int hWallet) {
  debugPrint('get_wallet_info hWallet $hWallet');
  final result = convertUTF8ToString(pointer: _getWalletInfoNative(hWallet));
  debugPrint('get_wallet_info result $result');
  return result;
}

String getConnectivityStatus() {
  final result = convertUTF8ToString(pointer: _getConnectivityStatusNative());
  debugPrint('get_connectivity_status result $result');
  return result;
}

String getVersion() {
  final result = convertUTF8ToString(pointer: _getVersionNative());
  debugPrint('get_version result $result');
  return result;
}

String restoreWalletFromSeed(String path, String password, String seed) {
  debugPrint('restore_wallet_from_seed path $path password $password seed $seed');
  final pathPointer = path.toNativeUtf8();
  final passwordPointer = password.toNativeUtf8();
  final seedPointer = seed.toNativeUtf8();
  final errorMessagePointer = ''.toNativeUtf8();
  final result = convertUTF8ToString(pointer: _restoreWalletFromSeedNative(pathPointer,
    passwordPointer, seedPointer, 0, 0, errorMessagePointer));
  return result;
}

String loadWallet(String path, String password, int nettype) {
  debugPrint('load_wallet path $path password $password nettype $nettype');
  final pathPointer = path.toNativeUtf8();
  final passwordPointer = password.toNativeUtf8();
  final result = convertUTF8ToString(
    pointer: _loadWalletNative(pathPointer, passwordPointer, nettype),
  );
  debugPrint('load_wallet result $result');
  return result;
}

String tryPullResult(int jobId) {
  debugPrint('try_pull_result jobId $jobId');
  final result = convertUTF8ToString(pointer: _tryPullResultNative(jobId));
  debugPrint('try_pull_result result $result');
  return result;
}
