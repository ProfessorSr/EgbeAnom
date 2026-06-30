part of '../main.dart';

class CartView extends StatelessWidget {
  const CartView({
    super.key,
    required this.lines,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.onQuantityChanged,
    required this.onCheckout,
  });

  final List<CartLine> lines;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final void Function(CartLine line, int delta) onQuantityChanged;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _StorefrontPage(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 860;
            return Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 6 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Shopping cart',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      if (lines.isEmpty)
                        const _EmptyState(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Your cart is empty',
                          body: 'Add perfumes or colognes to begin an order.',
                        )
                      else
                        ...lines.map(
                          (line) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: line.product.featuredColor
                                          .withValues(alpha: 0.24),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: ProductPhoto(product: line.product),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          line.product.name,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        Text(
                                          '${line.product.type} • ${line.size}',
                                        ),
                                        Text(currency(line.unitPrice)),
                                      ],
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    tooltip: 'Remove one',
                                    onPressed: () =>
                                        onQuantityChanged(line, -1),
                                    icon: const Icon(Icons.remove),
                                  ),
                                  SizedBox(
                                    width: 42,
                                    child: Text(
                                      '${line.quantity}',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  IconButton.filledTonal(
                                    tooltip: 'Add one',
                                    onPressed: () => onQuantityChanged(line, 1),
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (wide)
                  const SizedBox(width: 20)
                else
                  const SizedBox(height: 20),
                Expanded(
                  flex: wide ? 4 : 0,
                  child: CartSummaryPanel(
                    subtotal: subtotal,
                    tax: tax,
                    shipping: shipping,
                    total: total,
                    canCheckout: lines.isNotEmpty,
                    onCheckout: onCheckout,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class CartSummaryPanel extends StatelessWidget {
  const CartSummaryPanel({
    super.key,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.canCheckout,
    required this.onCheckout,
  });

  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final bool canCheckout;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Order summary',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            _PriceRow(label: 'Subtotal', value: subtotal),
            _PriceRow(label: 'Estimated tax', value: tax),
            _PriceRow(label: 'Shipping', value: shipping),
            const Divider(height: 28),
            _PriceRow(label: 'Total', value: total, emphasized: true),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: canCheckout ? onCheckout : null,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Continue to checkout'),
            ),
            const SizedBox(height: 10),
            const Text(
              'Taxes and shipping are estimated. Final totals are confirmed before payment.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class CheckoutView extends StatelessWidget {
  const CheckoutView({
    super.key,
    required this.lines,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.checkoutEmail,
    required this.checkoutPhone,
    required this.shippingAddress,
    required this.onCheckoutEmailChanged,
    required this.onCheckoutPhoneChanged,
    required this.onShippingAddressChanged,
    required this.shippingOptions,
    required this.selectedShippingOptionId,
    required this.onShippingOptionChanged,
    required this.onBackToCart,
    required this.onPlaceOrder,
    required this.paymentMethods,
  });

  final List<CartLine> lines;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final String checkoutEmail;
  final String checkoutPhone;
  final ShippingAddress shippingAddress;
  final ValueChanged<String> onCheckoutEmailChanged;
  final ValueChanged<String> onCheckoutPhoneChanged;
  final ValueChanged<ShippingAddress> onShippingAddressChanged;
  final List<ShippingOption> shippingOptions;
  final String selectedShippingOptionId;
  final ValueChanged<String> onShippingOptionChanged;
  final VoidCallback onBackToCart;
  final VoidCallback onPlaceOrder;
  final List<PaymentMethodConfig> paymentMethods;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _StorefrontPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: onBackToCart,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to cart'),
            ),
            const SizedBox(height: 10),
            Text(
              'Secure checkout',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Complete your order without leaving the Egbe Anom experience.',
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 920;
                return Flex(
                  direction: wide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: wide ? 7 : 0,
                      child: Column(
                        children: [
                          _CheckoutContactSection(
                            email: checkoutEmail,
                            phone: checkoutPhone,
                            onEmailChanged: onCheckoutEmailChanged,
                            onPhoneChanged: onCheckoutPhoneChanged,
                          ),
                          const SizedBox(height: 14),
                          _CheckoutAddressForms(
                            shippingAddress: shippingAddress,
                            onShippingAddressChanged: onShippingAddressChanged,
                          ),
                          const SizedBox(height: 14),
                          _CheckoutSection(
                            title: 'Delivery',
                            icon: Icons.inventory_2_outlined,
                            children: [
                              if (shippingOptions.isEmpty)
                                const Text(
                                  'No enabled shipping options are configured.',
                                )
                              else
                                for (final option in shippingOptions)
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    onTap: () =>
                                        onShippingOptionChanged(option.id),
                                    leading: Icon(
                                      option.id == selectedShippingOptionId
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                    ),
                                    title: Text(option.name),
                                    subtitle: Text(
                                      '${option.carrier} ${option.service} • ${option.priority} • ${option.estimatedDays}',
                                    ),
                                    trailing: Text(
                                      option.price == 0
                                          ? 'Free'
                                          : currency(option.price),
                                    ),
                                  ),
                              if (subtotal > 125)
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Text(
                                    'Your order qualifies for free shipping at checkout.',
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _CheckoutSection(
                            title: 'Payment',
                            icon: Icons.payments_outlined,
                            children: [
                              _CheckoutPaymentOptions(methods: paymentMethods),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (wide)
                      const SizedBox(width: 20)
                    else
                      const SizedBox(height: 20),
                    Expanded(
                      flex: wide ? 4 : 0,
                      child: CheckoutReviewPanel(
                        lines: lines,
                        subtotal: subtotal,
                        tax: tax,
                        shipping: shipping,
                        total: total,
                        onPlaceOrder: onPlaceOrder,
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
}

class _CheckoutAddressForms extends StatefulWidget {
  const _CheckoutAddressForms({
    required this.shippingAddress,
    required this.onShippingAddressChanged,
  });

  final ShippingAddress shippingAddress;
  final ValueChanged<ShippingAddress> onShippingAddressChanged;

  @override
  State<_CheckoutAddressForms> createState() => _CheckoutAddressFormsState();
}

class _CheckoutAddressFormsState extends State<_CheckoutAddressForms> {
  bool _gift = false;
  bool _billingSameAsShipping = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CheckoutSection(
          title: 'Shipping',
          icon: Icons.local_shipping_outlined,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _gift,
              onChanged: (value) => setState(() => _gift = value ?? false),
              title: const Text('Ship this order as a gift'),
              subtitle: const Text(
                'Send to a recipient at a different address.',
              ),
            ),
            _AddressFields(
              prefix: _gift ? 'Recipient' : 'Ship to',
              address: widget.shippingAddress,
              onChanged: widget.onShippingAddressChanged,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _CheckoutSection(
          title: 'Billing',
          icon: Icons.receipt_long_outlined,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _billingSameAsShipping,
              onChanged: (value) =>
                  setState(() => _billingSameAsShipping = value ?? true),
              title: const Text('Billing address is the same as shipping'),
            ),
            if (!_billingSameAsShipping)
              _AddressFields(
                prefix: 'Bill to',
                address: ShippingAddress(),
                onChanged: (_) {},
              ),
          ],
        ),
      ],
    );
  }
}

class _AddressFields extends StatelessWidget {
  const _AddressFields({
    required this.prefix,
    required this.address,
    required this.onChanged,
  });

  final String prefix;
  final ShippingAddress address;
  final ValueChanged<ShippingAddress> onChanged;

  @override
  Widget build(BuildContext context) {
    InputDecoration decoration(String label) {
      return InputDecoration(labelText: label);
    }

    void updateAddress({
      String? firstName,
      String? lastName,
      String? addressLine1,
      String? addressLine2,
      String? city,
      String? state,
      String? postalCode,
    }) {
      onChanged(
        ShippingAddress(
          firstName: firstName ?? address.firstName,
          lastName: lastName ?? address.lastName,
          addressLine1: addressLine1 ?? address.addressLine1,
          addressLine2: addressLine2 ?? address.addressLine2,
          city: city ?? address.city,
          state: state ?? address.state,
          postalCode: postalCode ?? address.postalCode,
          country: address.country,
          phone: address.phone,
          email: address.email,
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: decoration('$prefix first name'),
                controller: TextEditingController(text: address.firstName)
                  ..selection = TextSelection.collapsed(
                    offset: address.firstName.length,
                  ),
                onChanged: (value) => updateAddress(firstName: value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: decoration('$prefix last name'),
                controller: TextEditingController(text: address.lastName)
                  ..selection = TextSelection.collapsed(
                    offset: address.lastName.length,
                  ),
                onChanged: (value) => updateAddress(lastName: value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: decoration('$prefix address line 1'),
          controller: TextEditingController(text: address.addressLine1)
            ..selection = TextSelection.collapsed(
              offset: address.addressLine1.length,
            ),
          onChanged: (value) => updateAddress(addressLine1: value),
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Apartment, suite, etc.',
          ),
          controller: TextEditingController(text: address.addressLine2)
            ..selection = TextSelection.collapsed(
              offset: address.addressLine2.length,
            ),
          onChanged: (value) => updateAddress(addressLine2: value),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: decoration('City'),
                controller: TextEditingController(text: address.city)
                  ..selection = TextSelection.collapsed(
                    offset: address.city.length,
                  ),
                onChanged: (value) => updateAddress(city: value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: decoration('State'),
                controller: TextEditingController(text: address.state)
                  ..selection = TextSelection.collapsed(
                    offset: address.state.length,
                  ),
                onChanged: (value) => updateAddress(state: value),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: decoration('ZIP'),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: address.postalCode)
                  ..selection = TextSelection.collapsed(
                    offset: address.postalCode.length,
                  ),
                onChanged: (value) => updateAddress(postalCode: value),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CheckoutContactSection extends StatefulWidget {
  const _CheckoutContactSection({
    required this.email,
    required this.phone,
    required this.onEmailChanged,
    required this.onPhoneChanged,
  });

  final String email;
  final String phone;
  final ValueChanged<String> onEmailChanged;
  final ValueChanged<String> onPhoneChanged;

  @override
  State<_CheckoutContactSection> createState() =>
      _CheckoutContactSectionState();
}

class _CheckoutContactSectionState extends State<_CheckoutContactSection> {
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
  }

  @override
  void didUpdateWidget(covariant _CheckoutContactSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.email != _emailController.text) {
      _emailController.text = widget.email;
    }
    if (widget.phone != _phoneController.text) {
      _phoneController.text = widget.phone;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CheckoutSection(
      title: 'Contact',
      icon: Icons.email_outlined,
      children: [
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: widget.onEmailChanged,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone number',
            prefixIcon: Icon(Icons.phone_outlined),
          ),
          keyboardType: TextInputType.phone,
          onChanged: widget.onPhoneChanged,
        ),
      ],
    );
  }
}

class _CheckoutPaymentOptions extends StatefulWidget {
  const _CheckoutPaymentOptions({required this.methods});

  final List<PaymentMethodConfig> methods;

  @override
  State<_CheckoutPaymentOptions> createState() =>
      _CheckoutPaymentOptionsState();
}

class _CheckoutPaymentOptionsState extends State<_CheckoutPaymentOptions> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final methods = widget.methods;
    if (methods.isEmpty) {
      return const Text(
        'No payment providers are enabled yet. Orders can still be placed in test mode for fulfillment review.',
      );
    }

    final selected = _selected ?? methods.first.provider;
    final method = methods.firstWhere(
      (item) => item.provider == selected,
      orElse: () => methods.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: selected,
          decoration: const InputDecoration(
            labelText: 'Payment provider',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
          items: [
            for (final method in methods)
              DropdownMenuItem(
                value: method.provider,
                child: Text('${method.name} • ${method.mode}'),
              ),
          ],
          onChanged: (value) => setState(() => _selected = value),
        ),
        const SizedBox(height: 8),
        _ProviderPaymentFields(method: method),
      ],
    );
  }
}

class _ProviderPaymentFields extends StatelessWidget {
  const _ProviderPaymentFields({required this.method});

  final PaymentMethodConfig method;

  @override
  Widget build(BuildContext context) {
    final provider = method.provider.toLowerCase();
    if (provider.contains('paypal')) {
      return const TextField(
        decoration: InputDecoration(
          labelText: 'PayPal account email',
          prefixIcon: Icon(Icons.account_balance_wallet_outlined),
        ),
        keyboardType: TextInputType.emailAddress,
      );
    }
    if (provider.contains('apple') || provider.contains('google')) {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.phone_iphone_outlined),
        title: Text('${method.name} authorization'),
        subtitle: const Text(
          'Wallet token request is prepared for backend capture.',
        ),
      );
    }
    return const Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Card number',
            prefixIcon: Icon(Icons.credit_card),
          ),
          keyboardType: TextInputType.number,
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(labelText: 'MM / YY'),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: TextField(decoration: InputDecoration(labelText: 'CVC')),
            ),
          ],
        ),
      ],
    );
  }
}

class _CheckoutSection extends StatelessWidget {
  const _CheckoutSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFC88F52)),
                const SizedBox(width: 10),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class CheckoutReviewPanel extends StatelessWidget {
  const CheckoutReviewPanel({
    super.key,
    required this.lines,
    required this.subtotal,
    required this.tax,
    required this.shipping,
    required this.total,
    required this.onPlaceOrder,
  });

  final List<CartLine> lines;
  final double subtotal;
  final double tax;
  final double shipping;
  final double total;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Review order', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: 50,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: ProductPhoto(product: line.product),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${line.product.name} • ${line.size} x ${line.quantity}',
                      ),
                    ),
                    Text(currency(line.total)),
                  ],
                ),
              ),
            const Divider(height: 24),
            _PriceRow(label: 'Subtotal', value: subtotal),
            _PriceRow(label: 'Estimated tax', value: tax),
            _PriceRow(label: 'Shipping', value: shipping),
            const Divider(height: 28),
            _PriceRow(label: 'Total', value: total, emphasized: true),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: lines.isEmpty ? null : onPlaceOrder,
              icon: const Icon(Icons.lock_outline),
              label: const Text('Place order'),
            ),
            const SizedBox(height: 10),
            const Text(
              'By placing this order, payment will be processed securely and inventory will be reserved against this cart.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: style),
          const Spacer(),
          Text(currency(value), style: style),
        ],
      ),
    );
  }
}

