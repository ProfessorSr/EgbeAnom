part of '../main.dart';

class _CatalogSection extends StatelessWidget {
  const _CatalogSection({
    required this.products,
    required this.categories,
    required this.measurementSystem,
    required this.noteOptions,
    required this.pendingNoteOptions,
    required this.familyOptions,
    required this.seasonOptions,
    required this.occasionOptions,
    required this.editing,
    required this.onEdit,
    required this.onRemove,
    required this.onApproveFragranceNote,
    required this.onUploadImages,
    required this.onCancel,
    required this.onSave,
  });

  final List<Fragrance> products;
  final List<Category> categories;
  final MeasurementSystem measurementSystem;
  final List<String> noteOptions;
  final List<String> pendingNoteOptions;
  final List<String> familyOptions;
  final List<String> seasonOptions;
  final List<String> occasionOptions;
  final Fragrance? editing;
  final ValueChanged<Fragrance> onEdit;
  final ProductRemoveCallback onRemove;
  final AsyncValueChanged<String> onApproveFragranceNote;
  final Future<List<ProductImage>> Function(
    Fragrance product,
    List<UploadedImageFile> files,
  )
  onUploadImages;
  final VoidCallback onCancel;
  final AsyncValueChanged<Fragrance> onSave;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 980;
        final grid = _CatalogGrid(
          products: products,
          onEdit: onEdit,
          onRemove: onRemove,
        );
        final editor = editing == null
            ? const _EmptyState(
                icon: Icons.add_photo_alternate_outlined,
                title: 'Product media and merchandising',
                body:
                    'Select a fragrance or add a new one to manage photos, SKU, vendor, stock, and pricing.',
              )
            : ProductEditor(
                key: ValueKey(editing!.id),
                product: editing!,
                categories: categories,
                measurementSystem: measurementSystem,
                noteOptions: noteOptions,
                familyOptions: familyOptions,
                seasonOptions: seasonOptions,
                occasionOptions: occasionOptions,
                onUploadImages: onUploadImages,
                onCancel: onCancel,
                onSave: onSave,
              );
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pendingNoteOptions.isNotEmpty) ...[
                _PendingNotesPanel(
                  notes: pendingNoteOptions,
                  onApprove: onApproveFragranceNote,
                ),
                const SizedBox(height: 18),
              ],
              grid,
              const SizedBox(height: 18),
              editor,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (pendingNoteOptions.isNotEmpty) ...[
              _PendingNotesPanel(
                notes: pendingNoteOptions,
                onApprove: onApproveFragranceNote,
              ),
              const SizedBox(height: 18),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: grid),
                const SizedBox(width: 18),
                Expanded(flex: 5, child: editor),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _PendingNotesPanel extends StatelessWidget {
  const _PendingNotesPanel({required this.notes, required this.onApprove});

  final List<String> notes;
  final AsyncValueChanged<String> onApprove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom notes awaiting approval',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final note in notes)
                  ActionChip(
                    avatar: const Icon(Icons.check, size: 18),
                    label: Text(note),
                    onPressed: () => onApprove(note),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogGrid extends StatelessWidget {
  const _CatalogGrid({
    required this.products,
    required this.onEdit,
    required this.onRemove,
  });

  final List<Fragrance> products;
  final ValueChanged<Fragrance> onEdit;
  final ProductRemoveCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 760
            ? 3
            : constraints.maxWidth > 520
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 2.2 : 1.25,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      color: product.featuredColor.withValues(alpha: 0.18),
                      child: ProductPhoto(product: product, iconSize: 42),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(product.sku),
                        const SizedBox(height: 6),
                        Text('${product.vendor} • ${product.size}'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => onEdit(product),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.outlined(
                              tooltip: 'Remove',
                              onPressed: () async => onRemove(product),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _InventorySection extends StatelessWidget {
  const _InventorySection({
    required this.products,
    required this.activeCarts,
    required this.lowStockProducts,
    required this.measurementSystem,
    required this.onOpenReports,
    required this.onEdit,
    required this.onRemove,
  });

  final List<Fragrance> products;
  final List<ActiveCart> activeCarts;
  final List<Fragrance> lowStockProducts;
  final MeasurementSystem measurementSystem;
  final VoidCallback onOpenReports;
  final ValueChanged<Fragrance> onEdit;
  final ProductRemoveCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _InventoryTable(
          products: products,
          activeCarts: activeCarts,
          measurementSystem: measurementSystem,
          onEdit: onEdit,
          onRemove: onRemove,
        ),
        const SizedBox(height: 16),
        _LowStockPanel(products: lowStockProducts),
        const SizedBox(height: 16),
        _InventoryDownloadCard(onOpenReports: onOpenReports),
      ],
    );
  }
}

class _InventoryDownloadCard extends StatelessWidget {
  const _InventoryDownloadCard({required this.onOpenReports});

  final VoidCallback onOpenReports;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Database export',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose tables and download CSV, JSON, or SQL from Reports.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onOpenReports,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Download database'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HorizontalTableScroller extends StatefulWidget {
  const _HorizontalTableScroller({required this.child});

  final Widget child;

  @override
  State<_HorizontalTableScroller> createState() =>
      _HorizontalTableScrollerState();
}

class _HorizontalTableScrollerState extends State<_HorizontalTableScroller> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        child: widget.child,
      ),
    );
  }
}

