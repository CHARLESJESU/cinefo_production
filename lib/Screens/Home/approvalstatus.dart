import 'dart:convert';
import 'package:flutter/material.dart';
import '../apicalls/apicall.dart';
import '../../variables.dart';

class Approvalstatus extends StatefulWidget {
  const Approvalstatus({super.key});

  @override
  State<Approvalstatus> createState() => _ApprovalstatusState();
}

class ApprovalItem {
  int callSheetRequestId;
  int callSheetId;
  String requestedName;
  String requestUnitName;
  String requestStatus;
  String requestedTime;
  String requestDate;
  String projectName;
  String callSheetNo;

  ApprovalItem({
    required this.callSheetRequestId,
    required this.callSheetId,
    required this.requestedName,
    required this.requestUnitName,
    required this.requestStatus,
    required this.requestedTime,
    required this.requestDate,
    required this.projectName,
    required this.callSheetNo,
  });

  factory ApprovalItem.fromJson(Map<String, dynamic> json) {
    return ApprovalItem(
      callSheetRequestId: json['callSheetRequestId'] ?? json['callsheetrequestid'] ?? 0,
      callSheetId: json['callSheetId'] ?? json['callsheetid'] ?? 0,
      requestedName: (json['requestedname'] ?? json['requestedName'] ?? '').toString(),
      requestUnitName: (json['requestunitname'] ?? json['requestUnitName'] ?? '').toString(),
      requestStatus: (json['requeststatus'] ?? '').toString(),
      requestedTime: (json['requestedtime'] ?? '').toString(),
      requestDate: (json['requestdate'] ?? '').toString(),
      projectName: (json['projectname'] ?? json['projectName'] ?? '').toString(),
      callSheetNo: (json['callsheetno'] ?? json['callsheetNo'] ?? '').toString(),
    );
  }
}

class _ApprovalstatusState extends State<Approvalstatus> {
  bool _loading = true;
  String? _error;
  String _vsid = '';
  List<ApprovalItem> _items = [];
  final Set<int> _approvingIds = {}; // track which items are being approved
  final Set<int> _expandedIds = {}; // track which items are expanded

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // load login data from local DB (populates `globalloginData`)
    await fetchLoginData();

    // get vsid from the loaded login data (fallback to empty string)
    _vsid = (globalloginData?['vsid'] ?? '').toString();

    // call approval API with vsid
    try {
      final resp = await approvalofproductionmanagerapi(vsid: _vsid);
      print('approval API raw response: $resp');

      if (resp['success'] == true && resp['body'] != null) {
        try {
          final decoded = jsonDecode(resp['body']);
          final List<dynamic>? responseData = decoded['responseData'] as List<dynamic>?;
          if (responseData == null || responseData.isEmpty) {
            setState(() {
              _items = [];
              _loading = false;
            });
          } else {
            final parsed = responseData
                .map((e) => ApprovalItem.fromJson(e as Map<String, dynamic>))
                .toList();
            setState(() {
              _items = parsed;
              _loading = false;
            });
          }
        } catch (e) {
          setState(() {
            _error = 'Failed to parse response: $e';
            _loading = false;
          });
        }
      } else {
        setState(() {
          _error = 'API error: status ${resp['statusCode']}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error calling approval API: $e';
        _loading = false;
      });
    }
  }

  String _formatDate(String raw) {
    // raw might be an int like 20251210 or a string. Try to produce DD-MM-YYYY
    final s = raw.trim();
    if (s.length == 8 && int.tryParse(s) != null) {
      return '${s.substring(6, 8)}-${s.substring(4, 6)}-${s.substring(0, 4)}';
    }
    return s;
  }

  Future<void> _approveItem(ApprovalItem item, int index) async {
    if (_approvingIds.contains(item.callSheetRequestId)) return;
    setState(() => _approvingIds.add(item.callSheetRequestId));
    try {
      final resp = await approvalstatuspostapi(vsid: _vsid, callsheetrequestid: item.callSheetRequestId);
      print('approvalstatuspostapi returned: $resp');
      if (resp['success'] == true) {
        // update local UI to show Approved
        setState(() {
          _items[index].requestStatus = 'Approved';
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request approved')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approval failed: status ${resp['statusCode']}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approval error: $e')));
    } finally {
      setState(() => _approvingIds.remove(item.callSheetRequestId));
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Status'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _init,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.inbox, size: 56, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No approval requests found', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final isApproving = _approvingIds.contains(item.callSheetRequestId);
                        final isExpanded = _expandedIds.contains(item.callSheetRequestId);

                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (isExpanded) {
                                  _expandedIds.remove(item.callSheetRequestId);
                                } else {
                                  _expandedIds.add(item.callSheetRequestId);
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Compact header row - always visible
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: item.requestStatus.toLowerCase().contains('approved')
                                            ? Colors.green[50]
                                            : Colors.blue[50],
                                        child: Icon(
                                          item.requestStatus.toLowerCase().contains('approved')
                                              ? Icons.check_circle
                                              : Icons.person,
                                          color: item.requestStatus.toLowerCase().contains('approved')
                                              ? Colors.green
                                              : Colors.blue,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.requestedName.isNotEmpty ? item.requestedName : 'Unknown',
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.requestStatus,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: item.requestStatus.toLowerCase().contains('approved')
                                                    ? Colors.green[700]
                                                    : Colors.orange[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Approve button - always visible
                                      SizedBox(
                                        height: 36,
                                        child: ElevatedButton(
                                          onPressed: (item.requestStatus.toLowerCase().contains('approved') || isApproving)
                                              ? null
                                              : () => _approveItem(item, index),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                          ),
                                          child: isApproving
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                  ),
                                                )
                                              : const Text('Approve', style: TextStyle(fontSize: 13)),
                                        ),
                                      ),
                                      Icon(
                                        isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ),
                                  // Expandable details section
                                  if (isExpanded) ...[
                                    const Divider(height: 20),
                                    _buildDetailRow(
                                      Icons.movie,
                                      'Project',
                                      item.projectName.isNotEmpty
                                          ? item.projectName
                                          : (item.callSheetNo.isNotEmpty ? 'CS#${item.callSheetNo}' : '-'),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailRow(
                                      Icons.business,
                                      'Unit',
                                      item.requestUnitName.isNotEmpty ? item.requestUnitName : '-',
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailRow(
                                      Icons.calendar_today,
                                      'Date',
                                      _formatDate(item.requestDate),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildDetailRow(
                                      Icons.access_time,
                                      'Time',
                                      item.requestedTime,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemCount: _items.length,
                    ),
    );
  }
}
