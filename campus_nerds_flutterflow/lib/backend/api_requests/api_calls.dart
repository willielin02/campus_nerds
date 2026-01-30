import 'dart:convert';
import 'dart:typed_data';
import '../schema/structs/index.dart';

import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

class SendSchoolEmailCodeCall {
  static Future<ApiCallResponse> call({
    String? bookingId = '',
    String? authToken = '',
  }) async {
    final ffApiRequestBody = '''
{
  "p_booking_id": "${escapeStringForJson(bookingId)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'SendSchoolEmailCode',
      apiUrl:
          'https://lzafwlmznlkvmbdxcxop.supabase.co/functions/v1/send-school-email-code',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'apikey': 'sb_publishable_f7e_u2uJlXAKcUyNxO2-9w_-p8L-f_P',
        'Authorization': 'Bearer ${authToken}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class VerifySchoolEmailCodeCall {
  static Future<ApiCallResponse> call({
    String? schoolEmail = '',
    String? code = '',
    String? authToken = '',
  }) async {
    final ffApiRequestBody = '''
{
  "school_email": "${escapeStringForJson(schoolEmail)}",
  "code": "${escapeStringForJson(code)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'VerifySchoolEmailCode',
      apiUrl:
          'https://lzafwlmznlkvmbdxcxop.supabase.co/functions/v1/verify-school-email-code',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'apikey': 'sb_publishable_f7e_u2uJlXAKcUyNxO2-9w_-p8L-f_P',
        'Authorization': 'Bearer ${authToken}',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class EcpayCreateOrderCall {
  static Future<ApiCallResponse> call({
    String? authToken = '',
    String? productId = '',
  }) async {
    final ffApiRequestBody = '''
{
  "product_id": "${escapeStringForJson(productId)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'EcpayCreateOrder',
      apiUrl:
          'https://lzafwlmznlkvmbdxcxop.supabase.co/functions/v1/ecpay_create_order',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${authToken}',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static dynamic orderid(dynamic response) => getJsonField(
        response,
        r'''$.order_id''',
      );
  static dynamic checkouturl(dynamic response) => getJsonField(
        response,
        r'''$.checkout_url''',
      );
  static dynamic checkoutToken(dynamic response) => getJsonField(
        response,
        r'''$.checkout_token''',
      );
}

class GetEcpayHtmlCall {
  static Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetEcpayHtml',
      apiUrl:
          'https://lzafwlmznlkvmbdxcxop.supabase.co/functions/v1/ecpay_pay?token=${token}',
      callType: ApiCallType.GET,
      headers: {
        'Accept': 'application/json',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static dynamic html(dynamic response) => getJsonField(
        response,
        r'''$.html''',
      );
}

class RpcCreateBookingCall {
  static Future<ApiCallResponse> call({
    String? authToken = '',
    String? eventId = '',
  }) async {
    final ffApiRequestBody = '''
{
  "p_event_id": "${escapeStringForJson(eventId)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'rpcCreateBooking',
      apiUrl:
          'https://lzafwlmznlkvmbdxcxop.supabase.co/rest/v1/rpc/create_booking_and_consume_ticket',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${authToken}',
        'Content-Type': 'application/json',
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6YWZ3bG16bmxrdm1iZHhjeG9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwNTcyODIsImV4cCI6MjA4MTYzMzI4Mn0.5i_r7IRg1ZDjFIvlki_Oy9IYQ6dCXeA5PrCZ-g-XAFQ',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RpcCancelBookingCall {
  static Future<ApiCallResponse> call({
    String? authToken = '',
    String? bookingId = '',
  }) async {
    final ffApiRequestBody = '''
{
  "p_booking_id": "bookingId"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'rpcCancelBooking',
      apiUrl:
          'https://lzafwlmznlkvmbdxcxop.supabase.co/rest/v1/rpc/cancel_booking_and_refund_ticket',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${authToken}',
        'Content-Type': 'application/json',
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6YWZ3bG16bmxrdm1iZHhjeG9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwNTcyODIsImV4cCI6MjA4MTYzMzI4Mn0.5i_r7IRg1ZDjFIvlki_Oy9IYQ6dCXeA5PrCZ-g-XAFQ',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RpcGetGroupFocusedStudyPlansCall {
  static Future<ApiCallResponse> call({
    String? authToken = '',
    String? groupId = '',
  }) async {
    final ffApiRequestBody = '''
{
  "p_group_id": "${escapeStringForJson(groupId)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'rpcGetGroupFocusedStudyPlans',
      apiUrl:
          'https://lzafwlmznlkvmxbdxcop.supabase.co/rest/v1/rpc/get_group_focused_study_plans',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${authToken}',
        'Content-Type': 'application/json',
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6YWZ3bG16bmxrdm1iZHhjeG9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwNTcyODIsImV4cCI6MjA4MTYzMzI4Mn0.5i_r7IRg1ZDjFIvlki_Oy9IYQ6dCXeA5PrCZ-g-XAFQ',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static dynamic plansList(dynamic response) => getJsonField(
        response,
        r'''$''',
      );
}

class RpcUpdateFocusedStudyPlanCall {
  static Future<ApiCallResponse> call({
    String? planId = '',
    String? content = '',
    bool? done,
    String? authToken = '',
  }) async {
    final ffApiRequestBody = '''
{
  "p_plan_id": "${escapeStringForJson(planId)}",
  "p_content": "${escapeStringForJson(content)}",
  "p_done": "${done}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'rpcUpdateFocusedStudyPlan',
      apiUrl:
          'https://lzafwlmznlkvmbdxcxop.supabase.co/rest/v1/rpc/update_focused_study_plan',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${authToken}',
        'Content-Type': 'application/json',
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6YWZ3bG16bmxrdm1iZHhjeG9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwNTcyODIsImV4cCI6MjA4MTYzMzI4Mn0.5i_r7IRg1ZDjFIvlki_Oy9IYQ6dCXeA5PrCZ-g-XAFQ',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RpcChatSendMessageCall {
  static Future<ApiCallResponse> call({
    String? groupId = '',
    String? content = '',
    String? authToken = '',
  }) async {
    final ffApiRequestBody = '''
{
  "p_group_id": "${escapeStringForJson(groupId)}",
  "p_content": "${escapeStringForJson(content)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'rpcChatSendMessage',
      apiUrl:
          'https://lzafwlmznlkvmbdxcxop.supabase.co/rest/v1/rpc/chat_send_message',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${authToken}',
        'Content-Type': 'application/json',
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6YWZ3bG16bmxrdm1iZHhjeG9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwNTcyODIsImV4cCI6MjA4MTYzMzI4Mn0.5i_r7IRg1ZDjFIvlki_Oy9IYQ6dCXeA5PrCZ-g-XAFQ',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RpcChatMarkJoinedCall {
  static Future<ApiCallResponse> call({
    String? groupId = '',
    String? authToken = '',
  }) async {
    final ffApiRequestBody = '''
{
  "p_group_id": "${escapeStringForJson(groupId)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'rpcChatMarkJoined',
      apiUrl:
          'https://lzafwlmznlkvmbdxcxop.supabase.co/rest/v1/rpc/chat_mark_joined',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${authToken}',
        'Content-Type': 'application/json',
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6YWZ3bG16bmxrdm1iZHhjeG9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwNTcyODIsImV4cCI6MjA4MTYzMzI4Mn0.5i_r7IRg1ZDjFIvlki_Oy9IYQ6dCXeA5PrCZ-g-XAFQ',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class RpcChatFetchTimelinePageCall {
  static Future<ApiCallResponse> call({
    String? groupId = '',
    String? beforeSortTs = '',
    int? beforeSortRank,
    String? beforeItemId = '',
    int? limit = 50,
    String? authToken = '',
  }) async {
    final ffApiRequestBody = '''
{
  "p_group_id": "${escapeStringForJson(groupId)}",
  "p_before_sort_ts": "${escapeStringForJson(beforeSortTs)}",
  "p_before_sort_rank": "${beforeSortRank}",
  "p_before_item_id": "${escapeStringForJson(beforeItemId)}",
  "p_limit": "${limit}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'rpcChatFetchTimelinePage',
      apiUrl:
          'https://lzafwlmznlkvmbdxcxop.supabase.co/rest/v1/rpc/chat_fetch_timeline_page',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${authToken}',
        'Content-Type': 'application/json',
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx6YWZ3bG16bmxrdm1iZHhjeG9wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYwNTcyODIsImV4cCI6MjA4MTYzMzI4Mn0.5i_r7IRg1ZDjFIvlki_Oy9IYQ6dCXeA5PrCZ-g-XAFQ',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
