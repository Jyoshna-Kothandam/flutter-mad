import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class PoliceDashboard extends StatefulWidget {
  const PoliceDashboard({super.key});

  @override
  State<PoliceDashboard> createState() => _PoliceDashboardState();
}

class _PoliceDashboardState extends State<PoliceDashboard> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const PoliceHomeTab(),
    const AddItemTab(),
    const PoliceRequestsTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Police Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).colorScheme.primary, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), activeIcon: Icon(Icons.add_box), label: 'Add Item'),
            BottomNavigationBarItem(icon: Icon(Icons.mail_outline), activeIcon: Icon(Icons.mail), label: 'Requests'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class PoliceHomeTab extends StatefulWidget {
  const PoliceHomeTab({super.key});

  @override
  State<PoliceHomeTab> createState() => _PoliceHomeTabState();
}

class _PoliceHomeTabState extends State<PoliceHomeTab> {
  final ApiService _api = ApiService();
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    final items = await _api.getItems();
    setState(() {
      _items = items;
      _isLoading = false;
    });
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Available': return Colors.green;
      case 'Claimed': return Colors.orange;
      case 'Verified': return Colors.blue;
      default: return Colors.grey;
    }
  }

  Future<void> _confirmDelete(int itemId) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Delete', style: TextStyle(color: Colors.white))
          ),
        ],
      )
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final success = await _api.deleteItem(itemId);
      if (success) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item deleted successfully')));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete item')));
      }
      _fetchItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return const Center(child: Text('No items uploaded yet.'));

    return RefreshIndicator(
      onRefresh: _fetchItems,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          final statusColor = _getStatusColor(item['status']);
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: Colors.black12,
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item['image'] != null 
                    ? Container(
                        color: Colors.black12,
                        width: 60, height: 60,
                        child: Image.network(item['image'], fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(Icons.image)),
                      )
                    : Container(color: Colors.grey[200], width: 60, height: 60, child: const Icon(Icons.image)),
              ),
              title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('${item['category']} • ${item['location']}'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      item['status'],
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'Delete') {
                    _confirmDelete(item['id']);
                  } else {
                    await _api.updateItemStatus(item['id'], value);
                    _fetchItems();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'Available', child: Text('Mark Available')),
                  PopupMenuItem(value: 'Claimed', child: Text('Mark Claimed')),
                  PopupMenuItem(value: 'Verified', child: Text('Mark Verified')),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'Delete', child: Text('Delete Item', style: TextStyle(color: Colors.red))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class AddItemTab extends StatefulWidget {
  const AddItemTab({super.key});

  @override
  State<AddItemTab> createState() => _AddItemTabState();
}

