import 'package:computacion_movil_proyecto/features/marketplace/data/marketplace_service.dart';
import 'package:computacion_movil_proyecto/features/marketplace/presentation/marketplace_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Marketplace extends MarketplaceService {
  _Marketplace(SupabaseClient client) : super(client: client);

  final queries = <String>[];
  static const _row = {
    'id': 'comercio',
    'nombre': 'Tienda local',
    'categoria': 'Belleza',
  };

  @override
  Future<List<CommerceData>> search({
    String query = '',
    String category = '',
    String zone = '',
    String type = '',
    int? rating,
    int offset = 0,
  }) async {
    queries.add(query.trim());
    if (queries.length == 1) throw StateError('Fallo simulado');
    return query == 'masaje' ? [_row] : [];
  }

  @override
  Future<CommerceData> detail(String id) async => {
    ..._row,
    'direccion': 'Calle 1',
    'productos': ['Champú de coco'],
    'servicios': ['Masaje'],
    'resenas': [],
  };
}

void main() {
  late SupabaseClient client;
  setUp(() {
    client = SupabaseClient(
      'https://example.com',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
  });
  tearDown(() => client.dispose());

  testWidgets(
    'reintenta la carga y mantiene la búsqueda al volver del detalle',
    (tester) async {
      final service = _Marketplace(client);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MarketplaceCatalog(service: service),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No pudimos cargar los comercios.'), findsOneWidget);
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(
        find.text('No hay comercios con estos criterios.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'masaje');
      await tester.tap(find.byTooltip('Buscar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tienda local'));
      await tester.pumpAndSettle();
      expect(find.text('Calle 1'), findsOneWidget);
      await tester.tap(find.text('Productos'));
      await tester.pumpAndSettle();
      expect(find.text('Champú de coco'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('masaje'), findsOneWidget);
      expect(service.queries, ['', '', 'masaje']);
    },
  );
}
