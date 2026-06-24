// services/pdf_service.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../model/analysis_model.dart';

class PdfService {
  static Future<void> generateAndShare(AnalysisResultModel result, {Map<String, bool>? options}) async {
    final opts = options ?? {'resumen': true, 'reps': true, 'alertas': true, 'mejoras': true, 'ejercicios': false};
    final pdf = pw.Document();
    final score = result.techniqueScore;
    final scoreColor = score >= 75 ? PdfColors.teal : score >= 60 ? PdfColors.orange : PdfColors.red;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) {
        final W = <pw.Widget>[];

        // ── Portada (siempre) ──────────────────────────────────────────────
        W.add(pw.Container(
          padding: const pw.EdgeInsets.all(20),
          decoration: pw.BoxDecoration(
            color: const PdfColor(0.42, 0.39, 1.0),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('BioMove v4.0', style: pw.TextStyle(
                    color: PdfColors.white, fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Informe de Analisis Biomecanico',
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 13)),
                pw.SizedBox(height: 6),
                pw.Text(_fmt(result.sessionDate),
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 11)),
              ]),
              pw.Container(
                width: 72, height: 72,
                decoration: pw.BoxDecoration(color: PdfColors.white, shape: pw.BoxShape.circle),
                child: pw.Center(child: pw.Column(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text('${score.toStringAsFixed(0)}',
                        style: pw.TextStyle(color: scoreColor, fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.Text('/100', style: const pw.TextStyle(color: PdfColors.grey, fontSize: 9)),
                  ],
                )),
              ),
            ],
          ),
        ));
        W.add(pw.SizedBox(height: 18));

        // ── Resumen (opt) ──────────────────────────────────────────────────
        if (opts['resumen'] == true) {
          W.add(_title('Resumen de la sesion'));
          W.add(pw.SizedBox(height: 10));

          // 4 cajas de métricas en una tabla simple (evita problemas con Expanded en PDF)
          final reps = result.repetitions;
          final fatiga = result.fatigueDetected ? 'Si' : 'No';
          final durStr = result.durationSeconds != null
              ? '${result.durationSeconds!.toStringAsFixed(0)}s' : '--';
          final pesoStr = result.weightKg != null
              ? '${result.weightKg!.toStringAsFixed(0)} kg' : '--';

          W.add(pw.Table(
            columnWidths: {
              0: const pw.FlexColumnWidth(1),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(children: [
                _metricCell('${result.totalReps}', 'Reps', const PdfColor(0.42,0.39,1.0)),
                _metricCell(durStr, 'Duracion', const PdfColor(0.0,0.83,0.67)),
                _metricCell(pesoStr, 'Peso', PdfColors.orange),
                _metricCell(fatiga, 'Fatiga',
                    result.fatigueDetected ? PdfColors.red : const PdfColor(0.0,0.83,0.67)),
              ]),
            ],
          ));
          W.add(pw.SizedBox(height: 14));

          // Tabla de métricas técnicas (sin emojis)
          if (reps.isNotEmpty) {
            double avg(double? Function(RepResultModel) fn) {
              final vals = reps.map(fn).whereType<double>().toList();
              return vals.isEmpty ? 0.0 : vals.reduce((a,b)=>a+b)/vals.length;
            }
            final knee  = avg((r) => r.kneeAngleMin);
            final valg  = avg((r) => ((r.leftValgus??0)+(r.rightValgus??0))/2);
            final trunk = avg((r) => r.trunkLeanMax);
            final asym  = avg((r) => r.kneeAsymmetryPct);
            final acl   = avg((r) => r.aclRiskScore);

            W.add(_title('Metricas tecnicas'));
            W.add(pw.SizedBox(height: 8));
            W.add(pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2.5),
                1: const pw.FlexColumnWidth(1),
                2: const pw.FlexColumnWidth(1.2),
              },
              children: [
                _hdrRow(['Parametro', 'Valor', 'Estado']),
                _techRow('Angulo rodilla (profundidad)', '${knee.toStringAsFixed(0)}grados', knee<=95?'Correcto':'Insuficiente'),
                _techRow('Valgo de rodilla promedio', '${valg.toStringAsFixed(0)}grados', valg<=10?'Correcto':'Revisar'),
                _techRow('Inclinacion de tronco', '${trunk.toStringAsFixed(0)}grados', trunk<=55?'Correcto':'Excesiva'),
                _techRow('Simetria bilateral', '${asym.toStringAsFixed(0)}%', asym<=8?'Correcto':'Asimetrico'),
                _techRow('Riesgo LCA (0-100)', acl.toStringAsFixed(0), acl<=25?'Bajo':'${ acl<=50?'Moderado':'Alto'}'),
              ],
            ));
            W.add(pw.SizedBox(height: 18));
          }
        }

        // ── Reps (opt) ─────────────────────────────────────────────────────
        if (opts['reps'] == true && result.repetitions.isNotEmpty) {
          W.add(_title('Analisis por repeticion'));
          W.add(pw.SizedBox(height: 8));
          W.add(pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(0.7),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1),
              5: const pw.FlexColumnWidth(1),
            },
            children: [
              _hdrRow(['Rep', 'Score', 'Rodilla', 'Tronco', 'Valgo', 'LCA']),
              ...result.repetitions.map((rep) {
                final sc = rep.repScore;
                final rc = sc>=75 ? PdfColors.teal : sc>=60 ? PdfColors.orange : PdfColors.red;
                return pw.TableRow(children: [
                  _c('${rep.repNumber}'),
                  pw.Padding(padding: const pw.EdgeInsets.all(5),
                    child: pw.Text('${sc.toStringAsFixed(0)}/100',
                        style: pw.TextStyle(color: rc, fontSize: 9, fontWeight: pw.FontWeight.bold))),
                  _c('${rep.kneeAngleMin?.toStringAsFixed(0)??'--'}g'),
                  _c('${rep.trunkLeanMax?.toStringAsFixed(0)??'--'}g'),
                  _c('${rep.leftValgus?.toStringAsFixed(0)??'--'}g'),
                  _c('${rep.aclRiskScore?.toStringAsFixed(0)??'--'}'),
                ]);
              }),
            ],
          ));
          W.add(pw.SizedBox(height: 18));
        }

        // ── Alertas (opt) ──────────────────────────────────────────────────
        if (opts['alertas'] == true && result.riskFeedback.isNotEmpty) {
          W.add(_title('ALERTAS DE LESION'));
          W.add(pw.SizedBox(height: 8));
          for (final f in result.riskFeedback.take(4)) {
            W.add(pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: const PdfColor(1.0, 0.32, 0.32, 0.08),
                border: pw.Border.all(color: PdfColors.red300, width: 0.5),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(f.message, style: pw.TextStyle(
                    color: PdfColors.red700, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Correccion: ${f.correction}',
                    style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
              ]),
            ));
          }
          W.add(pw.SizedBox(height: 12));
        }

        // ── Mejoras (opt) ──────────────────────────────────────────────────
        if (opts['mejoras'] == true && result.improveFeedback.isNotEmpty) {
          W.add(_title('PUNTOS A MEJORAR'));
          W.add(pw.SizedBox(height: 8));
          for (final f in result.improveFeedback.take(5)) {
            W.add(pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: const PdfColor(1.0, 0.72, 0.3, 0.08),
                border: pw.Border.all(color: PdfColors.orange300, width: 0.5),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(f.message, style: pw.TextStyle(
                    color: PdfColors.orange800, fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Correccion: ${f.correction}',
                    style: const pw.TextStyle(color: PdfColors.grey700, fontSize: 10)),
              ]),
            ));
          }
          W.add(pw.SizedBox(height: 12));
        }

        // ── Ejercicios (opt) ──────────────────────────────────────────────
        if (opts['ejercicios'] == true) {
          final withEx = [...result.riskFeedback, ...result.improveFeedback]
              .where((f) => (f.exerciseRecommendation?.isNotEmpty ?? false)).toList();
          if (withEx.isNotEmpty) {
            W.add(_title('EJERCICIOS RECOMENDADOS'));
            W.add(pw.SizedBox(height: 8));
            for (final f in withEx.take(5)) {
              W.add(pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Row(children: [
                  pw.Text('- ', style: pw.TextStyle(color: const PdfColor(0.42,0.39,1.0),
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.Expanded(child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text(f.message,
                        style: const pw.TextStyle(color: PdfColors.grey800, fontSize: 10)),
                    pw.Text(f.exerciseRecommendation ?? '',
                        style: pw.TextStyle(color: const PdfColor(0.42,0.39,1.0), fontSize: 9)),
                  ])),
                ]),
              ));
            }
            W.add(pw.SizedBox(height: 12));
          }
        }

        // ── Pie ───────────────────────────────────────────────────────────
        W.add(pw.Divider(color: PdfColors.grey300));
        W.add(pw.SizedBox(height: 6));
        W.add(pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('BioMove v4.0 - Analisis biomecanico con IA',
                style: const pw.TextStyle(color: PdfColors.grey, fontSize: 8)),
            pw.Text('Generado: ${_fmt(DateTime.now())}',
                style: const pw.TextStyle(color: PdfColors.grey, fontSize: 8)),
          ],
        ));

        return W;
      },
    ));

    final dir  = await getTemporaryDirectory();
    final path = '${dir.path}/biomove_${DateTime.now().millisecondsSinceEpoch}.pdf';
    await File(path).writeAsBytes(await pdf.save());
    await Share.shareXFiles([XFile(path)],
        subject: 'Informe BioMove ${score.toStringAsFixed(0)}/100',
        text: 'Analisis de sentadilla ${_fmt(result.sessionDate)}');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  static pw.Widget _title(String t) => pw.Text(t,
      style: pw.TextStyle(color: const PdfColor(0.42,0.39,1.0),
          fontSize: 13, fontWeight: pw.FontWeight.bold));

  static pw.Widget _metricCell(String value, String label, PdfColor color) =>
    pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColor(color.red, color.green, color.blue, 0.1),
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColor(color.red, color.green, color.blue, 0.3), width: 0.5),
        ),
        child: pw.Column(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(value, style: pw.TextStyle(color: color, fontSize: 15, fontWeight: pw.FontWeight.bold),
                textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 3),
            pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey, fontSize: 9),
                textAlign: pw.TextAlign.center),
          ],
        ),
      ),
    );

  static pw.TableRow _hdrRow(List<String> cols) => pw.TableRow(
    decoration: const pw.BoxDecoration(color: PdfColor(0.42,0.39,1.0)),
    children: cols.map((h) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(h, style: pw.TextStyle(
          color: PdfColors.white, fontSize: 9, fontWeight: pw.FontWeight.bold)),
    )).toList(),
  );

  static pw.TableRow _techRow(String param, String value, String status) =>
    pw.TableRow(children: [
      _c(param),
      _c(value),
      pw.Padding(padding: const pw.EdgeInsets.all(5),
        child: pw.Text(status, style: pw.TextStyle(
            color: status == 'Correcto' || status == 'Bajo' ? PdfColors.teal700 : PdfColors.orange700,
            fontSize: 9, fontWeight: pw.FontWeight.bold))),
    ]);

  static pw.Widget _c(String t) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
    child: pw.Text(t, style: const pw.TextStyle(color: PdfColors.grey800, fontSize: 9)));

  static String _fmt(DateTime d) =>
    '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
}
