import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/home_controller.dart';

import 'package:pomodoro/app/data/models/pomodoro_models.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pomodoro'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Get.toNamed('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.toNamed('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSessionInfo(context),
          _buildTimerSection(context),
          _buildControlButtons(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSessionSettingsModal(context),
        child: const Icon(Icons.timer_outlined),
      ),
    );
  }

  Widget _buildSessionInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Obx(
            () => Text(
              controller.sessionTitle.value,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Obx(
                () => Text(
                  'Sessions completed: ${controller.sessionsCompleted}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection(BuildContext context) {
    return Expanded(
      child: Center(
        child: Obx(() {
          final sessionTypeColor = controller.getSessionTypeColor(context);

          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 280,
                height: 280,
                child: CircularProgressIndicator(
                  value: controller.progress,
                  strokeWidth: 12,
                  backgroundColor: sessionTypeColor.withOpacity(0.2),
                  color: sessionTypeColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    controller.formattedTimeRemaining,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    controller.currentSessionType.value.name.capitalizeFirst!,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildControlButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Obx(() {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!controller.isRunning.value || controller.isPaused.value)
              OutlinedButton.icon(
                onPressed: () => controller.startTimer(),
                icon: const Icon(Icons.play_arrow),
                label: Text(controller.isPaused.value ? 'Resume' : 'Start'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            if (controller.isRunning.value && !controller.isPaused.value)
              OutlinedButton.icon(
                onPressed: () => controller.pauseTimer(),
                icon: const Icon(Icons.pause),
                label: const Text('Pause'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () => controller.resetSession(),
              icon: const Icon(Icons.restart_alt),
              label: const Text('Reset'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(width: 16),
            OutlinedButton.icon(
              onPressed: () => controller.skipToNextSession(),
              icon: const Icon(Icons.skip_next),
              label: const Text('Skip'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  void _showSessionSettingsModal(BuildContext context) {
    final workController = TextEditingController(
      text: controller.settings.value.workTime.toString(),
    );
    final shortBreakController = TextEditingController(
      text: controller.settings.value.shortBreakTime.toString(),
    );
    final longBreakController = TextEditingController(
      text: controller.settings.value.longBreakTime.toString(),
    );
    final sessionsController = TextEditingController(
      text: controller.settings.value.sessionsBeforeLongBreak.toString(),
    );

    final formKey = GlobalKey<FormState>();

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        padding: EdgeInsets.only(
          top: 16,
          left: 16,
          right: 16,
          // Add padding to avoid keyboard
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customize Sessions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              _buildTimerSettingField(
                context: context,
                controller: workController,
                label: 'Work Time (minutes)',
                icon: Icons.work,
                validator: (value) {
                  final time = int.tryParse(value ?? '');
                  if (time == null || time <= 0) {
                    return 'Enter valid time';
                  }
                  return null;
                },
              ),

              _buildTimerSettingField(
                context: context,
                controller: shortBreakController,
                label: 'Short Break (minutes)',
                icon: Icons.coffee,
                validator: (value) {
                  final time = int.tryParse(value ?? '');
                  if (time == null || time <= 0) {
                    return 'Enter valid time';
                  }
                  return null;
                },
              ),

              _buildTimerSettingField(
                context: context,
                controller: longBreakController,
                label: 'Long Break (minutes)',
                icon: Icons.hotel,
                validator: (value) {
                  final time = int.tryParse(value ?? '');
                  if (time == null || time <= 0) {
                    return 'Enter valid time';
                  }
                  return null;
                },
              ),

              _buildTimerSettingField(
                context: context,
                controller: sessionsController,
                label: 'Sessions before long break',
                icon: Icons.repeat,
                validator: (value) {
                  final sessions = int.tryParse(value ?? '');
                  if (sessions == null || sessions <= 0) {
                    return 'Enter valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('CANCEL'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final newSettings = PomodoroSettings(
                          workTime: int.parse(workController.text),
                          shortBreakTime: int.parse(shortBreakController.text),
                          longBreakTime: int.parse(longBreakController.text),
                          sessionsBeforeLongBreak: int.parse(
                            sessionsController.text,
                          ),
                        );

                        controller.updateSettings(newSettings);
                        Get.back();
                      }
                    },
                    child: const Text('SAVE'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerSettingField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
        keyboardType: TextInputType.number,
        validator: validator,
      ),
    );
  }
}
