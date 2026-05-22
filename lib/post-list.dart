import 'dart:io';
import 'package:LawyerOnline/component/appbar.dart';
import 'package:LawyerOnline/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:LawyerOnline/shared/responsive/res_layout.dart';
import 'package:LawyerOnline/shared/responsive/app_layout.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:LawyerOnline/models/user_profile_store.dart';

// ─── Data Models ───────────────────────────────────────────────────────────────

enum UserRole { client, lawyer }

class CommunityUser {
  final String id;
  final String name;
  final String avatarUrl;
  final UserRole role;
  final String? specialty;
  final bool isVerified;

  const CommunityUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.role,
    this.specialty,
    this.isVerified = false,
  });
}

class PostComment {
  final String id;
  final CommunityUser author;
  String content;
  final DateTime createdAt;
  int likes;
  bool isLiked;
  final List<PostComment> replies;

  PostComment({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    this.likes = 0,
    this.isLiked = false,
    List<PostComment>? replies,
  }) : replies = replies ?? [];
}

class CommunityPost {
  final String id;
  final CommunityUser author;
  String content;
  final String category;
  final DateTime createdAt;
  final List<String> imagePaths;
  int likes;
  int views;
  int shares;
  bool isLiked;
  bool isBookmarked;
  final List<PostComment> comments;

  CommunityPost({
    required this.id,
    required this.author,
    required this.content,
    required this.category,
    required this.createdAt,
    this.imagePaths = const [],
    this.likes = 0,
    this.views = 0,
    this.shares = 0,
    this.isLiked = false,
    this.isBookmarked = false,
    List<PostComment>? comments,
  }) : comments = comments ?? [];
}

// ─── Current User (loaded from profile) ────────────────────────────────────────

CommunityUser get currentUser {
  final store = UserProfileStore.instance;
  return CommunityUser(
    id: 'me',
    name: store.name.isNotEmpty ? store.name : 'defaultUser'.tr(),
    avatarUrl: store.imageUrl,
    role: store.userType == 'lawyer' ? UserRole.lawyer : UserRole.client,
    isVerified: store.userType == 'lawyer',
  );
}

// ─── Mock Data ─────────────────────────────────────────────────────────────────

// ─── แทนที่ส่วน mockPosts ในไฟล์หลัก ─────────────────────────────────────────
// วางแทน List<CommunityPost> mockPosts = [...]; ตัวเดิม

