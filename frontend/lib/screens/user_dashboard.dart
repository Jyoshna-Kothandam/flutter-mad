import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const UserHomeTab(),
    const SearchTab(),
    const UserRequestsTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('eCop - Citizen', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Theme.of(context).colorScheme.primary, Colors.lightBlue],
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
            BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.mail_outline), activeIcon: Icon(Icons.mail), label: 'My Requests'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class UserHomeTab extends StatefulWidget {
  const UserHomeTab({super.key});

  @override
  State<UserHomeTab> createState() => _UserHomeTabState();
}

class _UserHomeTabState extends State<UserHomeTab> {
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return const Center(child: Text('No available items right now.'));

    return RefreshIndicator(
      onRefresh: _fetchItems,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          return ItemCard(item: item);
        },
      ),
    );
  }
}

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final ApiService _api = ApiService();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<dynamic> _items = [];
  bool _isLoading = false;

  final List<String> _categories = ['All', 'Mobile', 'Wallet', 'Vehicle', 'Person', 'Others'];

  Future<void> _performSearch() async {
    setState(() => _isLoading = true);
    final items = await _api.getItems(category: _selectedCategory == 'All' ? null : _selectedCategory);
    setState(() {
      _items = items.where((i) {
        bool matchesQuery = i['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            i['location'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
        return matchesQuery;
      }).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
          ),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name or location...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: (val) {
                  _searchQuery = val;
                  _performSearch();
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = cat);
                            _performSearch();
                          }
                        },
                        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )
            ],
          ),
        ),
        Expanded(
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _items.isEmpty 
                  ? const Center(child: Text('No results found.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      itemBuilder: (context, index) => ItemCard(item: _items[index]),
                    ),
        )
      ],
    );
  }
}

class ItemCard extends StatelessWidget {
  final dynamic item;
  const ItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ItemDetailScreen(item: item))),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
        shadowColor: Colors.black12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'item_img_${item['id']}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: item['image'] != null
                    ? Container(
                        color: Colors.black12,
                        height: 180,
                        width: double.infinity,
                        child: Image.network(item['image'], fit: BoxFit.contain,
                          errorBuilder: (c, e, s) => const Icon(Icons.image, size: 50)),
                      )
                    : Container(color: Colors.grey[200], height: 180, child: const Icon(Icons.image, size: 50)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(8)),
                            child: Text(item['category'], style: TextStyle(color: Colors.blue[800], fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                          Text(
                            item['location'].length > 15 
                                ? '${item['location'].substring(0, 15)}...' 
                                : item['location'], 
                            style: TextStyle(color: Colors.grey[600])
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: item['status'] == 'Available' ? Colors.green[100] : Colors.orange[100], 
                          borderRadius: BorderRadius.circular(8)
                        ),
                        child: Text(item['status'], style: TextStyle(
                          color: item['status'] == 'Available' ? Colors.green[800] : Colors.orange[800], 
                          fontSize: 12, fontWeight: FontWeight.bold
                        )),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class ItemDetailScreen extends StatefulWidget {
  final dynamic item;
  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final _messageController = TextEditingController();
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isSending = false;
  XFile? _proofImage;

  Future<void> _pickProofImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _proofImage = pickedFile);
    }
  }

  Future<void> _sendRequest() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a message')));
      return;
    }
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a proof image to claim this item.')));
      return;
    }
    
    setState(() => _isSending = true);
    final success = await _api.sendRequest(widget.item['id'], _messageController.text, _proofImage!);
    setState(() => _isSending = false);
    
    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Claim Request Sent Successfully!')));
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send request')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> details = widget.item['details'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Item Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Colors.lightBlue]),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'item_img_${widget.item['id']}',
              child: widget.item['image'] != null
                  ? Container(
                      color: Colors.black12,
                      height: 250,
                      width: double.infinity,
                      child: Image.network(widget.item['image'], fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => const Icon(Icons.image, size: 80)),
                    )
                  : Container(color: Colors.grey[200], height: 250, child: const Icon(Icons.image, size: 80)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(widget.item['name'], style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.item['status'] == 'Available' ? Colors.green[100] : Colors.orange[100], 
                          borderRadius: BorderRadius.circular(20)
                        ),
                        child: Text(widget.item['status'], style: TextStyle(
                          color: widget.item['status'] == 'Available' ? Colors.green[800] : Colors.orange[800], 
                          fontSize: 14, fontWeight: FontWeight.bold
                        )),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.category, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text('Category: ${widget.item['category']}', style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text('Found at: ${widget.item['location']}', style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.local_police, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text('Reporting Station: ${widget.item['reporting_station'] ?? 'N/A'}', style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                      const SizedBox(width: 8),
                      Text('Date Found: ${widget.item['date_found']}', style: TextStyle(fontSize: 16, color: Colors.grey[800])),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  if (details.isNotEmpty) ...[
                    const Text('Specific Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: details.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                              Expanded(flex: 3, child: Text(e.value.toString(), style: const TextStyle(color: Colors.black54))),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  const Text('General Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.item['description'], style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
                  
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  
                  if (widget.item['status'] == 'Available') ...[
                    const Text('Claim this Item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Please upload a proof of ownership (e.g., photo of original receipt, ID card, or clear photo of the missing person) to proceed.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    
                    GestureDetector(
                      onTap: _pickProofImage,
                      child: Container(
                        height: 120,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                        ),
                        child: _proofImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14), 
                                child: kIsWeb 
                                  ? Image.network(_proofImage!.path, fit: BoxFit.cover) 
                                  : Image.file(File(_proofImage!.path), fit: BoxFit.cover)
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.upload_file, size: 40, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                                  const SizedBox(height: 8),
                                  const Text('Upload Proof Image', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        labelText: 'Message to Police',
                        hintText: 'Provide any additional details...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Colors.blueAccent]),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        onPressed: _isSending ? null : _sendRequest,
                        child: _isSending 
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                            : const Text('Submit Claim Request', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange[200]!)),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 12),
                          Expanded(child: Text('This item has already been claimed or verified and is no longer available.', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class UserRequestsTab extends StatefulWidget {
  const UserRequestsTab({super.key});

  @override
  State<UserRequestsTab> createState() => _UserRequestsTabState();
}

class _UserRequestsTabState extends State<UserRequestsTab> {
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
    if (_requests.isEmpty) return const Center(child: Text('You have not made any requests.'));

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
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text('Item: ${req['item_name']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text('"${req['message']}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                  Text('Requested on: ${req['created_at'].toString().substring(0, 10)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              trailing: Container(
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
            ),
          );
        },
      ),
    );
  }
}

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Colors.lightBlue]),
              ),
              child: const CircleAvatar(radius: 60, backgroundColor: Colors.white, child: Icon(Icons.person, size: 60, color: Colors.blue)),
            ),
            const SizedBox(height: 24),
            Text(auth.username.toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(20)),
              child: Text(auth.role.toUpperCase(), style: TextStyle(fontSize: 14, color: Colors.blue[800], fontWeight: FontWeight.bold)),
            ),
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
