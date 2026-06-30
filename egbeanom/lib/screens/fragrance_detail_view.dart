part of '../main.dart';

class FragranceDetailView extends StatefulWidget {
  const FragranceDetailView({
    super.key,
    required this.product,
    required this.onBack,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.onBrandSelected,
    required this.paymentMethods,
    required this.shippingOptions,
    required this.returnPolicy,
    required this.measurementSystem,
    required this.reviews,
    required this.canSubmitReview,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onSubmitReview,
  });

  final Fragrance? product;
  final VoidCallback onBack;
  final void Function(Fragrance product, ProductVariant variant) onAddToCart;
  final void Function(Fragrance product, ProductVariant variant) onBuyNow;
  final ValueChanged<String> onBrandSelected;
  final List<PaymentMethodConfig> paymentMethods;
  final List<ShippingOption> shippingOptions;
  final String returnPolicy;
  final MeasurementSystem measurementSystem;
  final List<ReviewSummary> reviews;
  final bool canSubmitReview;
  final bool isFavorite;
  final ValueChanged<Fragrance> onToggleFavorite;
  final void Function(Fragrance product, int rating, String title, String body)
  onSubmitReview;

  @override
  State<FragranceDetailView> createState() => _FragranceDetailViewState();
}

class _FragranceDetailViewState extends State<FragranceDetailView> {
  ProductVariant? _selectedVariant;
  ProductImage? _selectedImage;

  @override
  void didUpdateWidget(covariant FragranceDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product?.id != widget.product?.id) {
      _selectedVariant = null;
      _selectedImage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.product;
    if (item == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _StorefrontPage(
          child: _EmptyState(
            icon: Icons.spa_outlined,
            title: 'Select a fragrance',
            body: 'Return to the catalog to view product details.',
          ),
        ),
      );
    }