class PaymentReturnView extends StatelessWidget {
  const PaymentReturnView({
    super.key,
    required this.isSuccess,
    required this.onContinueShopping,
    this.onViewAccount,
    this.onViewCart,
    this.completedOrder,
    this.onSubmitSurvey,
  });

  final bool isSuccess;
  final VoidCallback onContinueShopping;
  final VoidCallback? onViewAccount;
  final VoidCallback? onViewCart;
  final Order? completedOrder;
  final void Function({
    required Order order,
    required int rating,
    required String title,
    required String body,
    required bool anonymous,
    required bool wouldRecommend,
  })?
  onSubmitSurvey;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _StorefrontPage(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      isSuccess
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      size: 52,
                      color: isSuccess
                          ? const Color(0xFF27724E)
                          : const Color(0xFF9C3D2E),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      isSuccess ? 'Payment received' : 'Payment not completed',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isSuccess
                          ? 'Thank you. Your order is accepted, the admin team has been notified, and your email receipt is queued.'
                          : 'The payment provider returned without a completed payment. Your cart is still available so you can try again or choose another method.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: onContinueShopping,
                          icon: const Icon(Icons.storefront),
                          label: const Text('Continue shopping'),
                        ),
                        if (isSuccess && onViewAccount != null)
                          OutlinedButton.icon(
                            onPressed: onViewAccount,
                            icon: const Icon(Icons.person_outline),
                            label: const Text('View account'),
                          ),
                        if (!isSuccess && onViewCart != null)
                          OutlinedButton.icon(
                            onPressed: onViewCart,
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: const Text('Return to cart'),
                          ),
                      ],
                    ),
                    if (isSuccess &&
                        completedOrder != null &&
                        onSubmitSurvey != null) ...[
                      const SizedBox(height: 18),
                      _PostPurchaseSurvey(
                        order: completedOrder!,
                        onSubmit: onSubmitSurvey!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PostPurchaseSurvey extends StatefulWidget {
  const _PostPurchaseSurvey({required this.order, required this.onSubmit});

  final Order order;
  final void Function({
    required Order order,
    required int rating,
    required String title,
    required String body,
    required bool anonymous,
    required bool wouldRecommend,
  })
  onSubmit;

  @override
  State<_PostPurchaseSurvey> createState() => _PostPurchaseSurveyState();
}

class _PostPurchaseSurveyState extends State<_PostPurchaseSurvey> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  int _rating = 5;
  bool _anonymous = false;
  bool _recommend = true;
  bool _submitted = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) {
      return const _EmptyState(
        icon: Icons.rate_review_outlined,
        title: 'Thank you for the review',
        body: 'Your verified purchase review was sent for admin approval.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 24),
        Text(
          'How was your experience?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          'Verified purchase reviews help future customers. Company reviews appear on the home page after admin approval.',
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: _rating,
          decoration: const InputDecoration(labelText: 'Rating'),
          items: const [
            DropdownMenuItem(value: 5, child: Text('5 - Excellent')),
            DropdownMenuItem(value: 4, child: Text('4 - Good')),
            DropdownMenuItem(value: 3, child: Text('3 - Okay')),
            DropdownMenuItem(value: 2, child: Text('2 - Poor')),
            DropdownMenuItem(value: 1, child: Text('1 - Bad')),
          ],
          onChanged: (value) => setState(() => _rating = value ?? _rating),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Review title'),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _body,
          decoration: const InputDecoration(labelText: 'Review'),
          minLines: 3,
          maxLines: 5,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Post as anonymous'),
          value: _anonymous,
          onChanged: (value) => setState(() => _anonymous = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('I would recommend EgbeAnom'),
          value: _recommend,
          onChanged: (value) => setState(() => _recommend = value),
        ),
        FilledButton.icon(
          onPressed: () {
            widget.onSubmit(
              order: widget.order,
              rating: _rating,
              title: _title.text,
              body: _body.text,
              anonymous: _anonymous,
              wouldRecommend: _recommend,
            );
            setState(() => _submitted = true);
          },
          icon: const Icon(Icons.send_outlined),
          label: const Text('Submit review'),
        ),
      ],
    );
  }
}