List<CommunityPost> mockPosts = [
  // ── 1 ──
  CommunityPost(
    id: '1',
    author: const CommunityUser(
        id: 'u1', name: 'สมชาย วงศ์ใหญ่', avatarUrl: '', role: UserRole.client),
    content:
        'ผมทำงานมา 5 ปี โดนเลิกจ้างกะทันหันโดยไม่ได้รับแจ้งล่วงหน้า และไม่ได้รับค่าชดเชยใดๆ เลย ต้องทำอะไรได้บ้างครับ?',
    category: 'category.labor',
    createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    likes: 47,
    views: 312,
    shares: 8,
    comments: [
      PostComment(
        id: 'c1',
        author: const CommunityUser(
            id: 'l1',
            name: 'ทนาย ภาณุพงศ์ ศรีสวัสดิ์',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'กฎหมายแรงงาน',
            isVerified: true),
        content:
            'กรณีนี้ถือเป็นการเลิกจ้างที่ไม่เป็นธรรมตามพ.ร.บ.คุ้มครองแรงงาน คุณมีสิทธิ์ได้รับค่าชดเชยตามอายุงาน และสามารถยื่นเรื่องต่อสำนักงานสวัสดิการและคุ้มครองแรงงานได้ภายใน 60 วัน',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        likes: 23,
      ),
    ],
  ),

  // ── 2 ──
  CommunityPost(
    id: '2',
    author: const CommunityUser(
        id: 'u2', name: 'นิภา รักษ์ดี', avatarUrl: '', role: UserRole.client),
    content:
        'เช่าบ้านมา 2 ปี ตอนย้ายออกเจ้าของบ้านอ้างว่าบ้านเสียหาย แต่ความจริงไม่มีความเสียหายใดๆ เลย มีวิธีเรียกคืนเงินมัดจำ 20,000 บาทได้ไหมคะ?',
    category: 'category.real_estate',
    createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    likes: 89,
    views: 543,
    shares: 21,
    isLiked: true,
    comments: [
      PostComment(
        id: 'c2',
        author: const CommunityUser(
            id: 'l2',
            name: 'ทนาย สุนทรี แก้วมณี',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'กฎหมายแพ่ง',
            isVerified: true),
        content:
            'คุณสามารถฟ้องเรียกเงินมัดจำคืนได้ที่ศาลแขวง โดยไม่ต้องมีทนายความ เนื่องจากวงเงินไม่เกิน 300,000 บาท ควรรวบรวมหลักฐานเป็นรูปถ่ายบ้านตอนย้ายออก สัญญาเช่า และหลักฐานการโอนเงินมัดจำ',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        likes: 41,
      ),
    ],
  ),

  // ── 3 ──
  CommunityPost(
    id: '3',
    author: const CommunityUser(
        id: 'u3', name: 'ธนพล มีสุข', avatarUrl: '', role: UserRole.client),
    content:
        'โอนเงินไปแล้ว 15,000 บาท สินค้าไม่มา ติดต่อผู้ขายไม่ได้ บล็อกในทุกช่องทาง จะแจ้งความอย่างไร มีโอกาสได้เงินคืนไหมครับ?',
    category: 'category.criminal',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    likes: 156,
    views: 1024,
    shares: 45,
    isBookmarked: true,
    comments: [
      PostComment(
        id: 'c3',
        author: const CommunityUser(
            id: 'l3',
            name: 'ทนาย อนันต์ พรหมพิทักษ์',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'คดีอาญา & ไซเบอร์',
            isVerified: true),
        content:
            'แจ้งความที่สถานีตำรวจท้องที่ได้เลย ข้อหาฉ้อโกง พร้อมรวบรวม screenshot การสนทนา หลักฐานการโอนเงิน และข้อมูลบัญชีผู้ขาย นอกจากนี้แจ้งธนาคารให้อายัดบัญชีปลายทางได้ทันที',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        likes: 67,
        isLiked: true,
      ),
    ],
  ),

  // ── 4 ──
  CommunityPost(
    id: '4',
    author: const CommunityUser(
        id: 'u4', name: 'รัตนา ใจดี', avatarUrl: '', role: UserRole.client),
    content:
        'ต้องการหย่าร้าง สามีมีพฤติกรรมดื่มเหล้าและทำร้ายร่างกาย มีลูก 1 คน อายุ 5 ขวบ อยากได้สิทธิ์เลี้ยงดูลูก ต้องทำอย่างไรคะ?',
    category: 'category.family',
    createdAt: DateTime.now().subtract(const Duration(hours: 3)),
    likes: 203,
    views: 1872,
    shares: 67,
    comments: [
      PostComment(
        id: 'c4',
        author: const CommunityUser(
            id: 'l4',
            name: 'ทนาย วรรณา จิตต์ดี',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'กฎหมายครอบครัว',
            isVerified: true),
        content:
            'กรณีมีหลักฐานการทำร้ายร่างกาย คุณมีโอกาสสูงมากในการได้สิทธิ์ปกครองบุตร แนะนำให้เก็บหลักฐานรูปถ่ายบาดแผล ใบรับรองแพทย์ และแจ้งความไว้เป็นหลักฐานก่อนยื่นฟ้องหย่าครับ',
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
        likes: 89,
      ),
    ],
  ),

  // ── 5 ──
  CommunityPost(
    id: '5',
    author: const CommunityUser(
        id: 'u5', name: 'ปิยะ สว่างใจ', avatarUrl: '', role: UserRole.client),
    content:
        'รถชนกัน ฝ่ายตรงข้ามอ้างว่าผมผิด แต่กล้องวงจรปิดน่าจะช่วยได้ ประกันเขาไม่ยอมจ่าย บอกว่าคนขับไม่ใช่ชื่อเดียวกับกรมธรรม์ จะทำอย่างไรดีครับ?',
    category: 'category.civil',
    createdAt: DateTime.now().subtract(const Duration(hours: 4)),
    likes: 78,
    views: 567,
    shares: 12,
    comments: [],
  ),

  // ── 6 ──
  CommunityPost(
    id: '6',
    author: const CommunityUser(
        id: 'u6',
        name: 'มาลี สุขสวัสดิ์',
        avatarUrl: '',
        role: UserRole.client),
    content:
        'นายจ้างไม่จ่ายเงินเดือนมา 3 เดือนแล้ว อ้างว่าบริษัทขาดสภาพคล่อง แต่เห็นว่าซื้อรถใหม่ ทำได้ไหมคะ มีลูกต้องเลี้ยงดู สภาพหนักมาก',
    category: 'category.labor',
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    likes: 312,
    views: 2341,
    shares: 89,
    comments: [
      PostComment(
        id: 'c6',
        author: const CommunityUser(
            id: 'l1',
            name: 'ทนาย ภาณุพงศ์ ศรีสวัสดิ์',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'กฎหมายแรงงาน',
            isVerified: true),
        content:
            'ยื่นเรื่องต่อกรมสวัสดิการและคุ้มครองแรงงานได้เลย นายจ้างมีหน้าที่จ่ายค่าจ้างตามกำหนด หากไม่จ่ายถือว่าผิดกฎหมาย มีโทษทั้งจำทั้งปรับ และคุณมีสิทธิ์เรียกดอกเบี้ยได้ด้วย',
        createdAt: DateTime.now().subtract(const Duration(hours: 7)),
        likes: 145,
      ),
      PostComment(
        id: 'c6b',
        author: const CommunityUser(
            id: 'u6b',
            name: 'สุดา ใจงาม',
            avatarUrl: '',
            role: UserRole.client),
        content:
            'เจอแบบเดียวกันเลยค่ะ ยื่นเรื่องแล้วได้เงินคืนในเวลา 2 สัปดาห์ สู้ๆ นะคะ',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        likes: 34,
      ),
    ],
  ),

  // ── 7 ──
  CommunityPost(
    id: '7',
    author: const CommunityUser(
        id: 'u7',
        name: 'อภิชัย ดำรงค์ศักดิ์',
        avatarUrl: '',
        role: UserRole.client),
    content:
        'ซื้อคอนโดใหม่จากโครงการ สัญญาบอกว่าจะโอนกรรมสิทธิ์ใน 2 ปี แต่ผ่านมา 4 ปีแล้วยังไม่โอน โครงการอ้างปัญหาการก่อสร้าง จะเรียกเงินคืนพร้อมดอกเบี้ยได้ไหม?',
    category: 'category.real_estate',
    createdAt: DateTime.now().subtract(const Duration(hours: 6)),
    likes: 445,
    views: 3210,
    shares: 124,
    comments: [
      PostComment(
        id: 'c7',
        author: const CommunityUser(
            id: 'l5',
            name: 'ทนาย กิตติพงศ์ นิลพัท',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'อสังหาริมทรัพย์',
            isVerified: true),
        content:
            'ผิดสัญญาชัดเจนครับ คุณมีสิทธิ์บอกเลิกสัญญาและเรียกเงินคืนพร้อมดอกเบี้ย 7.5% ต่อปี นับจากวันที่ชำระเงิน รวมถึงเรียกค่าเสียหายอื่นๆ ได้ด้วย',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        likes: 201,
      ),
    ],
  ),

  // ── 8 ──
  CommunityPost(
    id: '8',
    author: const CommunityUser(
        id: 'u8', name: 'กนกวรรณ พรมมา', avatarUrl: '', role: UserRole.client),
    content:
        'โดนสามีเก่าหมิ่นประมาทใน Facebook โพสต์ข้อความเท็จว่าเราเป็นชู้ให้เพื่อนๆ เห็น อยากฟ้องได้ไหมคะ เขาทำมาตั้งแต่เลิกกัน ทรมานมากเลย',
    category: 'category.criminal',
    createdAt: DateTime.now().subtract(const Duration(hours: 7)),
    likes: 289,
    views: 1987,
    shares: 56,
    comments: [
      PostComment(
        id: 'c8',
        author: const CommunityUser(
            id: 'l3',
            name: 'ทนาย อนันต์ พรหมพิทักษ์',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'คดีอาญา & ไซเบอร์',
            isVerified: true),
        content:
            'ฟ้องได้เลยครับ ข้อหาหมิ่นประมาทตาม พ.ร.บ. คอมพิวเตอร์ มีโทษจำคุกสูงสุด 3 ปี screenshot ไว้ให้ครบก่อนโพสต์ถูกลบ แล้วแจ้งความที่กองบังคับการปราบปรามการกระทำความผิดเกี่ยวกับอาชญากรรมทางเทคโนโลยี (บก.ปอท.)',
        createdAt: DateTime.now().subtract(const Duration(hours: 9)),
        likes: 178,
      ),
    ],
  ),

  // ── 9 ──
  CommunityPost(
    id: '9',
    author: const CommunityUser(
        id: 'u9', name: 'วิชาญ ตั้งมั่น', avatarUrl: '', role: UserRole.client),
    content:
        'เปิดร้านอาหาร มีพนักงานลาออกไปเปิดร้านแข่งข้างๆ ใช้สูตรอาหารเดียวกันหมดเลย สัญญาจ้างไม่ได้ระบุเรื่อง Non-compete เอาผิดได้ไหมครับ?',
    category: 'category.labor',
    createdAt: DateTime.now().subtract(const Duration(hours: 9)),
    likes: 134,
    views: 876,
    shares: 23,
    comments: [],
  ),

  // ── 10 ──
  CommunityPost(
    id: '10',
    author: const CommunityUser(
        id: 'u10',
        name: 'ลลิตา ศรีวิชัย',
        avatarUrl: '',
        role: UserRole.client),
    content:
        'พ่อเสียชีวิต มีทรัพย์สินเป็นบ้านและที่ดิน แต่พี่ชายอ้างว่าพ่อทำพินัยกรรมยกให้เขาคนเดียว ไม่เคยเห็นพินัยกรรมเลย จะตรวจสอบได้อย่างไรว่าพินัยกรรมจริงหรือปลอม?',
    category: 'category.family',
    createdAt: DateTime.now().subtract(const Duration(hours: 10)),
    likes: 567,
    views: 4321,
    shares: 145,
    comments: [
      PostComment(
        id: 'c10',
        author: const CommunityUser(
            id: 'l4',
            name: 'ทนาย วรรณา จิตต์ดี',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'กฎหมายครอบครัว',
            isVerified: true),
        content:
            'สามารถยื่นคำร้องต่อศาลเพื่อขอตรวจสอบความถูกต้องของพินัยกรรมได้ครับ หากพินัยกรรมไม่ถูกต้องตามแบบที่กฎหมายกำหนด หรือมีการปลอมแปลง ถือเป็นโมฆะ และทรัพย์สินจะตกแก่ทายาทโดยธรรมทุกคน',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        likes: 234,
      ),
    ],
  ),

  // ── 11 ──
  CommunityPost(
    id: '11',
    author: const CommunityUser(
        id: 'u11',
        name: 'ชัยวัฒน์ บุญประเสริฐ',
        avatarUrl: '',
        role: UserRole.client),
    content:
        'ขับรถชนคนข้ามถนน บาดเจ็บสาหัส ทำประกันภัยชั้น 1 ไว้ แต่ประกันบอกว่าคนเดินถนนต้องพิสูจน์ความผิดก่อน ถูกต้องไหมครับ? ตอนนี้คนเจ็บฟ้องแพ่งด้วย',
    category: 'category.civil',
    createdAt: DateTime.now().subtract(const Duration(hours: 11)),
    likes: 98,
    views: 743,
    shares: 19,
    comments: [
      PostComment(
        id: 'c11',
        author: const CommunityUser(
            id: 'l5',
            name: 'ทนาย กิตติพงศ์ นิลพัท',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'อสังหาริมทรัพย์',
            isVerified: true),
        content:
            'ประกันภัยชั้น 1 ต้องคุ้มครองทั้งทรัพย์สินและบุคคล ไม่ว่าจะเป็นฝ่ายผิดหรือถูก คุณมีสิทธิ์เรียกร้องให้ประกันจัดการได้ ควรแจ้งกรมการประกันภัยหากประกันไม่ปฏิบัติตามเงื่อนไขกรมธรรม์',
        createdAt: DateTime.now().subtract(const Duration(hours: 13)),
        likes: 56,
      ),
    ],
  ),

  // ── 12 ──
  CommunityPost(
    id: '12',
    author: const CommunityUser(
        id: 'u12',
        name: 'นงนุช พัฒนาการ',
        avatarUrl: '',
        role: UserRole.client),
    content:
        'ยืมเงินเพื่อนไป 50,000 บาท มีสัญญากู้ยืมลงนาม แต่เพื่อนบอกว่าฉีกทิ้งแล้ว เราถ่ายรูปสัญญาไว้ รูปถ่ายใช้เป็นหลักฐานในศาลได้ไหมคะ?',
    category: 'category.civil',
    createdAt: DateTime.now().subtract(const Duration(hours: 12)),
    likes: 176,
    views: 1234,
    shares: 34,
    comments: [
      PostComment(
        id: 'c12',
        author: const CommunityUser(
            id: 'l2',
            name: 'ทนาย สุนทรี แก้วมณี',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'กฎหมายแพ่ง',
            isVerified: true),
        content:
            'รูปถ่ายสัญญาสามารถใช้เป็นพยานหลักฐานในศาลได้ครับ แต่ศาลอาจให้น้ำหนักน้อยกว่าเอกสารต้นฉบับ แนะนำให้หาพยานบุคคลที่รู้เห็นการกู้ยืมประกอบด้วย และมีหลักฐานการโอนเงินหรือหลักฐานอื่นๆ สนับสนุน',
        createdAt: DateTime.now().subtract(const Duration(hours: 14)),
        likes: 89,
      ),
    ],
  ),

  // ── 13 ──
  CommunityPost(
    id: '13',
    author: const CommunityUser(
        id: 'u13',
        name: 'สุรชัย แก้วประเสริฐ',
        avatarUrl: '',
        role: UserRole.client),
    content:
        'บริษัทให้ทำ OT ทุกวัน แต่ไม่จ่ายค่า OT เพิ่ม บอกว่ารวมอยู่ในเงินเดือนแล้ว สัญญาจ้างระบุว่า "ค่าจ้างรวม OT" แบบนี้ถูกกฎหมายไหมครับ?',
    category: 'category.labor',
    createdAt: DateTime.now().subtract(const Duration(hours: 13)),
    likes: 423,
    views: 3456,
    shares: 112,
    comments: [
      PostComment(
        id: 'c13',
        author: const CommunityUser(
            id: 'l1',
            name: 'ทนาย ภาณุพงศ์ ศรีสวัสดิ์',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'กฎหมายแรงงาน',
            isVerified: true),
        content:
            'ไม่ถูกต้องครับ พ.ร.บ.คุ้มครองแรงงานกำหนดให้นายจ้างต้องจ่ายค่า OT แยกต่างหากจากค่าจ้าง การระบุในสัญญาว่า "รวม OT" ขัดต่อกฎหมาย ใช้บังคับไม่ได้ คุณมีสิทธิ์เรียกค่า OT ย้อนหลังได้สูงสุด 2 ปี',
        createdAt: DateTime.now().subtract(const Duration(hours: 15)),
        likes: 267,
      ),
    ],
  ),

  // ── 14 ──
  CommunityPost(
    id: '14',
    author: const CommunityUser(
        id: 'u14', name: 'พิมพ์ใจ ทองดี', avatarUrl: '', role: UserRole.client),
    content:
        'สั่งซื้อของออนไลน์ ได้รับสินค้าแต่แตกหักเสียหาย แม่ค้าบอกว่าไม่รับผิดชอบเพราะเป็นความผิดของบริษัทขนส่ง ต้องเรียกร้องจากใครคะ?',
    category: 'category.criminal',
    createdAt: DateTime.now().subtract(const Duration(hours: 14)),
    likes: 234,
    views: 1876,
    shares: 67,
    comments: [],
  ),

  // ── 15 ──
  CommunityPost(
    id: '15',
    author: const CommunityUser(
        id: 'u15',
        name: 'ธีรพงษ์ วงษ์สุวรรณ',
        avatarUrl: '',
        role: UserRole.client),
    content:
        'เปิดธุรกิจเล็กๆ มีคู่แข่งมาถ่ายรูปสินค้าและราคาของเรา แล้วเอาไปโพสต์แอดโจมตีร้านเรา บอกว่าสินค้าเราด้อยคุณภาพ ทั้งที่ไม่จริง มีผลต่อยอดขายมาก จะฟ้องได้ไหมครับ?',
    category: 'category.civil',
    createdAt: DateTime.now().subtract(const Duration(hours: 15)),
    likes: 189,
    views: 1456,
    shares: 45,
    comments: [
      PostComment(
        id: 'c15',
        author: const CommunityUser(
            id: 'l3',
            name: 'ทนาย อนันต์ พรหมพิทักษ์',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'คดีอาญา & ไซเบอร์',
            isVerified: true),
        content:
            'ฟ้องได้ครับทั้งคดีแพ่ง (เรียกค่าเสียหาย) และอาญา (หมิ่นประมาท) เก็บหลักฐานโพสต์ไว้ให้ครบ ทั้ง screenshot, URL, และข้อมูลยอดขายก่อนและหลังที่เสียหาย เพื่อใช้ประกอบการเรียกร้องค่าเสียหาย',
        createdAt: DateTime.now().subtract(const Duration(hours: 17)),
        likes: 112,
      ),
    ],
  ),

  // ── 16 ──
  CommunityPost(
    id: '16',
    author: const CommunityUser(
        id: 'u16', name: 'จินตนา บุญมี', avatarUrl: '', role: UserRole.client),
    content:
        'แม่ป่วยหนักอยู่โรงพยาบาล แต่พี่ชายไม่ยอมให้เราเข้าเยี่ยม อ้างว่าเป็นคนดูแลตามกฎหมาย มีสิทธิ์ห้ามได้ไหม? และถ้าแม่เสีย เราจะมีสิทธิ์รับมรดกอย่างไร?',
    category: 'category.family',
    createdAt: DateTime.now().subtract(const Duration(hours: 16)),
    likes: 334,
    views: 2654,
    shares: 78,
    comments: [
      PostComment(
        id: 'c16',
        author: const CommunityUser(
            id: 'l4',
            name: 'ทนาย วรรณา จิตต์ดี',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'กฎหมายครอบครัว',
            isVerified: true),
        content:
            'ลูกทุกคนมีสิทธิ์เยี่ยมบิดามารดา การห้ามเยี่ยมไม่มีฐานทางกฎหมาย หากถูกขัดขวาง สามารถร้องขอต่อศาลได้ ส่วนมรดก ลูกทุกคนมีสิทธิ์รับมรดกเท่าๆ กัน หากไม่มีพินัยกรรมยกเว้นไว้',
        createdAt: DateTime.now().subtract(const Duration(hours: 18)),
        likes: 198,
      ),
    ],
  ),

  // ── 17 ──
  CommunityPost(
    id: '17',
    author: const CommunityUser(
        id: 'u17',
        name: 'สมศักดิ์ อินทร์ทอง',
        avatarUrl: '',
        role: UserRole.client),
    content:
        'ซื้อรถมือสองจากเต็นท์ ใช้ไปได้ 1 เดือน เครื่องยนต์พังหมด ตรวจพบว่าถูกซ่อนข้อบกพร่องมาก่อนขาย มีใบเสร็จ สัญญาซื้อขาย จะเรียกค่าเสียหายหรือยกเลิกสัญญาได้ไหมครับ?',
    category: 'category.civil',
    createdAt: DateTime.now().subtract(const Duration(hours: 18)),
    likes: 267,
    views: 2134,
    shares: 56,
    comments: [
      PostComment(
        id: 'c17',
        author: const CommunityUser(
            id: 'l2',
            name: 'ทนาย สุนทรี แก้วมณี',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'กฎหมายแพ่ง',
            isVerified: true),
        content:
            'เข้าข่ายความรับผิดเพื่อความชำรุดบกพร่องครับ ผู้ขายต้องรับผิดชอบ คุณมีสิทธิ์เรียกให้ซ่อมแซม ลดราคา หรือเลิกสัญญาพร้อมคืนเงิน ต้องดำเนินการภายใน 1 ปีนับจากวันที่รู้ข้อบกพร่อง',
        createdAt: DateTime.now().subtract(const Duration(hours: 20)),
        likes: 145,
      ),
    ],
  ),

  // ── 18 ──
  CommunityPost(
    id: '18',
    author: const CommunityUser(
        id: 'u18',
        name: 'ทิพวรรณ มณีรัตน์',
        avatarUrl: '',
        role: UserRole.client),
    content:
        'ถูกบริษัทประกันปฏิเสธจ่ายค่าสินไหมทดแทนประกันชีวิตของสามีที่เพิ่งเสียชีวิต อ้างว่าสามีปกปิดโรคประจำตัว แต่ตอนทำประกันไม่เคยถูกถามถึงโรคนี้เลย มีทางสู้ได้ไหมคะ?',
    category: 'category.civil',
    createdAt: DateTime.now().subtract(const Duration(hours: 20)),
    likes: 523,
    views: 4567,
    shares: 167,
    comments: [
      PostComment(
        id: 'c18',
        author: const CommunityUser(
            id: 'l5',
            name: 'ทนาย กิตติพงศ์ นิลพัท',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'กฎหมายแพ่ง',
            isVerified: true),
        content:
            'สู้ได้ครับ บริษัทประกันต้องถามเฉพาะในแบบฟอร์มที่กำหนด ถ้าไม่ได้ถาม ผู้เอาประกันไม่มีหน้าที่แจ้ง ยื่นเรื่องร้องเรียนต่อสำนักงาน คปภ. ได้เลย มีอำนาจบังคับให้บริษัทจ่าย',
        createdAt: DateTime.now().subtract(const Duration(hours: 22)),
        likes: 289,
      ),
    ],
  ),

  // ── 19 ──
  CommunityPost(
    id: '19',
    author: const CommunityUser(
        id: 'u19',
        name: 'ประยุทธ์ สาริกา',
        avatarUrl: '',
        role: UserRole.client),
    content:
        'เปิดร้านเช่าบ้าน ผู้เช่าค้างค่าเช่า 4 เดือน ขอเข้าไปเก็บของของตัวเองที่วางไว้ในห้องแต่ผู้เช่าไม่ให้ จะทำอย่างไรได้บ้างครับ ตอนนี้ทะเลาะกันหนักมาก',
    category: 'category.real_estate',
    createdAt: DateTime.now().subtract(const Duration(hours: 22)),
    likes: 156,
    views: 1234,
    shares: 34,
    comments: [],
  ),

  // ── 20 ──
  CommunityPost(
    id: '20',
    author: const CommunityUser(
        id: 'u20', name: 'วาสนา ศรีสุข', avatarUrl: '', role: UserRole.client),
    content:
        'ลูกชายถูกครูที่โรงเรียนตีจนเป็นรอย อ้างว่าทำผิดระเบียบ โรงเรียนบอกว่าเป็นการลงโทษตามระเบียบ แบบนี้ถูกกฎหมายไหม และจะฟ้องได้ไหมคะ?',
    category: 'category.criminal',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    likes: 678,
    views: 5432,
    shares: 234,
    comments: [
      PostComment(
        id: 'c20',
        author: const CommunityUser(
            id: 'l3',
            name: 'ทนาย อนันต์ พรหมพิทักษ์',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'คดีอาญา & ไซเบอร์',
            isVerified: true),
        content:
            'ไม่ถูกต้องครับ กฎหมายปัจจุบันห้ามลงโทษด้วยการทำร้ายร่างกายนักเรียนโดยเด็ดขาด ฟ้องครูข้อหาทำร้ายร่างกายได้ และฟ้องโรงเรียน/สพฐ. ข้อหาละเลย ถ่ายรูปรอยช้ำและพาไปตรวจแพทย์เพื่อรับใบรับรองแพทย์ด้วย',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        likes: 345,
      ),
    ],
  ),

  // ── 21 ──
  CommunityPost(
    id: '21',
    author: const CommunityUser(
        id: 'u21', name: 'อรุณ ไชยวงศ์', avatarUrl: '', role: UserRole.client),
    content:
        'ซื้อที่ดินมา 10 ปี เพิ่งรู้ว่ามีเส้นทางสาธารณะผ่านกลางที่ดิน ตอนซื้อไม่มีใครบอก โฉนดไม่ได้ระบุไว้ ต้องการปิดทางนั้น ทำได้ไหมครับ?',
    category: 'category.real_estate',
    createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    likes: 234,
    views: 1876,
    shares: 45,
    comments: [
      PostComment(
        id: 'c21',
        author: const CommunityUser(
            id: 'l5',
            name: 'ทนาย กิตติพงศ์ นิลพัท',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'อสังหาริมทรัพย์',
            isVerified: true),
        content:
            'ถ้าเป็นทางสาธารณะที่ใช้กันมานานจนเกิดสิทธิ์โดยนิติกรรมหรือจารีตประเพณี จะปิดได้ยากมาก ต้องตรวจสอบประวัติการใช้ทาง ปรึกษาเจ้าหน้าที่ที่ดิน และพิจารณาว่าเป็น "ทางภาระจำยอม" หรือไม่',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        likes: 123,
      ),
    ],
  ),

  // ── 22 ──
  CommunityPost(
    id: '22',
    author: const CommunityUser(
        id: 'u22',
        name: 'เพ็ญพักตร์ สุวรรณภูมิ',
        avatarUrl: '',
        role: UserRole.client),
    content:
        'ทำงานเป็น Freelance รับงานออกแบบ ลูกค้าเอางานไปใช้แล้วไม่จ่ายเงิน อ้างว่างานไม่ตรงตาม brief บอกว่าจะแก้ไขให้กี่ครั้งก็ได้ฟรี แต่ตอนนี้แก้ไปแล้ว 15 ครั้ง สัญญาจ้างไม่มี จะทำอะไรได้บ้างคะ?',
    category: 'category.civil',
    createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
    likes: 445,
    views: 3456,
    shares: 89,
    comments: [
      PostComment(
        id: 'c22',
        author: const CommunityUser(
            id: 'l2',
            name: 'ทนาย สุนทรี แก้วมณี',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'กฎหมายแพ่ง',
            isVerified: true),
        content:
            'แม้ไม่มีสัญญาลายลักษณ์อักษร แต่การสื่อสารผ่าน chat ถือเป็นหลักฐานสัญญาจ้างได้ครับ เก็บ screenshot ทุกการสื่อสาร รวมถึงไฟล์งานที่ส่ง ฟ้องเรียกค่าจ้างได้ที่ศาลแขวง',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
        likes: 267,
      ),
    ],
  ),

  // ── 23 ──
  CommunityPost(
    id: '23',
    author: const CommunityUser(
        id: 'u23', name: 'บุญรอด ทับทิม', avatarUrl: '', role: UserRole.client),
    content:
        'เกษียณแล้ว นายจ้างไม่จ่ายกองทุนสำรองเลี้ยงชีพที่หักออกจากเงินเดือนมาตลอด 20 ปี บอกว่ากองทุนเจ๊งแล้ว เอาเงินไปไหน ทำอะไรได้บ้างครับ?',
    category: 'category.labor',
    createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
    likes: 789,
    views: 6543,
    shares: 234,
    comments: [
      PostComment(
        id: 'c23',
        author: const CommunityUser(
            id: 'l1',
            name: 'ทนาย ภาณุพงศ์ ศรีสวัสดิ์',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'กฎหมายแรงงาน',
            isVerified: true),
        content:
            'เรื่องนี้ร้ายแรงมากครับ กองทุนสำรองเลี้ยงชีพต้องจดทะเบียนและอยู่ภายใต้การกำกับของ กลต. ยื่นเรื่องร้องเรียนที่ กลต. และกรมพัฒนาธุรกิจการค้าได้ทันที นายจ้างอาจมีความผิดทางอาญาฐานยักยอกทรัพย์',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
        likes: 456,
      ),
    ],
  ),

  // ── 24 ──
  CommunityPost(
    id: '24',
    author: const CommunityUser(
        id: 'u24',
        name: 'ศิริพร นาคสุวรรณ',
        avatarUrl: '',
        role: UserRole.client),
    content:
        'เปิดเพจขายของออนไลน์ มีคนมา impersonate เปิดเพจปลอมชื่อเหมือนกัน ขายของปลอม ลูกค้าหลงซื้อแล้วมาด่าเรา เพจ Facebook ไม่ช่วย จะทำอย่างไรได้บ้างคะ?',
    category: 'category.criminal',
    createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
    likes: 345,
    views: 2876,
    shares: 78,
    comments: [],
  ),

  // ── 25 ──
  CommunityPost(
    id: '25',
    author: const CommunityUser(
        id: 'u25',
        name: 'ณรงค์ศักดิ์ พวงมาลัย',
        avatarUrl: '',
        role: UserRole.client),
    content:
        'ถูกรถชน บาดเจ็บ รถผมเสียหายหนัก แต่คนขับรถที่ชนไม่มีประกัน และไม่มีเงินจ่ายค่าเสียหาย กรมธรรม์ผมมีประกันภัยภาคสมัครใจ จะได้รับค่าชดเชยจากที่ไหนบ้างครับ?',
    category: 'category.civil',
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
    likes: 198,
    views: 1654,
    shares: 56,
    comments: [
      PostComment(
        id: 'c25',
        author: const CommunityUser(
            id: 'l5',
            name: 'ทนาย กิตติพงศ์ นิลพัท',
            avatarUrl: '',
            role: UserRole.lawyer,
            specialty: 'กฎหมายแพ่ง',
            isVerified: true),
        content:
            'มีหลายทางครับ 1) เรียกจากกองทุนทดแทนผู้ประสบภัยจากรถ (พ.ร.บ.) ของรถที่ชน 2) ถ้ารถคุณมีประกันชั้น 1 อาจคุ้มครองรถของตัวเองด้วย 3) ฟ้องคดีแพ่งเรียกค่าเสียหายจากคนขับและเจ้าของรถ',
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
        likes: 134,
      ),
    ],
  ),
];
// ─── Community Feed Screen ─────────────────────────────────────────────────────

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  List<CommunityPost> _posts = [];

  String typeLogin = "";
  final storage = FlutterSecureStorage();

  int _selectedCategoryIndex = 0;
  int _selectedTabIndex = 0;

  final List<String> _categories = [
    'category.all',
    'category.criminal',
    'category.civil',
    'category.labor',
    'category.real_estate',
    'category.family',
  ];
  final List<String> _tabs = [
    'home_tabs.popular',
    'home_tabs.newest',
    'home_tabs.saved',
  ];

  // ── Filtered & sorted posts ──────────────────────────────
  List<CommunityPost> get _filteredPosts {
    // "บันทึกไว้" — show ALL bookmarked, ignore category
    if (_selectedTabIndex == 2) {
      final result = _posts.where((p) => p.isBookmarked).toList();
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return result;
    }

    // 1) Filter by category
    List<CommunityPost> result;
    if (_selectedCategoryIndex == 0) {
      result = List.from(_posts);
    } else {
      final selectedCategory = _categories[_selectedCategoryIndex];
      result = _posts.where((p) => p.category == selectedCategory).toList();
    }

    // 2) Sort by tab
    if (_selectedTabIndex == 0) {
      result.sort((a, b) => b.likes.compareTo(a.likes));
    } else {
      result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return result;
  }

  @override
  void initState() {
    super.initState();
    UserProfileStore.instance.addListener(_onProfileChanged);
    callRead();
    _posts = List.from(mockPosts);
  }

  @override
  void dispose() {
    UserProfileStore.instance.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void callRead() async {
    final type = await storage.read(key: 'typeLogin');

    setState(() {
      typeLogin = type.toString();
    });
  }

  void _toggleLike(String postId) {
    setState(() {
      final post = _posts.firstWhere((p) => p.id == postId);
      post.isLiked ? post.likes-- : post.likes++;
      post.isLiked = !post.isLiked;
    });
  }

  void _toggleBookmark(String postId) {
    setState(() {
      final post = _posts.firstWhere((p) => p.id == postId);
      post.isBookmarked = !post.isBookmarked;
    });
    HapticFeedback.lightImpact();
  }

  void _openPostForm() async {
    final newPost = await Navigator.push<CommunityPost>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (newPost != null) {
      setState(() => _posts.insert(0, newPost));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = ResponsiveLayout.isMobile(context);
    final bool isTablet = ResponsiveLayout.isTablet(context);
    final bool isDesktop = ResponsiveLayout.isDesktop(context);

    // Responsive horizontal padding
    final double hPadding = isDesktop ? 20 : (isTablet ? 24 : 16);
    // Responsive top spacing
    final double topSpacing = isMobile ? 12 : 24;

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: isDesktop
            ? const Color.fromARGB(255, 233, 242, 249)
            : (isMobile ? Colors.white : const Color(0xFFF8F9FA)),
        body: SafeArea(
          bottom: false,
          child: AppLayout(
            child: Container(
              clipBehavior: isDesktop ? Clip.antiAlias : Clip.none,
              decoration: isDesktop
                  ? const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    )
                  : null,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: Column(
                  children: [
                    SizedBox(height: topSpacing),
                    // ── Header ──
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Column(
                        children: [
                          Text(
                            'community'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'communitySubtitle'.tr(),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCategories(isMobile: isMobile),
                    SizedBox(height: isMobile ? 12 : 24),
                    if (!isMobile) ...[
                      _buildCreatePostCard(isMobile: false),
                      const SizedBox(height: 24),
                    ],
                    _buildTabs(),
                    SizedBox(height: isMobile ? 8 : 16),
                    Expanded(child: _buildPostsList()),
                  ],
                ),
              ),
            ),
          ),
        ),
        floatingActionButton: isMobile ? _buildFAB() : null,
      ),
    );
  }

  // ── Mobile FAB ──────────────────────────────────────────
  Widget _buildFAB() {
    return GestureDetector(
      onTap: () {
        if (typeLogin != 'null') {
          _openPostForm();
        } else {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => LoginPage(isBack: true)));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: const EdgeInsets.only(bottom: 80),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF5E4BFF), Color(0xFF3D2DB5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5E4BFF).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  // ── Categories chips ────────────────────────────────────
  Widget _buildCategories({required bool isMobile}) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _categories.asMap().entries.map((entry) {
          int idx = entry.key;
          String text = entry.value;
          bool isSelected = idx == _selectedCategoryIndex;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryIndex = idx),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 6),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 20,
                vertical: isMobile ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF5E4BFF) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF5E4BFF)
                      : Colors.grey.shade300,
                ),
              ),
              child: Text(
                text.tr(),
                style: TextStyle(
                  fontSize: isMobile ? 13 : 14,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Create post card ────────────────────────────────────
  Widget _buildCreatePostCard({required bool isMobile}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 20,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            radius: isMobile ? 18 : 20,
            child: Icon(Icons.person,
                color: Colors.grey.shade500, size: isMobile ? 20 : 24),
          ),
          SizedBox(width: isMobile ? 10 : 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (typeLogin != 'null') {
                  _openPostForm();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => LoginPage(isBack: true)),
                  );
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 10 : 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'postQuestionHint'.tr(),
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: isMobile ? 13 : 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tabs (ยอดนิยม / มาใหม่) ───────────────────────────
  Widget _buildTabs() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: TabBar(
        onTap: (idx) => setState(() => _selectedTabIndex = idx),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: const Color(0xFF5E4BFF),
        labelColor: const Color(0xFF5E4BFF),
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        indicatorWeight: 2,
        dividerColor: Colors.transparent,
        tabs: _tabs.map((tabKey) {
          return Tab(
            text: tabKey.tr(), // มาแปลภาษาตรงนี้
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2))
            ]),
        child: Row(children: [
          const SizedBox(width: 14),
          Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade400),
          const SizedBox(width: 10),
          Text('searchHint'.tr(),
              style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
          const Spacer(),
          Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(10)),
            child: Text('search'.tr(),
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }

  Widget _buildPostsList() {
    final bool isMobile = ResponsiveLayout.isMobile(context);
    final posts = _filteredPosts;
    return posts.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    _selectedTabIndex == 2
                        ? Icons.bookmark_outline_rounded
                        : Icons.article_outlined,
                    size: 48,
                    color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  _selectedTabIndex == 2
                      ? 'noSavedPosts'.tr()
                      : 'noPostsInCategory'.tr(),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                ),
              ],
            ),
          )
        : ListView.separated(
            padding: EdgeInsets.fromLTRB(0, 4, 0, isMobile ? 140 : 40),
            itemCount: posts.length,
            itemBuilder: (context, index) => PostCard(
              post: posts[index],
              onLike: () => _toggleLike(posts[index].id),
              onBookmark: () => _toggleBookmark(posts[index].id),
              typeLogin: typeLogin,
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailScreen(post: posts[index]),
                  ),
                );
                setState(() {});
              },
            ),
            separatorBuilder: (context, index) => isMobile
                ? Divider(height: 1, color: Colors.grey.shade100)
                : const SizedBox(height: 16),
          );
  }
}

