import 'package:flutter/material.dart';

import 'diagramme/grafcet_basis_diagramm.dart';
import 'diagramme/hydraulik_kolben_diagramm.dart';
import 'diagramme/kraeftedreieck_diagramm.dart';
import 'diagramme/passungsdiagramm.dart';
import 'diagramme/pneumatik_ventil_diagramm.dart';
import 'diagramme/schnittdaten_diagramm.dart';
import 'diagramme/toleranzfeld_diagramm.dart';
import 'diagramme/werkzeugwinkel_diagramm.dart';
import 'diagramme/zahnrad_geometrie_diagramm.dart';

// Zeigt eine technische Illustration wenn bildAsset mit "diag:" beginnt.
// Unbekannte Keys werden still ignoriert (null zurück).
class TechnischeIllustration extends StatelessWidget {
  final String diagrammKey;
  const TechnischeIllustration({super.key, required this.diagrammKey});

  static bool istDiagramm(String? bildAsset) =>
      bildAsset != null && bildAsset.startsWith('diag:');

  static String keyAus(String bildAsset) => bildAsset.substring(5);

  @override
  Widget build(BuildContext context) {
    final painter = _painter(diagrammKey, Theme.of(context).colorScheme);
    if (painter == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 180,
          child: CustomPaint(painter: painter, child: const SizedBox.expand()),
        ),
      ),
    );
  }

  CustomPainter? _painter(String key, ColorScheme cs) {
    switch (key) {
      case 'werkzeugwinkel':
        return WerkzeugwinkelPainter(cs: cs);
      case 'passungsdiagramm':
        return PassungsPainter(cs: cs);
      case 'schnittdaten':
        return SchnittdatenPainter(cs: cs);
      case 'kraeftedreieck':
        return KraefteDreieckPainter(cs: cs);
      case 'pneumatik_52_ventil':
        return Pneumatik52VentilPainter(cs: cs);
      case 'toleranzfeld':
        return ToleranzfeldPainter(cs: cs);
      case 'hydraulik_kolben':
        return HydraulikKolbenPainter(cs: cs);
      case 'zahnrad_geometrie':
        return ZahnradGeometriePainter(cs: cs);
      case 'grafcet_basis':
        return GrafcetBasisPainter(cs: cs);
      default:
        return null;
    }
  }
}