String _storeAddress(StoreInfo storeInfo) {
  return [
    storeInfo.addressLine1,
    storeInfo.addressLine2,
    [
      storeInfo.city,
      storeInfo.state,
      storeInfo.postalCode,
    ].where((item) => item.trim().isNotEmpty).join(', '),
    storeInfo.country,
  ].where((item) => item.trim().isNotEmpty).join('<br>');
}

String _orderDate(Order order) {
  final value = order.createdAt ?? DateTime.now();
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '$month/$day/${value.year}';
}

String _invoiceHtml(
  Order order,
  StoreInfo storeInfo, {
  bool printLite = false,
}) {
  final storeName = htmlEscape.convert(storeInfo.displayName);
  final address = _storeAddress(storeInfo);
  final contact =
      [
            storeInfo.email,
            storeInfo.phone,
            if (storeInfo.fax.isNotEmpty) 'Fax: ${storeInfo.fax}',
          ]
          .where((item) => item.trim().isNotEmpty)
          .map(htmlEscape.convert)
          .join('<br>');
  final subtotal = order.lines.fold<double>(
    0,
    (total, line) => total + line.total,
  );
  final tax = math.max(0.0, order.total - order.shippingTotal - subtotal);
  final rows = order.lines.isEmpty
      ? '''
        <tr>
          <td class="item-photo"></td>
          <td><strong>Order item</strong><br><em>EgbeAnom Fragrance</em></td>
          <td>${order.itemCount}</td>
          <td>${currency(order.total - order.shippingTotal)}</td>
          <td>${currency(order.total - order.shippingTotal)}</td>
        </tr>
      '''
      : order.lines
            .map(
              (line) =>
                  '''
        <tr>
          <td class="item-photo">${line.product.primaryPhotoUrl.trim().isEmpty ? '' : '<img src="${htmlEscape.convert(line.product.primaryPhotoUrl)}" alt="${htmlEscape.convert(line.product.name)}">'}</td>
          <td>
            <strong>${htmlEscape.convert(line.product.name)}</strong><br>
            <em>${htmlEscape.convert(line.product.concentration)}</em><br>
            <span>${htmlEscape.convert(line.sku)} • ${htmlEscape.convert(line.size)}</span>
          </td>
          <td>${line.quantity}</td>
          <td>${currency(line.unitPrice)}</td>
          <td>${currency(line.total)}</td>
        </tr>
      ''',
            )
            .join();
  final due =
      order.createdAt?.add(const Duration(days: 14)) ??
      DateTime.now().add(const Duration(days: 14));
  final logo = storeInfo.logoUrl.trim().isEmpty
      ? '<div class="invoice-logo-mark">EgbeAnom<br><span>Fragrance</span></div>'
      : '<img class="invoice-logo-img" src="${htmlEscape.convert(storeInfo.logoUrl)}" alt="EgbeAnom Fragrance">';
  return '''
<section class="egbeanom-print-page invoice-doc">
  <style>
    .invoice-doc { font-family: Georgia, 'Times New Roman', serif; color: #121212; max-width: 940px; margin: 0 auto; background: #fff; border: 1px solid #b7892f; }
    .invoice-top { background: #050505; color: #f5d27a; padding: 34px 46px; display: grid; grid-template-columns: 240px 1fr 260px; gap: 34px; align-items: center; border-bottom: 14px solid #d3a13c; }
    .invoice-logo-img { width: 210px; height: 210px; object-fit: contain; border-radius: 999px; }
    .invoice-logo-mark { width: 210px; height: 210px; border: 3px solid #bd8a2d; border-radius: 999px; display: grid; place-items: center; text-align: center; font-size: 34px; line-height: 1; box-shadow: inset 0 0 0 4px #111; }
    .invoice-logo-mark span { font-size: 16px; letter-spacing: 8px; text-transform: uppercase; }
    .invoice-brand h1 { margin: 0; font-size: 54px; font-weight: 400; }
    .invoice-brand .spaced { letter-spacing: 12px; text-transform: uppercase; font-size: 25px; }
    .invoice-brand p { color: #fff; font-size: 20px; text-align: center; margin: 18px 0 0; line-height: 1.35; }
    .invoice-meta { border-left: 1px solid #936e2a; padding-left: 36px; }
    .invoice-meta h2 { margin: 0 0 22px; font-size: 54px; letter-spacing: 4px; font-weight: 500; }
    .invoice-meta-grid { display: grid; grid-template-columns: 110px 1fr; gap: 12px 20px; color: #fff; font-family: Arial, sans-serif; font-size: 18px; }
    .invoice-meta-grid strong { color: #d3a13c; text-transform: uppercase; }
    .invoice-addresses { padding: 48px 64px 34px; display: grid; grid-template-columns: 1fr 1px 1fr; gap: 46px; align-items: start; }
    .gold-title { color: #b8842b; text-transform: uppercase; letter-spacing: 1px; font: 700 22px Arial, sans-serif; margin-bottom: 14px; }
    .divider-vertical { width: 1px; min-height: 180px; background: #caa45c; }
    .invoice-addresses p { margin: 0; font-size: 18px; line-height: 1.45; }
    .contact-line { display: grid; grid-template-columns: 34px 1fr; gap: 12px; margin-bottom: 16px; font-size: 18px; line-height: 1.35; }
    .contact-line b { color: #b8842b; font-size: 24px; text-align: center; }
    .invoice-table-wrap { padding: 0 46px 18px; position: relative; }
    .invoice-table-wrap:before { content: 'EgbeAnom'; position: absolute; inset: 40px 0 auto; text-align: center; font-size: 96px; color: rgba(184,132,43,.08); pointer-events: none; }
    .invoice-items { width: 100%; border-collapse: collapse; position: relative; z-index: 1; font-family: Arial, sans-serif; }
    .invoice-items th { background: #050505; color: #d3a13c; padding: 14px; font-size: 15px; text-transform: uppercase; border-right: 1px solid #caa45c; }
    .invoice-items td { border: 1px solid #d8bd80; padding: 14px; vertical-align: middle; font-size: 16px; }
    .invoice-items em { font-family: Georgia, serif; }
    .invoice-items span { color: #555; font-size: 12px; }
    .item-photo { width: 78px; text-align: center; }
    .item-photo img { width: 54px; height: 68px; object-fit: cover; }
    .invoice-lower { display: grid; grid-template-columns: 1fr 360px; gap: 44px; padding: 14px 46px 30px; align-items: end; }
    .thank-you { font-size: 20px; }
    .thank-you .script { color: #c28d2e; font-size: 38px; font-style: italic; display: block; margin-bottom: 8px; }
    .invoice-summary { font-family: Arial, sans-serif; }
    .invoice-summary div { display: flex; justify-content: space-between; padding: 14px 28px; border: 1px solid #d8bd80; border-bottom: 0; font-size: 17px; }
    .invoice-summary .grand { background: #050505; color: #d3a13c; border: 1px solid #d8bd80; font-size: 30px; font-weight: 700; }
    .invoice-footer { background: #fbf8f0; border-top: 1px solid #d8bd80; padding: 28px 70px 34px; display: grid; grid-template-columns: 1fr 1fr 120px; gap: 34px; align-items: center; font-family: Arial, sans-serif; }
    .invoice-footer-title { color: #b8842b; text-transform: uppercase; font-weight: 700; margin-bottom: 8px; }
    .invoice-qr { width: 96px; height: 96px; border: 4px solid #111; display: grid; place-items: center; text-align: center; font-size: 11px; margin-left: auto; }
    ${printLite ? '.invoice-top { background: #fff; color: #111; border-bottom-width: 2px; } .invoice-brand p, .invoice-meta-grid { color: #111; } .invoice-logo-mark { box-shadow: none; }' : ''}
    @media print { .invoice-doc { max-width: none; } }
  </style>
  <div class="invoice-top">
    <div>$logo</div>
    <div class="invoice-brand">
      <h1>$storeName</h1>
      <div class="spaced">Fragrance</div>
      <p>Where Elegance Speaks.<br>Scents Last Forever.</p>
    </div>
    <div class="invoice-meta">
      <h2>INVOICE</h2>
      <div class="invoice-meta-grid">
        <strong>Invoice #</strong><span>${htmlEscape.convert(order.id)}</span>
        <strong>Date</strong><span>${_orderDate(order)}</span>
        <strong>Due Date</strong><span>${due.month}/${due.day}/${due.year}</span>
      </div>
    </div>
  </div>
  <div class="invoice-addresses">
    <div>
      <div class="gold-title">Bill To:</div>
      <p><strong>${htmlEscape.convert(order.customer)}</strong><br>${htmlEscape.convert(order.email)}<br>${htmlEscape.convert(order.shippingCarrier)} ${htmlEscape.convert(order.shippingService)}</p>
    </div>
    <div class="divider-vertical"></div>
    <div>
      <div class="contact-line"><b>•</b><span><strong>$storeName</strong><br>$address</span></div>
      <div class="contact-line"><b>☎</b><span>${htmlEscape.convert(storeInfo.phone.isEmpty ? 'Phone not set' : storeInfo.phone)}</span></div>
      <div class="contact-line"><b>✉</b><span>${htmlEscape.convert(storeInfo.email.isEmpty ? 'Email not set' : storeInfo.email)}</span></div>
      <div class="contact-line"><b>◎</b><span>www.egbeanom.com</span></div>
    </div>
  </div>
  <div class="invoice-table-wrap">
    <table class="invoice-items">
      <thead>
        <tr><th></th><th>Item Description</th><th>Qty</th><th>Unit Price</th><th>Total</th></tr>
      </thead>
      <tbody>$rows</tbody>
    </table>
  </div>
  <div class="invoice-lower">
    <div class="thank-you"><span class="script">Thank you</span>for choosing EgbeAnom Fragrance.</div>
    <div class="invoice-summary">
      <div><strong>SUBTOTAL</strong><span>${currency(subtotal)}</span></div>
      <div><strong>SHIPPING</strong><span>${currency(order.shippingTotal)}</span></div>
      <div><strong>TAX</strong><span>${currency(tax)}</span></div>
      <div class="grand"><span>TOTAL</span><span>${currency(order.total)}</span></div>
    </div>
  </div>
  <div class="invoice-footer">
    <div><div class="invoice-footer-title">Customer Support</div>$contact</div>
    <div><div class="invoice-footer-title">Follow Us</div>@egbeanom.fragrance</div>
    <div class="invoice-qr">egbeanom.com<br>QR</div>
  </div>
</section>
''';
}

