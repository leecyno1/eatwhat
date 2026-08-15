import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/v2/core/external/platform/meituan_delivery_order_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/services/v2_location_service.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/execution/widgets/execution_widgets.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef MeituanPaymentLauncher = Future<bool> Function(Uri uri);

class MeituanOrderPage extends StatefulWidget {
  const MeituanOrderPage({
    super.key,
    required this.intent,
    required this.match,
    this.client,
    this.locationResolver,
    this.paymentLauncher,
  });

  final ExecutionIntent intent;
  final DeliveryMatchResult match;
  final MeituanDeliveryOrderClient? client;
  final Future<GeoPoint> Function()? locationResolver;
  final MeituanPaymentLauncher? paymentLauncher;

  @override
  State<MeituanOrderPage> createState() => _MeituanOrderPageState();
}

class _MeituanOrderPageState extends State<MeituanOrderPage> {
  late final MeituanDeliveryOrderClient _client;
  late Future<MeituanProductSearchResult> _productsFuture;
  final Map<String, _CartLine> _cart = {};
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _houseNumberController = TextEditingController();
  final _noteController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  GeoPoint? _location;
  bool _previewing = false;
  bool _submitting = false;
  bool _needsVerification = false;
  String? _errorMessage;
  MeituanOrderPreview? _preview;

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? MeituanDeliveryOrderClient();
    for (final controller in [
      _nameController,
      _phoneController,
      _addressController,
      _houseNumberController,
      _noteController,
    ]) {
      controller.addListener(_invalidatePreview);
    }
    _productsFuture = _loadProducts();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _houseNumberController.dispose();
    _noteController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<MeituanProductSearchResult> _loadProducts() async {
    final location = await (widget.locationResolver ??
        V2LocationService.instance.getCurrentLocationOrFallback)();
    _location = location;
    final result = await _client.searchProducts(
      merchantId: widget.match.merchantId,
      location: location,
    );
    _buildSuggestedMenu(result.products);
    return result;
  }

  void _buildSuggestedMenu(List<MeituanDeliveryProduct> products) {
    _cart.clear();
    final targets = [
      widget.intent.recipe.name,
      ...widget.intent.pairings.map((pairing) => pairing.title),
    ];
    for (final target in targets) {
      final product = _bestMatch(products, target);
      if (product == null || _cart.containsKey(product.productId)) continue;
      final sku = product.skus.where((sku) => sku.isAvailable).firstOrNull;
      if (sku == null) continue;
      _cart[product.productId] = _CartLine(
        product: product,
        sku: sku,
        quantity: sku.minimumOrderCount,
        attributes: _defaultAttributes(product),
        suggested: true,
      );
    }
  }

  MeituanDeliveryProduct? _bestMatch(
    List<MeituanDeliveryProduct> products,
    String target,
  ) {
    final normalizedTarget = _normalize(target);
    if (normalizedTarget.isEmpty) return null;
    MeituanDeliveryProduct? best;
    var bestScore = 0;
    for (final product in products) {
      if (!product.skus.any((sku) => sku.isAvailable)) continue;
      final productName = _normalize(product.name);
      var score = 0;
      if (productName == normalizedTarget) score += 100;
      if (productName.contains(normalizedTarget) ||
          normalizedTarget.contains(productName)) {
        score += 60;
      }
      for (final rune in normalizedTarget.runes.toSet()) {
        if (productName.runes.contains(rune)) score++;
      }
      if (score > bestScore) {
        best = product;
        bestScore = score;
      }
    }
    return bestScore >= 2 ? best : null;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[\s·（）()【】\[\]—_-]'), '');
  }

  Map<String, int> _defaultAttributes(MeituanDeliveryProduct product) {
    return {
      for (final attribute in product.attributes)
        if (attribute.values.isNotEmpty)
          attribute.name: attribute.values.first.id,
    };
  }

  void _refreshProducts() {
    setState(() {
      _cart.clear();
      _preview = null;
      _errorMessage = null;
      _productsFuture = _loadProducts();
    });
  }