class _AddItemTabState extends State<AddItemTab> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  
  String _name = '';
  String _category = 'Mobile';
  String _description = '';
  String _location = '';
  String _reportingStation = '';
  String _dateFound = DateTime.now().toIso8601String().split('T')[0];
  XFile? _image;
  bool _isUploading = false;
  
  Map<String, String> _details = {};

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields and pick an image')));
      return;
    }
    _formKey.currentState!.save();
    
    setState(() => _isUploading = true);
    final success = await _api.uploadItem(_name, _category, _description, _location, _reportingStation, _dateFound, _image!, _details);
    setState(() => _isUploading = false);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item uploaded successfully')));
      _formKey.currentState!.reset();
      setState(() {
        _image = null;
        _details.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload failed')));
    }
  }

  List<Widget> _buildDynamicFields() {
    List<String> fields = [];
    if (_category == 'Mobile') {
      fields = ['Brand', 'Color', 'IMEI or Serial Number'];
    } else if (_category == 'Person') {
      fields = ['Height', 'Build', 'Complexion', 'Clothing Description'];
    } else if (_category == 'Vehicle') {
      fields = ['Make', 'Model', 'Color', 'License Plate'];
    } else {
      fields = ['Color', 'Identifying Marks'];
    }

    return fields.map((field) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: TextFormField(
          decoration: InputDecoration(
            labelText: field,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onSaved: (value) => _details[field] = value ?? '',
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14), 
                        child: Container(
                          color: Colors.black12,
                          child: kIsWeb 
                            ? Image.network(_image!.path, fit: BoxFit.contain) 
                            : Image.file(File(_image!.path), fit: BoxFit.contain),
                        )
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          const Text('Tap to upload photo', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Name / Title', 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: Colors.grey[50],
              ),
              validator: (value) => value!.isEmpty ? 'Enter name' : null,
              onSaved: (value) => _name = value!,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Category', 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: Colors.grey[50],
              ),
              value: _category,
              items: ['Mobile', 'Wallet', 'Vehicle', 'Person', 'Others'].map((cat) {
                return DropdownMenuItem(value: cat, child: Text(cat));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _category = val!;
                  _details.clear();
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Category Specific Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            ..._buildDynamicFields(),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'General Description', 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: Colors.grey[50],
              ),
              maxLines: 3,
              validator: (value) => value!.isEmpty ? 'Enter description' : null,
              onSaved: (value) => _description = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Location Found', 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.location_on),
              ),
              validator: (value) => value!.isEmpty ? 'Enter location' : null,
              onSaved: (value) => _location = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Reporting Police Station', 
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true, fillColor: Colors.grey[50],
                prefixIcon: const Icon(Icons.local_police),
              ),
              validator: (value) => value!.isEmpty ? 'Enter police station' : null,
              onSaved: (value) => _reportingStation = value!,
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Colors.blueAccent]),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                ),
                onPressed: _isUploading ? null : _submit,
                child: _isUploading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                    : const Text('Submit Record', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class PoliceRequestsTab extends StatefulWidget {
  const PoliceRequestsTab({super.key});

  @override
  State<PoliceRequestsTab> createState() => _PoliceRequestsTabState();
}

class _PoliceRequestsTabState extends State<PoliceRequestsTab> {
  final ApiService _api = ApiService();
  List<dynamic> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    final requests = await _api.getRequests();
    setState(() {
      _requests = requests;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_requests.isEmpty) return const Center(child: Text('No requests yet.'));

    return RefreshIndicator(
      onRefresh: _fetchRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final req = _requests[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: Colors.black12,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('Claim by: ${req['user_name']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  const Divider(),
                  Text('Item: ${req['item_name']}', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  if (req['proof_image'] != null)
                    GestureDetector(
                      onTap: () => _showImageDialog(context, req['proof_image']),
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Center(child: Image.network(req['proof_image'], fit: BoxFit.contain)),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                                child: const Text('Tap to view proof', style: TextStyle(color: Colors.white, fontSize: 10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                    child: Text('"${req['message']}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: req['status'] == 'Pending' ? Colors.orange[100] : (req['status'] == 'Accepted' ? Colors.green[100] : Colors.red[100]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(req['status'], style: TextStyle(
                          color: req['status'] == 'Pending' ? Colors.orange[800] : (req['status'] == 'Accepted' ? Colors.green[800] : Colors.red[800]),
                          fontWeight: FontWeight.bold,
                        )),
                      ),
                      if (req['status'] == 'Pending')
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
                              onPressed: () async {
                                await _api.updateRequestStatus(req['id'], 'Accepted');
                                _fetchRequests();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                              onPressed: () async {
                                await _api.updateRequestStatus(req['id'], 'Rejected');
                                _fetchRequests();
                              },
                            ),
                          ],
                        )
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: InteractiveViewer(child: Container(color: Colors.black, child: Image.network(imageUrl, fit: BoxFit.contain))),
        ),
      ),
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final ApiService _api = ApiService();
  bool _showStats = false;
  bool _isLoadingStats = false;
  Map<String, dynamic>? _stats;

  Future<void> _fetchStats() async {
    setState(() {
      _showStats = !_showStats;
      if (_showStats && _stats == null) {
        _isLoadingStats = true;
      }
    });

    if (_showStats && _stats == null) {
      final stats = await _api.getPoliceStats();
      setState(() {
        _stats = stats;
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Colors.blueAccent]),
              ),
              child: const CircleAvatar(radius: 60, backgroundColor: Colors.white, child: Icon(Icons.local_police, size: 60, color: Colors.blue)),
            ),
            const SizedBox(height: 24),
            Text(auth.username.toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
              child: Text(auth.role.toUpperCase(), style: TextStyle(fontSize: 14, color: Colors.blue[800], fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: _fetchStats, 
              icon: Icon(_showStats ? Icons.visibility_off : Icons.bar_chart), 
              label: Text(_showStats ? 'Hide My Statistics' : 'View My Statistics'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            
            if (_showStats) ...[
              const SizedBox(height: 16),
              if (_isLoadingStats) 
                const CircularProgressIndicator()
              else if (_stats != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: Column(
                    children: [
                      _StatRow(title: 'Items Uploaded', value: _stats!['uploaded_items'].toString(), icon: Icons.upload_file, color: Colors.blue),
                      const Divider(height: 24),
                      _StatRow(title: 'Claims Accepted', value: _stats!['accepted_claims'].toString(), icon: Icons.check_circle, color: Colors.green),
                      const Divider(height: 24),
                      _StatRow(title: 'Claims Rejected', value: _stats!['rejected_claims'].toString(), icon: Icons.cancel, color: Colors.red),
                    ],
                  ),
                )
              else
                const Text('Failed to load stats', style: TextStyle(color: Colors.red)),
            ],

            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
                elevation: 0,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatRow({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