class _CartsSection extends StatelessWidget {
  const _CartsSection({required this.activeCarts});

  final List<ActiveCart> activeCarts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Active carts and reserved inventory',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (activeCarts.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No active cart reservations.'),
            ),
          )
        else
          for (final cart in activeCarts)
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.shopping_cart_checkout),
                title: Text('${cart.id} • ${cart.customer}'),
                subtitle: Text(
                  '${cart.itemCount} unit(s) reserved • ${currency(cart.value)} • ${cart.minutesAgo} min ago',
                ),
                childrenPadding: const EdgeInsets.only(bottom: 8),
                children: [
                  for (final line in cart.lines)
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 16, right: 8),
                      leading: SizedBox.square(
                        dimension: 42,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: ProductPhoto(product: line.product),
                        ),
                      ),
                      title: Text(line.product.name),
                      subtitle: Text(
                        '${line.quantity} reserved from ${line.stockAvailable} on hand',
                      ),
                      trailing: Text(currency(line.total)),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}

class _CategoriesSection extends StatefulWidget {
  const _CategoriesSection({
    required this.categories,
    required this.onSave,
    required this.onRemove,
  });

  final List<Category> categories;
  final AsyncValueChanged<Category> onSave;
  final ValueChanged<Category> onRemove;

  @override
  State<_CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<_CategoriesSection> {
  Category? _editing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 900;
        return Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: wide ? 6 : 0,
              child: Card(
                child: _HorizontalTableScroller(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Order')),
                      DataColumn(label: Text('Category')),
                      DataColumn(label: Text('Description')),
                      DataColumn(label: Text('Visible')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: [
                      for (final category in widget.categories)
                        DataRow(
                          cells: [
                            DataCell(Text('${category.sortOrder}')),
                            DataCell(Text(category.name)),
                            DataCell(
                              SizedBox(
                                width: 280,
                                child: Text(category.description),
                              ),
                            ),
                            DataCell(Text(category.isVisible ? 'Yes' : 'No')),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    tooltip: 'Edit',
                                    onPressed: () =>
                                        setState(() => _editing = category),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  IconButton(
                                    tooltip: 'Hide',
                                    onPressed: () => widget.onRemove(category),
                                    icon: const Icon(
                                      Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (wide) const SizedBox(width: 16) else const SizedBox(height: 16),
            Expanded(
              flex: wide ? 4 : 0,
              child: CategoryEditor(
                category: _editing,
                nextId: DateTime.now().millisecondsSinceEpoch,
                onSave: (category) async {
                  await widget.onSave(category);
                  if (mounted) {
                    setState(() => _editing = null);
                  }
                },
                onNew: () => setState(() => _editing = null),
              ),
            ),
          ],
        );
      },
    );
  }
}

class CategoryEditor extends StatefulWidget {
  const CategoryEditor({
    super.key,
    required this.category,
    required this.nextId,
    required this.onSave,
    required this.onNew,
  });

  final Category? category;
  final int nextId;
  final AsyncValueChanged<Category> onSave;
  final VoidCallback onNew;

  @override
  State<CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<CategoryEditor> {
  late TextEditingController _name;
  late TextEditingController _description;
  late TextEditingController _sortOrder;
  bool _isVisible = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CategoryEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category?.id != widget.category?.id) {
      _name.dispose();
      _description.dispose();
      _sortOrder.dispose();
      _load();
    }
  }

  void _load() {
    _name = TextEditingController(text: widget.category?.name ?? '');
    _description = TextEditingController(
      text: widget.category?.description ?? '',
    );
    _sortOrder = TextEditingController(
      text: '${widget.category?.sortOrder ?? 10}',
    );
    _isVisible = widget.category?.isVisible ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _sortOrder.dispose();
    super.dispose();
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
              'Category manager',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Category name'),
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
              controller: _sortOrder,
              decoration: const InputDecoration(labelText: 'Sort order'),
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Visible on storefront'),
              value: _isVisible,
              onChanged: (value) => setState(() => _isVisible = value),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onNew,
                    icon: const Icon(Icons.add),
                    label: const Text('New'),
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
        Category(
          id: widget.category?.id ?? widget.nextId,
          name: _name.text.trim().isEmpty ? 'New category' : _name.text.trim(),
          description: _description.text.trim(),
          sortOrder: int.tryParse(_sortOrder.text) ?? 10,
          isVisible: _isVisible,
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category saved.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Category save failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _PromotionsSection extends StatefulWidget {
  const _PromotionsSection({required this.coupons, required this.onSave});

  final List<CouponRule> coupons;
  final AsyncValueChanged<CouponRule> onSave;

  @override
  State<_PromotionsSection> createState() => _PromotionsSectionState();
}

class _PromotionsSectionState extends State<_PromotionsSection> {
  CouponRule? _editing;
  bool _showArchive = false;

  @override
  Widget build(BuildContext context) {
    final visibleCoupons = widget.coupons
        .where((coupon) => coupon.isArchived == _showArchive)
        .toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 900;
        return Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: wide ? 7 : 0,
              child: Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            icon: Icon(Icons.sell_outlined),
                            label: Text('Active'),
                          ),
                          ButtonSegment(
                            value: true,
                            icon: Icon(Icons.archive_outlined),
                            label: Text('Archive'),
                          ),
                        ],
                        selected: {_showArchive},
                        onSelectionChanged: (value) {
                          setState(() {
                            _showArchive = value.first;
                            _editing = null;
                          });
                        },
                      ),
                    ),
                    if (visibleCoupons.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Text(
                          _showArchive
                              ? 'No archived coupon codes.'
                              : 'No active coupon codes.',
                        ),
                      )
                    else
                      _HorizontalTableScroller(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Code')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Type')),
                            DataColumn(label: Text('Value')),
                            DataColumn(label: Text('Min spend')),
                            DataColumn(label: Text('Usage')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Actions')),
                          ],
                          rows: [
                            for (final coupon in visibleCoupons)
                              DataRow(
                                cells: [
                                  DataCell(Text(coupon.code)),
                                  DataCell(Text(coupon.name)),
                                  DataCell(Text(coupon.type)),
                                  DataCell(
                                    Text(switch (coupon.type) {
                                      'Percent' =>
                                        '${coupon.value.toStringAsFixed(0)}%',
                                      'Buy X get Y' =>
                                        'Buy ${coupon.buyQuantity}, get ${coupon.getQuantity} @ ${currency(coupon.getPrice)}',
                                      'Gift card' =>
                                        '${currency(coupon.remainingBalance)} remaining',
                                      _ => currency(coupon.value),
                                    }),
                                  ),
                                  DataCell(Text(currency(coupon.minimumSpend))),
                                  DataCell(
                                    Text('${coupon.used}/${coupon.usageLimit}'),
                                  ),
                                  DataCell(
                                    Text(
                                      coupon.isArchived
                                          ? 'Archived'
                                          : coupon.isActive
                                          ? 'Active'
                                          : 'Inactive',
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Edit',
                                          onPressed: () =>
                                              setState(() => _editing = coupon),
                                          icon: const Icon(Icons.edit_outlined),
                                        ),
                                        IconButton(
                                          tooltip: coupon.isArchived
                                              ? 'Unarchive'
                                              : 'Archive',
                                          onPressed: () => _setArchived(
                                            coupon,
                                            !coupon.isArchived,
                                          ),
                                          icon: Icon(
                                            coupon.isArchived
                                                ? Icons.unarchive_outlined
                                                : Icons.archive_outlined,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (wide) const SizedBox(width: 16) else const SizedBox(height: 16),
            Expanded(
              flex: wide ? 4 : 0,
              child: CouponEditor(
                coupon: _editing,
                onSave: (coupon) async {
                  await widget.onSave(coupon);
                  if (mounted) {
                    setState(() => _editing = null);
                  }
                },
                onNew: () => setState(() => _editing = null),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setArchived(CouponRule coupon, bool archived) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.onSave(
        CouponRule(
          code: coupon.code,
          name: coupon.name,
          type: coupon.type,
          value: coupon.value,
          minimumSpend: coupon.minimumSpend,
          usageLimit: coupon.usageLimit,
          used: coupon.used,
          starts: coupon.starts,
          ends: coupon.ends,
          buyQuantity: coupon.buyQuantity,
          getQuantity: coupon.getQuantity,
          getPrice: coupon.getPrice,
          remainingBalance: coupon.remainingBalance,
          recipientEmail: coupon.recipientEmail,
          isActive: archived ? false : coupon.isActive,
          isArchived: archived,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() => _editing = null);
      messenger.showSnackBar(
        SnackBar(
          content: Text(archived ? 'Coupon archived.' : 'Coupon unarchived.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            archived
                ? 'Coupon archive failed: $error'
                : 'Coupon unarchive failed: $error',
          ),
        ),
      );
    }
  }
}

class CouponEditor extends StatefulWidget {
  const CouponEditor({
    super.key,
    required this.coupon,
    required this.onSave,
    required this.onNew,
  });

  final CouponRule? coupon;
  final AsyncValueChanged<CouponRule> onSave;
  final VoidCallback onNew;

  @override
  State<CouponEditor> createState() => _CouponEditorState();
}

class _CouponEditorState extends State<CouponEditor> {
  late TextEditingController _code;
  late TextEditingController _name;
  late TextEditingController _value;
  late TextEditingController _minimumSpend;
  late TextEditingController _usageLimit;
  late TextEditingController _buyQuantity;
  late TextEditingController _getQuantity;
  late TextEditingController _getPrice;
  late TextEditingController _remainingBalance;
  late TextEditingController _recipientEmail;
  late String _type;
  bool _active = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant CouponEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coupon?.code != widget.coupon?.code) {
      _disposeControllers();
      _load();
    }
  }

  void _load() {
    _code = TextEditingController(text: widget.coupon?.code ?? '');
    _name = TextEditingController(text: widget.coupon?.name ?? '');
    _value = TextEditingController(text: '${widget.coupon?.value ?? 10}');
    _minimumSpend = TextEditingController(
      text: '${widget.coupon?.minimumSpend ?? 0}',
    );
    _usageLimit = TextEditingController(
      text: '${widget.coupon?.usageLimit ?? 100}',
    );
    _buyQuantity = TextEditingController(
      text: '${widget.coupon?.buyQuantity ?? 1}',
    );
    _getQuantity = TextEditingController(
      text: '${widget.coupon?.getQuantity ?? 1}',
    );
    _getPrice = TextEditingController(text: '${widget.coupon?.getPrice ?? 0}');
    _remainingBalance = TextEditingController(
      text: '${widget.coupon?.remainingBalance ?? widget.coupon?.value ?? 0}',
    );
    _recipientEmail = TextEditingController(
      text: widget.coupon?.recipientEmail ?? '',
    );
    _type = widget.coupon?.type ?? 'Percent';
    _active = widget.coupon?.isActive ?? true;
  }

  void _disposeControllers() {
    _code.dispose();
    _name.dispose();
    _value.dispose();
    _minimumSpend.dispose();
    _usageLimit.dispose();
    _buyQuantity.dispose();
    _getQuantity.dispose();
    _getPrice.dispose();
    _remainingBalance.dispose();
    _recipientEmail.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
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
              'Discount rule',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _code,
              decoration: const InputDecoration(labelText: 'Coupon code'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Promotion name'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Discount type'),
              items: const [
                DropdownMenuItem(value: 'Percent', child: Text('Percent off')),
                DropdownMenuItem(
                  value: 'Fixed amount',
                  child: Text('Fixed amount off'),
                ),
                DropdownMenuItem(
                  value: 'Free shipping',
                  child: Text('Free shipping'),
                ),
                DropdownMenuItem(
                  value: 'Buy X get Y',
                  child: Text('Buy X get Y'),
                ),
                DropdownMenuItem(value: 'Gift card', child: Text('Gift card')),
              ],
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _value,
                    decoration: InputDecoration(
                      labelText: _type == 'Buy X get Y'
                          ? 'Legacy value'
                          : 'Value',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _minimumSpend,
                    decoration: const InputDecoration(
                      labelText: 'Minimum spend',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            if (_type == 'Buy X get Y') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _buyQuantity,
                      decoration: const InputDecoration(labelText: 'Buy qty'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _getQuantity,
                      decoration: const InputDecoration(labelText: 'Get qty'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _getPrice,
                      decoration: const InputDecoration(
                        labelText: 'Get item price',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
            if (_type == 'Gift card') ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _remainingBalance,
                      decoration: const InputDecoration(
                        labelText: 'Remaining balance',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _recipientEmail,
                      decoration: const InputDecoration(
                        labelText: 'Recipient email',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _usageLimit,
              decoration: const InputDecoration(labelText: 'Usage limit'),
              keyboardType: TextInputType.number,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active promotion'),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onNew,
                    icon: const Icon(Icons.add),
                    label: const Text('New'),
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

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(
        CouponRule(
          code: _code.text.trim().isEmpty
              ? 'NEWCODE'
              : _code.text.trim().toUpperCase(),
          name: _name.text.trim().isEmpty ? 'New promotion' : _name.text.trim(),
          type: _type,
          value: double.tryParse(_value.text) ?? 0,
          minimumSpend: double.tryParse(_minimumSpend.text) ?? 0,
          usageLimit: int.tryParse(_usageLimit.text) ?? 100,
          used: widget.coupon?.used ?? 0,
          starts: widget.coupon?.starts ?? '2026-06-01',
          ends: widget.coupon?.ends ?? '2026-12-31',
          buyQuantity: int.tryParse(_buyQuantity.text) ?? 0,
          getQuantity: int.tryParse(_getQuantity.text) ?? 0,
          getPrice: double.tryParse(_getPrice.text) ?? 0,
          remainingBalance: _type == 'Gift card'
              ? double.tryParse(_remainingBalance.text) ??
                    double.tryParse(_value.text) ??
                    0
              : 0,
          recipientEmail: _recipientEmail.text.trim().toLowerCase(),
          isActive: _active,
          isArchived: widget.coupon?.isArchived ?? false,
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Promotion saved.')));
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Promotion save failed: $error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _PaymentsSection extends StatefulWidget {
  const _PaymentsSection({
    required this.methods,
    required this.onToggle,
    required this.onSave,
  });

  final List<PaymentMethodConfig> methods;
  final AsyncValueChanged<PaymentMethodConfig> onToggle;
  final AsyncValueChanged<PaymentMethodConfig> onSave;

  @override
  State<_PaymentsSection> createState() => _PaymentsSectionState();
}

class _PaymentsSectionState extends State<_PaymentsSection> {
  PaymentMethodConfig? _editing;

  @override
  Widget build(BuildContext context) {
    final connected = widget.methods.where((method) {
      return method.publicKey.isNotEmpty || method.merchantId.isNotEmpty;
    }).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricGrid(
          metrics: [
            const _MetricData(Icons.credit_card, 'Cards', 'Stripe-ready'),
            _MetricData(
              Icons.account_balance_wallet_outlined,
              'Wallets',
              '${widget.methods.where((m) => m.isEnabled).length} enabled',
            ),
            _MetricData(Icons.link_outlined, 'Connected', '$connected methods'),
            const _MetricData(
              Icons.security_outlined,
              'Fraud tools',
              'Rules needed',
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 920;
            return Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 6 : 0,
                  child: Card(
                    child: Column(
                      children: [
                        for (final method in widget.methods)
                          ListTile(
                            leading: Switch(
                              value: method.isEnabled,
                              onChanged: (_) => widget.onToggle(method),
                            ),
                            title: Text('${method.name} • ${method.provider}'),
                            subtitle: Text(
                              '${method.status} • ${method.mode} • ${method.fee} • ${method.settlement}',
                            ),
                            trailing: IconButton(
                              tooltip: 'Configure',
                              onPressed: () =>
                                  setState(() => _editing = method),
                              icon: const Icon(Icons.settings_outlined),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 5 : 0,
                  child: _PaymentMethodEditor(
                    method:
                        _editing ??
                        (widget.methods.isEmpty ? null : widget.methods.first),
                    onSave: (method) async {
                      await widget.onSave(method);
                      setState(() => _editing = method);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _PaymentMethodEditor extends StatefulWidget {
  const _PaymentMethodEditor({required this.method, required this.onSave});

  final PaymentMethodConfig? method;
  final AsyncValueChanged<PaymentMethodConfig> onSave;

  @override
  State<_PaymentMethodEditor> createState() => _PaymentMethodEditorState();
}

class _PaymentMethodEditorState extends State<_PaymentMethodEditor> {
  late TextEditingController _publicKey;
  late TextEditingController _merchantId;
  late TextEditingController _apiSecret;
  late TextEditingController _checkoutUrl;
  late TextEditingController _webhookUrl;
  late TextEditingController _descriptor;
  late String _mode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _PaymentMethodEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.method != widget.method) {
      _disposeControllers();
      _load();
    }
  }

  void _load() {
    final method = widget.method;
    _publicKey = TextEditingController(text: method?.publicKey ?? '');
    _merchantId = TextEditingController(text: method?.merchantId ?? '');
    _apiSecret = TextEditingController(text: method?.apiSecret ?? '');
    _checkoutUrl = TextEditingController(text: method?.checkoutUrl ?? '');
    _webhookUrl = TextEditingController(text: method?.webhookUrl ?? '');
    _descriptor = TextEditingController(
      text: method?.statementDescriptor ?? 'EGBE ANOM',
    );
    _mode = method?.mode ?? 'Test';
  }

  void _disposeControllers() {
    _publicKey.dispose();
    _merchantId.dispose();
    _apiSecret.dispose();
    _checkoutUrl.dispose();
    _webhookUrl.dispose();
    _descriptor.dispose();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final method = widget.method;
    if (method == null) {
      return const _EmptyState(
        icon: Icons.payments_outlined,
        title: 'No payment methods',
        body:
            'Add payment providers in the admin database to configure merchant accounts.',
      );
    }
    final provider = method.provider.toLowerCase();
    final labels = _PaymentProviderLabels.forProvider(provider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Provider setup',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text('${method.name} • ${method.provider}'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _mode,
              decoration: const InputDecoration(labelText: 'Mode'),
              items: const [
                DropdownMenuItem(value: 'Test', child: Text('Test')),
                DropdownMenuItem(value: 'Live', child: Text('Live')),
              ],
              onChanged: (value) => setState(() => _mode = value ?? _mode),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _publicKey,
              decoration: InputDecoration(
                labelText: labels.publicKey,
                prefixIcon: const Icon(Icons.key_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _merchantId,
              decoration: InputDecoration(
                labelText: labels.merchantId,
                prefixIcon: const Icon(Icons.account_balance_outlined),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _apiSecret,
              decoration: InputDecoration(
                labelText: labels.apiSecret,
                prefixIcon: const Icon(Icons.lock_outlined),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _checkoutUrl,
              decoration: InputDecoration(
                labelText: labels.checkoutUrl,
                helperText: labels.returnUrls,
                prefixIcon: const Icon(Icons.open_in_new_outlined),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _webhookUrl,
              decoration: InputDecoration(
                labelText: labels.webhook,
                helperText: labels.webhookHelp,
                prefixIcon: const Icon(Icons.webhook_outlined),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptor,
              decoration: InputDecoration(
                labelText: labels.descriptor,
                prefixIcon: const Icon(Icons.receipt_long_outlined),
              ),
            ),
            const SizedBox(height: 10),
            Text(labels.instructions),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () => widget.onSave(
                PaymentMethodConfig(
                  name: method.name,
                  provider: method.provider,
                  status:
                      _publicKey.text.trim().isEmpty &&
                          _merchantId.text.trim().isEmpty
                      ? 'Not connected'
                      : 'Configured',
                  fee: method.fee,
                  settlement: method.settlement,
                  isEnabled: method.isEnabled,
                  mode: _mode,
                  publicKey: _publicKey.text.trim(),
                  merchantId: _merchantId.text.trim(),
                  apiSecret: _apiSecret.text.trim(),
                  checkoutUrl: _checkoutUrl.text.trim(),
                  webhookUrl: _webhookUrl.text.trim(),
                  statementDescriptor: _descriptor.text.trim(),
                ),
              ),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save provider settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentProviderLabels {
  const _PaymentProviderLabels({
    required this.publicKey,
    required this.merchantId,
    required this.apiSecret,
    required this.checkoutUrl,
    required this.webhook,
    required this.webhookHelp,
    required this.descriptor,
    required this.returnUrls,
    required this.instructions,
  });

  final String publicKey;
  final String merchantId;
  final String apiSecret;
  final String checkoutUrl;
  final String webhook;
  final String webhookHelp;
  final String descriptor;
  final String returnUrls;
  final String instructions;

  factory _PaymentProviderLabels.forProvider(String provider) {
    if (provider.contains('stripe')) {
      return const _PaymentProviderLabels(
        publicKey: 'Stripe publishable key',
        merchantId: 'Stripe account ID',
        apiSecret: 'Stripe secret key',
        checkoutUrl: 'Stripe Checkout URL (customer redirect)',
        webhook: 'Stripe webhook endpoint (server callback)',
        webhookHelp:
            'Endpoint URL only. Put the whsec_... signing secret in Supabase function secret STRIPE_WEBHOOK_SECRET.',
        descriptor: 'Stripe statement descriptor',
        returnUrls:
            'Success: /?payment=success or /payment-success • Cancel: /?payment=failed or /payment-failed',
        instructions:
            'Store Stripe secret keys server-side. Use Checkout success_url and cancel_url for the return pages.',
      );
    }
    if (provider.contains('paypal')) {
      return const _PaymentProviderLabels(
        publicKey: 'PayPal client ID',
        merchantId: 'PayPal merchant ID',
        apiSecret: 'PayPal client secret',
        checkoutUrl: 'PayPal approval URL (customer redirect)',
        webhook: 'PayPal webhook ID / endpoint',
        webhookHelp:
            'Use the callback endpoint URL/ID only. Keep verification secrets in server-side function secrets.',
        descriptor: 'PayPal invoice prefix',
        returnUrls:
            'Return URL: /?payment=success • Cancel URL: /?payment=failed',
        instructions:
            'Store the PayPal client secret server-side. Use PayPal return_url and cancel_url for checkout approval results.',
      );
    }
    if (provider.contains('square')) {
      return const _PaymentProviderLabels(
        publicKey: 'Square application ID',
        merchantId: 'Square location ID',
        apiSecret: 'Square access token',
        checkoutUrl: 'Square checkout URL (customer redirect)',
        webhook: 'Square webhook signature key / endpoint',
        webhookHelp:
            'Use the callback endpoint URL only. Keep signature keys in server-side function secrets.',
        descriptor: 'Square statement descriptor',
        returnUrls:
            'Square Web Payments SDK should return to /payment-success or /payment-failed after backend capture.',
        instructions:
            'Store the Square access token server-side. Browser checkout should only use the application ID and location ID.',
      );
    }
    if (provider.contains('apple') || provider.contains('google')) {
      return const _PaymentProviderLabels(
        publicKey: 'Wallet merchant identifier',
        merchantId: 'Processor merchant account',
        apiSecret: 'Processor certificate or token',
        checkoutUrl: 'Wallet checkout URL (customer redirect)',
        webhook: 'Wallet processor callback endpoint',
        webhookHelp:
            'Use callback endpoint only. Store signing/verification secrets in server-side function secrets.',
        descriptor: 'Wallet display name',
        returnUrls:
            'Wallet authorization should resolve to /payment-success or /payment-failed after backend capture.',
        instructions:
            'Apple Pay and Google Pay are device wallet buttons. Customers do not type card details here; wallet tokens must be validated and captured server-side through the configured card processor.',
      );
    }
    return const _PaymentProviderLabels(
      publicKey: 'Provider public key / client ID',
      merchantId: 'Provider merchant account ID',
      apiSecret: 'Provider secret key or API token',
      checkoutUrl: 'Provider checkout URL (customer redirect)',
      webhook: 'Provider webhook endpoint (server callback)',
      webhookHelp:
          'Endpoint URL only. Keep webhook/signing secrets in server-side function secrets.',
      descriptor: 'Statement descriptor',
      returnUrls:
          'Success: /payment-success or /?payment=success • Failure: /payment-failed or /?payment=failed',
      instructions:
          'Secret keys must be stored in a secure server-side payment backend.',
    );
  }
}
