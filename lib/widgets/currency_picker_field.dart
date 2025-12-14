import 'package:flutter/material.dart';

import '../core/constants/gulf_currencies.dart';

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
  Future<void> _openPicker() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final searchController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setModalState) {
            final query = searchController.text.toLowerCase();
            final filtered = gulfCurrencies.where((currency) {
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
                    decoration: const InputDecoration(
                      labelText: 'ابحث عن العملة',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: filtered.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text('لا توجد نتائج'),
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
        labelText: widget.label,
        prefixIcon: const Icon(Icons.monetization_on_outlined),
        suffixIcon: const Icon(Icons.arrow_drop_down),
      ),
      onTap: _openPicker,
    );
  }
}
