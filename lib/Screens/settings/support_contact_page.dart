import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SupportContactPage extends StatefulWidget {
  final String userId;

  const SupportContactPage({Key? key, required this.userId}) : super(key: key);

  @override
  _SupportContactPageState createState() => _SupportContactPageState();
}

class _SupportContactPageState extends State<SupportContactPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Save to Firestore
        await FirebaseFirestore.instance.collection('support_messages').add({
          'userId': widget.userId,
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'message': _messageController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'new',
          'adminResponse': null
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message sent successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );

        // Clear form
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Text(
          "Contact Support",
          style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Support Contact Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Get in Touch",
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                        letterSpacing: 1.2
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    _buildTextFormField(
                      controller: _nameController,
                      label: "Name",
                      icon: Icons.person,
                      validator: (value) => value!.isEmpty ? "Please enter your name" : null,
                    ),
                    SizedBox(height: 15),
                    _buildTextFormField(
                      controller: _emailController,
                      label: "Email",
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value!.isEmpty) return "Please enter your email";
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        return !emailRegex.hasMatch(value) ? "Enter a valid email" : null;
                      },
                    ),
                    SizedBox(height: 15),
                    _buildTextFormField(
                      controller: _messageController,
                      label: "Your Message",
                      icon: Icons.message,
                      maxLines: 5,
                      validator: (value) => value!.isEmpty ? "Please enter your message" : null,
                    ),
                    SizedBox(height: 20),
                    _isLoading 
                      ? Center(child: CircularProgressIndicator(color: colorScheme.onSurface))
                      : ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Send Message",
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "We typically respond within 24-48 hours",
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Support Message History
              SizedBox(height: 30),
              Text(
                "Previous Conversations",
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              _buildSupportHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportHistory() {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('support_messages')
          .where('userId', isEqualTo: widget.userId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.onSurface),
          );
        }
        
        var messages = snapshot.data!.docs;
        
        if (messages.isEmpty) {
          return Center(
            child: Text(
              'No previous support messages',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
            ),
          );
        }
        
        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            var message = messages[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // User Message
                Card(
                  color: colorScheme.surfaceVariant,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Message:', 
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.bold
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          message['message'], 
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Sent: ${_formatTimestamp(message['timestamp'])}',
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.5)),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Admin Response (if exists)
                if (message['adminResponse'] != null)
                  Card(
                    color: colorScheme.tertiaryContainer,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Support Response:', 
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            message['adminResponse'], 
                            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: colorScheme.onSurface.withOpacity(0.7)),
        labelText: label,
        labelStyle: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.7)),
        filled: true,
        fillColor: colorScheme.surfaceVariant,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.onSurface.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Unknown date';
    return '${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}