  void _selectSku(
    MeituanDeliveryProduct product,
    MeituanDeliverySku sku,
  ) {
    setState(() {
      final existing = _cart[product.productId];
      _cart[product.productId] = _CartLine(
        product: product,
        sku: sku,
        quantity: existing?.quantity.clamp(sku.minimumOrderCount, 99) ??
            sku.minimumOrderCount,
        attributes: existing?.attributes ?? _defaultAttributes(product),
        suggested: existing?.suggested ?? false,
      );
      _clearPreview();
    });
  }

  void _removeProduct(MeituanDeliveryProduct product) {
    setState(() {
      _cart.remove(product.productId);
      _clearPreview();
    });
  }

  void _changeQuantity(String productId, int delta) {
    final line = _cart[productId];
    if (line == null) return;
    final next = line.quantity + delta;
    if (next < line.sku.minimumOrderCount) {
      _removeProduct(line.product);
      return;
    }
    final stock = line.sku.stock;
    if (stock != null && stock >= 0 && next > stock) return;
    setState(() {
      line.quantity = next;
      _clearPreview();
    });
  }

  void _selectAttribute(String productId, String name, int value) {
    final line = _cart[productId];
    if (line == null) return;
    setState(() {
      line.attributes[name] = value;
      _clearPreview();
    });
  }

  void _invalidatePreview() {
    if (!mounted || _preview == null) return;
    setState(_clearPreview);
  }

  void _clearPreview() {
    _preview = null;
    _needsVerification = false;
    _verificationCodeController.clear();
  }

  MeituanDeliveryOrderRequest? _buildOrderRequest() {
    final location = _location;
    if (_cart.isEmpty || location == null) {
      _showError('请先确认至少一道菜');
      return null;
    }
    for (final line in _cart.values) {
      final missingAttribute = line.product.attributes.any(
        (attribute) =>
            attribute.values.isNotEmpty &&
            !line.attributes.containsKey(attribute.name),
      );
      if (missingAttribute) {
        _showError('请把 ${line.product.name} 的口味和属性选完整');
        return null;
      }
    }
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    if (name.isEmpty || phone.isEmpty || address.isEmpty) {
      _showError('请填写收餐人、手机号和详细地址');
      return null;
    }
    if (!RegExp(r'^1\d{10}$').hasMatch(phone)) {
      _showError('请输入正确的 11 位手机号');
      return null;
    }

    return MeituanDeliveryOrderRequest(
      merchantId: widget.match.merchantId,
      items: _cart.values
          .map(
            (line) => MeituanDeliveryOrderItem(
              skuId: line.sku.skuId,
              count: line.quantity,
              attributeIds: line.attributes.values.toList(),
            ),
          )
          .toList(),
      recipient: MeituanDeliveryRecipient(
        name: name,
        phone: phone,
        address: address,
        currentLocation: location,
        addressLocation: location,
        houseNumber: _houseNumberController.text.trim(),
        note: _noteController.text.trim(),
      ),
    );
  }

