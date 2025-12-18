import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';


class AppLocale {
  final String title;
  final String camera;
  final String album;
  final String settings;
  final String motherLanguage;
  final String learnLanguage;
  final String learnLanguageSub;
  final String appLanguage;
  final String appLanguageSub;
  final String next;
  final String back;
  final String getStarted;
  final String identify;
  final String retake;
  final String analyzing;
  final String newCapture;
  final String noPhotos;
  final String goTakeSome;
  final String close;
  final String learnPrompt;
  final String subjectLabel;
  final String translationLabel;

  AppLocale({

    required this.title,
    required this.camera,
    required this.album,
    required this.settings,
    required this.motherLanguage,
    required this.learnLanguage,
    required this.learnLanguageSub,
    required this.appLanguage,
    required this.appLanguageSub,
    required this.next,
    required this.back,
    required this.getStarted,
    required this.identify,
    required this.retake,
    required this.analyzing,
    required this.newCapture,
    required this.noPhotos,
    required this.goTakeSome,
    required this.close,
    required this.learnPrompt,
    required this.subjectLabel,
    required this.translationLabel,
  });
}

final Map<String, AppLocale> supportedLocales = {
  'English': AppLocale(
    title: 'LangTake',
    camera: 'Camera',
    album: 'Album',
    settings: 'Settings',
    motherLanguage: 'Mother Language',
    learnLanguage: 'What language you wanna learn?',
    learnLanguageSub: 'You can change this anytime later',
    appLanguage: 'App Language',
    appLanguageSub: 'Select your preferred interface language',
    next: 'Next',
    back: 'Back',
    getStarted: 'Get Started',
    identify: 'Identify',
    retake: 'Retake',
    analyzing: 'Analyzing...',
    newCapture: 'New Capture',
    noPhotos: 'No photos yet.',
    goTakeSome: 'Go take some!',
    close: 'Close',
    learnPrompt: 'I want to learn: ',
    subjectLabel: 'Subject',
    translationLabel: 'Translation',
  ),

  'Thai': AppLocale(
    title: 'LangTake',
    camera: 'กล้อง',
    album: 'อัลบั้ม',
    settings: 'ตั้งค่า',
    motherLanguage: 'ภาษาแม่',
    learnLanguage: 'คุณต้องการเรียนภาษาอะไร?',
    learnLanguageSub: 'คุณสามารถเปลี่ยนได้ตลอดเวลา',
    appLanguage: 'ภาษาของแอป',
    appLanguageSub: 'เลือกภาษาสำหรับหน้าจอใช้งาน',
    next: 'ถัดไป',
    back: 'ย้อนกลับ',
    getStarted: 'เริ่มใช้งาน',
    identify: 'วิเคราะห์',
    retake: 'ถ่ายใหม่',
    analyzing: 'กำลังวิเคราะห์...',
    newCapture: 'ถ่ายภาพใหม่',
    noPhotos: 'ยังไม่มีรูปภาพ',
    goTakeSome: 'ลองถ่ายรูปดูสิ!',
    close: 'ปิด',
    learnPrompt: 'ฉันต้องการเรียน: ',
    subjectLabel: 'สิ่งที่เห็น',
    translationLabel: 'คำแปล',
  ),
};


final appLocaleProvider = Provider<AppLocale>((ref) {
  final language = ref.watch(appLanguageProvider);
  return supportedLocales[language] ?? supportedLocales['English']!;
});

// We'll need an appLanguageProvider in SettingsService
