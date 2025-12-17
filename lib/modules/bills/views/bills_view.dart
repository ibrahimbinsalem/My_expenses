import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/bill_group_model.dart';
import '../controllers/bills_controller.dart';

class BillsView extends GetView<BillsController> {
  const BillsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('billBook.title'.tr),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateBillSheet(context),
        icon: const Icon(Icons.add),
        label: Text('billBook.add'.tr),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.bills.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.bills.isEmpty) {
          return Center(
            child: Text(
              'billBook.empty'.tr,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.refreshBills,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.bills.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final bill = controller.bills[index];
              final walletNames = {
                for (final wallet in controller.wallets)
                  if (wallet.id != null) wallet.id!: wallet.name,
              };
              return _BillCard(
                bill: bill,
                walletNames: walletNames,
                onDelete: () {
                  if (bill.id != null) {
                    controller.deleteBill(bill.id!);
                  }
                },
                onShare: () => _shareBill(bill),
                onMarkPaid: (participant) =>
                    controller.markParticipantAsPaid(bill, participant),
              );
            },
          ),
        );
      }),
    );
  }

  Future<void> _showCreateBillSheet(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final totalController = TextEditingController();
    DateTime eventDate = DateTime.now();
    String? selectedCurrency = controller.wallets.isNotEmpty
        ? controller.wallets.first.currency
        : 'SAR';
    final participants = <_ParticipantFormEntry>[
      _ParticipantFormEntry(),
      _ParticipantFormEntry(),
    ];
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void addParticipant() {
              setState(() {
                participants.add(_ParticipantFormEntry());
              });
            }

            void removeParticipant(int index) {
              if (participants.length <= 1) return;
              setState(() {
                participants.removeAt(index);
              });
            }

            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: eventDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() {
                  eventDate = picked;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'billBook.sheetTitle'.tr,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'billBook.titleLabel'.tr,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'billBook.required'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'billBook.descriptionLabel'.tr,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: totalController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                labelText: 'billBook.totalLabel'.tr,
                              ),
                              validator: (value) {
                                final parsed =
                                    double.tryParse(value ?? '0') ?? 0;
                                if (parsed <= 0) {
                                  return 'billBook.required'.tr;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedCurrency,
                              items: controller.wallets
                                  .map((wallet) => wallet.currency)
                                  .toSet()
                                  .map(
                                    (code) => DropdownMenuItem(
                                      value: code,
                                      child: Text(code),
                                    ),
                                  )
                                  .toList(),
                              decoration: InputDecoration(
                                labelText: 'billBook.currencyLabel'.tr,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  selectedCurrency = value;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event),
                        title: Text(
                          Formatters.compactDate(eventDate),
                        ),
                        subtitle: Text('billBook.dateLabel'.tr),
                        trailing: TextButton(
                          onPressed: pickDate,
                          child: Text('billBook.pickDate'.tr),
                        ),
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'billBook.participants'.tr,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          TextButton.icon(
                            onPressed: addParticipant,
                            icon: const Icon(Icons.person_add_alt),
                            label: Text('billBook.addParticipant'.tr),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...participants.indexed.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: entry.$2.nameController,
                                      decoration: InputDecoration(
                                        labelText: 'billBook.personName'.tr,
                                      ),
                                      validator: (value) {
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'billBook.required'.tr;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: entry.$2.amountController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'billBook.shareLabel'.tr,
                                      ),
                                      validator: (value) {
                                        final parsed =
                                            double.tryParse(value ?? '0') ?? 0;
                                        if (parsed <= 0) {
                                          return 'billBook.required'.tr;
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  if (participants.length > 1)
                                    IconButton(
                                      onPressed: () =>
                                          removeParticipant(entry.$1),
                                      icon: const Icon(Icons.close),
                                    ),
                                ],
                              ),
                              if (controller.wallets.isNotEmpty)
                                DropdownButtonFormField<int>(
                                  value: entry.$2.walletId,
                                  decoration: InputDecoration(
                                    labelText: 'billBook.walletLabel'.tr,
                                  ),
                                  items: controller.wallets
                                      .where((wallet) => wallet.id != null)
                                      .map(
                                        (wallet) => DropdownMenuItem(
                                          value: wallet.id,
                                          child: Text(wallet.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      entry.$2.walletId = value;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final total =
                                double.tryParse(totalController.text) ?? 0;
                            final participantModels =
                                participants.map((participant) {
                              return BillParticipantModel(
                                billId: 0,
                                name: participant.nameController.text.trim(),
                                share: double.tryParse(
                                      participant.amountController.text,
                                    ) ??
                                    0,
                                walletId: participant.walletId,
                              );
                            }).toList();
                            Navigator.of(context).pop();
                            final success = await controller.addBill(
                              title: titleController.text.trim(),
                              description:
                                  descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                              eventDate: eventDate,
                              total: total,
                              currency: selectedCurrency ?? 'SAR',
                              participants: participantModels,
                            );
                            if (success) {
                              Get.snackbar(
                                'common.success'.tr,
                                'billBook.created'.tr,
                              );
                            } else {
                              Get.snackbar(
                                'common.alert'.tr,
                                'billBook.error'.tr,
                              );
                            }
                          },
                          child: Text('common.save'.tr),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _shareBill(BillGroupModel bill) async {
    final buffer = StringBuffer()
      ..writeln('${'billBook.shareTitle'.tr}: ${bill.title}')
      ..writeln(
        '${'billBook.total'.tr}: ${Formatters.currency(bill.total, symbol: bill.currency)}',
      )
      ..writeln(
        '${'billBook.dateLabel'.tr}: ${Formatters.shortDate(bill.eventDate)}',
      )
      ..writeln('')
      ..writeln('${'billBook.participants'.tr}:');
    for (final participant in bill.participants) {
      buffer.writeln(
        '- ${participant.name}: ${Formatters.currency(participant.share, symbol: bill.currency)}',
      );
    }
    await Share.share(buffer.toString());
  }
}

class _ParticipantFormEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  int? walletId;
}

class _BillCard extends StatelessWidget {
  const _BillCard({
    required this.bill,
    required this.onDelete,
    required this.walletNames,
    required this.onShare,
    required this.onMarkPaid,
  });

  final BillGroupModel bill;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final Map<int, String> walletNames;
  final Future<void> Function(BillParticipantModel participant) onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalPaid = bill.participants.fold<double>(
      0,
      (prev, participant) => prev + participant.paid,
    );
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.title,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.compactDate(bill.eventDate),
                        style:
                            theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onShare,
                  icon: const Icon(Icons.ios_share),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if (bill.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                bill.description!,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _BillMetric(
                    label: 'billBook.total'.tr,
                    value: Formatters.currency(
                      bill.total,
                      symbol: bill.currency,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BillMetric(
                    label: 'billBook.paid'.tr,
                    value: Formatters.currency(
                      totalPaid,
                      symbol: bill.currency,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: bill.participants
                  .map(
                    (participant) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        child: Icon(Icons.person, size: 18),
                      ),
                      title: Text(participant.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            Formatters.currency(
                              participant.share,
                              symbol: bill.currency,
                            ),
                          ),
                          Text(
                            participant.walletId != null
                                ? walletNames[participant.walletId!] ??
                                    'billBook.noWallet'.tr
                                : 'billBook.noWallet'.tr,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.grey),
                          ),
                        ],
                      ),
                      trailing: participant.paid >= participant.share
                          ? Chip(
                              label: Text('billBook.paidStatus'.tr),
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                            )
                          : TextButton(
                              onPressed: () => onMarkPaid(participant),
                              child: Text('billBook.markPaid'.tr),
                            ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillMetric extends StatelessWidget {
  const _BillMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