  Future<void> _previewOrder() async {
    final request = _buildOrderRequest();
    if (request == null) return;
    setState(() {
      _previewing = true;
      _errorMessage = null;
    });
    try {
      final preview = await _client.previewOrder(request);
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _needsVerification = false;
      });
    } catch (error) {
      if (mounted) _showError(_messageFrom(error));
    } finally {
      if (mounted) setState(() => _previewing = false);
    }
  }

  Future<void> _submitOrder() async {
    final request = _buildOrderRequest();
    final preview = _preview;
    if (request == null || preview == null) return;
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      final order = await _client.submitOrder(
        request,
        previewToken: preview.previewToken,
        verifyCode: _verificationCodeController.text.trim(),
        paymentSuccessUrl: EnvConfig.meituanPaymentSuccessUrl,
        paymentFailureUrl: EnvConfig.meituanPaymentFailureUrl,
      );
      if (!mounted) return;
      if (order.requiresVerification) {
        setState(() {
          _needsVerification = true;
          _errorMessage = order.message ?? '请输入美团发送的验证码';
        });
        return;
      }
      final paymentUri = Uri.tryParse(order.paymentUrl);
      if (paymentUri == null) {
        _showError('美团没有返回可用的支付地址');
        return;
      }
      final launched = await (widget.paymentLauncher ?? _launchPayment)(
        paymentUri,
      );
      if (!launched && mounted) _showError('暂时无法打开美团收银台');
    } catch (error) {
      if (mounted) _showError(_messageFrom(error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<bool> _launchPayment(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
  }

  String _messageFrom(Object error) {
    final text = error.toString();
    return text.replaceFirst(RegExp(r'^[^:]+:\s*'), '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return ExecutionAsyncScaffold<MeituanProductSearchResult>(
      title: '确认外卖菜单',
      accent: AppPalette.chili,
      future: _productsFuture,
      onRefresh: _refreshProducts,
      builder: (context, result) {
        if (result.products.isEmpty) {
          return const ExecutionUnavailableState(
            title: '这家店暂时没有可点菜品',
            description: '可以返回换一家门店，或稍后刷新菜品库存。',
          );
        }
        return ListView(
          key: const ValueKey('meituan-order-flow'),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: AppDecorations.card(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('当前门店', style: AppType.microLabel),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    result.merchantName.isEmpty
                        ? widget.match.merchantName
                        : result.merchantName,
                    style: AppType.title,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '已按推荐菜和搭配预选菜单，可增减菜品或更换规格。',
                    style: AppType.body.copyWith(color: AppPalette.inkSoft),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildCartSummary(),
            const SizedBox(height: 18),
            for (final entry in _groupedProducts(result.products).entries) ...[
              Text(
                entry.key,
                style: AppType.label.copyWith(color: AppPalette.herb),
              ),
              const SizedBox(height: 8),
              for (final product in entry.value)
                _ProductCard(
                  product: product,
                  line: _cart[product.productId],
                  onSelected: (sku) => _selectSku(product, sku),
                  onRemoved: () => _removeProduct(product),
                  onQuantityChanged: (delta) =>
                      _changeQuantity(product.productId, delta),
                  onAttributeSelected: (name, value) =>
                      _selectAttribute(product.productId, name, value),
                ),
              const SizedBox(height: 6),
            ],
            if (_cart.isNotEmpty) ...[
              const SizedBox(height: 4),
              _buildRecipientPanel(),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  key: const ValueKey('meituan-order-error'),
                  style: AppType.body.copyWith(
                    color: AppPalette.chili,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              if (_preview != null) ...[
                const SizedBox(height: 14),
                _buildPreviewPanel(_preview!),
              ],
              if (_needsVerification) ...[
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('meituan-verification-code'),
                  controller: _verificationCodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '美团短信验证码',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FilledButton.icon(
                key: ValueKey(
                  _preview == null
                      ? 'meituan-preview-order'
                      : 'meituan-submit-order',
                ),
                onPressed: _previewing || _submitting
                    ? null
                    : _preview == null
                        ? _previewOrder
                        : _submitOrder,
                icon: _previewing || _submitting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        _preview == null
                            ? Icons.receipt_long_rounded
                            : Icons.open_in_new_rounded,
                      ),
                label: Text(
                  _preview == null ? '预览订单金额' : '提交订单并去美团支付',
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Map<String, List<MeituanDeliveryProduct>> _groupedProducts(
    List<MeituanDeliveryProduct> products,
  ) {
    final result = <String, List<MeituanDeliveryProduct>>{};
    for (final product in products) {
      final category = product.categoryName.trim().isEmpty
          ? '全部菜品'
          : product.categoryName.trim();
      result.putIfAbsent(category, () => []).add(product);
    }
    return result;
  }

  Widget _buildCartSummary() {
    final count = _cart.values.fold<int>(
      0,
      (sum, line) => sum + line.quantity,
    );
    final total = _cart.values.fold<double>(
      0,
      (sum, line) => sum + (line.sku.price + line.sku.boxPrice) * line.quantity,
    );
    return Container(
      key: const ValueKey('meituan-cart-summary'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(
        color: AppPalette.positiveSurface,
        borderColor: AppPalette.chili.withValues(alpha: 0.24),
      ),
      child: Row(
        children: [
          const Icon(Icons.shopping_bag_outlined, color: AppPalette.chili),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _cart.isEmpty ? '还没有选菜' : '菜单已选 $count 份',
              style: AppType.section,
            ),
          ),
          Text('约 ¥${total.toStringAsFixed(2)}', style: AppType.label),
        ],
      ),
    );
  }

  Widget _buildRecipientPanel() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('收货信息', style: AppType.section),
          const SizedBox(height: 6),
          Text(
            '配送坐标使用当前位置，详细地址仅用于本次订单。',
            style: AppType.body.copyWith(
              color: AppPalette.ink.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('meituan-recipient-name'),
            controller: _nameController,
            decoration: const InputDecoration(labelText: '收餐人'),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('meituan-recipient-phone'),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: '手机号'),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const ValueKey('meituan-recipient-address'),
            controller: _addressController,
            decoration: const InputDecoration(labelText: '详细地址'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _houseNumberController,
            decoration: const InputDecoration(labelText: '门牌号（可选）'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: '备注（可选）'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewPanel(MeituanOrderPreview preview) {
    return Container(
      key: const ValueKey('meituan-order-preview'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.card(
        color: AppPalette.positiveSurface,
        borderColor: AppPalette.chili.withValues(alpha: 0.24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('美团订单预览', style: AppType.section),
          const SizedBox(height: 8),
          Text('商品与优惠后合计：¥${preview.total.toStringAsFixed(2)}'),
          Text('配送费：¥${preview.shippingFee.toStringAsFixed(2)}'),
          Text('餐盒费：¥${preview.boxFee.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          Text(
            '确认后创建美团订单，并进入美团收银台付款。',
            style: AppType.body.copyWith(
              color: AppPalette.ink.withValues(alpha: 0.64),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.line,
    required this.onSelected,
    required this.onRemoved,
    required this.onQuantityChanged,
    required this.onAttributeSelected,
  });

  final MeituanDeliveryProduct product;
  final _CartLine? line;
  final ValueChanged<MeituanDeliverySku> onSelected;
  final VoidCallback onRemoved;
  final ValueChanged<int> onQuantityChanged;
  final void Function(String name, int value) onAttributeSelected;

  @override
  Widget build(BuildContext context) {
    final availableSkus = product.skus.where((sku) => sku.isAvailable).toList();
    if (availableSkus.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: AppDecorations.card(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(product.name, style: AppType.section)),
              if (line?.suggested == true)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppPalette.positiveSurface,
                    borderRadius: AppRadii.capsule,
                  ),
                  child: Text(
                    '已为你选',
                    style: AppType.microLabel.copyWith(color: AppPalette.chili),
                  ),
                ),
            ],
          ),
          if (product.description?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              product.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppType.body.copyWith(
                color: AppPalette.ink.withValues(alpha: 0.58),
                fontSize: 13,
              ),
            ),
          ],
          for (final sku in availableSkus)
            RadioListTile<String>(
              key: ValueKey('meituan-sku-${sku.skuId}'),
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: sku.skuId,
              groupValue: line?.sku.skuId,
              onChanged: (_) => onSelected(sku),
              title: Text(
                sku.specification.trim().isEmpty ? '标准份' : sku.specification,
              ),
              subtitle: Text('¥${sku.price.toStringAsFixed(2)}'),
            ),
          if (line != null) ...[
            for (final attribute in product.attributes)
              if (attribute.values.isNotEmpty) ...[
                Text(attribute.name, style: AppType.label),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final value in attribute.values)
                      ChoiceChip(
                        label: Text(value.label),
                        selected: line!.attributes[attribute.name] == value.id,
                        onSelected: (_) =>
                            onAttributeSelected(attribute.name, value.id),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            Row(
              children: [
                TextButton.icon(
                  key: ValueKey('meituan-remove-${product.productId}'),
                  onPressed: onRemoved,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('移除'),
                ),
                const Spacer(),
                IconButton(
                  key: ValueKey('meituan-minus-${product.productId}'),
                  onPressed: () => onQuantityChanged(-1),
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Text('${line!.quantity}', style: AppType.section),
                IconButton(
                  key: ValueKey('meituan-plus-${product.productId}'),
                  onPressed: () => onQuantityChanged(1),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CartLine {
  _CartLine({
    required this.product,
    required this.sku,
    required this.quantity,
    required this.attributes,
    required this.suggested,
  });

  final MeituanDeliveryProduct product;
  final MeituanDeliverySku sku;
  int quantity;
  final Map<String, int> attributes;
  final bool suggested;
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
