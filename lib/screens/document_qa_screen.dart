import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../services/api_service.dart';
import '../services/app_language.dart' as app_language;

// ============================================================
// BIS SAATHI DOCUMENT Q&A
// ============================================================

class DocumentQAScreen extends StatefulWidget {
  const DocumentQAScreen({super.key});

  @override
  State<DocumentQAScreen> createState() => _DocumentQAScreenState();
}

class _DocumentQAScreenState extends State<DocumentQAScreen> {
  final TextEditingController _questionController = TextEditingController();

  String? _selectedFileName;
  Uint8List? _selectedFileBytes;

  String? _documentId;
  String? _answer;

  List<int> _answerPages = [];
  int _retrievedChunks = 0;

  bool _isUploading = false;
  bool _isAsking = false;

  String? _statusMessage;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get _documentReady {
    return _documentId != null && _documentId!.trim().isNotEmpty;
  }

  // ============================================================
  // PICK PDF
  // ============================================================

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

      if (file.bytes == null || file.bytes!.isEmpty) {
        _showMessage('Could not read the selected PDF.');
        return;
      }

      setState(() {
        _selectedFileName = file.name;
        _selectedFileBytes = Uint8List.fromList(file.bytes!);

        _documentId = null;
        _answer = null;
        _answerPages = [];
        _retrievedChunks = 0;
        _statusMessage = null;
        _questionController.clear();
      });
    } catch (e) {
      _showMessage('Could not select the PDF.');
    }
  }

  // ============================================================
  // PROCESS PDF
  // ============================================================

  Future<void> _processPdf() async {
    if (_selectedFileBytes == null || _selectedFileName == null) {
      _showMessage('Please choose a PDF first.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isUploading = true;
      _documentId = null;
      _answer = null;
      _answerPages = [];
      _retrievedChunks = 0;
      _statusMessage = 'Uploading and processing your PDF...';
    });

    try {
      final result = await ApiService.uploadDocument(
        _selectedFileName!,
        _selectedFileBytes!,
      );

      if (!mounted) {
        return;
      }

      if (result.success && result.documentId.trim().isNotEmpty) {
        setState(() {
          _documentId = result.documentId;
          _isUploading = false;
          _statusMessage =
              'PDF processed successfully. You can now ask questions.';
        });
      } else {
        setState(() {
          _isUploading = false;
          _documentId = null;
          _statusMessage = result.message.isNotEmpty
              ? result.message
              : 'The PDF could not be processed.';
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUploading = false;
        _documentId = null;
        _statusMessage = _friendlyError(e, 'process the PDF');
      });
    }
  }

  // ============================================================
  // ASK QUESTION
  // ============================================================

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();

    if (!_documentReady) {
      _showMessage('Please process the PDF first.');
      return;
    }

    if (question.isEmpty) {
      _showMessage('Please enter a question.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isAsking = true;
      _answer = null;
      _answerPages = [];
      _retrievedChunks = 0;
      _statusMessage = 'Reading the relevant parts of your document...';
    });

    try {
      final language = app_language.AppLanguage.instance.code;

      final result = await ApiService.askDocument(
        _documentId!,
        question,
        language: language,
      );

      if (!mounted) {
        return;
      }

      if (result.success && result.answer.trim().isNotEmpty) {
        setState(() {
          _isAsking = false;
          _answer = result.answer;
          _answerPages = result.pages;
          _retrievedChunks = result.retrievedChunks;
          _statusMessage = 'Answer generated from the uploaded document.';
        });
      } else {
        setState(() {
          _isAsking = false;
          _statusMessage = result.message.isNotEmpty
              ? result.message
              : 'BIS Saathi could not generate an answer.';
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAsking = false;
        _statusMessage = _friendlyError(e, 'answer your document question');
      });
    }
  }

  // ============================================================
  // CHOOSE NEW DOCUMENT
  // ============================================================

  void _chooseNewDocument() {
    setState(() {
      _selectedFileName = null;
      _selectedFileBytes = null;

      _documentId = null;
      _answer = null;

      _answerPages = [];
      _retrievedChunks = 0;

      _statusMessage = null;

      _questionController.clear();
    });
  }

  // ============================================================
  // FRIENDLY ERROR
  // ============================================================

  String _friendlyError(Object error, String operation) {
    final message = error.toString();

    if (message.contains('(404)')) {
      return 'BIS Saathi could not find the document service.';
    }

    if (message.contains('(422)')) {
      return 'The document request could not be understood by the server.';
    }

    if (message.contains('SocketException')) {
      return 'Could not connect to the BIS Saathi server.';
    }

    if (message.contains('TimeoutException')) {
      return 'The request took too long. Please try again.';
    }

    return 'Unable to $operation. Please try again.';
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final language = app_language.AppLanguage.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          language.t('Document Q&A'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF101828),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF101828)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bool isWide = constraints.maxWidth >= 900;

          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 48 : 16,
              vertical: 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _buildUploadCard(context),
                    if (_documentReady) ...[
                      const SizedBox(height: 24),
                      _buildQuestionCard(context),
                    ],
                    if (_answer != null) ...[
                      const SizedBox(height: 24),
                      _buildAnswerCard(context),
                    ],
                    if (_statusMessage != null &&
                        !_documentReady &&
                        !_isUploading) ...[
                      const SizedBox(height: 16),
                      _buildStatusCard(context),
                    ],
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    final language = app_language.AppLanguage.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.description_outlined,
                color: Color(0xFF0B5ED7),
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                language.t('Ask Your BIS Document'),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF101828),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          language.t(
            'Upload a PDF and ask questions naturally. BIS Saathi will find the relevant information and explain it for you.',
          ),
          style: const TextStyle(
            color: Color(0xFF667085),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // UPLOAD CARD
  // ============================================================

  Widget _buildUploadCard(BuildContext context) {
    final language = app_language.AppLanguage.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E7F0)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 6),
            color: Color(0x0D101828),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.picture_as_pdf_outlined,
              color: Color(0xFF0B5ED7),
              size: 40,
            ),
          ),

          const SizedBox(height: 16),

          Text(
            language.t('Upload BIS PDF'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),

          const SizedBox(height: 7),

          Text(
            language.t(
              'Upload a PDF document and ask BIS Saathi anything about its contents.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF667085),
              fontSize: 14,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 20),

          OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickPdf,
            icon: const Icon(Icons.upload_file),
            label: Text(language.t('Choose PDF')),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0B5ED7),
              side: const BorderSide(color: Color(0xFF0B5ED7)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          if (_selectedFileName != null) ...[
            const SizedBox(height: 18),
            _buildSelectedFile(context),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isUploading ? null : _processPdf,
                icon: _isUploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(
                  _isUploading
                      ? language.t('Processing...')
                      : language.t('Process PDF'),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4D67A1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],

          if (_documentReady) ...[
            const SizedBox(height: 18),
            _buildSuccessCard(context),
          ],

          if (_isUploading) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(minHeight: 3),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SELECTED FILE
  // ============================================================

  Widget _buildSelectedFile(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFDCE8FA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf, color: Color(0xFF0B5ED7), size: 27),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              _selectedFileName!,
              style: const TextStyle(fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUCCESS CARD
  // ============================================================

  Widget _buildSuccessCard(BuildContext context) {
    final language = app_language.AppLanguage.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEFFAF3),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFCDEBD8)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF16A34A)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  language.t(
                    'PDF processed successfully. You can now ask questions.',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF166534),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _chooseNewDocument,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(language.t('Choose New Document')),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUESTION CARD
  // ============================================================

  Widget _buildQuestionCard(BuildContext context) {
    final language = app_language.AppLanguage.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E7F0)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 6),
            color: Color(0x0D101828),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.question_answer_outlined,
                  color: Color(0xFF0B5ED7),
                ),
              ),
              const SizedBox(width: 11),
              Text(
                language.t('Ask a Question'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          TextField(
            controller: _questionController,
            enabled: !_isAsking,
            minLines: 3,
            maxLines: 7,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: language.t('Ask anything about this document...'),
              hintStyle: const TextStyle(color: Color(0xFF98A2B3)),
              filled: true,
              fillColor: const Color(0xFFF8FAFD),
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E7F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E7F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF0B5ED7),
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 13),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isAsking ? null : _askQuestion,
              icon: _isAsking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.arrow_upward),
              label: Text(
                _isAsking
                    ? language.t('Generating...')
                    : language.t('Ask Question'),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4D67A1),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          if (_isAsking) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _statusMessage ??
                        'Reading the relevant parts of your document...',
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ANSWER CARD
  // ============================================================

  Widget _buildAnswerCard(BuildContext context) {
    final language = app_language.AppLanguage.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E7F0)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 6),
            color: Color(0x0D101828),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFF0B5ED7)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  language.t('BIS Saathi Answer'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ======================================================
          // IMPORTANT:
          // MarkdownBody renders **bold**, lists, headings, etc.
          // ======================================================
          MarkdownBody(
            data: _answer!,
            selectable: true,
            styleSheet: MarkdownStyleSheet(
              p: const TextStyle(
                fontSize: 16,
                height: 1.65,
                color: Color(0xFF344054),
              ),
              h1: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF101828),
                height: 1.3,
              ),
              h2: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF101828),
                height: 1.35,
              ),
              h3: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF101828),
                height: 1.4,
              ),
              strong: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF101828),
              ),
              listBullet: const TextStyle(
                fontSize: 16,
                color: Color(0xFF0B5ED7),
              ),
              blockquote: const TextStyle(
                color: Color(0xFF667085),
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),

          if (_answerPages.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildPageReferences(context),
          ],

          if (_retrievedChunks > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Retrieved $_retrievedChunks relevant document section(s).',
              style: const TextStyle(color: Color(0xFF98A2B3), fontSize: 12),
            ),
          ],

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Color(0xFF667085),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    language.t(
                      'Answer generated from the uploaded document. Verify important decisions against the original document.',
                    ),
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAGE REFERENCES
  // ============================================================

  Widget _buildPageReferences(BuildContext context) {
    final language = app_language.AppLanguage.of(context);

    final pages = [..._answerPages]..sort();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFDCE8FA)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Text(
            language.t('Relevant Pages'),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF344054),
            ),
          ),
          ...pages.map(
            (page) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFDCE8FA)),
              ),
              child: Text(
                'Page $page',
                style: const TextStyle(
                  color: Color(0xFF0B5ED7),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CARD
  // ============================================================

  Widget _buildStatusCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFEA580C)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _statusMessage!,
              style: const TextStyle(color: Color(0xFF9A3412), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
