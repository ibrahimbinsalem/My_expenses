import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/formatters.dart';
import '../../../data/models/recurring_task_model.dart';
import '../controllers/tasks_controller.dart';

class TasksView extends GetView<TasksController> {
  const TasksView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('tasks.title'.tr),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateTaskSheet(context),
        icon: const Icon(Icons.add_task),
        label: Text('tasks.add'.tr),
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.tasks.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.tasks.isEmpty) {
          return Center(
            child: Text(
              'tasks.empty'.tr,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: controller.loadTasks,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.tasks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final task = controller.tasks[index];
              return _TaskCard(
                task: task,
                onComplete: () => controller.completeTask(task),
                onDelete: () {
                  if (task.id != null) {
                    controller.deleteTask(task.id!);
                  }
                },
              );
            },
          ),
        );
      }),
    );
  }

  Future<void> _showCreateTaskSheet(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    DateTime nextDate = DateTime.now();
    RecurringFrequency frequency = RecurringFrequency.monthly;
    int? selectedWallet =
        controller.wallets.isNotEmpty ? controller.wallets.first.id : null;
    String? selectedCurrency =
        controller.wallets.isNotEmpty ? controller.wallets.first.currency : null;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              Future<void> pickDate() async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: nextDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) {
                  setState(() => nextDate = picked);
                }
              }

              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'tasks.sheetTitle'.tr,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'tasks.titleLabel'.tr,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'tasks.required'.tr;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'tasks.descriptionLabel'.tr,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              decoration: InputDecoration(
                                labelText: 'tasks.amountLabel'.tr,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedCurrency,
                              decoration: InputDecoration(
                                labelText: 'tasks.currencyLabel'.tr,
                              ),
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
                              onChanged: (value) {
                                setState(() => selectedCurrency = value);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<RecurringFrequency>(
                        value: frequency,
                        items: RecurringFrequency.values
                            .map(
                              (freq) => DropdownMenuItem(
                                value: freq,
                                child: Text('tasks.freq.${freq.name}'.tr),
                              ),
                            )
                            .toList(),
                        decoration: InputDecoration(
                          labelText: 'tasks.frequencyLabel'.tr,
                        ),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => frequency = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event),
                        title: Text(
                          DateFormat('dd MMM yyyy').format(nextDate),
                        ),
                        subtitle: Text('tasks.nextDateLabel'.tr),
                        trailing: TextButton(
                          onPressed: pickDate,
                          child: Text('tasks.pickDate'.tr),
                        ),
                      ),
                      if (controller.wallets.isNotEmpty)
                        DropdownButtonFormField<int>(
                          value: selectedWallet,
                          decoration: InputDecoration(
                            labelText: 'tasks.walletLabel'.tr,
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
                            setState(() => selectedWallet = value);
                          },
                        ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final task = RecurringTaskModel(
                              title: titleController.text.trim(),
                              description:
                                  descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                              amount: amountController.text.trim().isEmpty
                                  ? null
                                  : double.tryParse(
                                      amountController.text.trim(),
                                    ),
                              currency: selectedCurrency,
                              frequency: frequency,
                              nextDate: nextDate,
                              walletId: selectedWallet,
                              createdAt: DateTime.now(),
                            );
                            Navigator.of(context).pop();
                            final success = await controller.addTask(task);
                            if (success) {
                              Get.snackbar(
                                'common.success'.tr,
                                'tasks.created'.tr,
                              );
                            } else {
                              Get.snackbar(
                                'common.alert'.tr,
                                'tasks.error'.tr,
                              );
                            }
                          },
                          child: Text('common.save'.tr),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onDelete,
    required this.onComplete,
  });

  final RecurringTaskModel task;
  final VoidCallback onDelete;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                        task.title,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'tasks.freq.${task.frequency.name}'.tr,
                        style:
                            theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            if (task.description?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (task.amount != null) ...[
                  _TaskMetric(
                    label: 'tasks.amount'.tr,
                    value: Formatters.currency(
                      task.amount!,
                      symbol: task.currency ?? '﷼',
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                _TaskMetric(
                  label: 'tasks.next'.tr,
                  value: DateFormat('dd MMM').format(task.nextDate),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onComplete,
                icon: const Icon(Icons.check_circle_outline),
                label: Text('tasks.markDone'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskMetric extends StatelessWidget {
  const _TaskMetric({required this.label, required this.value});

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
