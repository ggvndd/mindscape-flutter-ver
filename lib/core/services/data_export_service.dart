import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Researcher-only service: fetches all evaluation_logs from Firestore,
/// converts them to a CSV file and triggers the native share sheet.
///
/// Triggered by a hidden long-press gesture in the Profile screen —
/// never visible or accessible to regular users.
class DataExportService {
  DataExportService._();
  static final DataExportService instance = DataExportService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Fetches every document in `evaluation_logs`, writes a CSV to the
  /// temporary directory, and opens the native share sheet.
  ///
  /// Returns a human-readable status string (used for SnackBar feedback).
  Future<String> exportToCsv() async {
    // ── 1. Fetch all documents ─────────────────────────────────────────────
    final QuerySnapshot snapshot =
        await _db.collection('evaluation_logs').orderBy('logged_at').get();

    if (snapshot.docs.isEmpty) {
      return 'No data found in evaluation_logs.';
    }

    // ── 2. Build CSV rows ──────────────────────────────────────────────────
    final List<List<dynamic>> rows = [
      // Header row
      ['user_id', 'ui_condition', 'tot_ms', 'mood_logged', 'logged_at'],
    ];

    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Resolve timestamp — handle both Timestamp and missing field gracefully.
      String timestampStr = '';
      final ts = data['logged_at'];
      if (ts is Timestamp) {
        final dt = ts.toDate().toLocal();
        timestampStr =
            '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
            '${_pad(dt.hour)}:${_pad(dt.minute)}:${_pad(dt.second)}';
      }

      rows.add([
        data['user_id'] ?? '',
        data['ui_condition'] ?? '',
        data['tot_ms'] ?? '',
        data['mood_logged'] ?? '',
        timestampStr,
      ]);
    }

    // ── 3. Convert to CSV string ───────────────────────────────────────────
    final String csvContent = const ListToCsvConverter().convert(rows);

    // ── 4. Write to a temp file ────────────────────────────────────────────
    final Directory dir = await getApplicationDocumentsDirectory();
    final String filePath = '${dir.path}/tot_results.csv';
    final File file = File(filePath);
    await file.writeAsString(csvContent);

    // ── 5. Share via native sheet ──────────────────────────────────────────
    await Share.shareXFiles(
      [XFile(filePath, mimeType: 'text/csv')],
      subject: 'Mindscape – TOT Evaluation Logs (${snapshot.docs.length} rows)',
    );

    return 'Exported ${snapshot.docs.length} rows successfully.';
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _pad(int n) => n.toString().padLeft(2, '0');
}