    final variants = _activeVariants(item);
    final selected =
        _selectedVariant != null &&
            variants.any((variant) => variant.id == _selectedVariant!.id)
        ? _selectedVariant!
        : variants.first;
    final inStock = selected.stock > 0;
    final displayImage = _displayImage(item);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _StorefrontPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to catalog'),
              style: TextButton.styleFrom(foregroundColor: Colors.white),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 860;
                return Flex(
                  direction: wide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: wide ? 5 : 0,
                      child: Column(
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              child: Container(
                                color: item.featuredColor.withValues(
                                  alpha: 0.18,
                                ),
                                child: ProductPhoto(
                                  product: item,
                                  sourceOverride: displayImage?.url,
                                  iconSize: 80,
                                ),
                              ),
                            ),
                          ),
                          if (item.images.length > 1) ...[
                            const SizedBox(height: 10),
                            _ProductGalleryStrip(
                              product: item,
                              selected: displayImage,
                              onSelected: (image) =>
                                  setState(() => _selectedImage = image),
                            ),
                          ],
                          const SizedBox(height: 14),
                          _FragranceSectionsCard(product: item),
                          const SizedBox(height: 14),
                          _FragranceComments(
                            product: item,
                            reviews: widget.reviews,
                          ),
                        ],
                      ),
                    ),
                    if (wide)
                      const SizedBox(width: 28)
                    else
                      const SizedBox(height: 18),
                    Expanded(
                      flex: wide ? 6 : 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            item.brand,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 18),
                          _VariantSelector(
                            variants: variants,
                            selected: selected,
                            onSelected: (variant) =>
                                setState(() => _selectedVariant = variant),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _DetailChip(
                                label: 'Concentration',
                                value: item.concentration,
                              ),
                              _DetailChip(label: 'Family', value: item.family),
                              _DetailChip(
                                label: 'Ships as',
                                value: item.shippingSize(
                                  widget.measurementSystem,
                                ),
                              ),
                              _DetailChip(
                                label: 'Availability',
                                value: inStock
                                    ? '${selected.stock} available'
                                    : 'Sold out',
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Text(
                                currency(selected.price),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                              const SizedBox(width: 14),
                              const Icon(Icons.star, color: Color(0xFFC88F52)),
                              const SizedBox(width: 4),
                              Text(
                                '${item.rating.toStringAsFixed(1)} (${item.reviewCount})',
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(width: 14),
                              const Icon(
                                Icons.verified_outlined,
                                color: Color(0xFF27724E),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Authentic bottle',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.icon(
                                onPressed: inStock
                                    ? () => widget.onAddToCart(item, selected)
                                    : null,
                                icon: const Icon(Icons.add_shopping_cart),
                                label: const Text('Add to cart'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: inStock
                                    ? () => widget.onBuyNow(item, selected)
                                    : null,
                                icon: const Icon(Icons.flash_on_outlined),
                                label: const Text('Buy now'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => widget.onToggleFavorite(item),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white70),
                                ),
                                icon: Icon(
                                  widget.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                                label: Text(
                                  widget.isFavorite
                                      ? 'Saved'
                                      : 'Add to wishlist',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _CommerceInfoPanel(
                            shipping: _shippingStatement(
                              widget.shippingOptions,
                            ),
                            returns: widget.returnPolicy,
                            paymentOptions: widget.paymentMethods.isEmpty
                                ? 'Payment methods can be enabled by an admin.'
                                : widget.paymentMethods
                                      .map((method) => method.name)
                                      .join(', '),
                          ),
                          if (widget.canSubmitReview) ...[
                            const SizedBox(height: 12),
                            _FragranceReviewForm(
                              product: item,
                              onSubmitReview: widget.onSubmitReview,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<ProductVariant> _activeVariants(Fragrance product) {
    final variants = product.variants
        .where((variant) => variant.isActive && variant.size.trim().isNotEmpty)
        .toList();
    variants.sort((a, b) => a.price.compareTo(b.price));
    if (variants.isNotEmpty) {
      return variants;
    }
    return [
      ProductVariant(
        id: product.id,
        size: product.size,
        sku: product.sku,
        price: product.price,
        stock: product.stock,
        reorderPoint: product.reorderPoint,
      ),
    ];
  }

  ProductImage? _displayImage(Fragrance product) {
    final selected = _selectedImage;
    if (selected != null &&
        product.images.any((image) => image.url == selected.url)) {
      return selected;
    }
    for (final image in product.images) {
      if (image.isPrimary) {
        return image;
      }
    }
    return product.images.isEmpty ? null : product.images.first;
  }

  String _shippingStatement(List<ShippingOption> options) {
    final enabled = options.where((option) => option.isEnabled).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (enabled.isEmpty) {
      return 'Shipping choices are confirmed at checkout.';
    }
    final summaries = enabled
        .take(3)
        .map((option) {
          final price = option.price <= 0 ? 'free' : currency(option.price);
          return '${option.name} via ${option.carrier} ${option.service} (${option.estimatedDays}, $price)';
        })
        .join('; ');
    final extra = enabled.length > 3
        ? ' Additional options may appear at checkout.'
        : '';
    return '$summaries.$extra';
  }
}

class _ProductGalleryStrip extends StatelessWidget {
  const _ProductGalleryStrip({
    required this.product,
    required this.selected,
    required this.onSelected,
  });

  final Fragrance product;
  final ProductImage? selected;
  final ValueChanged<ProductImage> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: product.images.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final image = product.images[index];
          final isSelected = selected?.url == image.url;
          return SizedBox.square(
            dimension: 82,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onSelected(image),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFC88F52)
                          : const Color(0xFFE2DCD2),
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: ProductImageView(
                      source: image.url,
                      fallbackColor: product.featuredColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FragranceSectionsCard extends StatelessWidget {
  const _FragranceSectionsCard({required this.product});

  final Fragrance product;

  @override
  Widget build(BuildContext context) {
    final sections = [
      ('Description', product.description),
      ('Vibe', product.vibe),
      ('Performance', product.performance),
      ('Comparison', product.comparison),
      ('Fragrance Profile', product.fragranceProfile),
    ].where((section) => section.$2.trim().isNotEmpty).toList();
    final noteSections = [
      ('Top notes', product.topNotes),
      ('Heart Notes', product.heartNotes),
      ('Base Notes', product.baseNotes),
    ].where((section) => section.$2.trim().isNotEmpty).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < sections.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              Text(
                sections[i].$1,
                style: i == 0
                    ? Theme.of(context).textTheme.titleLarge
                    : Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(sections[i].$2),
            ],
            if (product.ingredients.trim().isNotEmpty) ...[
              if (sections.isNotEmpty) const SizedBox(height: 16),
              Text(
                'Notes and ingredients',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(product.ingredients),
            ],
            for (final section in noteSections) ...[
              if (sections.isNotEmpty ||
                  product.ingredients.trim().isNotEmpty ||
                  section != noteSections.first)
                const SizedBox(height: 16),
              Text(section.$1, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _NoteChips(notes: section.$2),
            ],
          ],
        ),
      ),
    );
  }
}

class _NoteChips extends StatelessWidget {
  const _NoteChips({required this.notes});

  final String notes;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final note
            in notes
                .split(',')
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty))
          Chip(
            label: Text(note),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
      ],
    );
  }
}

class _CommerceInfoPanel extends StatelessWidget {
  const _CommerceInfoPanel({
    required this.shipping,
    required this.returns,
    required this.paymentOptions,
  });

  final String shipping;
  final String returns;
  final String paymentOptions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(color: Colors.white38),
        const SizedBox(height: 12),
        _DetailInfoRow(
          icon: Icons.local_shipping_outlined,
          title: 'Shipping',
          body: shipping,
        ),
        _DetailInfoRow(
          icon: Icons.replay_outlined,
          title: 'Returns',
          body: returns,
        ),
        const _DetailInfoRow(
          icon: Icons.lock_outline,
          title: 'Checkout',
          body:
              'Order total, delivery choice, and payment method are confirmed before payment is submitted.',
        ),
        _DetailInfoRow(
          icon: Icons.payments_outlined,
          title: 'Payment options',
          body: paymentOptions,
        ),
      ],
    );
  }
}

class _VariantSelector extends StatelessWidget {
  const _VariantSelector({
    required this.variants,
    required this.selected,
    required this.onSelected,
  });

  final List<ProductVariant> variants;
  final ProductVariant selected;
  final ValueChanged<ProductVariant> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final variant in variants)
          ChoiceChip(
            selected: variant.id == selected.id,
            onSelected: variant.stock > 0 ? (_) => onSelected(variant) : null,
            label: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variant.size,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(currency(variant.price)),
                Text(
                  variant.stock > 0 ? '${variant.stock} left' : 'Sold out',
                  style: TextStyle(
                    color: variant.stock > 0
                        ? const Color(0xFF27724E)
                        : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
      ],
    );
  }
}