// ─── Post Card ─────────────────────────────────────────────────────────────────

class PostCard extends StatefulWidget {
  final CommunityPost post;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback onTap;
  final String typeLogin;

  const PostCard(
      {super.key,
      required this.post,
      required this.onLike,
      required this.onBookmark,
      required this.typeLogin,
      required this.onTap});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeCtrl;
  late Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _likeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _likeScale = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _likeCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _likeCtrl.dispose();
    super.dispose();
  }

  void _handleLike() {
    _likeCtrl.forward(from: 0);
    HapticFeedback.lightImpact();
    widget.onLike();
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'category.labor':
        return const Color(0xFF2196F3);
      case 'category.real_estate':
        return const Color(0xFF4CAF50);
      case 'category.family':
        return const Color(0xFFE91E63);
      case 'category.criminal':
        return const Color(0xFFFF5722);
      default:
        return const Color(0xFF9C27B0);
    }
  }

  String _formatTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return 'time.minutesAgo'.tr(args: [d.inMinutes.toString()]);
    if (d.inHours < 24) return 'time.hoursAgo'.tr(args: [d.inHours.toString()]);
    return 'time.daysAgo'.tr(args: [d.inDays.toString()]);
  }

  String _fmt(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';

  @override
  Widget build(BuildContext context) {
    final cc = _categoryColor(widget.post.category);
    final lawyerComments = widget.post.comments
        .where((c) => c.author.role == UserRole.lawyer)
        .toList();

    bool isDesktop = ResponsiveLayout.isDesktop(context);

    return GestureDetector(
      onTap: () {
        if (widget.typeLogin != 'null') {
          widget.onTap();
        } else {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => LoginPage(isBack: true)));
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 16, 16, 0),
        margin: isDesktop
            ? const EdgeInsets.symmetric(horizontal: 2)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isDesktop ? Border.all(color: Colors.grey.shade200) : null,
          boxShadow: isDesktop
              ? [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _avatar(widget.post.author, 42),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: widget.post.author.name,
                                    style: GoogleFonts.prompt(
                                      color: const Color(0xFF1A1A2E),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ), // Base style
                                    children: <TextSpan>[
                                      TextSpan(
                                        text: ' > ',
                                        style: GoogleFonts.prompt(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 11,
                                            color: Colors.grey.shade400),
                                      ),
                                      TextSpan(
                                        text: widget.post.category.tr(),
                                        style: GoogleFonts.prompt(
                                          fontWeight: FontWeight.w500,
                                          color: const Color(0xFF1A1A2E),
                                          // color: cc,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Text(
                                //   widget.post.author.name,
                                //   style: const TextStyle(
                                //     fontSize: 13,
                                //     fontWeight: FontWeight.w600,
                                //     color: Color(0xFF1A1A2E),
                                //   ),
                                // ),
                                // Container(
                                //   // padding: const EdgeInsets.symmetric(
                                //   //     horizontal: 10, vertical: 4),
                                //   // decoration: BoxDecoration(
                                //   //     color: cc.withOpacity(0.1),
                                //   //     borderRadius: BorderRadius.circular(8)),
                                //   child: Text(
                                //     ' > ${widget.post.category}',
                                //     style: TextStyle(
                                //       fontSize: 11,
                                //       fontWeight: FontWeight.w600,
                                //       // color: cc,
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          if (widget.typeLogin != 'null') {
                            widget.onBookmark();
                          } else {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => LoginPage(isBack: true)));
                          }
                        },
                        child: Icon(
                            widget.post.isBookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            size: 20,
                            color: widget.post.isBookmarked
                                ? Colors.yellow.shade800
                                : Colors.grey.shade300),
                      ),
                    ],
                  ),
                  Text(
                    _formatTime(widget.post.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  // Divider(height: 1, color: Colors.grey.shade100),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Text(widget.post.title,
                        //     style: const TextStyle(
                        //         fontSize: 14,
                        //         fontWeight: FontWeight.w600,
                        //         color: Color(0xFF1A1A2E),
                        //         height: 1.4,
                        //         letterSpacing: -0.3)),
                        // const SizedBox(height: 6),
                        Text(
                          widget.post.content,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1A1A2E),
                              height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  if (widget.post.imagePaths.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(widget.post.imagePaths.first),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover),
                      ),
                    ),
                  // if (lawyerComments.isNotEmpty) _lawyerPreview(lawyerComments.first),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 14),
                    child: Row(
                      children: [
                        _actionBtn(
                          icon: widget.post.isLiked
                              ? Icons.favorite_rounded
                              : Icons.favorite_outline_rounded,
                          label: _fmt(widget.post.likes),
                          color: widget.post.isLiked
                              ? const Color(0xFFE53935)
                              : const Color(0xFF9E9E9E),
                          onTap: () {
                            if (widget.typeLogin != 'null') {
                              _handleLike();
                            } else {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => LoginPage(isBack: true)));
                            }
                          },
                          scale: _likeScale,
                        ),
                        const SizedBox(width: 16),
                        _actionBtn(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: '${widget.post.comments.length}',
                          color: const Color(0xFF9E9E9E),
                          onTap: () {
                            if (widget.typeLogin != 'null') {
                              widget.onTap();
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => LoginPage(isBack: true),
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 16),
                        _actionBtn(
                            icon: Icons.ios_share_rounded,
                            label: _fmt(widget.post.shares),
                            color: const Color(0xFF9E9E9E),
                            onTap: () {
                              if (widget.typeLogin != 'null') {
                                null;
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => LoginPage(isBack: true),
                                  ),
                                );
                              }
                            }),
                        const Spacer(),
                        Icon(Icons.remove_red_eye_outlined,
                            size: 14, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(_fmt(widget.post.views),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lawyerPreview(PostComment c) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3F2FD))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
              color: const Color(0xFF1565C0),
              borderRadius: BorderRadius.circular(6)),
          child: Text('lawyerBadge'.tr(),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.author.name,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1565C0))),
          const SizedBox(height: 2),
          Text(c.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF546E7A), height: 1.4)),
        ])),
      ]),
    );
  }

  Widget _actionBtn(
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap,
      Animation<double>? scale}) {
    Widget i = Icon(icon, size: 18, color: color);
    if (scale != null)
      i = AnimatedBuilder(
          animation: scale,
          builder: (_, child) =>
              Transform.scale(scale: scale.value, child: child),
          child: i);
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          i,
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
                fontSize: 13, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _avatar(CommunityUser user, double size) {
    final isLawyer = user.role == UserRole.lawyer;
    final isMe = user.id == currentUser.id;
    final initials = user.name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join();
    return Stack(children: [
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                colors: isMe
                    ? [const Color(0xFFF57F17), const Color(0xFFFF8F00)]
                    : (isLawyer
                        ? [const Color(0xFF1565C0), const Color(0xFF1976D2)]
                        : [const Color(0xFF37474F), const Color(0xFF546E7A)]),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)),
        child: ClipOval(
          child: user.avatarUrl.isNotEmpty
              ? (user.avatarUrl.startsWith('http') || user.avatarUrl.startsWith('https')
                  ? Image.network(user.avatarUrl, fit: BoxFit.cover)
                  : Image.asset(user.avatarUrl, fit: BoxFit.cover))
              : Center(
                  child: Text(initials,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: size * 0.33,
                          fontWeight: FontWeight.w700)),
                ),
        ),
      ),
      if (user.isVerified)
        Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.33,
              height: size * 0.33,
              decoration: BoxDecoration(
                  color: const Color(0xFF00ACC1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5)),
              child: Icon(Icons.check_rounded,
                  size: size * 0.18, color: Colors.white),
            )),
    ]);
  }
}

