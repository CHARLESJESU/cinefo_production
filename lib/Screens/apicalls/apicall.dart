
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import '../../variables.dart';

Future<Map<String, dynamic>> approvalofproductionmanagerapi({

  required String vsid,
}) async {
  try {
    final payload =
    {};
    final approvalofproductionmanagerapiresponse = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
        'eqbzWtl0tFIBLELyprJXz6Z3FZ3ggz/j30wFRtOa5tf1xuWhBDtS+6z9f9rKQn55WTAb/abcRdBWrOhODx0BobhZixz93zybOQR60JQayFQ4JoDLjpHpaUYBttGaRtWeHngsb9Ouo/FlqNNl072/zob0rnOFXCcTcUStlagljYZTjop4QJ0/dbCDbjjxYbSsAX1SDL2SJYyzsEk7yj5FkmlI+PqlHqvvh3h/icdXNCrlhXCijmLp4SRherKBtVnhagPTbrxif8vKAzhh4i+bghJWAliTmgIbBjwxZ1YsTu0JBeRYw3D7O5YGLj/KQG5C6C2mG505rIw0AJE6/nNKzQ==',
        'VSID': vsid,
      },
      body: jsonEncode(payload),
    );

    print(
        '🚗 approvalofproductionmanagerapiresponse Status API Response Status: ${approvalofproductionmanagerapiresponse.statusCode}');
    print('🚗 approvalofproductionmanagerapiresponse Status API Response Status: ${payload}');
    print('🚗 approvalofproductionmanagerapiresponse Status API Response Body: ${approvalofproductionmanagerapiresponse.body}');

    return {
      'statusCode': approvalofproductionmanagerapiresponse.statusCode,
      'body': approvalofproductionmanagerapiresponse.body,
      'success': approvalofproductionmanagerapiresponse.statusCode == 200,
    };
  } catch (e) {
    print('❌ Error in tripstatusapi: $e');
    return {
      'statusCode': 0,
      'body': 'Error: $e',
      'success': false,
    };
  }
}
Future<Map<String, dynamic>> approvalstatuspostapi({

  required String vsid,
  required int callsheetrequestid,
}) async {
  try {
    final payload =
    {
      "callsheetrequestid": callsheetrequestid
    };
    final approvalstatuspostapiapiresponse = await http.post(
      processSessionRequest,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'VMETID':
        'Gi70iQkeJJV5XfgXw9F8VLY0pBr66YvZvWwXLbrW8NHcefPfJ7UORB2ulQMrWvgWiXFpizWqwpv8xqAEGfC+b/jAGmQKdEU12ihI6opBlpt+KZdPihVz617VZAK8fKmrU2Ghy2bCdM4h/LYZaYZOI4ZNhejSDERgcJ30OrwKFeLPBZUxWpXceR0yvt9/p8hvstxOaZhT6/6leQK09fsFIkwUO+LffbDck7EhjhLAkhGShZjnTY62a3PAL0Uh51e4K74iQZSqAjv87J6/XeGHH11b5YEtFhS+62CRHvoc555wJCiBptThfcxHprjXkuyiHajemWaupNz4IO8n4qwpiA==',
        'VSID': vsid,
      },
      body: jsonEncode(payload),
    );

    print(
        '🚗 approvalstatuspostapiapiresponse Status API Response Status: ${approvalstatuspostapiapiresponse.statusCode}');
    print('🚗 approvalstatuspostapiapiresponse Status API Response Status: ${payload}');
    print('🚗 approvalstatuspostapiapiresponse Status API Response Body: ${approvalstatuspostapiapiresponse.body}');

    return {
      'statusCode': approvalstatuspostapiapiresponse.statusCode,
      'body': approvalstatuspostapiapiresponse.body,
      'success': approvalstatuspostapiapiresponse.statusCode == 200,
    };
  } catch (e) {
    print('❌ Error in tripstatusapi: $e');
    return {
      'statusCode': 0,
      'body': 'Error: $e',
      'success': false,
    };
  }
}
Future<void> fetchLoginData() async {
  final dbPath = await getDatabasesPath();
  final db = await openDatabase(path.join(dbPath, 'production_login.db'));
  final List<Map<String, dynamic>> loginMaps = await db.query('login_data');
  if (loginMaps.isNotEmpty) {
    globalloginData = loginMaps.first;
  }
  await db.close();
}