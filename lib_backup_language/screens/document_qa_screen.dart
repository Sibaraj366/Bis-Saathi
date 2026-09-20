import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';

class DocumentQAScreen extends StatefulWidget {
  const DocumentQAScreen({super.key});

  @override
  State<DocumentQAScreen> createState() => _DocumentQAScreenState();
}

class _DocumentQAScreenState extends State<DocumentQAScreen> {
  final TextEditingController _questionController = TextEditingController();

  String? _selectedFileName;
  List<int>? _selectedFileBytes;

  String? _documentId;
  String? _answer;

  bool _isUploading = false;
  bool _isAsking = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // Choose PDF
  // ------------------------------------------------------------

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null) {
        return;
      }

      final file = result.files.single;

      if (file.bytes == null) {
        _showMessage('Could not read the selected PDF.');
        return;
      }

      setState(() {
        _selectedFileName = file.name;
        _selectedFileBytes = file.bytes;

        _documentId = null;
        _answer = null;
      });
    } catch (e) {
      _showMessage('Could not select the PDF.');
    }
  }

  // ------------------------------------------------------------
  // Upload PDF
  // ------------------------------------------------------------

  Future<void> _uploadPdf() async {
    if (_selectedFileBytes == null || _selectedFileName == null) {
      _showMessage('Please choose a PDF first.');
      return;
    }

    setState(() {
      _isUploading = true;
      _documentId = null;
      _answer = null;
    });

    final result = await ApiService.uploadDocument(
      _selectedFileBytes!,
      _selectedFileName!,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isUploading = false;
    });

    if (result.success && result.documentId != null) {
      setState(() {
        _documentId = result.documentId;
      });

      _showMessage('PDF processed successfully.');
    } else {
      _showMessage(result.message);
    }
  }

  // ------------------------------------------------------------
  // Ask Question
  // ------------------------------------------------------------

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();

    if (_documentId == null) {
      _showMessage('Please process the PDF first.');
      return;
    }

    if (question.isEmpty) {
      _showMessage('Please enter a question.');
      return;
    }

    setState(() {
      _isAsking = true;
      _answer = null;
    });

    final result = await ApiService.askDocument(_documentId!, question);

    if (!mounted) {
      return;
    }

    setState(() {
      _isAsking = false;
      _answer = result.success ? result.answer : result.message;
    });
  }

  // ------------------------------------------------------------
  // Choose another document
  // ------------------------------------------------------------

  void _chooseNewDocument() {
    setState(() {
      _selectedFileName = null;
      _selectedFileBytes = null;
      _documentId = null;
      _answer = null;
      _questionController.clear();
    });
  }

  // ------------------------------------------------------------
  // Snackbar
  // ------------------------------------------------------------

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Document Q&A',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Ask Your BIS Document',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Upload a BIS document and ask questions about its contents.',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),

            const SizedBox(height: 25),

            // ------------------------------------------------
            // Upload Card
            // ------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E7F0)),
              ),

              child: Column(
                children: [
                  const Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 55,
                    color: Color(0xFF0B5ED7),
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Upload BIS PDF',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'PDF documents will be processed for Q&A.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),

                  const SizedBox(height: 20),

                  FilledButton.icon(
                    onPressed: _isUploading ? null : _pickPdf,

                    icon: const Icon(Icons.upload_file),

                    label: const Text('Choose PDF'),
                  ),

                  // Selected file
                  if (_selectedFileName != null) ...[
                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),

                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F8FF),
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: Row(
                        children: [
                          const Icon(
                            Icons.picture_as_pdf,
                            color: Color(0xFF0B5ED7),
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              _selectedFileName!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Process button
                    SizedBox(
                      width: double.infinity,

                      child: FilledButton.icon(
                        onPressed: _isUploading ? null : _uploadPdf,

                        icon: _isUploading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.cloud_upload),

                        label: Text(
                          _isUploading ? 'Processing...' : 'Process PDF',
                        ),
                      ),
                    ),
                  ],

                  // Success message
                  if (_documentId != null) ...[
                    const SizedBox(height: 18),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),

                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFAF3),
                        borderRadius: BorderRadius.circular(12),
                      ),

                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),

                          SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              'PDF processed successfully. You can now ask questions.',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton.icon(
                      onPressed: _chooseNewDocument,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Choose New Document'),
                    ),
                  ],
                ],
              ),
            ),

            // ------------------------------------------------
            // Question section
            // ------------------------------------------------
            if (_documentId != null) ...[
              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E7F0)),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Row(
                      children: [
                        Icon(Icons.question_answer, color: Color(0xFF0B5ED7)),

                        SizedBox(width: 10),

                        Text(
                          'Ask a Question',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: _questionController,

                      minLines: 3,
                      maxLines: 5,

                      decoration: InputDecoration(
                        hintText:
                            'Example: What does this document say about certification requirements?',

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,

                      child: FilledButton.icon(
                        onPressed: _isAsking ? null : _askQuestion,

                        icon: _isAsking
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),

                        label: Text(
                          _isAsking ? 'Asking BIS Saathi...' : 'Ask Question',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // ------------------------------------------------
            // Answer
            // ------------------------------------------------
            if (_answer != null) ...[
              const SizedBox(height: 25),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E7F0)),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Color(0xFF0B5ED7)),

                        SizedBox(width: 10),

                        Text(
                          'BIS Saathi Answer',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 15),

                    Text(
                      _answer!,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
