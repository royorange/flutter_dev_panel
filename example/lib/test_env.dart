import 'package:flutter/material.dart';
import 'package:flutter_dev_panel/flutter_dev_panel.dart';

class TestEnvPage extends StatelessWidget {
  const TestEnvPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Environment Test'),
      ),
      body: ListenableBuilder(
        listenable: EnvironmentManager.instance,
        builder: (context, _) {
          final manager = EnvironmentManager.instance;
          final environments = manager.environments;
          final current = manager.currentEnvironment;
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Environment Status',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Text('Total Environments: ${environments.length}'),
                      Text('Current: ${current?.name ?? "None"}'),
                      const SizedBox(height: 16),
                      Text('Available Environments:'),
                      ...environments.map((env) => Padding(
                        padding: const EdgeInsets.only(left: 16, top: 4),
                        child: Text('• ${env.name} (${env.variables.length} variables)'),
                      )),
                    ],
                  ),
                ),
              ),
              
              if (current != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Environment Variables',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        ...current.variables.entries.map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 150,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                child: SelectableText(
                                  entry.value.toString(),
                                  style: const TextStyle(fontFamily: 'monospace'),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Test loading from .env files
              ElevatedButton(
                onPressed: () async {
                  debugPrint('Reinitializing environment...');
                  await EnvironmentManager.instance.initialize(
                    loadFromEnvFiles: true,
                    environments: [
                      const EnvironmentConfig(
                        name: 'Fallback',
                        variables: {'source': 'code'},
                      ),
                    ],
                  );
                  debugPrint('Reinitialization complete');
                },
                child: const Text('Reload Environments'),
              ),
            ],
          );
        },
      ),
    );
  }
}