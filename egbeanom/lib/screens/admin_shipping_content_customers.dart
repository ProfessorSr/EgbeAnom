part of '../main.dart';

class _ShippingSection extends StatefulWidget {
  const _ShippingSection({
    required this.options,
    required this.credentials,
    required this.onSave,
    required this.onDelete,
    required this.onSaveCredentials,
  });

  final List<ShippingOption> options;
  final Map<String, ShippingCarrierCredentials> credentials;
  final AsyncValueChanged<ShippingOption> onSave;
  final AsyncValueChanged<ShippingOption> onDelete;
  final Future<void> Function(
    String carrier,
    ShippingCarrierCredentials credentials,
  )
  onSaveCredentials;

  @override
  State<_ShippingSection> createState() => _ShippingSectionState();
}

class _ShippingSectionState extends State<_ShippingSection> {
  String _selectedCarrier = 'USPS';
  String? _editingCarrier;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.options.where((option) => option.isEnabled).length;
    final enabledCarriers = _carriers
        .where((carrier) => _carrierOptions(carrier).any((o) => o.isEnabled))
        .length;
    final flatPerOrder = _flatRatePerOrderOption;
    final flatPerItem = _flatRatePerItemOption;
    final selectedMethods = _carrierMethods(_selectedCarrier);
    final selectedOptions = _carrierOptions(_selectedCarrier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricGrid(
          metrics: [
            _MetricData(
              Icons.local_shipping_outlined,
              'Checkout options',
              '$enabled live',
            ),
            _MetricData(
              Icons.hub_outlined,
              'Providers on',
              '$enabledCarriers / ${_carriers.length}',
            ),
            _MetricData(
              Icons.route_outlined,
              'Carrier methods',
              '${widget.options.where((option) => !_isFlatRate(option)).length}',
            ),
            const _MetricData(Icons.print_outlined, 'Labels', 'Order screen'),
          ],
        ),
        const SizedBox(height: 16),
        _FlatRateShippingCard(
          option: flatPerOrder,
          title: 'Flat rate per order',
          subtitle: 'Charge one flat shipping price for the full order.',
          onSave: widget.onSave,
          onDisable: () => widget.onSave(
            ShippingOption(
              id: flatPerOrder.id,
              name: flatPerOrder.name,
              carrier: flatPerOrder.carrier,
              service: flatPerOrder.service,
              priority: flatPerOrder.priority,
              price: flatPerOrder.price,
              chargeType: flatPerOrder.chargeType,
              estimatedDays: flatPerOrder.estimatedDays,
              isEnabled: false,
              sortOrder: flatPerOrder.sortOrder,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _FlatRateShippingCard(
          option: flatPerItem,
          title: 'Flat rate per item',
          subtitle: 'Charge the flat shipping price once for each item.',
          onSave: widget.onSave,
          onDisable: () => widget.onSave(
            ShippingOption(
              id: flatPerItem.id,
              name: flatPerItem.name,
              carrier: flatPerItem.carrier,
              service: flatPerItem.service,
              priority: flatPerItem.priority,
              price: flatPerItem.price,
              chargeType: flatPerItem.chargeType,
              estimatedDays: flatPerItem.estimatedDays,
              isEnabled: false,
              sortOrder: flatPerItem.sortOrder,
            ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth > 1000
                ? 4
                : constraints.maxWidth > 720
                ? 2
                : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: columns == 1 ? 4.2 : 2.7,
              children: [
                for (final carrier in _carriers)
                  _ShippingProviderCard(
                    carrier: carrier,
                    enabled: _carrierOptions(
                      carrier,
                    ).any((option) => option.isEnabled),
                    selected: carrier == _selectedCarrier,
                    configured:
                        (widget.credentials[carrier] ??
                                const ShippingCarrierCredentials())
                            .isConfigured,
                    methodCount: _carrierMethods(carrier).length,
                    selectedMethodCount: _carrierOptions(
                      carrier,
                    ).where((option) => option.isEnabled).length,
                    onSelected: () =>
                        setState(() => _selectedCarrier = carrier),
                    onEnabledChanged: (value) => _toggleCarrier(carrier, value),
                    onEdit: () => setState(() => _editingCarrier = carrier),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            return Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 5 : 0,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Shipping providers',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Turn carriers on or off here. Select a provider to choose which carrier-provided services appear at checkout.',
                          ),
                          const SizedBox(height: 12),
                          for (final carrier in _carriers)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              onTap: () =>
                                  setState(() => _selectedCarrier = carrier),
                              leading: Icon(
                                carrier == _selectedCarrier
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                              ),
                              title: Text(carrier),
                              subtitle: Text(
                                '${_carrierOptions(carrier).where((o) => o.isEnabled).length} checkout method(s) selected',
                              ),
                              trailing: Switch(
                                value: _carrierOptions(
                                  carrier,
                                ).any((option) => option.isEnabled),
                                onChanged: (value) =>
                                    _toggleCarrier(carrier, value),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 7 : 0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_editingCarrier != null) ...[
                        _ShippingProviderCredentialsCard(
                          carrier: _editingCarrier!,
                          credentials:
                              widget.credentials[_editingCarrier!] ??
                              const ShippingCarrierCredentials(),
                          onSave: (credentials) {
                            final carrier = _editingCarrier!;
                            setState(() {
                              _editingCarrier = null;
                            });
                            widget.onSaveCredentials(carrier, credentials);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$carrier credentials saved for backend shipping services.',
                                ),
                              ),
                            );
                          },
                          onCancel: () =>
                              setState(() => _editingCarrier = null),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_selectedCarrier carrier methods',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Prices and delivery windows come from the carrier rate adapter once credentials are connected. Select the methods customers can choose at checkout.',
                              ),
                              const SizedBox(height: 12),
                              for (final method in selectedMethods)
                                _ShippingMethodTile(
                                  method: method,
                                  option: selectedOptions.firstWhere(
                                    (option) =>
                                        _sameCarrier(
                                          option.carrier,
                                          method.carrier,
                                        ) &&
                                        option.service == method.service,
                                    orElse: () =>
                                        method.toOption(sortOrder: 50),
                                  ),
                                  onChanged: (value) => _saveMethodSelection(
                                    method,
                                    selectedOptions.firstWhere(
                                      (option) =>
                                          _sameCarrier(
                                            option.carrier,
                                            method.carrier,
                                          ) &&
                                          option.service == method.service,
                                      orElse: () =>
                                          method.toOption(sortOrder: 50),
                                    ),
                                    value,
                                  ),
                                  onDelete: () {
                                    final existing = selectedOptions
                                        .where(
                                          (option) =>
                                              option.service == method.service,
                                        )
                                        .toList();
                                    for (final option in existing) {
                                      widget.onDelete(option);
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  static const List<String> _carriers = ['FedEx', 'UPS', 'USPS', 'DHL'];

  ShippingOption get _flatRatePerOrderOption {
    return widget.options.firstWhere(
      (option) =>
          option.id == 'ship-flat-rate-order' || option.id == 'ship-flat-rate',
      orElse: () => ShippingOption(
        id: 'ship-flat-rate-order',
        name: 'Flat rate per order',
        carrier: 'Flat Rate',
        service: 'Per order',
        priority: 'Standard',
        price: 7.95,
        chargeType: 'per_order',
        estimatedDays: '3-5 business days',
        isEnabled: false,
        sortOrder: 5,
      ),
    );
  }

  ShippingOption get _flatRatePerItemOption {
    return widget.options.firstWhere(
      (option) => option.id == 'ship-flat-rate-item',
      orElse: () => ShippingOption(
        id: 'ship-flat-rate-item',
        name: 'Flat rate per item',
        carrier: 'Flat Rate',
        service: 'Per item',
        priority: 'Standard',
        price: 2.95,
        chargeType: 'per_item',
        estimatedDays: '3-5 business days',
        isEnabled: false,
        sortOrder: 6,
      ),
    );
  }

  bool _isFlatRate(ShippingOption option) =>
      option.carrier.trim().toLowerCase() == 'flat rate' ||
      option.id == 'ship-flat-rate' ||
      option.id == 'ship-flat-rate-order' ||
      option.id == 'ship-flat-rate-item';

  List<ShippingOption> _carrierOptions(String carrier) => widget.options
      .where((option) => _sameCarrier(option.carrier, carrier))
      .toList();

  void _toggleCarrier(String carrier, bool enabled) {
    final options = _carrierOptions(carrier);
    setState(() => _selectedCarrier = carrier);
    if (options.isEmpty && enabled) {
      final first = _carrierMethods(carrier).first;
      _saveMethodSelection(first, first.toOption(sortOrder: 40), true);
      return;
    }
    for (final option in options) {
      option.isEnabled = enabled;
      widget.onSave(option);
    }
  }

  void _saveMethodSelection(
    _CarrierShippingMethod method,
    ShippingOption option,
    bool enabled,
  ) {
    widget.onSave(
      ShippingOption(
        id: option.id.isEmpty ? method.id : option.id,
        name: option.name.isEmpty ? method.customerLabel : option.name,
        carrier: method.carrier,
        service: method.service,
        priority: method.priority,
        price: method.price,
        chargeType: option.chargeType,
        estimatedDays: method.estimatedDays,
        isEnabled: enabled,
        sortOrder: option.sortOrder,
      ),
    );
    setState(() {});
  }

  List<_CarrierShippingMethod> _carrierMethods(String carrier) {
    return switch (carrier.toUpperCase()) {
      'FEDEX' => const [
        _CarrierShippingMethod(
          carrier: 'FedEx',
          service: 'Ground',
          priority: 'Standard',
          estimatedDays: '3-5 business days',
          price: 9.95,
        ),
        _CarrierShippingMethod(
          carrier: 'FedEx',
          service: 'Home Delivery',
          priority: 'Standard',
          estimatedDays: '2-5 business days',
          price: 10.95,
        ),
        _CarrierShippingMethod(
          carrier: 'FedEx',
          service: '2 Day',
          priority: 'Priority',
          estimatedDays: '2 business days',
          price: 18.95,
        ),
        _CarrierShippingMethod(
          carrier: 'FedEx',
          service: 'Priority Overnight',
          priority: 'Express',
          estimatedDays: 'Next business day',
          price: 34.95,
        ),
      ],
      'UPS' => const [
        _CarrierShippingMethod(
          carrier: 'UPS',
          service: 'Ground',
          priority: 'Standard',
          estimatedDays: '3-5 business days',
          price: 9.95,
        ),
        _CarrierShippingMethod(
          carrier: 'UPS',
          service: '3 Day Select',
          priority: 'Priority',
          estimatedDays: '3 business days',
          price: 16.95,
        ),
        _CarrierShippingMethod(
          carrier: 'UPS',
          service: '2nd Day Air',
          priority: 'Priority',
          estimatedDays: '2 business days',
          price: 22.95,
        ),
        _CarrierShippingMethod(
          carrier: 'UPS',
          service: 'Next Day Air',
          priority: 'Express',
          estimatedDays: 'Next business day',
          price: 38.95,
        ),
      ],
      'DHL' => const [
        _CarrierShippingMethod(
          carrier: 'DHL',
          service: 'Express Worldwide',
          priority: 'Express',
          estimatedDays: '1-3 business days',
          price: 39.95,
        ),
        _CarrierShippingMethod(
          carrier: 'DHL',
          service: 'Express Easy',
          priority: 'Priority',
          estimatedDays: '2-5 business days',
          price: 29.95,
        ),
        _CarrierShippingMethod(
          carrier: 'DHL',
          service: 'Packet Plus',
          priority: 'Standard',
          estimatedDays: '4-8 business days',
          price: 14.95,
        ),
      ],
      _ => const [
        _CarrierShippingMethod(
          carrier: 'USPS',
          service: 'Ground Advantage',
          priority: 'Standard',
          estimatedDays: '3-5 business days',
          price: 7.95,
        ),
        _CarrierShippingMethod(
          carrier: 'USPS',
          service: 'Priority Mail',
          priority: 'Priority',
          estimatedDays: '1-3 business days',
          price: 11.95,
        ),
        _CarrierShippingMethod(
          carrier: 'USPS',
          service: 'Priority Mail Express',
          priority: 'Express',
          estimatedDays: '1-2 business days',
          price: 29.95,
        ),
      ],
    };
  }

  bool _sameCarrier(String left, String right) =>
      left.trim().toUpperCase() == right.trim().toUpperCase();
}

class _CarrierShippingMethod {
  const _CarrierShippingMethod({
    required this.carrier,
    required this.service,
    required this.priority,
    required this.estimatedDays,
    required this.price,
  });

  final String carrier;
  final String service;
  final String priority;
  final String estimatedDays;
  final double price;

  String get id =>
      'ship-${carrier.toLowerCase().replaceAll(' ', '-')}-${service.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}';
  String get customerLabel => '$carrier $service';

  ShippingOption toOption({required int sortOrder}) {
    return ShippingOption(
      id: id,
      name: customerLabel,
      carrier: carrier,
      service: service,
      priority: priority,
      price: price,
      estimatedDays: estimatedDays,
      isEnabled: false,
      sortOrder: sortOrder,
    );
  }
}

class _FlatRateShippingCard extends StatefulWidget {
  const _FlatRateShippingCard({
    required this.option,
    required this.title,
    required this.subtitle,
    required this.onSave,
    required this.onDisable,
  });

  final ShippingOption option;
  final String title;
  final String subtitle;
  final AsyncValueChanged<ShippingOption> onSave;
  final VoidCallback onDisable;

  @override
  State<_FlatRateShippingCard> createState() => _FlatRateShippingCardState();
}

class _FlatRateShippingCardState extends State<_FlatRateShippingCard> {
  late final TextEditingController _price;
  late final TextEditingController _days;

  @override
  void initState() {
    super.initState();
    _price = TextEditingController(text: widget.option.price.toString());
    _days = TextEditingController(text: widget.option.estimatedDays);
  }

  @override
  void didUpdateWidget(covariant _FlatRateShippingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.option.price != widget.option.price) {
      _price.text = widget.option.price.toString();
    }
    if (oldWidget.option.estimatedDays != widget.option.estimatedDays) {
      _days.text = widget.option.estimatedDays;
    }
  }

  @override
  void dispose() {
    _price.dispose();
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 720;
            final priceField = TextField(
              controller: _price,
              decoration: const InputDecoration(
                labelText: 'Flat shipping price',
                prefixIcon: Icon(Icons.attach_money),
              ),
              keyboardType: TextInputType.number,
            );
            final daysField = TextField(
              controller: _days,
              decoration: const InputDecoration(
                labelText: 'Delivery estimate',
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
            );
            final fields = wide
                ? Row(
                    children: [
                      Expanded(child: priceField),
                      const SizedBox(width: 10),
                      Expanded(child: daysField),
                    ],
                  )
                : Column(
                    children: [
                      priceField,
                      const SizedBox(height: 10),
                      daysField,
                    ],
                  );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(widget.subtitle),
                  value: widget.option.isEnabled,
                  onChanged: (value) {
                    if (value) {
                      _save(isEnabled: true);
                    } else {
                      widget.onDisable();
                    }
                  },
                ),
                const SizedBox(height: 10),
                fields,
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => _save(isEnabled: true),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save flat rate'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _save({required bool isEnabled}) {
    widget.onSave(
      ShippingOption(
        id: widget.option.id,
        name: widget.option.chargeType == 'per_item'
            ? 'Flat rate per item'
            : 'Flat rate per order',
        carrier: 'Flat Rate',
        service: widget.option.chargeType == 'per_item'
            ? 'Per item'
            : 'Per order',
        priority: 'Standard',
        price: double.tryParse(_price.text) ?? 0,
        chargeType: widget.option.chargeType,
        estimatedDays: _days.text.trim().isEmpty
            ? '3-5 business days'
            : _days.text.trim(),
        isEnabled: isEnabled,
        sortOrder: widget.option.sortOrder,
      ),
    );
  }
}

class _ShippingProviderCard extends StatelessWidget {
  const _ShippingProviderCard({
    required this.carrier,
    required this.enabled,
    required this.selected,
    required this.configured,
    required this.methodCount,
    required this.selectedMethodCount,
    required this.onSelected,
    required this.onEnabledChanged,
    required this.onEdit,
  });

  final String carrier;
  final bool enabled;
  final bool selected;
  final bool configured;
  final int methodCount;
  final int selectedMethodCount;
  final VoidCallback onSelected;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? const Color(0xFFFFF7EA) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onSelected,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color: enabled ? const Color(0xFF27724E) : Colors.grey,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      carrier,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '$selectedMethodCount of $methodCount methods selected',
                    ),
                    Text(
                      configured ? 'Credentials added' : 'Credentials needed',
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit provider credentials',
                onPressed: onEdit,
                icon: const Icon(Icons.key_outlined),
              ),
              Switch(value: enabled, onChanged: onEnabledChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShippingMethodTile extends StatelessWidget {
  const _ShippingMethodTile({
    required this.method,
    required this.option,
    required this.onChanged,
    required this.onDelete,
  });

  final _CarrierShippingMethod method;
  final ShippingOption option;
  final ValueChanged<bool> onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Switch(value: option.isEnabled, onChanged: onChanged),
      title: Text(method.customerLabel),
      subtitle: Text('${method.priority} • ${method.estimatedDays}'),
      trailing: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(currency(method.price)),
          IconButton(
            tooltip: 'Remove saved checkout method',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
    );
  }
}

class _ShippingProviderCredentialsCard extends StatefulWidget {
  const _ShippingProviderCredentialsCard({
    required this.carrier,
    required this.credentials,
    required this.onSave,
    required this.onCancel,
  });

  final String carrier;
  final ShippingCarrierCredentials credentials;
  final ValueChanged<ShippingCarrierCredentials> onSave;
  final VoidCallback onCancel;

  @override
  State<_ShippingProviderCredentialsCard> createState() =>
      _ShippingProviderCredentialsCardState();
}

class _ShippingProviderCredentialsCardState
    extends State<_ShippingProviderCredentialsCard> {
  late final TextEditingController _customerId;
  late final TextEditingController _accountNumber;
  late final TextEditingController _apiKey;
  late final TextEditingController _apiSecret;
  late final TextEditingController _meterNumber;
  late final TextEditingController _clientId;
  late final TextEditingController _clientSecret;

  @override
  void initState() {
    super.initState();
    final credentials = widget.credentials;
    _customerId = TextEditingController(text: credentials.customerId);
    _accountNumber = TextEditingController(text: credentials.accountNumber);
    _apiKey = TextEditingController(text: credentials.apiKey);
    _apiSecret = TextEditingController(text: credentials.apiSecret);
    _meterNumber = TextEditingController(text: credentials.meterNumber);
    _clientId = TextEditingController(text: credentials.clientId);
    _clientSecret = TextEditingController(text: credentials.clientSecret);
  }

  @override
  void didUpdateWidget(covariant _ShippingProviderCredentialsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.carrier == widget.carrier &&
        oldWidget.credentials == widget.credentials) {
      return;
    }
    final credentials = widget.credentials;
    _customerId.text = credentials.customerId;
    _accountNumber.text = credentials.accountNumber;
    _apiKey.text = credentials.apiKey;
    _apiSecret.text = credentials.apiSecret;
    _meterNumber.text = credentials.meterNumber;
    _clientId.text = credentials.clientId;
    _clientSecret.text = credentials.clientSecret;
  }

  @override
  void dispose() {
    _customerId.dispose();
    _accountNumber.dispose();
    _apiKey.dispose();
    _apiSecret.dispose();
    _meterNumber.dispose();
    _clientId.dispose();
    _clientSecret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carrier = widget.carrier.trim().toUpperCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.carrier} provider credentials',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'These values belong in the secure shipping backend. The admin form captures the exact carrier fields needed for live rates and labels.',
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 680;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (carrier == 'USPS') ...[
                      _credentialField(
                        controller: _customerId,
                        label: 'Customer registration ID (CRID)',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _accountNumber,
                        label: 'EPS account number',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _meterNumber,
                        label: 'Mailer ID (MID)',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiKey,
                        label: 'Manifest MID',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _clientId,
                        label: 'USPS consumer key',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _clientSecret,
                        label: 'USPS consumer secret',
                        wide: wide,
                        obscure: true,
                      ),
                    ] else if (carrier == 'UPS') ...[
                      _credentialField(
                        controller: _accountNumber,
                        label: 'UPS shipper account number',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiKey,
                        label: 'UPS API key',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiSecret,
                        label: 'UPS API secret',
                        wide: wide,
                        obscure: true,
                      ),
                      _credentialField(
                        controller: _clientId,
                        label: 'UPS OAuth client ID',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _clientSecret,
                        label: 'UPS OAuth client secret',
                        wide: wide,
                        obscure: true,
                      ),
                    ] else if (carrier == 'FEDEX') ...[
                      _credentialField(
                        controller: _accountNumber,
                        label: 'FedEx account number',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _meterNumber,
                        label: 'FedEx meter number',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiKey,
                        label: 'FedEx API key',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiSecret,
                        label: 'FedEx API secret',
                        wide: wide,
                        obscure: true,
                      ),
                      _credentialField(
                        controller: _clientId,
                        label: 'FedEx OAuth client ID',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _clientSecret,
                        label: 'FedEx OAuth client secret',
                        wide: wide,
                        obscure: true,
                      ),
                    ] else if (carrier == 'DHL') ...[
                      _credentialField(
                        controller: _accountNumber,
                        label: 'DHL account number',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _customerId,
                        label: 'DHL site ID',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiKey,
                        label: 'DHL API key',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiSecret,
                        label: 'DHL API password',
                        wide: wide,
                        obscure: true,
                      ),
                      _credentialField(
                        controller: _clientId,
                        label: 'DHL API client ID',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _clientSecret,
                        label: 'DHL API client secret',
                        wide: wide,
                        obscure: true,
                      ),
                    ] else ...[
                      _credentialField(
                        controller: _customerId,
                        label: '${widget.carrier} site ID',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _accountNumber,
                        label: '${widget.carrier} account number',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiKey,
                        label: '${widget.carrier} API key',
                        wide: wide,
                      ),
                      _credentialField(
                        controller: _apiSecret,
                        label: '${widget.carrier} API password/secret',
                        wide: wide,
                        obscure: true,
                      ),
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => widget.onSave(
                    ShippingCarrierCredentials(
                      customerId: _customerId.text.trim(),
                      accountNumber: _accountNumber.text.trim(),
                      apiKey: _apiKey.text.trim(),
                      apiSecret: _apiSecret.text.trim(),
                      meterNumber: _meterNumber.text.trim(),
                      clientId: _clientId.text.trim(),
                      clientSecret: _clientSecret.text.trim(),
                    ),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save provider'),
                ),
                OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _credentialField({
    required TextEditingController controller,
    required String label,
    required bool wide,
    bool obscure = false,
  }) {
    return SizedBox(
      width: wide ? 310 : double.infinity,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _ShippingOptionEditor extends StatefulWidget {
  const _ShippingOptionEditor({required this.option, required this.onSave});

  final ShippingOption? option;
  final AsyncValueChanged<ShippingOption> onSave;

  @override
  State<_ShippingOptionEditor> createState() => _ShippingOptionEditorState();
}

class _ShippingOptionEditorState extends State<_ShippingOptionEditor> {
  late TextEditingController _name;
  late TextEditingController _carrier;
  late TextEditingController _service;
  late TextEditingController _price;
  late TextEditingController _days;
  late TextEditingController _sortOrder;
  late String _priority;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant _ShippingOptionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.option != widget.option) {
      _disposeControllers();
      _load();
    }
  }

  void _load() {
    final option = widget.option;
    _name = TextEditingController(text: option?.name ?? 'New shipping option');
    _carrier = TextEditingController(
      text: _normalizedCarrier(option?.carrier ?? 'USPS'),
    );
    _service = TextEditingController(
      text: option?.service ?? 'Ground Advantage',
    );
    _price = TextEditingController(text: (option?.price ?? 7.95).toString());
    _days = TextEditingController(
      text: option?.estimatedDays ?? '3-5 business days',
    );
    _sortOrder = TextEditingController(
      text: (option?.sortOrder ?? 40).toString(),
    );
    _priority = option?.priority ?? 'Standard';
    _enabled = option?.isEnabled ?? true;
  }

  List<String> get _servicesForCarrier {
    return switch (_carrier.text.trim().toUpperCase()) {
      'USPS' => const [
        'Ground Advantage',
        'Priority Mail',
        'Priority Mail Express',
        'First-Class Package',
      ],
      'UPS' => const ['Ground', '3 Day Select', '2nd Day Air', 'Next Day Air'],
      'FEDEX' => const [
        'Ground',
        'Home Delivery',
        'Express Saver',
        '2 Day',
        'Priority Overnight',
      ],
      'DHL' => const ['Express Worldwide', 'Express Easy', 'Packet Plus'],
      _ => const ['Ground', 'Express'],
    };
  }

  void _disposeControllers() {
    _name.dispose();
    _carrier.dispose();
    _service.dispose();
    _price.dispose();
    _days.dispose();
    _sortOrder.dispose();
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
              'Checkout shipping option',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Customer label'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        ['USPS', 'UPS', 'FedEx', 'DHL'].contains(_carrier.text)
                        ? _carrier.text
                        : 'USPS',
                    decoration: const InputDecoration(labelText: 'Carrier'),
                    items: const [
                      DropdownMenuItem(value: 'USPS', child: Text('USPS')),
                      DropdownMenuItem(value: 'UPS', child: Text('UPS')),
                      DropdownMenuItem(value: 'FedEx', child: Text('FedEx')),
                      DropdownMenuItem(value: 'DHL', child: Text('DHL')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _carrier.text = value ?? 'USPS';
                        final services = _servicesForCarrier;
                        if (!services.contains(_service.text)) {
                          _service.text = services.first;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey(_carrier.text),
                    initialValue: _servicesForCarrier.contains(_service.text)
                        ? _service.text
                        : _servicesForCarrier.first,
                    decoration: InputDecoration(
                      labelText: '${_carrier.text} service',
                      helperText: _shippingHelperText(_carrier.text),
                    ),
                    items: [
                      for (final service in _servicesForCarrier)
                        DropdownMenuItem(value: service, child: Text(service)),
                    ],
                    onChanged: (value) =>
                        setState(() => _service.text = value ?? _service.text),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _priority,
                    decoration: const InputDecoration(labelText: 'Priority'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Standard',
                        child: Text('Standard'),
                      ),
                      DropdownMenuItem(
                        value: 'Priority',
                        child: Text('Priority'),
                      ),
                      DropdownMenuItem(
                        value: 'Express',
                        child: Text('Express'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _priority = value ?? _priority),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _price,
                    decoration: const InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _days,
                    decoration: const InputDecoration(
                      labelText: 'Delivery estimate',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _sortOrder,
                    decoration: const InputDecoration(labelText: 'Sort order'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show at checkout'),
              value: _enabled,
              onChanged: (value) => setState(() => _enabled = value),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                final id =
                    widget.option?.id ??
                    'ship-${DateTime.now().millisecondsSinceEpoch}';
                widget.onSave(
                  ShippingOption(
                    id: id,
                    name: _name.text.trim().isEmpty
                        ? 'Shipping option'
                        : _name.text.trim(),
                    carrier: _carrier.text.trim(),
                    service: _service.text.trim(),
                    priority: _priority,
                    price: double.tryParse(_price.text) ?? 0,
                    estimatedDays: _days.text.trim(),
                    isEnabled: _enabled,
                    sortOrder: int.tryParse(_sortOrder.text) ?? 10,
                  ),
                );
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save shipping option'),
            ),
          ],
        ),
      ),
    );
  }

  String _shippingHelperText(String carrier) {
    return switch (carrier.trim().toUpperCase()) {
      'USPS' => 'USPS labels/rates require USPS or aggregator credentials.',
      'UPS' =>
        'UPS rates use account number, OAuth client, and shipper address.',
      'FEDEX' => 'FedEx rates use meter/account credentials and service code.',
      'DHL' => 'DHL Express uses account number and API key credentials.',
      _ =>
        'Carrier-specific API credentials are configured in backend shipping services.',
    };
  }

  String _normalizedCarrier(String carrier) {
    return switch (carrier.trim().toUpperCase()) {
      'UPS' => 'UPS',
      'FEDEX' => 'FedEx',
      'DHL' => 'DHL',
      _ => 'USPS',
    };
  }
}

class _ContentManagementSection extends StatelessWidget {
  const _ContentManagementSection({required this.blocks, required this.onSave});

  final List<ContentBlock> blocks;
  final AsyncValueChanged<ContentBlock> onSave;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 580
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: columns == 1 ? 1.05 : 0.78,
          ),
          itemCount: blocks.length,
          itemBuilder: (context, index) =>
              ContentBlockCard(block: blocks[index], onSave: onSave),
        );
      },
    );
  }
}

class ContentBlockCard extends StatefulWidget {
  const ContentBlockCard({
    super.key,
    required this.block,
    required this.onSave,
  });

  final ContentBlock block;
  final AsyncValueChanged<ContentBlock> onSave;

  @override
  State<ContentBlockCard> createState() => _ContentBlockCardState();
}

class _ContentBlockCardState extends State<ContentBlockCard> {
  late final TextEditingController _title;
  late final TextEditingController _placement;
  late final TextEditingController _body;
  late final TextEditingController _sortOrder;
  late bool _visible;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.block.title);
    _placement = TextEditingController(text: widget.block.placement);
    _body = TextEditingController(text: widget.block.body);
    _sortOrder = TextEditingController(text: '${widget.block.sortOrder}');
    _visible = widget.block.isVisible;
  }

  @override
  void dispose() {
    _title.dispose();
    _placement.dispose();
    _body.dispose();
    _sortOrder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Content block',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _placement,
              decoration: const InputDecoration(labelText: 'Placement'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _body,
              decoration: const InputDecoration(labelText: 'Body copy'),
              minLines: 2,
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sortOrder,
                    decoration: const InputDecoration(labelText: 'Sort'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Visible'),
                    value: _visible,
                    onChanged: (value) => setState(() => _visible = value),
                  ),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: () => widget.onSave(
                ContentBlock(
                  id: widget.block.id,
                  title: _title.text.trim(),
                  placement: _placement.text.trim(),
                  body: _body.text.trim(),
                  sortOrder:
                      int.tryParse(_sortOrder.text) ?? widget.block.sortOrder,
                  isVisible: _visible,
                ),
              ),
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save content'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomersSection extends StatefulWidget {
  const _CustomersSection({
    required this.customers,
    required this.orders,
    required this.activeCarts,
    required this.storeInfo,
    required this.onSendEmail,
    required this.onSaveCustomer,
    required this.onBlockIp,
  });

  final List<CustomerAccount> customers;
  final List<Order> orders;
  final List<ActiveCart> activeCarts;
  final StoreInfo storeInfo;
  final void Function(String audience, String subject, String body) onSendEmail;
  final AsyncValueChanged<CustomerAccount> onSaveCustomer;
  final ValueChanged<String> onBlockIp;

  @override
  State<_CustomersSection> createState() => _CustomersSectionState();
}

class _CustomersSectionState extends State<_CustomersSection> {
  String _query = '';
  String _sortBy = 'Newest';
  CustomerAccount? _selected;

  List<CustomerAccount> get _visibleCustomers {
    final query = _query.trim().toLowerCase();
    final customers = widget.customers.where((customer) {
      if (query.isEmpty) {
        return true;
      }
      return customer.name.toLowerCase().contains(query) ||
          customer.email.toLowerCase().contains(query) ||
          customer.segment.toLowerCase().contains(query) ||
          customer.createdIp.toLowerCase().contains(query) ||
          customer.lastLoginIp.toLowerCase().contains(query) ||
          customer.createdSource.toLowerCase().contains(query) ||
          customer.lastLoginSource.toLowerCase().contains(query);
    }).toList();
    customers.sort((a, b) {
      return switch (_sortBy) {
        'Orders' => b.orders.compareTo(a.orders),
        'LTV' => b.lifetimeValue.compareTo(a.lifetimeValue),
        'Newest' => a.joinedDaysAgo.compareTo(b.joinedDaysAgo),
        'Segment' => a.segment.compareTo(b.segment),
        _ => a.name.compareTo(b.name),
      };
    });
    return customers;
  }

  @override
  Widget build(BuildContext context) {
    final customers = _visibleCustomers;
    final selected = _selected;
    final newToday = widget.customers
        .where((customer) => customer.joinedDaysAgo == 0)
        .length;
    final new7 = widget.customers
        .where((customer) => customer.joinedDaysAgo <= 7)
        .length;
    final value = widget.customers.fold(
      0.0,
      (total, customer) => total + customer.lifetimeValue,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MetricGrid(
          metrics: [
            _MetricData(Icons.person_add_alt, 'New today', '$newToday users'),
            _MetricData(Icons.groups_outlined, 'New 7 days', '$new7 users'),
            _MetricData(
              Icons.diamond_outlined,
              'Customer value',
              currency(value),
            ),
            _MetricData(
              Icons.loyalty_outlined,
              'VIP customers',
              '${widget.customers.where((c) => c.segment == 'VIP').length}',
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 980;
            return Flex(
              direction: wide ? Axis.horizontal : Axis.vertical,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: wide ? 7 : 0,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: const InputDecoration(
                                    labelText: 'Search customers',
                                    prefixIcon: Icon(Icons.search),
                                  ),
                                  onChanged: (value) =>
                                      setState(() => _query = value),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 180,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _sortBy,
                                  decoration: const InputDecoration(
                                    labelText: 'Sort',
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Name',
                                      child: Text('Name'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Newest',
                                      child: Text('Newest'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Orders',
                                      child: Text('Orders'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'LTV',
                                      child: Text('LTV'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Segment',
                                      child: Text('Segment'),
                                    ),
                                  ],
                                  onChanged: (value) => setState(
                                    () => _sortBy = value ?? _sortBy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _HorizontalTableScroller(
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text('Customer')),
                                DataColumn(label: Text('Email')),
                                DataColumn(label: Text('Joined')),
                                DataColumn(label: Text('Orders')),
                                DataColumn(label: Text('LTV')),
                                DataColumn(label: Text('Segment')),
                                DataColumn(label: Text('Status')),
                                DataColumn(label: Text('Last IP')),
                                DataColumn(label: Text('Source')),
                                DataColumn(label: Text('Referral')),
                              ],
                              rows: [
                                for (final customer in customers)
                                  DataRow(
                                    selected: selected?.id == customer.id,
                                    onSelectChanged: (_) =>
                                        setState(() => _selected = customer),
                                    cells: [
                                      DataCell(Text(customer.name)),
                                      DataCell(Text(customer.email)),
                                      DataCell(
                                        Text(
                                          customer.joinedDaysAgo == 0
                                              ? 'Today'
                                              : '${customer.joinedDaysAgo} days ago',
                                        ),
                                      ),
                                      DataCell(Text('${customer.orders}')),
                                      DataCell(
                                        Text(currency(customer.lifetimeValue)),
                                      ),
                                      DataCell(Text(customer.segment)),
                                      DataCell(
                                        Text(
                                          customer.isBlocked
                                              ? 'Blocked'
                                              : 'Active',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          customer.lastLoginIp.isEmpty
                                              ? 'Not recorded'
                                              : customer.lastLoginIp,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          customer.lastLoginSource.isEmpty
                                              ? 'Unknown'
                                              : customer.lastLoginSource,
                                        ),
                                      ),
                                      DataCell(Text(customer.referralCode)),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (wide)
                  const SizedBox(width: 16)
                else
                  const SizedBox(height: 16),
                Expanded(
                  flex: wide ? 4 : 0,
                  child: _CustomerProfilePanel(
                    customer: selected,
                    orders: selected == null
                        ? const []
                        : widget.orders
                              .where((order) => order.email == selected.email)
                              .toList(),
                    carts: selected == null
                        ? const []
                        : widget.activeCarts
                              .where((cart) => cart.customer == selected.name)
                              .toList(),
                    storeInfo: widget.storeInfo,
                    onSendEmail: widget.onSendEmail,
                    onSaveCustomer: widget.onSaveCustomer,
                    onBlockIp: widget.onBlockIp,
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

class _MailingListsSection extends StatelessWidget {
  const _MailingListsSection({
    required this.customers,
    required this.subscribers,
  });

  final List<CustomerAccount> customers;
  final List<MailingListSubscriber> subscribers;

  @override
  Widget build(BuildContext context) {
    final accountMembers = customers
        .where((customer) => customer.acceptsMarketing)
        .toList();
    final accountEmails = customers
        .map((customer) => customer.email.trim().toLowerCase())
        .toSet();
    final publicMembers = subscribers
        .where(
          (subscriber) =>
              subscriber.isActive &&
              !accountEmails.contains(subscriber.email.trim().toLowerCase()),
        )
        .toList();
    return DefaultTabController(
      length: 2,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Mailing Lists',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'View account customers and public visitors who opted in.',
              ),
              const SizedBox(height: 12),
              TabBar(
                tabs: [
                  Tab(text: 'Account list (${accountMembers.length})'),
                  Tab(text: 'Public list (${publicMembers.length})'),
                ],
              ),
              SizedBox(
                height: 560,
                child: TabBarView(
                  children: [
                    _mailingMemberList(
                      accountMembers
                          .map(
                            (member) =>
                                (member.name, member.email, 'Customer account'),
                          )
                          .toList(),
                    ),
                    _mailingMemberList(
                      publicMembers
                          .map(
                            (member) =>
                                (member.name, member.email, member.source),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mailingMemberList(List<(String, String, String)> members) {
    if (members.isEmpty) {
      return const Center(child: Text('No active subscribers in this list.'));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: members.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final member = members[index];
        return ListTile(
          leading: const Icon(Icons.mark_email_read_outlined),
          title: Text(member.$1.trim().isEmpty ? member.$2 : member.$1),
          subtitle: Text(member.$2),
          trailing: Text(member.$3),
        );
      },
    );
  }
}

class _CustomerProfilePanel extends StatelessWidget {
  const _CustomerProfilePanel({
    required this.customer,
    required this.orders,
    required this.carts,
    required this.storeInfo,
    required this.onSendEmail,
    required this.onSaveCustomer,
    required this.onBlockIp,
  });

  final CustomerAccount? customer;
  final List<Order> orders;
  final List<ActiveCart> carts;
  final StoreInfo storeInfo;
  final void Function(String audience, String subject, String body) onSendEmail;
  final AsyncValueChanged<CustomerAccount> onSaveCustomer;
  final ValueChanged<String> onBlockIp;

  @override
  Widget build(BuildContext context) {
    final customer = this.customer;
    if (customer == null) {
      return const _EmptyState(
        icon: Icons.person_search_outlined,
        title: 'Select a customer',
        body:
            'Click a customer row to review profile, order history, and carts.',
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(customer.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(customer.email),
            if (customer.addressLine1.isNotEmpty ||
                customer.city.isNotEmpty ||
                customer.county.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                [
                  customer.addressLine1,
                  customer.addressLine2,
                  [
                    customer.city,
                    customer.county,
                    customer.state,
                    customer.postalCode,
                  ].where((item) => item.trim().isNotEmpty).join(', '),
                  customer.country,
                ].where((item) => item.trim().isNotEmpty).join('\n'),
              ),
            ],
            const SizedBox(height: 8),
            _CustomerMetaRow(
              icon: Icons.event_available_outlined,
              label: 'Account created',
              value: _formatCustomerDate(customer.createdAt),
            ),
            _CustomerMetaRow(
              icon: Icons.login_outlined,
              label: 'Last login',
              value: _formatCustomerDate(customer.lastLoginAt),
            ),
            _CustomerMetaRow(
              icon: Icons.public,
              label: 'Last IP address',
              value: customer.lastLoginIp.isEmpty
                  ? 'Not recorded'
                  : customer.lastLoginIp,
            ),
            _CustomerMetaRow(
              icon: Icons.devices_outlined,
              label: 'Last source type',
              value: customer.lastLoginSource.isEmpty
                  ? 'Unknown'
                  : customer.lastLoginSource,
            ),
            _CustomerMetaRow(
              icon: Icons.history_outlined,
              label: 'Created from',
              value:
                  [
                    if (customer.createdIp.isNotEmpty) customer.createdIp,
                    if (customer.createdSource.isNotEmpty)
                      customer.createdSource,
                  ].isEmpty
                  ? 'Not recorded'
                  : [
                      if (customer.createdIp.isNotEmpty) customer.createdIp,
                      if (customer.createdSource.isNotEmpty)
                        customer.createdSource,
                    ].join(' • '),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: Icon(
                    customer.isBlocked
                        ? Icons.block_outlined
                        : Icons.verified_user_outlined,
                    size: 18,
                  ),
                  label: Text(customer.isBlocked ? 'Blocked' : 'Active'),
                ),
                if (customer.lastLoginIp.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.public, size: 18),
                    label: Text('Last IP ${customer.lastLoginIp}'),
                  ),
                if (customer.createdIp.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.history, size: 18),
                    label: Text('Created from ${customer.createdIp}'),
                  ),
                if (customer.lastLoginSource.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.devices_outlined, size: 18),
                    label: Text(customer.lastLoginSource),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      customer
                        ..isBlocked = !customer.isBlocked
                        ..blockedReason = customer.isBlocked
                            ? 'Blocked from admin customer profile'
                            : '';
                      onSaveCustomer(customer);
                    },
                    icon: Icon(
                      customer.isBlocked
                          ? Icons.lock_open_outlined
                          : Icons.block_outlined,
                    ),
                    label: Text(
                      customer.isBlocked ? 'Unblock account' : 'Block account',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: customer.lastLoginIp.trim().isEmpty
                        ? null
                        : () => onBlockIp(customer.lastLoginIp),
                    icon: const Icon(Icons.public_off_outlined),
                    label: const Text('Block IP'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () =>
                  _showCustomerRewardsDialog(context, customer, onSaveCustomer),
              icon: const Icon(Icons.loyalty_outlined),
              label: const Text('Adjust credits, points, and referral'),
            ),
            const SizedBox(height: 8),
            Text(
              'Current rewards rule: 1 point per dollar paid; every 100 points provides \$5 credit. Referrals provide \$5 credit.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: () =>
                  _showCustomerEmailDialog(context, customer, onSendEmail),
              icon: const Icon(Icons.mail_outline),
              label: const Text('Send email'),
            ),
            if (customer.blockedReason.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(customer.blockedReason),
            ],
            const SizedBox(height: 12),
            Text('Orders', style: Theme.of(context).textTheme.titleMedium),
            if (orders.isEmpty)
              const Text('No orders for this customer yet.')
            else
              for (final order in orders)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${order.id} • ${currency(order.total)}'),
                  subtitle: Text(order.fulfillmentStatus),
                  trailing: const Icon(Icons.description_outlined),
                  onTap: () => _showInvoiceDialog(context, order, storeInfo),
                ),
            const Divider(),
            Text('Carts', style: Theme.of(context).textTheme.titleMedium),
            if (carts.isEmpty)
              const Text('No active carts for this customer.')
            else
              for (final cart in carts)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${cart.id} • ${currency(cart.value)}'),
                  subtitle: Text('${cart.itemCount} item(s)'),
                ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showCustomerRewardsDialog(
  BuildContext context,
  CustomerAccount customer,
  AsyncValueChanged<CustomerAccount> onSaveCustomer,
) async {
  final credits = TextEditingController(text: '${customer.referralCredits}');
  final points = TextEditingController(text: '${customer.loyaltyPoints}');
  final referralCode = TextEditingController(text: customer.referralCode);
  final referredBy = TextEditingController(text: customer.referredBy);
  var segment = customer.segment.trim().isEmpty ? 'Customer' : customer.segment;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text('Customer settings for ${customer.name}'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: segment,
                decoration: const InputDecoration(
                  labelText: 'Customer segment',
                ),
                items: const [
                  DropdownMenuItem(value: 'Customer', child: Text('Customer')),
                  DropdownMenuItem(value: 'VIP', child: Text('VIP')),
                ],
                onChanged: (value) {
                  if (value != null) setDialogState(() => segment = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: credits,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Store / referral credit balance',
                  prefixText: '\$',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: points,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Loyalty points'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: referralCode,
                decoration: const InputDecoration(labelText: 'Referral code'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: referredBy,
                decoration: const InputDecoration(
                  labelText: 'Referred by code',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await onSaveCustomer(
                customer.copyWith(
                  referralCredits: double.tryParse(credits.text) ?? 0,
                  loyaltyPoints: int.tryParse(points.text) ?? 0,
                  referralCode: referralCode.text.trim().toUpperCase(),
                  referredBy: referredBy.text.trim().toUpperCase(),
                  segment: segment,
                ),
              );
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Save rewards'),
          ),
        ],
      ),
    ),
  );
  credits.dispose();
  points.dispose();
  referralCode.dispose();
  referredBy.dispose();
}

void _showInvoiceDialog(
  BuildContext context,
  Order order,
  StoreInfo storeInfo, [
  String? returnPolicyText,
  AsyncValueChanged<Order>? onUpdateOrder,
]) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InvoiceDocumentPreview(
                order: order,
                storeInfo: storeInfo,
                returnPolicyText: returnPolicyText,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  order
                    ..status = 'Invoice created'
                    ..fulfillmentStatus = 'Invoice created';
                  onUpdateOrder?.call(order);
                  printHtmlDocument(
                    'Invoice ${order.id}',
                    _invoiceHtml(
                      order,
                      storeInfo,
                      returnPolicyText: returnPolicyText,
                    ),
                  );
                },
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

void _showCustomerEmailDialog(
  BuildContext context,
  CustomerAccount customer,
  void Function(String audience, String subject, String body) onSendEmail,
) {
  final subject = TextEditingController();
  final body = TextEditingController();
  var htmlMode = true;
  showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text('Email ${customer.name}'),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(customer.email),
              const SizedBox(height: 12),
              TextField(
                controller: subject,
                decoration: const InputDecoration(labelText: 'Subject'),
              ),
              const SizedBox(height: 10),
              _HtmlEditorField(
                controller: body,
                compact: true,
                htmlMode: htmlMode,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Send as HTML email'),
                value: htmlMode,
                onChanged: (value) => setDialogState(() => htmlMode = value),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () {
              onSendEmail(
                customer.email.trim().toLowerCase(),
                subject.text.trim(),
                htmlMode
                    ? '<html><body>${body.text.trim()}</body></html>'
                    : body.text.trim(),
              );
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.send_outlined),
            label: const Text('Send'),
          ),
        ],
      ),
    ),
  ).whenComplete(() {
    subject.dispose();
    body.dispose();
  });
}

class _CustomerMetaRow extends StatelessWidget {
  const _CustomerMetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF27724E)),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCustomerDate(DateTime? value) {
  if (value == null) {
    return 'Not recorded';
  }
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.year}-$month-$day $hour:$minute';
}
