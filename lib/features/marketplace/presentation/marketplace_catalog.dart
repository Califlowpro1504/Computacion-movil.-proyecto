import 'package:flutter/material.dart';

import '../data/marketplace_service.dart';

class MarketplaceCatalog extends StatefulWidget {
  const MarketplaceCatalog({super.key, required this.service});

  final MarketplaceService service;

  @override
  State<MarketplaceCatalog> createState() => _MarketplaceCatalogState();
}

class _MarketplaceCatalogState extends State<MarketplaceCatalog> {
  final _query = TextEditingController();
  final _category = TextEditingController();
  final _zone = TextEditingController();
  String _type = '';
  int? _rating;
  int _offset = 0;
  bool _showFilters = false;
  late Future<List<CommerceData>> _results;

  @override
  void initState() {
    super.initState();
    _results = _search();
  }

  @override
  void dispose() {
    _query.dispose();
    _category.dispose();
    _zone.dispose();
    super.dispose();
  }

  Future<List<CommerceData>> _search() => widget.service.search(
    query: _query.text,
    category: _category.text,
    zone: _zone.text,
    type: _type,
    rating: _rating,
    offset: _offset,
  );

  void _load([int offset = 0]) {
    setState(() {
      _offset = offset;
      _results = _search();
    });
  }

  void _clear() {
    _query.clear();
    _category.clear();
    _zone.clear();
    _type = '';
    _rating = null;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        TextField(
          controller: _query,
          maxLength: 120,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _load(),
          decoration: InputDecoration(
            labelText: 'Comercio, categoría, producto o servicio',
            counterText: '',
            suffixIcon: IconButton(
              tooltip: 'Buscar',
              onPressed: _load,
              icon: const Icon(Icons.search),
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            TextButton.icon(
              onPressed: () => setState(() => _showFilters = !_showFilters),
              icon: const Icon(Icons.tune),
              label: Text(_showFilters ? 'Ocultar filtros' : 'Filtros'),
            ),
            TextButton(onPressed: _clear, child: const Text('Limpiar')),
          ],
        ),
        if (_showFilters) ...[
          TextField(
            controller: _category,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _zone,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Barrio o zona',
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: ValueKey(_type),
            initialValue: _type,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Tipo de comercio'),
            items: [
              const DropdownMenuItem(value: '', child: Text('Todos')),
              for (final type in commerceTypes)
                DropdownMenuItem(value: type, child: Text(type)),
            ],
            onChanged: (value) => setState(() => _type = value ?? ''),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            key: ValueKey(_rating),
            initialValue: _rating ?? 0,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Calificación mínima'),
            items: [
              const DropdownMenuItem(value: 0, child: Text('Cualquiera')),
              for (var stars = 1; stars <= 5; stars++)
                DropdownMenuItem(value: stars, child: Text('$stars estrellas')),
            ],
            onChanged: (value) =>
                setState(() => _rating = value == 0 ? null : value),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: _load, child: const Text('Aplicar filtros')),
        ],
        const SizedBox(height: 12),
        Text(
          'Comercios disponibles',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        FutureBuilder(
          future: _results,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  const Text('No pudimos cargar los comercios.'),
                  TextButton(
                    onPressed: () => _load(_offset),
                    child: const Text('Reintentar'),
                  ),
                ],
              );
            }
            final rows = snapshot.requireData;
            return Column(
              children: [
                if (rows.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No hay comercios con estos criterios.'),
                  ),
                for (final row in rows)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.storefront),
                      title: Text(row['nombre'] as String),
                      subtitle: Text(
                        [
                          row['categoria'],
                          row['zona'],
                          if (row['calificacion'] case final num rating)
                            '★ $rating',
                        ].whereType<String>().join(' · '),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => CommerceDetail(
                            service: widget.service,
                            id: row['id'] as String,
                          ),
                        ),
                      ),
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  children: [
                    if (_offset > 0)
                      TextButton(
                        onPressed: () =>
                            _load(_offset - MarketplaceService.pageSize),
                        child: const Text('Anterior'),
                      ),
                    if (rows.length == MarketplaceService.pageSize)
                      TextButton(
                        onPressed: () =>
                            _load(_offset + MarketplaceService.pageSize),
                        child: const Text('Siguiente'),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class CommerceDetail extends StatefulWidget {
  const CommerceDetail({super.key, required this.service, required this.id});

  final MarketplaceService service;
  final String id;

  @override
  State<CommerceDetail> createState() => _CommerceDetailState();
}

class _CommerceDetailState extends State<CommerceDetail> {
  late Future<CommerceData?> _detail = widget.service.detail(widget.id);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Detalle del comercio')),
    body: FutureBuilder(
      future: _detail,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No pudimos cargar el comercio.'),
                TextButton(
                  onPressed: () => setState(
                    () => _detail = widget.service.detail(widget.id),
                  ),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
        final row = snapshot.data;
        if (row == null) {
          return const Center(
            child: Text('El comercio ya no está disponible.'),
          );
        }

        final image = Uri.tryParse(row['imagen'] as String? ?? '');
        final products = (row['productos'] as List).cast<String>();
        final services = (row['servicios'] as List).cast<String>();
        final reviews = (row['resenas'] as List).cast<CommerceData>();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (image?.scheme == 'https' && image!.host.isNotEmpty)
              Image.network(
                image.toString(),
                height: 160,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.storefront, size: 48),
              ),
            Text(
              row['nombre'] as String,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            if (row['descripcion'] case final String value) Text(value),
            for (final (key, label) in [
              ('direccion', 'Dirección'),
              ('telefono', 'Teléfono'),
              ('horario', 'Horario'),
              ('zona', 'Barrio o zona'),
              ('calificacion', 'Calificación'),
            ])
              ListTile(
                title: Text(label),
                subtitle: Text(row[key]?.toString() ?? 'Sin información'),
              ),
            ExpansionTile(
              title: const Text('Productos'),
              children: [
                if (products.isEmpty)
                  const ListTile(title: Text('Sin productos disponibles')),
                for (final name in products) ListTile(title: Text(name)),
              ],
            ),
            ExpansionTile(
              title: const Text('Servicios'),
              children: [
                if (services.isEmpty)
                  const ListTile(title: Text('Sin servicios disponibles')),
                for (final name in services) ListTile(title: Text(name)),
              ],
            ),
            ExpansionTile(
              title: const Text('Reseñas'),
              children: [
                if (reviews.isEmpty)
                  const ListTile(title: Text('Sin reseñas publicadas')),
                for (final review in reviews)
                  ListTile(
                    title: Text(review['comentario'] as String),
                    subtitle: Text('★ ${review['calificacion']}'),
                  ),
              ],
            ),
          ],
        );
      },
    ),
  );
}