String _packListHtml(Order order, StoreInfo storeInfo) {
  final rows = order.lines.isEmpty
      ? '<tr><td>Order record item count</td><td>${order.itemCount}</td><td></td><td></td></tr>'
      : order.lines
            .map(
              (line) =>
                  '''
        <tr>
          <td>${htmlEscape.convert(line.product.name)}<br><span>${htmlEscape.convert(line.sku)} • ${htmlEscape.convert(line.size)}</span></td>
          <td>${line.quantity}</td>
          <td>${htmlEscape.convert(line.product.itemLocation.isEmpty ? 'No location' : line.product.itemLocation)}</td>
          <td>${htmlEscape.convert(line.product.shippingSize(MeasurementSystem.standard))}</td>
        </tr>
      ''',
            )
            .join();
  return '''
<section class="egbeanom-print-page invoice-doc">
  <style>
    .invoice-doc { font-family: Arial, sans-serif; color: #111; max-width: 820px; margin: 0 auto; }
    .pick-head { display: flex; justify-content: space-between; border-bottom: 3px solid #111; padding-bottom: 14px; margin-bottom: 18px; }
    .pick-head h1 { margin: 0; text-transform: uppercase; letter-spacing: 2px; }
    .pick-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; margin-bottom: 18px; }
    .pick-box { border: 1px solid #bbb; padding: 12px; min-height: 82px; }
    table { width: 100%; border-collapse: collapse; margin-top: 18px; }
    th { background: #111; color: #fff; text-align: left; padding: 9px; }
    td { border-bottom: 1px solid #ddd; padding: 10px 9px; vertical-align: top; }
    td span { color: #555; font-size: 12px; }
    .signatures { display: grid; grid-template-columns: 1fr 1fr; gap: 24px; margin-top: 34px; }
    .sig { border-top: 1px solid #111; padding-top: 8px; }
  </style>
  <div class="pick-head">
    <div>
      <h1>Pack List</h1>
      <strong>${htmlEscape.convert(storeInfo.displayName)}</strong>
    </div>
    <div>
      <strong>${htmlEscape.convert(order.id)}</strong><br>
      ${_orderDate(order)}<br>
      ${htmlEscape.convert(order.shippingPriority)}
    </div>
  </div>
  <div class="pick-grid">
    <div class="pick-box"><strong>Customer</strong><br>${htmlEscape.convert(order.customer)}<br>${htmlEscape.convert(order.email)}</div>
    <div class="pick-box"><strong>Shipping</strong><br>${htmlEscape.convert(order.shippingCarrier)} ${htmlEscape.convert(order.shippingService)}<br>${htmlEscape.convert(order.trackingNumber.isEmpty ? 'Tracking pending' : order.trackingNumber)}</div>
  </div>
  <table>
    <thead><tr><th>Item</th><th>Qty</th><th>Pick location</th><th>Package size</th></tr></thead>
    <tbody>$rows</tbody>
  </table>
  <div class="signatures">
    <div class="sig">Picked by / Time</div>
    <div class="sig">Packed by / Time</div>
  </div>
</section>
''';
}

