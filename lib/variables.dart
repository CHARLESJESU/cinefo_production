import 'package:flutter/material.dart';

Map? baseurlresponsebody;
Map? baseurlresult;
TextEditingController loginmobilenumber = TextEditingController();
TextEditingController loginpassword = TextEditingController();

Map? loginresult;
Map? globalloginData;
String? location;
String? locationofcharles;
bool isoffline = false;
Map? getdeviceidresponse;

String? productionHouse;
String? projectId;
String? managerName;
Map? passProjectidresponse;
String? registeredMovie;
int? callsheetid;
String? projectid;
int? productionTypeId;
List<dynamic> movieProjects = [];
String? selectedProjectId;
String? selectedProjectTitle;
Map? shiftresponse1;
String? vcid;
String? vsid;
List<Map<String, dynamic>> updatedDubbingConfigs = [];
List<Map<String, dynamic>> dubbingConfigs = [];
int mainCharacter = 0;
int smallCharacter = 0;
int bitCharacter = 0;
int group = 0;
int fight = 0;
int mainCharacterOtherLanguage = 0;
int smallCharacterOtherLanguage = 0;
int bitCharacterOtherLanguage = 0;
int groupOtherLanguage = 0;
int fightOtherLanguage = 0;
int voicetest = 0;
int leadRole = 0;
int secondLeadRole = 0;
int leadRoleOtherLanguage = 0;
int secondLeadRoleOtherLanguage = 0;
final processRequest =
    Uri.parse('https://devvgate.vframework.in/vgateapi/processRequest');
final processSessionRequest =
    Uri.parse('https://devvgate.vframework.in/vgateapi/processSessionRequest');

Map? closecallsheetresponse;
Map<String, int> dubbingConfigStates = {};
Map<String, int> finalDoubingMap = {};

// Charles made Variables
Map? baseurlresultbody;
Map? loginresponsebody;
String? ProfileImage;
String? Platformlogo;
String? vpid;
int? vmid;
int? vuid;
int? mtypeId;
int? vmTypeId;
int? vpoid;
int? vbpid;
int? vsubid;
int? vpidpo;
int? vpidbp;
int? unitid;
String? companyName;
String? createdBy;
String? email;
String? unitName;
String? idcardurl;
int? attendanceid;
int? config_unitid;
String? config_unitname;
int lightman_unitid = 4;
int production_unitid = 20;
int tech_unitid = 29;
int juinor_unitid = 12;
int allowanceid_withoutbreak = 14;
int allowanceid_helper = 23;
int allowanceid_incharge = 24;
String vmetid_fetch_config_unit_allowance =
    "QFjnHX2oXXReKA3tMjSN4dO8aT2LlE8O098UrCx6/szGQef/YKIzM2LehxeOBDZDNKZaeuOkTBKOfTIg03wvVPXUONEXWTvvKrQQ7heqxVKuyDxiMRcyPqLTkbcMAiibPoSJGSCUIhYToVwE+TWVLUW2Ke68yJdCgMrKFAxMwkx+yZdfZkSYILX25NMAunaH7ziKHEfbinOTQdIUR9xGnH9uord4oVLNW7vPSjVNkc7VAbpuz8L8Qr5I4FYUDKRDuz63H0XZSeX2+U6kzaSPMk870Y/jW+V47iYb2z4OQryivUdycPtdj6Zm7Wt8WWk8jGQJRFWx+UVUIs16c11Kqg==";

String vmetid_Fecth_callsheet_members =
    "VtHdAOR3ljcro4U+M9+kByyNPjr8d/b3VNhQmK9lwHYmkC5cUmqkmv6Ku5FFOHTYi9W80fZoAGhzNSB9L/7VCTAfg9S2RhDOMd5J+wkFquTCikvz38ZUWaUe6nXew/NSdV9K58wL5gDAd/7W0zSOpw7Qb+fALxSDZ8UmWdk7MxLkZDn0VIHwVAgv13JeeZVivtG7gu0DJvTyPixMJUFCQzzADzJHoIYtgXV4342izgfc4Lqca4rdjVwYV79/LLqmz1M8yAWXqfSRb+ArLo6xtPrjPInGZcIO8U6uTH1WmXvw+pk3xKD/WEEAFk69w8MI1TrntrzGgDPZ21NhqZXE/w==";

String vmetid_save_config =
    "gFKVWEa2ILpLKWOx4gmKQmg+XgFaJTS0LO8qTryiXNVFrOrWJfUJQcCY+ZYIVlIE+IQuidE5H/YF2ihIrxCPO5mztWxu31g51Hd2YN3rtX0t53OAMBuBgFx3PJ3zREuW/9cw6Tj9+wdLEeMUZpSfzpMv1I0YuzwLInyHSRypIkcQD1MoFA9jUNpg6I7Ezpy/w1fJcpE4/GlN7HJKjtkJ/Xsg1YCRtc4xz5jc/5zy7SJxSbCl/WLmQxP4Nz0hS5HqtbshLEnQjflTfnq3NakSJkhlDdY6J6AdP0SDZzYKSQVnViQ1w+Euc14vg3SP+7I3hkETu25vvGDieIqMI+XdMQ==";

String vmetid_fetch_unit =
    "Zfryf2Jt7ZnHxP57cfHT0n2vmTihWPqkwA8/pppCsOODTriG9m20x+DOfaKwZiJZTXYMUS2BVh/1fk0LWpYMjmey/SADWvv7XQ2Cmyxpsf0++IQjT4YhEnHGkgyuoc2pxZyaw2bDIhzje7JOFAGkVjIFCvvN3TsWXxqH5boL+bhlmIIlNGqGivm+gLqR9RnU4E6YZcC6eRF030s6pdTQagY17SU3O4TfUNgdAFEcsADAh3V8TfxDPMG8Ih1iGRPZnD25WlmJXXyeSVmFBoW+R2UDa3mHhdUGPNwFZIqAJbmbMvdOHriIfO2yElyDYUCBXNZmF4Z622R3xFeuPcDcpA==";