// ─── Post Detail Screen ────────────────────────────────────────────────────────

class PostDetailScreen extends StatefulWidget {
  final CommunityPost post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late List<PostComment> _comments;
  bool _isSending = false;

  // ── Reply / Edit state ──────────────────────────────────
  PostComment? _replyTarget;
  PostComment? _editingComment;

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.post.comments);
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatTime(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return 'time.minutesAgo'.tr(args: [d.inMinutes.toString()]);
    if (d.inHours < 24) return 'time.hoursAgo'.tr(args: [d.inHours.toString()]);
    return 'time.daysAgo'.tr(args: [d.inDays.toString()]);
  }

  // ── Send comment (or reply or save edit) ────────────────
  void _sendComment() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    Future.delayed(const Duration(milliseconds: 300), () {
      // Editing existing comment
      if (_editingComment != null) {
        setState(() {
          _editingComment!.content = text;
          _editingComment = null;
          _isSending = false;
        });
        _commentCtrl.clear();
        _focusNode.unfocus();
        HapticFeedback.lightImpact();
        return;
      }

      final newComment = PostComment(
        id: 'c_${DateTime.now().millisecondsSinceEpoch}',
        author: currentUser,
        content: text,
        createdAt: DateTime.now(),
      );

      setState(() {
        if (_replyTarget != null) {
          // Add as a reply to the target comment
          _replyTarget!.replies.add(newComment);
          _replyTarget = null;
        } else {
          // Add as a top-level comment
          _comments.add(newComment);
          widget.post.comments.add(newComment);
        }
        _isSending = false;
      });
      _commentCtrl.clear();
      _focusNode.unfocus();
      HapticFeedback.lightImpact();
    });
  }

  void _startReply(PostComment target) {
    setState(() {
      _replyTarget = target;
      _editingComment = null;
    });
    _commentCtrl.clear();
    _focusNode.requestFocus();
  }

  void _startEditComment(PostComment c) {
    setState(() {
      _editingComment = c;
      _replyTarget = null;
    });
    _commentCtrl.text = c.content;
    _focusNode.requestFocus();
  }

  void _cancelReplyOrEdit() {
    setState(() {
      _replyTarget = null;
      _editingComment = null;
    });
    _commentCtrl.clear();
    _focusNode.unfocus();
  }

  // ── Edit Post ───────────────────────────────────────────
  void _editPost() {
    final ctrl = TextEditingController(text: widget.post.content);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('editPost'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          decoration: InputDecoration(
            hintText: 'postContentHint'.tr(),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('cancel'.tr(), style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E4BFF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                setState(() => widget.post.content = ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: Text('save'.tr(), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: isDesktop ? const Color.fromARGB(255, 233, 242, 249) : const Color(0xFFF5F4F0),
      appBar: isDesktop
          ? null
          : appBarCustom(
              title: "postDetailTitle".tr(),
              backBtn: true,
              isRightWidget: false,
              backAction: () => goBack(),
            ),
      body: AppLayout(
        child: Container(
          clipBehavior: isDesktop ? Clip.antiAlias : Clip.none,
          decoration: isDesktop
              ? const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                )
              : null,
          child: Column(
            children: [
              if (isDesktop) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                        onPressed: () => goBack(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "postDetailTitle".tr(),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPostContent(),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'commentsAndAnswers'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A2E),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_comments.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._comments.map((c) => _buildCommentCard(c)),
                      if (_comments.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Icon(Icons.chat_bubble_outline_rounded,
                                    size: 40, color: Colors.grey.shade300),
                                const SizedBox(height: 10),
                                Text(
                                  'noComments'.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade400,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _buildCommentInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostContent() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 3))
          ]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _avatar(widget.post.author, 38),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.post.author.name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              Text(_formatTime(widget.post.createdAt),
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
            ]),
          ),
          if (widget.post.author.id == currentUser.id)
            GestureDetector(
              onTap: _editPost,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F4F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.edit_outlined,
                    size: 18, color: Color(0xFF5E4BFF)),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        // Text(
        //   widget.post.title,
        //   style: const TextStyle(
        //       fontSize: 17,
        //       fontWeight: FontWeight.w800,
        //       color: Color(0xFF1A1A2E),
        //       height: 1.4,
        //       letterSpacing: -0.5),
        // ),
        const SizedBox(height: 8),
        Text(
          widget.post.content,
          style: const TextStyle(
              fontSize: 14, color: Color(0xFF1A1A2E), height: 1.6),
        ),
        if (widget.post.imagePaths.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(widget.post.imagePaths.first),
                  width: double.infinity, fit: BoxFit.cover)),
        ],
        const SizedBox(height: 16),
        Row(children: [
          _statChip(Icons.favorite_rounded, '${widget.post.likes}',
              const Color(0xFFE53935)),
          const SizedBox(width: 12),
          _statChip(Icons.chat_bubble_outline_rounded,
              '${widget.post.comments.length}', const Color(0xFF1565C0)),
          const SizedBox(width: 12),
          _statChip(Icons.remove_red_eye_outlined, '${widget.post.views}',
              const Color(0xFF9E9E9E)),
        ]),
      ]),
    );
  }

  Widget _buildCommentCard(PostComment c, {bool isReply = false}) {
    final isLawyer = c.author.role == UserRole.lawyer;
    final isMe = c.author.id == currentUser.id;
    return Padding(
      padding: EdgeInsets.only(left: isReply ? 32 : 0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFFFFF8E1)
              : (isLawyer ? const Color(0xFFF0F7FF) : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: isMe
              ? Border.all(color: const Color(0xFFFFE082))
              : (isLawyer ? Border.all(color: const Color(0xFFBBDEFB)) : null),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _avatar(c.author, 36),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Flexible(
                        child: Text(
                      isMe ? 'you'.tr() : c.author.name,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isMe
                              ? const Color(0xFFF57F17)
                              : (isLawyer
                                  ? const Color(0xFF1565C0)
                                  : const Color(0xFF1A1A2E))),
                    )),
                    if (isLawyer) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: const Color(0xFF1565C0),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(c.author.specialty ?? 'lawyerBadge'.tr(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: const Color(0xFFF57F17),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text('you'.tr(),
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ]),
                  Text(_formatTime(c.createdAt),
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF9E9E9E))),
                ])),
          ]),
          const SizedBox(height: 10),
          Text(c.content,
              style: TextStyle(
                  fontSize: 13,
                  color: isLawyer
                      ? const Color(0xFF37474F)
                      : const Color(0xFF616161),
                  height: 1.6)),
          const SizedBox(height: 10),
          Row(children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  c.isLiked ? c.likes-- : c.likes++;
                  c.isLiked = !c.isLiked;
                });
                HapticFeedback.lightImpact();
              },
              child: Row(children: [
                Icon(
                    c.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_outline_rounded,
                    size: 15,
                    color: c.isLiked
                        ? const Color(0xFFE53935)
                        : Colors.grey.shade400),
                const SizedBox(width: 4),
                Text('${c.likes}',
                    style: TextStyle(
                        fontSize: 12,
                        color: c.isLiked
                            ? const Color(0xFFE53935)
                            : Colors.grey.shade400)),
              ]),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => _startReply(c),
              child: Text('reply'.tr(),
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500)),
            ),
            if (isMe) ...[
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _startEditComment(c),
                child: Text('edit'.tr(),
                    style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF5E4BFF),
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ]),
          // ── Nested replies ──
          if (c.replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...c.replies.map((r) => _buildCommentCard(r, isReply: true)),
          ],
        ]),
      ),
    );
  }

  Widget _buildCommentInput() {
    final hasContext = _replyTarget != null || _editingComment != null;
    String hintText = 'commentHint'.tr();
    if (_replyTarget != null) {
      hintText = 'replyingTo'.tr(args: [_replyTarget!.author.name]);
    } else if (_editingComment != null) {
      hintText = 'editingComment'.tr();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Context banner (reply / edit) ──
        if (hasContext)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _editingComment != null
                ? const Color(0xFFF3F0FF)
                : const Color(0xFFF0F7FF),
            child: Row(children: [
              Icon(
                _editingComment != null
                    ? Icons.edit_outlined
                    : Icons.reply_rounded,
                size: 16,
                color: _editingComment != null
                    ? const Color(0xFF5E4BFF)
                    : const Color(0xFF1565C0),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _editingComment != null
                      ? 'editingComment'.tr()
                      : 'replyingTo'.tr(args: [_replyTarget!.author.name]),
                  style: TextStyle(
                    fontSize: 12,
                    color: _editingComment != null
                        ? const Color(0xFF5E4BFF)
                        : const Color(0xFF1565C0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _cancelReplyOrEdit,
                child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
              ),
            ]),
          ),
        // ── Input row ──
        Container(
          padding: EdgeInsets.fromLTRB(
              16, 12, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, -3))
          ]),
          child: Row(children: [
            _avatar(currentUser, 34),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                    color: const Color(0xFFF5F4F0),
                    borderRadius: BorderRadius.circular(14)),
                child: TextField(
                  controller: _commentCtrl,
                  focusNode: _focusNode,
                  decoration: InputDecoration.collapsed(
                    hintText: hintText,
                    hintStyle:
                        const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
                  ),
                  style:
                      const TextStyle(fontSize: 13, color: Color(0xFF1A1A2E)),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendComment(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: _sendComment,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF2D2D5E), Color(0xFF1A1A2E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _isSending
                    ? const Center(
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)))
                    : Icon(
                        _editingComment != null
                            ? Icons.check_rounded
                            : Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _avatar(CommunityUser user, double size) {
    final isLawyer = user.role == UserRole.lawyer;
    final isMe = user.id == currentUser.id;
    final initials = user.name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join();
    return Stack(children: [
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
                colors: isMe
                    ? [const Color(0xFFF57F17), const Color(0xFFFF8F00)]
                    : (isLawyer
                        ? [const Color(0xFF1565C0), const Color(0xFF1976D2)]
                        : [const Color(0xFF37474F), const Color(0xFF546E7A)]),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight)),
        child: ClipOval(
          child: user.avatarUrl.isNotEmpty
              ? (user.avatarUrl.startsWith('http') || user.avatarUrl.startsWith('https')
                  ? Image.network(user.avatarUrl, fit: BoxFit.cover)
                  : Image.asset(user.avatarUrl, fit: BoxFit.cover))
              : Center(
                  child: Text(initials,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: size * 0.33,
                          fontWeight: FontWeight.w700)),
                ),
        ),
      ),
      if (user.isVerified)
        Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: size * 0.33,
              height: size * 0.33,
              decoration: BoxDecoration(
                  color: const Color(0xFF00ACC1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5)),
              child: Icon(Icons.check_rounded,
                  size: size * 0.18, color: Colors.white),
            )),
    ]);
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Row(children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(label,
          style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w500))
    ]);
  }

  void goBack() async {
    Navigator.pop(context, false);
  }
}