class _InvoiceDocumentPreview extends StatelessWidget {
  const _InvoiceDocumentPreview({required this.order, required this.storeInfo});

  final Order order;
  final StoreInfo storeInfo;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(18),
      child: DefaultTextStyle(
        style: const TextStyle(color: Color(0xFF161616), fontSize: 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: const Color(0xFF050505),
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'INVOICE',
                      style: TextStyle(
                        color: Color(0xFFF7D47C),
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                  Text(
                    storeInfo.displayName,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            Container(
              color: const Color(0xFFF7F2E8),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(child: Text('${order.customer}\n${order.email}')),
                  Text('${order.id}\n${_orderDate(order)}'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final line in order.lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${line.product.name} • ${line.size}'),
                    ),
                    Text('${line.quantity} x ${currency(line.unitPrice)}'),
                    const SizedBox(width: 12),
                    Text(currency(line.total)),
                  ],
                ),
              ),
            const Divider(color: Color(0xFFCCCCCC)),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Shipping ${currency(order.shippingTotal)}\nTotal ${currency(order.total)}',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountView extends StatefulWidget {
  const AccountView({
    super.key,
    required this.customer,
    required this.orders,
    required this.storeInfo,
    required this.wishlistProducts,
    this.initialCreating = false,
    required this.onCreateAccount,
    required this.onLogin,
    required this.onOAuthLogin,
    required this.onLogout,
  });

  final CustomerAccount? customer;
  final List<Order> orders;
  final StoreInfo storeInfo;
  final List<Fragrance> wishlistProducts;
  final bool initialCreating;
  final Future<void> Function(String name, String email, String password)
  onCreateAccount;
  final Future<void> Function(String email, String password) onLogin;
  final Future<void> Function(String provider) onOAuthLogin;
  final VoidCallback onLogout;

  @override
  State<AccountView> createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late bool _creating;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _creating = widget.initialCreating;
  }

  @override
  void didUpdateWidget(covariant AccountView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCreating != oldWidget.initialCreating) {
      _creating = widget.initialCreating;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _StorefrontPage(
        child: customer == null ? _authPanel(context) : _accountPanel(customer),
      ),
    );
  }

