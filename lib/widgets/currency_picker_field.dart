import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/constants/gulf_currencies.dart';
import '../core/utils/currency_utils.dart';
import '../data/models/currency_model.dart';
import '../data/repositories/local_expense_repository.dart';

class CurrencyPickerField extends StatefulWidget {
  const CurrencyPickerField({
    super.key,
    required this.controller,
    this.label = 'العملة',
  });

  final TextEditingController controller;
  final String label;

  @override
  State<CurrencyPickerField> createState() => _CurrencyPickerFieldState();
}

class _CurrencyPickerFieldState extends State<CurrencyPickerField> {
  final _options = <Map<String, String>>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    try {
      final repo = Get.find<LocalExpenseRepository>();
      final currencies = await repo.fetchCurrencies();
      if (!mounted) return;
      if (currencies.isEmpty) {
        _applyFallbackOptions();
      } else {
        _options
          ..clear()
          ..addAll(
            currencies.map(
              (CurrencyModel currency) => {
                'code': currency.code,
                'name': currency.name,
              },
            ),
          );
      }
    } catch (_) {
      if (!mounted) return;
      _applyFallbackOptions();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFallbackOptions() {
    _options
      ..clear()
      ..addAll(
        gulfCurrencies.map(
          (currency) => {
            'code': currency['code'] as String,
            'name': localizedCurrencyName(
              currency.cast<String, String>(),
            ),
          },
        ),
      );
  }

  Future<void> _openPicker() async {
    if (_isLoading) return;
    final searchController = TextEditingController();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.toLowerCase();
            final filtered = _options.where((currency) {
              final code = (currency['code'] as String).toLowerCase();
              final name = (currency['name'] as String).toLowerCase();
              return code.contains(query) || name.contains(query);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'common.currency_search'.tr,
                      prefixIcon: const Icon(Icons.search),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('common.no_results'.tr),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final currency = filtered[index];
                              return ListTile(
                                leading: const Icon(
                                  Icons.monetization_on_outlined,
                                ),
                                title: Text(currency['name'] as String),
                                subtitle: Text(currency['code'] as String),
                                onTap: () => Navigator.of(
                                  context,
                                ).pop(currency['code'] as String),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    searchController.dispose();

    if (result != null) {
      setState(() {
        widget.controller.text = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.label.tr,
        prefixIcon: const Icon(Icons.monetization_on_outlined),
        suffixIcon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Icon(Icons.arrow_drop_down),
      ),
      onTap: _openPicker,
    );
  }
}