// ─── Create Post Screen ────────────────────────────────────────────────────────

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _contentCtrl = TextEditingController();
  String? _selectedCategory;
  final List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isPosting = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'label': 'category.labor',
      'icon': Icons.work_outline_rounded,
      'color': const Color(0xFF2196F3)
    },
    {
      'label': 'category.real_estate',
      'icon': Icons.home_outlined,
      'color': const Color(0xFF4CAF50)
    },
    {
      'label': 'category.family',
      'icon': Icons.people_outline_rounded,
      'color': const Color(0xFFE91E63)
    },
    {
      'label': 'category.criminal',
      'icon': Icons.gavel_rounded,
      'color': const Color(0xFFFF5722)
    },
    {
      'label': 'category.civil',
      'icon': Icons.balance_outlined,
      'color': const Color(0xFF9C27B0)
    },
    {
      'label': 'other',
      'icon': Icons.help_outline_rounded,
      'color': const Color(0xFF607D8B)
    },
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 80);
    if (images.isNotEmpty) {
      setState(() {
        for (final img in images) {
          if (_selectedImages.length < 4) _selectedImages.add(img);
        }
      });
    }
  }

  Future<void> _pickFromCamera() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (image != null && _selectedImages.length < 4)
      setState(() => _selectedImages.add(image));
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AppLayout(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('addImages'.tr(),
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _imgSourceBtn(
                      Icons.photo_library_outlined, 'gallery'.tr(), () {
                Navigator.pop(context);
                _pickFromGallery();
              })),
              const SizedBox(width: 12),
              Expanded(
                  child: _imgSourceBtn(
                      Icons.camera_alt_outlined, 'camera'.tr(), () {
                Navigator.pop(context);
                _pickFromCamera();
              })),
            ]),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    ),
  );
}

  Widget _imgSourceBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
            color: const Color(0xFFF5F4F0),
            borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          Icon(icon, size: 28, color: const Color(0xFF1A1A2E)),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1A1A2E))),
        ]),
      ),
    );
  }

  void _submitPost() async {
    if (_contentCtrl.text.trim().isEmpty) {
      _showError('enterDetails'.tr());
      return;
    }
    if (_selectedCategory == null) {
      _showError('selectCategory'.tr());
      return;
    }

    setState(() => _isPosting = true);
    await Future.delayed(const Duration(milliseconds: 600));

    final newPost = CommunityPost(
      id: 'p_${DateTime.now().millisecondsSinceEpoch}',
      author: currentUser,
      // title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      category: _selectedCategory!,
      createdAt: DateTime.now(),
      imagePaths: _selectedImages.map((x) => x.path).toList(),
    );
    if (mounted) Navigator.pop(context, newPost);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFFE53935),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ));
  }

  bool get _canPost =>
      _contentCtrl.text.trim().isNotEmpty && _selectedCategory != null;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: isDesktop ? const Color.fromARGB(255, 233, 242, 249) : const Color(0xFFF5F4F0),
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF5F4F0),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.close_rounded,
                      size: 20, color: Color(0xFF1A1A2E)),
                ),
              ),
              title: Text('newQuestion'.tr(),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              centerTitle: true,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: _canPost && !_isPosting ? _submitPost : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: _canPost
                              ? const Color(0xFF1A1A2E)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10)),
                      child: _isPosting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : Text('post'.tr(),
                              style: TextStyle(
                                  color:
                                      _canPost ? Colors.white : Colors.grey.shade400,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
      body: AppLayout(
        child: Container(
          clipBehavior: isDesktop ? Clip.antiAlias : Clip.none,
          decoration: isDesktop
              ? const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                )
              : null,
          child: Column(
            children: [
              if (isDesktop) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF5F4F0),
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.close_rounded,
                              size: 20, color: Color(0xFF1A1A2E)),
                        ),
                      ),
                      Text(
                        'newQuestion'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      GestureDetector(
                        onTap: _canPost && !_isPosting ? _submitPost : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                              color: _canPost
                                  ? const Color(0xFF1A1A2E)
                                  : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10)),
                          child: _isPosting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : Text('post'.tr(),
                                  style: TextStyle(
                                      color: _canPost ? Colors.white : Colors.grey.shade400,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
          // User info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]),
            child: Row(children: [
              _avatarWidget(currentUser, 40),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(currentUser.name,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
                Text('postPublicly'.tr(),
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9E9E9E))),
              ]),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: const Color(0xFFF5F4F0),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  Icon(Icons.public_rounded,
                      size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('public'.tr(),
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade600))
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 16),

          // Category
          Text('problemCategory'.tr(),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat['label'];
              final color = cat['color'] as Color;
              return GestureDetector(
                onTap: () =>
                    setState(() => _selectedCategory = cat['label'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: isSelected ? color : Colors.grey.shade200,
                        width: 1.5),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ]
                        : [],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(cat['icon'] as IconData,
                        size: 16, color: isSelected ? Colors.white : color),
                    const SizedBox(width: 6),
                    Text((cat['label'] as String).tr(),
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF424242))),
                  ]),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // // Title
          // const Text('หัวข้อคำถาม *',
          //     style: TextStyle(
          //         fontSize: 13,
          //         fontWeight: FontWeight.w700,
          //         color: Color(0xFF1A1A2E))),
          // const SizedBox(height: 8),
          // Container(
          //   decoration: BoxDecoration(
          //       color: Colors.white,
          //       borderRadius: BorderRadius.circular(14),
          //       boxShadow: [
          //         BoxShadow(
          //             color: Colors.black.withOpacity(0.04),
          //             blurRadius: 8,
          //             offset: const Offset(0, 2))
          //       ]),
          //   child: TextField(
          //     controller: _titleCtrl,
          //     onChanged: (_) => setState(() {}),
          //     decoration: const InputDecoration(
          //       hintText: 'เช่น "ถูกเลิกจ้างไม่มีสาเหตุ ต้องทำอย่างไร?"',
          //       hintStyle: TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
          //       contentPadding: EdgeInsets.all(16),
          //       border: InputBorder.none,
          //     ),
          //     style: const TextStyle(
          //         fontSize: 14,
          //         color: Color(0xFF1A1A2E),
          //         fontWeight: FontWeight.w600),
          //     maxLines: 2,
          //   ),
          // ),

          const SizedBox(height: 14),

          // Content
          Text('details'.tr(),
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]),
            child: TextField(
              controller: _contentCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText:
                    'describeProblemHint'.tr(),
                hintStyle: TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
              ),
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF424242), height: 1.6),
              maxLines: 6,
              minLines: 4,
            ),
          ),

          const SizedBox(height: 14),

          // Images
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('attachmentImages'.tr(),
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E))),
            Text('${_selectedImages.length}/4',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ]),
          const SizedBox(height: 8),

          if (_selectedImages.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length +
                    (_selectedImages.length < 4 ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == _selectedImages.length) {
                    return GestureDetector(
                      onTap: _showImageSourceSheet,
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.shade200, width: 1.5)),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded,
                                  size: 24, color: Colors.grey.shade400),
                              const SizedBox(height: 4),
                              Text('addImage'.tr(),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade400)),
                            ]),
                      ),
                    );
                  }
                  return Stack(children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(File(_selectedImages[i].path),
                              fit: BoxFit.cover)),
                    ),
                    Positioned(
                        top: 4,
                        right: 12,
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedImages.removeAt(i)),
                          child: Container(
                              width: 22,
                              height: 22,
                              decoration: const BoxDecoration(
                                  color: Color(0xFFE53935),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.close_rounded,
                                  size: 14, color: Colors.white)),
                        )),
                  ]);
                },
              ),
            )
          else
            GestureDetector(
              onTap: _showImageSourceSheet,
              child: Container(
                width: double.infinity,
                height: 90,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: Colors.grey.shade200, width: 1.5)),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 28, color: Colors.grey.shade400),
                      const SizedBox(height: 6),
                      Text('tapToAddImages'.tr(),
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade400)),
                    ]),
              ),
            ),

          const SizedBox(height: 20),

          // Tips
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBDEFB))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 18, color: Color(0xFF1565C0)),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('tipTitle'.tr(),
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1565C0))),
                    const SizedBox(height: 4),
                    Text(
                        'tipBody'.tr(),
                        style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.blue.shade700,
                            height: 1.5)),
                  ])),
            ]),
          ),

          const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarWidget(CommunityUser user, double size) {
    final initials = user.name
        .split(' ')
        .map((e) => e.isNotEmpty ? e[0] : '')
        .take(2)
        .join();
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
              colors: [Color(0xFFF57F17), Color(0xFFFF8F00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight)),
      child: ClipOval(
        child: user.avatarUrl.isNotEmpty
            ? (user.avatarUrl.startsWith('http') || user.avatarUrl.startsWith('https')
                ? Image.network(user.avatarUrl, fit: BoxFit.cover)
                : Image.asset(user.avatarUrl, fit: BoxFit.cover))
            : Center(
                child: Text(initials,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.33,
                        fontWeight: FontWeight.w700)),
              ),
      ),
    );
  }
}
