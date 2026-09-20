import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' as m;

class AppLanguage extends ChangeNotifier {
  AppLanguage._();

  static final AppLanguage instance = AppLanguage._();

  String _code = 'English';

  String get code => _code;

  static const List<String> supported = <String>['English', 'Hindi', 'Marathi'];

  void setLanguage(String language) {
    if (!supported.contains(language) || language == _code) {
      return;
    }

    _code = language;
    notifyListeners();
  }

  static AppLanguage of(m.BuildContext context) {
    final inherited = context
        .dependOnInheritedWidgetOfExactType<_LanguageScope>();

    return inherited?.language ?? instance;
  }

  String get label {
    switch (_code) {
      case 'Hindi':
        return 'हिंदी';
      case 'Marathi':
        return 'मराठी';
      default:
        return 'English';
    }
  }

  String t(String value) {
    return _translations[_code]?[value] ?? value;
  }

  static const Map<String, Map<String, String>>
  _translations = <String, Map<String, String>>{
    'Hindi': <String, String>{
      'Home': 'होम',
      'Assistant': 'सहायक',
      'Standards': 'मानक',
      'Compliance': 'अनुपालन',
      'Services': 'सेवाएँ',
      'Profile': 'प्रोफ़ाइल',
      'Smart BIS Assistant': 'स्मार्ट BIS सहायक',
      'Bureau of Indian Standards': 'भारतीय मानक ब्यूरो',
      'Select language': 'भाषा चुनें',
      'New conversation': 'नई बातचीत',
      'AI Assistant': 'AI सहायक',
      'Standard Finder': 'मानक खोजक',
      'Standard Details': 'मानक विवरण',
      'Compliance Assistant': 'अनुपालन सहायक',
      'Compliance Checklist': 'अनुपालन चेकलिस्ट',
      'Document Q&A': 'दस्तावेज़ प्रश्नोत्तर',
      'BIS Services': 'BIS सेवाएँ',
      'Find Standards': 'मानक खोजें',
      'Find a Standard': 'मानक खोजें',
      'Find Standard': 'मानक खोजें',
      'Search': 'खोजें',
      'Clear': 'साफ़ करें',
      'View Details': 'विवरण देखें',
      'All Categories': 'सभी श्रेणियाँ',
      'All Industries': 'सभी उद्योग',
      'Relevance': 'प्रासंगिकता',
      'A-Z': 'A-Z',
      'IS Number': 'IS संख्या',
      'Category': 'श्रेणी',
      'Industry': 'उद्योग',
      'Product': 'उत्पाद',
      'Certification': 'प्रमाणीकरण',
      'Certification requirements': 'प्रमाणीकरण आवश्यकताएँ',
      'Mandatory Certification': 'अनिवार्य प्रमाणीकरण',
      'Compulsory Certification': 'अनिवार्य प्रमाणीकरण',
      'Ask Questions': 'प्रश्न पूछें',
      'Ask BIS Saathi': 'BIS Saathi से पूछें',
      'Ask Question': 'प्रश्न पूछें',
      'Ask AI about this standard': 'इस मानक के बारे में AI से पूछें',
      'Check Compliance': 'अनुपालन जाँचें',
      'Generate Checklist': 'चेकलिस्ट बनाएँ',
      'Quick Actions': 'त्वरित कार्रवाइयाँ',
      'Quick Access': 'त्वरित पहुँच',
      'Your BIS Activity': 'आपकी BIS गतिविधि',
      'Official BIS Source': 'आधिकारिक BIS स्रोत',
      'Official BIS Sources': 'आधिकारिक BIS स्रोत',
      'Standard Information': 'मानक जानकारी',
      'Standard Number': 'मानक संख्या',
      'What this standard covers': 'यह मानक क्या कवर करता है',
      'Upload BIS PDF': 'BIS PDF अपलोड करें',
      'Upload a BIS PDF and ask questions.':
          'BIS PDF अपलोड करें और प्रश्न पूछें।',
      'Choose PDF': 'PDF चुनें',
      'Choose New Document': 'नया दस्तावेज़ चुनें',
      'Process PDF': 'PDF संसाधित करें',
      'Processing...': 'संसाधित हो रहा है...',
      'Generating...': 'बनाया जा रहा है...',
      'Ask Your BIS Document': 'अपने BIS दस्तावेज़ से पूछें',
      'Try asking': 'पूछकर देखें',
      'Search standards...': 'मानक खोजें...',
      'Ask anything about BIS...': 'BIS के बारे में कुछ भी पूछें...',
      'Apply for BIS Licence': 'BIS लाइसेंस के लिए आवेदन करें',
      'Renew BIS Licence': 'BIS लाइसेंस नवीनीकृत करें',
      'eBIS / Manakonline': 'eBIS / Manakonline',
      'BIS Care App': 'BIS Care ऐप',
      'Consumer Complaints': 'उपभोक्ता शिकायतें',
      'BIS Training': 'BIS प्रशिक्षण',
      'Dashboard': 'डैशबोर्ड',
      'Profile settings coming soon.': 'प्रोफ़ाइल सेटिंग्स जल्द उपलब्ध होंगी।',
      'AI Questions': 'AI प्रश्न',
      'Standards Viewed': 'देखे गए मानक',
      'Documents': 'दस्तावेज़',
      'Checklist Items': 'चेकलिस्ट आइटम',
      'Example: Cement or PVC Insulated Electric Cables':
          'उदाहरण: Cement या PVC Insulated Electric Cables',
      'Example: What does this document say about certification requirements?':
          'उदाहरण: यह दस्तावेज़ प्रमाणीकरण आवश्यकताओं के बारे में क्या कहता है?',
      'Please enter a product name first.':
          'कृपया पहले उत्पाद का नाम दर्ज करें।',
      'Please enter a question.': 'कृपया प्रश्न दर्ज करें।',
      'Please choose a PDF first.': 'कृपया पहले PDF चुनें।',
      'Please process the PDF first.': 'कृपया पहले PDF संसाधित करें।',
      'Could not open the BIS source.': 'BIS स्रोत नहीं खोला जा सका।',
      'Could not connect to BIS Saathi server.':
          'BIS Saathi सर्वर से कनेक्ट नहीं हो सका।',
      'Could not select the PDF.': 'PDF चयनित नहीं की जा सकी।',
      'Could not read the selected PDF.': 'चयनित PDF पढ़ी नहीं जा सकी।',
      'Please try again.': 'कृपया फिर से प्रयास करें।',
      'No standards found.': 'कोई मानक नहीं मिला।',
      'Try another product, keyword or IS number.':
          'कोई अन्य उत्पाद, कीवर्ड या IS संख्या आज़माएँ।',
      'Ask about IS numbers and product standards.':
          'IS संख्याओं और उत्पाद मानकों के बारे में पूछें।',
      'Understand BIS certification information.':
          'BIS प्रमाणीकरण की जानकारी समझें।',
      'Get guidance using the BIS knowledge base.':
          'BIS ज्ञान आधार से मार्गदर्शन प्राप्त करें।',
      'What is BIS certification?': 'BIS प्रमाणीकरण क्या है?',
      'How can I apply for BIS certification?':
          'मैं BIS प्रमाणीकरण के लिए आवेदन कैसे कर सकता हूँ?',
      'What BIS standard applies to cement?':
          'सीमेंट पर कौन सा BIS मानक लागू है?',
      'What is IS 269:2015?': 'IS 269:2015 क्या है?',
      'Ask about an IS number, a product standard,':
          'IS संख्या या उत्पाद मानक के बारे में पूछें,',
      'Search and explore Indian Standards.':
          'भारतीय मानकों को खोजें और देखें।',
      'Search by product, industry, standard number or keyword.':
          'उत्पाद, उद्योग, मानक संख्या या कीवर्ड से खोजें।',
      'Access important BIS services and official resources.':
          'महत्वपूर्ण BIS सेवाओं और आधिकारिक संसाधनों तक पहुँचें।',
      'Access important official BIS services.':
          'महत्वपूर्ण आधिकारिक BIS सेवाओं तक पहुँचें।',
      'Open Official Service': 'आधिकारिक सेवा खोलें',
      'One BIS companion': 'एक BIS साथी',
      'Built around official BIS information': 'आधिकारिक BIS जानकारी पर आधारित',
      'AI-Powered BIS Assistant': 'AI-संचालित BIS सहायक',
      'AI-assisted BIS response': 'AI-सहायित BIS उत्तर',
      'BIS Saathi Answer': 'BIS Saathi उत्तर',
      'BIS Saathi Guidance': 'BIS Saathi मार्गदर्शन',
      'BIS Saathi is checking its knowledge base...':
          'BIS Saathi अपने ज्ञान आधार की जाँच कर रहा है...',
      'Retrieving relevant BIS information':
          'प्रासंगिक BIS जानकारी प्राप्त की जा रही है...',
      'BIS Saathi could not generate an answer.':
          'BIS Saathi उत्तर उत्पन्न नहीं कर सका।',
      'Verify important compliance decisions against current official BIS information.':
          'महत्वपूर्ण अनुपालन निर्णयों को वर्तमान आधिकारिक BIS जानकारी से सत्यापित करें।',
      'Always verify important compliance decisions using current official BIS information.':
          'महत्वपूर्ण अनुपालन निर्णयों को हमेशा वर्तमान आधिकारिक BIS जानकारी से सत्यापित करें।',
      'Generate a product compliance checklist.':
          'उत्पाद अनुपालन चेकलिस्ट बनाएँ।',
      'Access official services': 'आधिकारिक सेवाओं तक पहुँचें',
      'Search IS standards': 'IS मानक खोजें',
      'Check product requirements': 'उत्पाद आवश्यकताएँ जाँचें',
      'Ask questions from PDFs': 'PDF से प्रश्न पूछें',
      'Frequently used BIS Saathi features.':
          'BIS Saathi की अक्सर उपयोग की जाने वाली सुविधाएँ।',
      'Get AI-assisted answers about BIS standards, certification and services.':
          'BIS मानकों, प्रमाणीकरण और सेवाओं के बारे में AI-सहायित उत्तर पाएँ।',
      'Understand Indian Standards, certification and compliance guidance.':
          'भारतीय मानकों, प्रमाणीकरण और अनुपालन मार्गदर्शन को समझें।',
      'Generate a product-specific BIS compliance checklist.':
          'उत्पाद-विशिष्ट BIS अनुपालन चेकलिस्ट बनाएँ।',
      'Search standards, understand certification requirements,':
          'मानक खोजें, प्रमाणीकरण आवश्यकताओं को समझें,',
      'and BIS services with AI assistance.':
          'और AI सहायता से BIS सेवाओं का उपयोग करें।',
      'all in one place.': 'सब कुछ एक ही स्थान पर।',
      'Explore BIS Services': 'BIS सेवाएँ देखें',
      'What can BIS Saathi help with?':
          'BIS Saathi किस प्रकार सहायता कर सकता है?',
      'Indian Standards': 'भारतीय मानक',
      'Consumer / Industry User': 'उपभोक्ता / उद्योग उपयोगकर्ता',
      'PVC Insulated Electric Cables': 'PVC इंसुलेटेड विद्युत केबल',
      'Heavy Duty PVC Insulated Electric Cables':
          'हेवी ड्यूटी PVC इंसुलेटेड विद्युत केबल',
      'Cement': 'सीमेंट',
      'Ordinary Portland Cement — Specification':
          'ऑर्डिनरी पोर्टलैंड सीमेंट — विनिर्देश',
      'Portland-Pozzolana Cement — Specification, Part 1: Fly Ash Based':
          'पोर्टलैंड-पोज़ोलाना सीमेंट — विनिर्देश, भाग 1: फ्लाई ऐश आधारित',
      'Electrical Products': 'विद्युत उत्पाद',
      'Electrical': 'विद्युत',
      'Construction': 'निर्माण',
      'BIS Saathi connects users with standards,':
          'BIS Saathi उपयोगकर्ताओं को मानकों से जोड़ता है,',
      'BIS certification or how to navigate BIS services.':
          'BIS प्रमाणीकरण या BIS सेवाओं को समझने में सहायता करता है.',
    },

    'Marathi': <String, String>{
      'Home': 'मुख्यपृष्ठ',
      'Assistant': 'सहाय्यक',
      'Standards': 'मानके',
      'Compliance': 'अनुपालन',
      'Services': 'सेवा',
      'Profile': 'प्रोफाइल',
      'Smart BIS Assistant': 'स्मार्ट BIS सहाय्यक',
      'Bureau of Indian Standards': 'भारतीय मानक ब्युरो',
      'Select language': 'भाषा निवडा',
      'New conversation': 'नवीन संभाषण',
      'AI Assistant': 'AI सहाय्यक',
      'Standard Finder': 'मानक शोधक',
      'Standard Details': 'मानक तपशील',
      'Compliance Assistant': 'अनुपालन सहाय्यक',
      'Compliance Checklist': 'अनुपालन तपासणी यादी',
      'Document Q&A': 'दस्तऐवज प्रश्नोत्तर',
      'BIS Services': 'BIS सेवा',
      'Find Standards': 'मानके शोधा',
      'Find a Standard': 'मानक शोधा',
      'Find Standard': 'मानक शोधा',
      'Search': 'शोधा',
      'Clear': 'साफ करा',
      'View Details': 'तपशील पहा',
      'All Categories': 'सर्व श्रेणी',
      'All Industries': 'सर्व उद्योग',
      'Relevance': 'सुसंगतता',
      'A-Z': 'A-Z',
      'IS Number': 'IS क्रमांक',
      'Category': 'श्रेणी',
      'Industry': 'उद्योग',
      'Product': 'उत्पादन',
      'Certification': 'प्रमाणीकरण',
      'Certification requirements': 'प्रमाणीकरण आवश्यकता',
      'Mandatory Certification': 'अनिवार्य प्रमाणीकरण',
      'Compulsory Certification': 'अनिवार्य प्रमाणीकरण',
      'Ask Questions': 'प्रश्न विचारा',
      'Ask BIS Saathi': 'BIS Saathi ला विचारा',
      'Ask Question': 'प्रश्न विचारा',
      'Ask AI about this standard': 'या मानकाबद्दल AI ला विचारा',
      'Check Compliance': 'अनुपालन तपासा',
      'Generate Checklist': 'तपासणी यादी तयार करा',
      'Quick Actions': 'त्वरित कृती',
      'Quick Access': 'त्वरित प्रवेश',
      'Your BIS Activity': 'तुमची BIS क्रियाशीलता',
      'Official BIS Source': 'अधिकृत BIS स्रोत',
      'Official BIS Sources': 'अधिकृत BIS स्रोत',
      'Standard Information': 'मानक माहिती',
      'Standard Number': 'मानक क्रमांक',
      'What this standard covers': 'हे मानक काय समाविष्ट करते',
      'Upload BIS PDF': 'BIS PDF अपलोड करा',
      'Upload a BIS PDF and ask questions.':
          'BIS PDF अपलोड करा आणि प्रश्न विचारा.',
      'Choose PDF': 'PDF निवडा',
      'Choose New Document': 'नवीन दस्तऐवज निवडा',
      'Process PDF': 'PDF प्रक्रिया करा',
      'Processing...': 'प्रक्रिया सुरू आहे...',
      'Generating...': 'तयार करत आहे...',
      'Ask Your BIS Document': 'तुमच्या BIS दस्तऐवजाला विचारा',
      'Try asking': 'विचारून पहा',
      'Search standards...': 'मानके शोधा...',
      'Ask anything about BIS...': 'BIS बद्दल काहीही विचारा...',
      'Apply for BIS Licence': 'BIS परवान्यासाठी अर्ज करा',
      'Renew BIS Licence': 'BIS परवाना नूतनीकरण करा',
      'eBIS / Manakonline': 'eBIS / Manakonline',
      'BIS Care App': 'BIS Care अॅप',
      'Consumer Complaints': 'ग्राहक तक्रारी',
      'BIS Training': 'BIS प्रशिक्षण',
      'Dashboard': 'डॅशबोर्ड',
      'Profile settings coming soon.': 'प्रोफाइल सेटिंग्ज लवकरच उपलब्ध होतील.',
      'AI Questions': 'AI प्रश्न',
      'Standards Viewed': 'पाहिलेली मानके',
      'Documents': 'दस्तऐवज',
      'Checklist Items': 'तपासणी यादीतील बाबी',
      'Example: Cement or PVC Insulated Electric Cables':
          'उदाहरण: Cement किंवा PVC Insulated Electric Cables',
      'Example: What does this document say about certification requirements?':
          'उदाहरण: हा दस्तऐवज प्रमाणीकरण आवश्यकतांबद्दल काय सांगतो?',
      'Please enter a product name first.': 'कृपया प्रथम उत्पादनाचे नाव भरा.',
      'Please enter a question.': 'कृपया प्रश्न भरा.',
      'Please choose a PDF first.': 'कृपया प्रथम PDF निवडा.',
      'Please process the PDF first.': 'कृपया प्रथम PDF प्रक्रिया करा.',
      'Could not open the BIS source.': 'BIS स्रोत उघडता आला नाही.',
      'Could not connect to BIS Saathi server.':
          'BIS Saathi सर्व्हरशी कनेक्ट होता आले नाही.',
      'Could not select the PDF.': 'PDF निवडता आली नाही.',
      'Could not read the selected PDF.': 'निवडलेली PDF वाचता आली नाही.',
      'Please try again.': 'कृपया पुन्हा प्रयत्न करा.',
      'No standards found.': 'कोणतेही मानक सापडले नाही.',
      'Try another product, keyword or IS number.':
          'दुसरे उत्पादन, कीवर्ड किंवा IS क्रमांक वापरून पहा.',
      'Ask about IS numbers and product standards.':
          'IS क्रमांक आणि उत्पादन मानकांबद्दल विचारा.',
      'Understand BIS certification information.':
          'BIS प्रमाणीकरण माहिती समजून घ्या.',
      'Get guidance using the BIS knowledge base.':
          'BIS ज्ञान आधारातून मार्गदर्शन मिळवा.',
      'What is BIS certification?': 'BIS प्रमाणीकरण म्हणजे काय?',
      'How can I apply for BIS certification?':
          'मी BIS प्रमाणीकरणासाठी अर्ज कसा करू शकतो?',
      'What BIS standard applies to cement?':
          'सिमेंटसाठी कोणते BIS मानक लागू होते?',
      'What is IS 269:2015?': 'IS 269:2015 म्हणजे काय?',
      'Ask about an IS number, a product standard,':
          'IS क्रमांक किंवा उत्पादन मानकाबद्दल विचारा,',
      'Search and explore Indian Standards.': 'भारतीय मानके शोधा आणि पहा.',
      'Search by product, industry, standard number or keyword.':
          'उत्पादन, उद्योग, मानक क्रमांक किंवा कीवर्डने शोधा.',
      'Access important BIS services and official resources.':
          'महत्त्वाच्या BIS सेवा आणि अधिकृत संसाधनांमध्ये प्रवेश मिळवा.',
      'Access important official BIS services.':
          'महत्त्वाच्या अधिकृत BIS सेवांमध्ये प्रवेश मिळवा.',
      'Open Official Service': 'अधिकृत सेवा उघडा',
      'One BIS companion': 'एक BIS साथी',
      'Built around official BIS information': 'अधिकृत BIS माहितीवर आधारित',
      'AI-Powered BIS Assistant': 'AI-सक्षम BIS सहाय्यक',
      'AI-assisted BIS response': 'AI-सहाय्यित BIS उत्तर',
      'BIS Saathi Answer': 'BIS Saathi उत्तर',
      'BIS Saathi Guidance': 'BIS Saathi मार्गदर्शन',
      'BIS Saathi is checking its knowledge base...':
          'BIS Saathi त्याच्या ज्ञान आधाराची तपासणी करत आहे...',
      'Retrieving relevant BIS information': 'संबंधित BIS माहिती मिळवत आहे...',
      'BIS Saathi could not generate an answer.':
          'BIS Saathi उत्तर तयार करू शकला नाही.',
      'Verify important compliance decisions against current official BIS information.':
          'महत्त्वाचे अनुपालन निर्णय सध्याच्या अधिकृत BIS माहितीसह पडताळा.',
      'Always verify important compliance decisions using current official BIS information.':
          'महत्त्वाचे अनुपालन निर्णय नेहमी सध्याच्या अधिकृत BIS माहितीसह पडताळा.',
      'Generate a product compliance checklist.':
          'उत्पादन अनुपालन तपासणी यादी तयार करा.',
      'Access official services': 'अधिकृत सेवांमध्ये प्रवेश मिळवा',
      'Search IS standards': 'IS मानके शोधा',
      'Check product requirements': 'उत्पादन आवश्यकता तपासा',
      'Ask questions from PDFs': 'PDF मधून प्रश्न विचारा',
      'Frequently used BIS Saathi features.':
          'BIS Saathi ची वारंवार वापरली जाणारी वैशिष्ट्ये.',
      'Get AI-assisted answers about BIS standards, certification and services.':
          'BIS मानके, प्रमाणीकरण आणि सेवांबद्दल AI-सहाय्यित उत्तरे मिळवा.',
      'Understand Indian Standards, certification and compliance guidance.':
          'भारतीय मानके, प्रमाणीकरण आणि अनुपालन मार्गदर्शन समजून घ्या.',
      'Generate a product-specific BIS compliance checklist.':
          'उत्पादन-विशिष्ट BIS अनुपालन तपासणी यादी तयार करा.',
      'Search standards, understand certification requirements,':
          'मानके शोधा, प्रमाणीकरण आवश्यकता समजून घ्या,',
      'and BIS services with AI assistance.':
          'आणि AI सहाय्याने BIS सेवांचा उपयोग करा.',
      'all in one place.': 'सर्व काही एका ठिकाणी.',
      'Explore BIS Services': 'BIS सेवा पहा',
      'What can BIS Saathi help with?': 'BIS Saathi कशात मदत करू शकतो?',
      'Indian Standards': 'भारतीय मानके',
      'Consumer / Industry User': 'ग्राहक / उद्योग वापरकर्ता',
      'PVC Insulated Electric Cables': 'PVC इन्सुलेटेड विद्युत केबल',
      'Heavy Duty PVC Insulated Electric Cables':
          'हेवी ड्यूटी PVC इन्सुलेटेड विद्युत केबल',
      'Cement': 'सिमेंट',
      'Ordinary Portland Cement — Specification':
          'ऑर्डिनरी पोर्टलँड सिमेंट — विनिर्देश',
      'Portland-Pozzolana Cement — Specification, Part 1: Fly Ash Based':
          'पोर्टलँड-पोझोलाना सिमेंट — विनिर्देश, भाग 1: फ्लाय अॅश आधारित',
      'Electrical Products': 'विद्युत उत्पादने',
      'Electrical': 'विद्युत',
      'Construction': 'बांधकाम',
      'BIS Saathi connects users with standards,':
          'BIS Saathi वापरकर्त्यांना मानकांशी जोडतो,',
      'BIS certification or how to navigate BIS services.':
          'BIS प्रमाणीकरण किंवा BIS सेवा वापरण्याबाबत मार्गदर्शन.',
    },
  };
}

