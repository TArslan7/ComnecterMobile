import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final List<String> joinedCommunities = <String>[
    'Flutter Devs',
    'Comnecter Beta Testers',
    'Amsterdam Tech',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary, size: 24),
          onPressed: () => context.push('/settings'),
          tooltip: 'Settings',
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Theme.of(context).colorScheme.primary, size: 24),
            onPressed: () => context.push('/notifications'),
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: Icon(Icons.people, color: Theme.of(context).colorScheme.primary, size: 24),
            onPressed: () => context.push('/friends'),
            tooltip: 'Friends',
          ),
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary, size: 24),
            tooltip: 'Search communities',
            onPressed: _showSearchComingSoon,
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: Icon(Icons.group_add, color: Theme.of(context).colorScheme.primary),
            tooltip: 'Create community',
            onPressed: _openCreateCommunitySheet,
            padding: const EdgeInsets.all(8),
          ),
        ],
      ),
      body: joinedCommunities.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: joinedCommunities.length,
              itemBuilder: (context, index) {
                final name = joinedCommunities[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.groups, color: Theme.of(context).colorScheme.primary),
                    ),
                    title: Text(name),
                    subtitle: const Text('Tap to open (coming soon)'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showOpenComingSoon,
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateCommunitySheet,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Icon(Icons.groups),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: Colors.white,
              size: 60,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No communities yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Search for a community or create your own',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  void _openCreateCommunitySheet() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Create Community',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Community name',
                  hintText: 'e.g., Flutter Amsterdam',
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check),
                  label: const Text('Create'),
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a community name.')),
                      );
                      return;
                    }
                    setState(() {
                      joinedCommunities.insert(0, name);
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(content: Text('Community "$name" created')),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      descriptionController.dispose();
    });
  }

  void _showSearchComingSoon() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Communities'),
        content: const Text('Community search is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showOpenComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening community is coming soon!')),
    );
  }
}


