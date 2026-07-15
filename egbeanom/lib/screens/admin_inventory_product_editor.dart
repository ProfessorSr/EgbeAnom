part of '../main.dart';

class _InventoryTable extends StatefulWidget {
  const _InventoryTable({
    required this.products,
    required this.activeCarts,
    required this.measurementSystem,
    required this.onEdit,
    required this.onRemove,
  });

  final List<Fragrance> products;
  final List<ActiveCart> activeCarts;
  final MeasurementSystem measurementSystem;
  final ValueChanged<Fragrance> onEdit;
  final ProductRemoveCallback onRemove;

  @override
  State<_InventoryTable> createState() => _InventoryTableState();
}

class _InventoryTableState extends State<_InventoryTable> {
  String _query = '';
  String _stockFilter = 'All';

  int _reservedFor(Fragrance product) {
    return widget.activeCarts.fold(0, (total, cart) {
      return total +
          cart.lines
              .where((line) => line.product.id == product.id)
              .fold(0, (lineTotal, line) => lineTotal + line.quantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.products.where((product) {
      final query = _query.toLowerCase();
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.sku.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query) ||
          product.itemLocation.toLowerCase().contains(query);
      final reserved = _reservedFor(product);
      final available = product.stock - reserved;
      final matchesStock = switch (_stockFilter) {
        'Low stock' => product.stock <= product.reorderPoint,
        'Reserved' => reserved > 0,
        'Available' => available > 0,
        _ => true,
      };
      return matchesQuery && matchesStock;
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                'Inventory',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 760;
                return Flex(
                  direction: wide ? Axis.horizontal : Axis.vertical,
                  children: [
                    Expanded(
                      flex: wide ? 4 : 0,
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Filter inventory',
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                    if (wide)
                      const SizedBox(width: 10)
                    else
                      const SizedBox(height: 10),
                    Expanded(
                      flex: wide ? 3 : 0,
                      child: DropdownButtonFormField<String>(
                        initialValue: _stockFilter,
                        decoration: const InputDecoration(
                          labelText: 'Stock view',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All', child: Text('All')),
                          DropdownMenuItem(
                            value: 'Low stock',
                            child: Text('Low stock'),
                          ),
                          DropdownMenuItem(
                            value: 'Reserved',
                            child: Text('Reserved'),
                          ),
                          DropdownMenuItem(
                            value: 'Available',
                            child: Text('Available'),
                          ),
                        ],
                        onChanged: (value) => setState(
                          () => _stockFilter = value ?? _stockFilter,
                        ),
                      ),
                    ),
                    if (wide)
                      const SizedBox(width: 10)
                    else
                      const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => _printInventory(products),
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Print'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _HorizontalTableScroller(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Photo')),
                  DataColumn(label: Text('Item')),
                  DataColumn(label: Text('SKU')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Stock')),
                  DataColumn(label: Text('Location')),
                  DataColumn(label: Text('In carts')),
                  DataColumn(label: Text('Available')),
                  DataColumn(label: Text('Reorder')),
                  DataColumn(label: Text('Ship size')),
                  DataColumn(label: Text('Sold')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: products.map((product) {
                  final reserved = _reservedFor(product);
                  final available = product.stock - reserved;
                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox.square(
                          dimension: 42,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: ProductPhoto(product: product),
                          ),
                        ),
                      ),
                      DataCell(Text(product.name)),
                      DataCell(Text(product.sku)),
                      DataCell(Text(product.type)),
                      DataCell(Text(currency(product.price))),
                      DataCell(Text('${product.stock}')),
                      DataCell(Text(product.itemLocation)),
                      DataCell(Text('$reserved')),
                      DataCell(Text('$available')),
                      DataCell(Text('${product.reorderPoint}')),
                      DataCell(
                        Text(product.shippingSize(widget.measurementSystem)),
                      ),
                      DataCell(Text('${product.sold}')),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              onPressed: () => widget.onEdit(product),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Remove',
                              onPressed: () async => widget.onRemove(product),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _printInventory(List<Fragrance> products) {
    final rows = products.map((product) {
      final reserved = _reservedFor(product);
      final available = product.stock - reserved;
      final photoUrl = _printImageSource(product.primaryPhotoUrl);
      final photo = photoUrl.isEmpty
          ? ''
          : '<img src="${htmlEscape.convert(photoUrl)}" alt="${htmlEscape.convert(product.name)}">';
      return '''
        <tr>
          <td class="photo">$photo</td>
          <td>${htmlEscape.convert(product.name)}</td>
          <td>${htmlEscape.convert(product.sku)}</td>
          <td>${htmlEscape.convert(product.type)}</td>
          <td>${htmlEscape.convert(currency(product.price))}</td>
          <td>${product.stock}</td>
          <td>${htmlEscape.convert(product.itemLocation)}</td>
          <td>$reserved</td>
          <td>$available</td>
          <td>${product.reorderPoint}</td>
          <td>${htmlEscape.convert(product.shippingSize(widget.measurementSystem))}</td>
          <td>${product.sold}</td>
        </tr>
      ''';
    }).join();
    final html =
        '''
      <style>
        .inventory-print h1 {
          font-size: 22px;
          margin: 0 0 6px;
        }
        .inventory-print .meta {
          font-size: 12px;
          margin: 0 0 14px;
        }
        .inventory-print table {
          width: 100%;
          border-collapse: collapse;
          font-size: 11px;
        }
        .inventory-print th,
        .inventory-print td {
          border: 1px solid #111;
          padding: 6px 7px;
          text-align: left;
          vertical-align: middle;
        }
        .inventory-print th {
          background: #f1ede6;
          font-weight: 700;
        }
        .inventory-print .photo {
          width: 48px;
          text-align: center;
        }
        .inventory-print img {
          width: 38px;
          height: 38px;
          object-fit: cover;
        }
      </style>
      <div class="inventory-print">
        <h1>Egbe Anom inventory</h1>
        <p class="meta">Filter: ${htmlEscape.convert(_stockFilter)} &nbsp; Generated: ${htmlEscape.convert(DateTime.now().toString())}</p>
        <table>
          <thead>
            <tr>
              <th>Photo</th>
              <th>Item</th>
              <th>SKU</th>
              <th>Type</th>
              <th>Price</th>
              <th>Stock</th>
              <th>Location</th>
              <th>In carts</th>
              <th>Available</th>
              <th>Reorder</th>
              <th>Ship size</th>
              <th>Sold</th>
            </tr>
          </thead>
          <tbody>
            $rows
          </tbody>
        </table>
      </div>
    ''';
    printHtmlDocument('Egbe Anom inventory', html);
  }

  String _printImageSource(String source) {
    final clean = source.trim();
    if (clean.isEmpty) {
      return '';
    }
    if (clean.startsWith('assets/')) {
      return Uri.encodeFull('assets/$clean');
    }
    return Uri.encodeFull(clean);
  }
}

class ProductEditor extends StatefulWidget {
  const ProductEditor({
    super.key,
    required this.product,
    required this.categories,
    required this.measurementSystem,
    required this.noteOptions,
    required this.familyOptions,
    required this.seasonOptions,
    required this.occasionOptions,
    required this.onSave,
    required this.onCancel,
    required this.onUploadImages,
  });

  final Fragrance product;
  final List<Category> categories;
  final MeasurementSystem measurementSystem;
  final List<String> noteOptions;
  final List<String> familyOptions;
  final List<String> seasonOptions;
  final List<String> occasionOptions;
  final AsyncValueChanged<Fragrance> onSave;
  final VoidCallback onCancel;
  final Future<List<ProductImage>> Function(
    Fragrance product,
    List<UploadedImageFile> files,
  )
  onUploadImages;

  @override
  State<ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<ProductEditor> {
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _description;
  late final TextEditingController _vibe;
  late final TextEditingController _performance;
  late final TextEditingController _comparison;
  late final TextEditingController _fragranceProfile;
  late final TextEditingController _ingredients;
  late final TextEditingController _size;
  late final TextEditingController _price;
  late final TextEditingController _cost;
  late final TextEditingController _stock;
  late final TextEditingController _sku;
  late final TextEditingController _vendor;
  late final TextEditingController _itemLocation;
  late final TextEditingController _reorderPoint;
  late final TextEditingController _weightOz;
  late final TextEditingController _lengthIn;
  late final TextEditingController _widthIn;
  late final TextEditingController _heightIn;
  late List<ProductImage> _images;
  late List<ProductVariant> _variants;
  bool _uploading = false;
  bool _saving = false;
  late String _type;
  late String _concentration;
  late String _gender;
  late int _categoryId;
  late Set<String> _generalNotes;
  late Set<String> _topNotes;
  late Set<String> _heartNotes;
  late Set<String> _baseNotes;
  late Set<String> _families;
  late Set<String> _seasons;
  late Set<String> _occasions;

  static const _typeOptions = ['Perfume', 'Cologne', 'Body Oil'];
  static const _concentrationOptions = [
    'EDT',
    'EDP',
    'Parfum',
    'Extrait de Parfum',
    'Oil',
  ];
  static const _genderOptions = ['Unisex', 'Women', 'Men'];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.product.name);
    _brand = TextEditingController(text: widget.product.brand);
    _description = TextEditingController(text: widget.product.description);
    _vibe = TextEditingController(text: widget.product.vibe);
    _performance = TextEditingController(text: widget.product.performance);
    _comparison = TextEditingController(text: widget.product.comparison);
    _fragranceProfile = TextEditingController(
      text: widget.product.fragranceProfile,
    );
    _ingredients = TextEditingController(text: widget.product.ingredients);
    _size = TextEditingController(text: widget.product.size);
    _price = TextEditingController(
      text: widget.product.price.toStringAsFixed(2),
    );
    _cost = TextEditingController(text: widget.product.cost.toStringAsFixed(2));
    _stock = TextEditingController(text: '${widget.product.stock}');
    _sku = TextEditingController(text: widget.product.sku);
    _vendor = TextEditingController(text: widget.product.vendor);
    _itemLocation = TextEditingController(text: widget.product.itemLocation);
    _reorderPoint = TextEditingController(
      text: '${widget.product.reorderPoint}',
    );
    _weightOz = TextEditingController(
      text: _displayWeight(widget.product.weightOz).toStringAsFixed(1),
    );
    _lengthIn = TextEditingController(
      text: _displayLength(widget.product.lengthIn).toStringAsFixed(1),
    );
    _widthIn = TextEditingController(
      text: _displayLength(widget.product.widthIn).toStringAsFixed(1),
    );
    _heightIn = TextEditingController(
      text: _displayLength(widget.product.heightIn).toStringAsFixed(1),
    );
    _type = _safeDropdownValue(widget.product.type, _typeOptions);
    _concentration = _safeDropdownValue(
      widget.product.concentration,
      _concentrationOptions,
    );
    _gender = _safeDropdownValue(widget.product.gender, _genderOptions);
    _categoryId = widget.product.categoryId;
    _generalNotes = _splitValues(widget.product.notes);
    _topNotes = _splitValues(widget.product.topNotes);
    _heartNotes = _splitValues(widget.product.heartNotes);
    _baseNotes = _splitValues(widget.product.baseNotes);
    _families = _splitValues(widget.product.family);
    _seasons = _splitValues(widget.product.season);
    _occasions = _splitValues(widget.product.occasion);
    _images = [...widget.product.images];
    _variants = widget.product.variants.isEmpty
        ? [
            ProductVariant(
              id: DateTime.now().millisecondsSinceEpoch,
              size: widget.product.size,
              sku: widget.product.sku,
              price: widget.product.price,
              stock: widget.product.stock,
              reorderPoint: widget.product.reorderPoint,
            ),
          ]
        : [
            for (final variant in widget.product.variants)
              ProductVariant(
                id: variant.id,
                size: variant.size,
                sku: variant.sku,
                price: variant.price,
                stock: variant.stock,
                reorderPoint: variant.reorderPoint,
                isActive: variant.isActive,
              ),
          ];
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _description.dispose();
    _vibe.dispose();
    _performance.dispose();
    _comparison.dispose();
    _fragranceProfile.dispose();
    _ingredients.dispose();
    _size.dispose();
    _price.dispose();
    _cost.dispose();
    _stock.dispose();
    _sku.dispose();
    _vendor.dispose();
    _itemLocation.dispose();
    _reorderPoint.dispose();
    _weightOz.dispose();
    _lengthIn.dispose();
    _widthIn.dispose();
    _heightIn.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_images.isNotEmpty && !_images.any((image) => image.isPrimary)) {
      _images.first.isPrimary = true;
    }
    final activeVariants = _variants
        .where((variant) => variant.isActive && variant.size.trim().isNotEmpty)
        .toList();
    final primaryVariant = activeVariants.isEmpty
        ? ProductVariant(
            id: DateTime.now().millisecondsSinceEpoch,
            size: _size.text.trim(),
            sku: _sku.text.trim(),
            price: double.tryParse(_price.text) ?? 0,
            stock: int.tryParse(_stock.text) ?? 0,
            reorderPoint: int.tryParse(_reorderPoint.text) ?? 8,
          )
        : activeVariants.first;
    final product = Fragrance(
      id: widget.product.id,
      name: _name.text.trim(),
      type: _type,
      brand: _brand.text.trim(),
      notes: _joinValues(_generalNotes),
      size: primaryVariant.size.trim(),
      price: primaryVariant.price,
      cost: double.tryParse(_cost.text) ?? 0,
      stock: activeVariants.fold(0, (total, variant) => total + variant.stock),
      sold: widget.product.sold,
      featuredColor: widget.product.featuredColor,
      sku: primaryVariant.sku.trim(),
      photoUrl: widget.product.photoUrl,
      vendor: _vendor.text.trim(),
      categoryId: _categoryId,
      brandId: widget.product.brandId,
      itemLocation: _itemLocation.text.trim(),
      reorderPoint: primaryVariant.reorderPoint,
      description: _description.text.trim(),
      vibe: _vibe.text.trim(),
      performance: _performance.text.trim(),
      comparison: _comparison.text.trim(),
      fragranceProfile: _fragranceProfile.text.trim(),
      ingredients: _ingredients.text.trim(),
      topNotes: _joinValues(_topNotes),
      heartNotes: _joinValues(_heartNotes),
      baseNotes: _joinValues(_baseNotes),
      concentration: _concentration,
      gender: _gender,
      season: _joinValues(_seasons),
      occasion: _joinValues(_occasions),
      family: _joinValues(_families),
      rating: widget.product.rating,
      reviewCount: widget.product.reviewCount,
      weightOz: _storedWeight(
        double.tryParse(_weightOz.text) ?? _displayWeight(8),
      ),
      lengthIn: _storedLength(
        double.tryParse(_lengthIn.text) ?? _displayLength(6),
      ),
      widthIn: _storedLength(
        double.tryParse(_widthIn.text) ?? _displayLength(3),
      ),
      heightIn: _storedLength(
        double.tryParse(_heightIn.text) ?? _displayLength(3),
      ),
      images: _images,
      variants: activeVariants,
    );
    setState(() => _saving = true);
    try {
      await widget.onSave(product);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product saved.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Product save failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  bool get _metric => widget.measurementSystem == MeasurementSystem.metric;
  String get _weightLabel => _metric ? 'Weight (g)' : 'Weight (oz)';
  String get _lengthLabel => _metric ? 'Length (cm)' : 'Length (in)';
  String get _widthLabel => _metric ? 'Width (cm)' : 'Width (in)';
  String get _heightLabel => _metric ? 'Height (cm)' : 'Height (in)';
  List<String> get _noteOptions => _mergedOptions(widget.noteOptions, [
    _generalNotes,
    _topNotes,
    _heartNotes,
    _baseNotes,
  ]);
  List<String> get _familyOptions =>
      _mergedOptions(widget.familyOptions, [_families]);
  List<String> get _seasonOptions =>
      _mergedOptions(widget.seasonOptions, [_seasons]);
  List<String> get _occasionOptions =>
      _mergedOptions(widget.occasionOptions, [_occasions]);
  double _displayWeight(double oz) => _metric ? oz * 28.3495 : oz;
  double _displayLength(double inches) => _metric ? inches * 2.54 : inches;
  double _storedWeight(double value) => _metric ? value / 28.3495 : value;
  double _storedLength(double value) => _metric ? value / 2.54 : value;
  Set<String> _splitValues(String value) => value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toSet();
  String _joinValues(Set<String> values) => values.join(', ');
  String _safeDropdownValue(String value, List<String> options) {
    return options.contains(value) ? value : options.first;
  }

  List<String> _mergedOptions(
    List<String> options,
    List<Set<String>> selected,
  ) {
    final merged = <String>{
      for (final option in options)
        if (option.trim().isNotEmpty) option.trim(),
      for (final values in selected)
        for (final value in values)
          if (value.trim().isNotEmpty) value.trim(),
    }.toList();
    merged.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return merged;
  }

  Future<void> _uploadImages() async {
    try {
      final files = await pickProductImages();
      if (files.isEmpty) {
        return;
      }
      setState(() => _uploading = true);
      final uploaded = await widget.onUploadImages(widget.product, files);
      if (!mounted) {
        return;
      }
      setState(() {
        _images.addAll(uploaded);
        if (_images.isNotEmpty && !_images.any((image) => image.isPrimary)) {
          _images.first.isPrimary = true;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${uploaded.length} photo(s) uploaded.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Photo upload failed: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  void _setPrimary(ProductImage image) {
    setState(() {
      for (final item in _images) {
        item.isPrimary = item == image;
      }
    });
  }

  void _removeImage(ProductImage image) {
    setState(() {
      final wasPrimary = image.isPrimary;
      _images.remove(image);
      if (wasPrimary && _images.isNotEmpty) {
        _images.first.isPrimary = true;
      }
    });
  }

  void _addVariant() {
    setState(() {
      _variants.add(
        ProductVariant(
          id: DateTime.now().millisecondsSinceEpoch + _variants.length,
          size: '',
          sku: '',
          price: 0,
          stock: 0,
          reorderPoint: 8,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Fragrance editor',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Item name'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Fragrance type'),
              items: [
                for (final option in _typeOptions)
                  DropdownMenuItem(value: option, child: Text(option)),
              ],
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              initialValue:
                  widget.categories.any(
                    (category) => category.id == _categoryId,
                  )
                  ? _categoryId
                  : null,
              decoration: const InputDecoration(
                labelText: 'Store category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final category in widget.categories.where(
                  (category) => category.isVisible,
                ))
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _categoryId = value ?? _categoryId),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _brand,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sku,
                    decoration: const InputDecoration(labelText: 'SKU'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _vendor,
                    decoration: const InputDecoration(labelText: 'Vendor'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _itemLocation,
              decoration: const InputDecoration(
                labelText: 'Item location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 10),
            _MultiSelectChipGroup(
              title: 'Fragrance notes',
              options: _noteOptions,
              selected: _generalNotes,
              allowCustomEntry: true,
              onChanged: (values) => setState(() => _generalNotes = values),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _vibe,
              decoration: const InputDecoration(labelText: 'Vibe'),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _performance,
              decoration: const InputDecoration(labelText: 'Performance'),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _comparison,
              decoration: const InputDecoration(labelText: 'Comparison'),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fragranceProfile,
              decoration: const InputDecoration(labelText: 'Fragrance profile'),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _ingredients,
              decoration: const InputDecoration(
                labelText: 'Notes / ingredients',
              ),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            _MultiSelectChipGroup(
              title: 'Top notes',
              options: _noteOptions,
              selected: _topNotes,
              allowCustomEntry: true,
              onChanged: (values) => setState(() => _topNotes = values),
            ),
            const SizedBox(height: 10),
            _MultiSelectChipGroup(
              title: 'Heart notes',
              options: _noteOptions,
              selected: _heartNotes,
              allowCustomEntry: true,
              onChanged: (values) => setState(() => _heartNotes = values),
            ),
            const SizedBox(height: 10),
            _MultiSelectChipGroup(
              title: 'Base notes',
              options: _noteOptions,
              selected: _baseNotes,
              allowCustomEntry: true,
              onChanged: (values) => setState(() => _baseNotes = values),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _concentration,
                    decoration: const InputDecoration(
                      labelText: 'Concentration',
                    ),
                    items: [
                      for (final option in _concentrationOptions)
                        DropdownMenuItem(value: option, child: Text(option)),
                    ],
                    onChanged: (value) => setState(
                      () => _concentration = value ?? _concentration,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _gender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: [
                      for (final option in _genderOptions)
                        DropdownMenuItem(value: option, child: Text(option)),
                    ],
                    onChanged: (value) =>
                        setState(() => _gender = value ?? _gender),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _MultiSelectChipGroup(
              title: 'Families',
              options: _familyOptions,
              selected: _families,
              onChanged: (values) => setState(() => _families = values),
            ),
            const SizedBox(height: 10),
            _MultiSelectChipGroup(
              title: 'Seasons',
              options: _seasonOptions,
              selected: _seasons,
              onChanged: (values) => setState(() => _seasons = values),
            ),
            const SizedBox(height: 10),
            _MultiSelectChipGroup(
              title: 'Occasions',
              options: _occasionOptions,
              selected: _occasions,
              onChanged: (values) => setState(() => _occasions = values),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _cost,
              decoration: const InputDecoration(
                labelText: 'Admin cost',
                prefixIcon: Icon(Icons.price_check_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            _VariantTable(
              variants: _variants,
              onAdd: _addVariant,
              onChanged: () => setState(() {}),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _weightOz,
                    decoration: InputDecoration(
                      labelText: _weightLabel,
                      prefixIcon: const Icon(Icons.scale_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _lengthIn,
                    decoration: InputDecoration(labelText: _lengthLabel),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _widthIn,
                    decoration: InputDecoration(labelText: _widthLabel),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _heightIn,
                    decoration: InputDecoration(labelText: _heightLabel),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Product photos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _uploading ? null : _uploadImages,
              icon: _uploading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined),
              label: Text(_uploading ? 'Uploading photos' : 'Upload photos'),
            ),
            if (_uploading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
              const SizedBox(height: 6),
              const Text('Uploading selected product photos...'),
            ],
            const SizedBox(height: 8),
            if (_images.isEmpty)
              const Text('No product photos uploaded yet.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final image in _images)
                    SizedBox(
                      width: 92,
                      height: 126,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: image.isPrimary
                                ? const Color(0xFFC88F52)
                                : const Color(0xFFE2DCD2),
                            width: image.isPrimary ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            Expanded(
                              child: ProductImageView(
                                source: image.url,
                                fallbackColor: widget.product.featuredColor,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  tooltip: 'Make primary',
                                  onPressed: () => _setPrimary(image),
                                  iconSize: 18,
                                  icon: Icon(
                                    image.isPrimary
                                        ? Icons.star
                                        : Icons.star_border,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Remove photo',
                                  onPressed: () => _removeImage(image),
                                  iconSize: 18,
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close),
                    label: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiSelectChipGroup extends StatefulWidget {
  const _MultiSelectChipGroup({
    required this.title,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.allowCustomEntry = false,
  });

  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final bool allowCustomEntry;

  @override
  State<_MultiSelectChipGroup> createState() => _MultiSelectChipGroupState();
}

class _MultiSelectChipGroupState extends State<_MultiSelectChipGroup> {
  final _custom = TextEditingController();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _addCustom() {
    final value = _custom.text.trim();
    if (value.isEmpty) {
      return;
    }
    final next = {...widget.selected, value};
    widget.onChanged(next);
    _custom.clear();
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: widget.title,
        filled: true,
        fillColor: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final option in widget.options)
                FilterChip(
                  label: Text(option),
                  selected: widget.selected.contains(option),
                  onSelected: (value) {
                    final next = {...widget.selected};
                    if (value) {
                      next.add(option);
                    } else {
                      next.remove(option);
                    }
                    widget.onChanged(next);
                  },
                ),
            ],
          ),
          if (widget.allowCustomEntry) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _custom,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Add note for this fragrance',
                    ),
                    onSubmitted: (_) => _addCustom(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Add note',
                  onPressed: _addCustom,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _VariantTable extends StatelessWidget {
  const _VariantTable({
    required this.variants,
    required this.onAdd,
    required this.onChanged,
  });

  final List<ProductVariant> variants;
  final VoidCallback onAdd;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sizes, pricing, and inventory',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add size'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _HorizontalTableScroller(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Live')),
              DataColumn(label: Text('Size')),
              DataColumn(label: Text('SKU')),
              DataColumn(label: Text('Price')),
              DataColumn(label: Text('Stock')),
              DataColumn(label: Text('Reorder')),
              DataColumn(label: Text('')),
            ],
            rows: [
              for (final variant in variants)
                DataRow(
                  cells: [
                    DataCell(
                      Switch(
                        value: variant.isActive,
                        onChanged: (value) {
                          variant.isActive = value;
                          onChanged();
                        },
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 96,
                        child: TextFormField(
                          initialValue: variant.size,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Size',
                          ),
                          onChanged: (value) => variant.size = value,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 130,
                        child: TextFormField(
                          initialValue: variant.sku,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'SKU',
                          ),
                          onChanged: (value) => variant.sku = value,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          initialValue: variant.price.toStringAsFixed(2),
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Price',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) =>
                              variant.price = double.tryParse(value) ?? 0,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 76,
                        child: TextFormField(
                          initialValue: '${variant.stock}',
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Stock',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) =>
                              variant.stock = int.tryParse(value) ?? 0,
                        ),
                      ),
                    ),
                    DataCell(
                      SizedBox(
                        width: 86,
                        child: TextFormField(
                          initialValue: '${variant.reorderPoint}',
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Reorder',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) =>
                              variant.reorderPoint = int.tryParse(value) ?? 8,
                        ),
                      ),
                    ),
                    DataCell(
                      IconButton(
                        tooltip: 'Remove size',
                        onPressed: variants.length == 1
                            ? null
                            : () {
                                variants.remove(variant);
                                onChanged();
                              },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReturnSummaryPanel extends StatelessWidget {
  const _ReturnSummaryPanel({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final lines = [
      'Status: ${order.returnStatus}',
      if (order.rmaNumber.trim().isNotEmpty) 'RMA: ${order.rmaNumber}',
      if (order.refundStatus.trim().isNotEmpty)
        'Refund: ${order.refundStatus} ${order.refundTotal > 0 ? currency(order.refundTotal) : ''}',
      if (order.refundOption.trim().isNotEmpty)
        'Refund option: ${order.refundOption}',
      if (order.refundReason.trim().isNotEmpty) 'Reason: ${order.refundReason}',
      if (order.returnAdminComment.trim().isNotEmpty)
        'Admin comment: ${order.returnAdminComment}',
      if (order.returnCondition.trim().isNotEmpty)
        'Condition: ${order.returnCondition}',
      if (order.stripeRefundId.trim().isNotEmpty)
        'Stripe refund: ${order.stripeRefundId}',
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFC88F52)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Return / refund',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text(line),
            ),
        ],
      ),
    );
  }
}