class _FragranceComments extends StatelessWidget {
  const _FragranceComments({required this.product, required this.reviews});

  final Fragrance product;
  final List<ReviewSummary> reviews;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fragrance comments',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text('${product.rating.toStringAsFixed(1)} average'),
              ],
            ),
            const SizedBox(height: 10),
            if (reviews.isEmpty)
              const Text('No approved comments yet.')
            else
              for (final review in reviews)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    review.status == 'approved'
                        ? Icons.star_outline
                        : Icons.schedule_outlined,
                  ),
                  title: Text(
                    '${review.title} • ${review.rating.toStringAsFixed(1)}',
                  ),
                  subtitle: Text(
                    review.status == 'approved'
                        ? '${review.author}: ${review.body}'
                        : '${review.author}: ${review.body}\nPending admin approval',
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _FragranceReviewForm extends StatefulWidget {
  const _FragranceReviewForm({
    required this.product,
    required this.onSubmitReview,
  });

  final Fragrance product;
  final void Function(Fragrance product, int rating, String title, String body)
  onSubmitReview;

  @override
  State<_FragranceReviewForm> createState() => _FragranceReviewFormState();
}

class _FragranceReviewFormState extends State<_FragranceReviewForm> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Leave a comment',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Your rating', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              children: [
                for (var value = 1; value <= 5; value++)
                  IconButton(
                    tooltip: '$value star${value == 1 ? '' : 's'}',
                    onPressed: () => setState(() => _rating = value),
                    icon: Icon(
                      value <= _rating ? Icons.star : Icons.star_border,
                      color: const Color(0xFFC88F52),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Review title',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _body,
              decoration: const InputDecoration(
                labelText: 'Write a fragrance comment',
                prefixIcon: Icon(Icons.rate_review_outlined),
              ),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () {
                  widget.onSubmitReview(
                    widget.product,
                    _rating,
                    _title.text.trim(),
                    _body.text.trim(),
                  );
                  _title.clear();
                  _body.clear();
                  setState(() => _rating = 5);
                },
                icon: const Icon(Icons.send_outlined),
                label: const Text('Submit for approval'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2DCD2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}

class _DetailInfoRow extends StatelessWidget {
  const _DetailInfoRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFC88F52)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