class _LanguageScope extends m.InheritedNotifier<AppLanguage> {
  const _LanguageScope({required super.notifier, required super.child});

  AppLanguage get language => notifier!;
}

class LanguageScope extends m.StatelessWidget {
  final m.Widget child;

  const LanguageScope({super.key, required this.child});

  @override
  m.Widget build(m.BuildContext context) {
    return _LanguageScope(notifier: AppLanguage.instance, child: child);
  }
}

class Text extends m.StatelessWidget {
  final String? data;
  final m.TextStyle? style;
  final m.TextAlign? textAlign;
  final m.TextDirection? textDirection;
  final m.TextOverflow? overflow;
  final bool? softWrap;
  final int? maxLines;
  final m.StrutStyle? strutStyle;
  final m.TextWidthBasis? textWidthBasis;
  final m.TextHeightBehavior? textHeightBehavior;
  final m.Locale? locale;
  final m.TextScaler? textScaler;
  final String? semanticsLabel;

  const Text(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.overflow,
    this.softWrap,
    this.maxLines,
    this.strutStyle,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.locale,
    this.textScaler,
    this.semanticsLabel,
  });

  @override
  m.Widget build(m.BuildContext context) {
    final String translatedText = data == null
        ? ''
        : AppLanguage.of(context).t(data!);

    return m.Text(
      translatedText,
      style: style,
      textAlign: textAlign,
      textDirection: textDirection,
      overflow: overflow,
      softWrap: softWrap,
      maxLines: maxLines,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      locale: locale,
      textScaler: textScaler,
      semanticsLabel: semanticsLabel,
    );
  }
}