  Widget _authPanel(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 840;
        return Flex(
          direction: wide ? Axis.horizontal : Axis.vertical,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _creating ? 'Create account' : 'Customer login',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (_creating) ...[
                        TextField(
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      TextField(
                        controller: _email,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _password,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: _submitting
                            ? null
                            : () async {
                                final email = _email.text.trim();
                                final password = _password.text;
                                if (!email.contains('@') ||
                                    !email.contains('.')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Enter a valid email address.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (password.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Password must be at least 6 characters.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                setState(() => _submitting = true);
                                try {
                                  if (_creating) {
                                    await widget.onCreateAccount(
                                      _name.text,
                                      _email.text,
                                      _password.text,
                                    );
                                  } else {
                                    await widget.onLogin(
                                      _email.text,
                                      _password.text,
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _submitting = false);
                                  }
                                }
                              },
                        icon: _submitting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                _creating ? Icons.person_add_alt : Icons.login,
                              ),
                        label: Text(
                          _submitting
                              ? (_creating ? 'Creating account' : 'Logging in')
                              : (_creating ? 'Create account' : 'Log in'),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => _creating = !_creating),
                        child: Text(
                          _creating
                              ? 'Already have an account? Log in'
                              : 'Need an account? Create one',
                        ),
                      ),
                      const Divider(height: 26),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _submitting
                                ? null
                                : () => widget.onOAuthLogin('google'),
                            icon: const Icon(Icons.g_mobiledata),
                            label: const Text('Continue with Google'),
                          ),
                          OutlinedButton.icon(
                            onPressed: _submitting
                                ? null
                                : () => widget.onOAuthLogin('apple'),
                            icon: const Icon(Icons.apple),
                            label: const Text('Continue with Apple'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (wide) const SizedBox(width: 16) else const SizedBox(height: 16),
            const Flexible(
              fit: FlexFit.loose,
              child: _EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Order history lives here',
                body:
                    'Customers can review previous orders, fulfillment status, tracking, and referral credits after login.',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _accountPanel(CustomerAccount customer) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Welcome, ${customer.name}',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
            ),
            OutlinedButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Log out'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _MetricGrid(
          tall: true,
          metrics: [
            _MetricData(
              Icons.receipt_long_outlined,
              'Orders',
              '${customer.orders}',
            ),
            _MetricData(
              Icons.diamond_outlined,
              'Lifetime',
              currency(customer.lifetimeValue),
            ),
            _MetricData(
              Icons.group_add_outlined,
              'Referral',
              customer.referralCode,
            ),
            _MetricData(
              Icons.card_giftcard,
              'Credits',
              currency(customer.referralCredits),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _CustomerOrdersPanel(
          orders: widget.orders,
          storeInfo: widget.storeInfo,
        ),
        const SizedBox(height: 16),
        _CustomerWishlistPanel(products: widget.wishlistProducts),
      ],
    );
  }
}

class _CustomerWishlistPanel extends StatelessWidget {
  const _CustomerWishlistPanel({required this.products});

  final List<Fragrance> products;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wishlist', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            if (products.isEmpty)
              const Text('Saved wishlist items will appear here.')
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final product in products)
                    SizedBox(
                      width: 220,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: SizedBox.square(
                          dimension: 48,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: ProductPhoto(product: product),
                          ),
                        ),
                        title: Text(product.name),
                        subtitle: Text(currency(product.price)),
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

class _CustomerOrdersPanel extends StatelessWidget {
  const _CustomerOrdersPanel({required this.orders, required this.storeInfo});

  final List<Order> orders;
  final StoreInfo storeInfo;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const _EmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No orders yet',
        body: 'Placed orders will appear here with fulfillment and tracking.',
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Previous orders',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            for (final order in orders)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                leading: const Icon(Icons.receipt_outlined),
                title: Text('${order.id} • ${currency(order.total)}'),
                subtitle: Text(
                  '${order.fulfillmentStatus} • ${order.shippingCarrier} ${order.shippingService}',
                ),
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 16, right: 8),
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Invoice'),
                    subtitle: const Text(
                      'Open printable invoice for this order.',
                    ),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openInvoice(context, order),
                  ),
                  ListTile(
                    contentPadding: const EdgeInsets.only(left: 16, right: 8),
                    title: const Text('Tracking'),
                    subtitle: Text(
                      order.trackingNumber.isEmpty
                          ? 'Tracking will appear after the label is created.'
                          : '${order.shippingCarrier} ${order.trackingNumber}',
                    ),
                  ),
                  if (order.lines.isNotEmpty)
                    for (final line in order.lines)
                      ListTile(
                        contentPadding: const EdgeInsets.only(
                          left: 16,
                          right: 8,
                        ),
                        title: Text(line.product.name),
                        subtitle: Text('${line.quantity} item(s)'),
                        trailing: Text(currency(line.total)),
                      ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _openInvoice(BuildContext context, Order order) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InvoiceDocumentPreview(order: order, storeInfo: storeInfo),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => printHtmlDocument(
                    'Invoice ${order.id}',
                    _invoiceHtml(order, storeInfo),
                  ),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print invoice'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
