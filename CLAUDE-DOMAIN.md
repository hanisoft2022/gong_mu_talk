# CLAUDE-DOMAIN.md

**Domain Knowledge for GongMuTalk Project**

This document contains detailed domain knowledge about Korean public servant systems that AI agents should understand when working on this project.

📚 **Main Document**: [CLAUDE.md](CLAUDE.md)

---

## GongMuTalk Domain Knowledge

### Korean Public Servant Salary System

**Core Concepts AI Must Understand**:

```dart
// Grade System (호봉)
// - Determines base salary
// - Increases annually (usually)
// - Range: 1-40+ depending on career track
int grade = 15; // 15호봉

// Career Track (직렬)
// - Determines job category and salary table
// - Examples: 교육공무원(educators), 소방(firefighters), 세무(tax officials)
String careerTrack = '교육공무원';

// Allowances (수당)
// - Multiple types: family, meal, commute, regional, etc.
// - Different rules per career track
Map<String, int> allowances = {
  'family': 100000,  // 가족수당
  'meal': 130000,    // 식비
  'commute': 50000,  // 교통비
  'position': 200000, // 직급보조비
};

// Tax Deductions (세금)
// - National tax (국세)
// - Local tax (지방세)
// - National pension (국민연금)
// - Health insurance (건강보험)
// - Employment insurance (고용보험)
```

**Salary Calculation Flow**:
```
1. Determine base salary from grade + career track table
2. Add all applicable allowances
3. Calculate gross salary
4. Deduct taxes (progressive rates)
5. Deduct social insurance
6. Result = net salary (실수령액)
```

### Career Track Verification System

**How Paystub OCR Works**:

```
User uploads paystub image/PDF
├─ 1. Vision API extracts text
│     └─ Returns raw OCR text
│
├─ 2. Career track detection
│     └─ Match keywords in text:
│        - "교육공무원" → Elementary/Middle/High School Teacher
│        - "소방" → Firefighter
│        - "세무" → Tax Official
│        - "경찰" → Police Officer
│        └─ Use massive keyword mapping (functions/src/paystubVerification.ts)
│
├─ 3. Salary verification
│     └─ Extract numeric values
│        - Base salary matches grade?
│        - Allowances reasonable?
│
└─ 4. Update user profile
      └─ Set career track
      └─ Mark as verified
      └─ Grant lounge access
```

**Important**: If you modify career verification, understand that it affects:
- User authentication level
- Lounge access permissions
- Community visibility
- Salary calculator accuracy

### Lounge Hierarchy System

**Structure**:
```
Lounges (라운지)
├─ Root Lounges (직렬 라운지)
│  ├─ 교육공무원 (Educators)
│  ├─ 소방공무원 (Firefighters)
│  ├─ 세무공무원 (Tax Officials)
│  └─ ...
│
└─ Sub-Lounges (세부 직렬 라운지)
   └─ 교육공무원
      ├─ 초등교사 (Elementary Teachers)
      ├─ 중등교사 (Middle School Teachers)
      ├─ 고등교사 (High School Teachers)
      └─ 교육전문직 (Education Specialists)
```

**Access Rules**:
- Unverified users: See only public posts
- Verified users: Access their career track lounge + sub-lounges
- Posts in lounges are semi-anonymous (position shown, not full name)

**When Building Lounge Features**:
- Always check user verification status
- Filter posts by lounge membership
- Respect hierarchy (sub-lounge users can see parent lounge)
- Handle anonymous/semi-anonymous display logic

### Semi-Anonymous System

**Key Concept**: Users are authenticated but displayed semi-anonymously

```dart
// Real user data
User {
  uid: "abc123",
  name: "김철수",
  careerTrack: "교육공무원",
  position: "초등교사",
  verified: true,
}

// Displayed in community
Post {
  author: "초등교사 5년차", // Position + years, NO name
  content: "...",
  lounge: "교육공무원/초등교사",
}
```

**Privacy Protection Rules**:
- ✅ Show: Career track, position, years of service
- ❌ Hide: Name, specific workplace, exact location
- ✅ Show only in lounge: Detailed career info
- ❌ Never show publicly: Contact info, government ID

---

## When to Reference This Document

**AI agents should read CLAUDE-DOMAIN.md when**:
- Working on salary/pension calculator features
- Implementing career track verification
- Building lounge/community features
- Handling user privacy/anonymity logic
- Questions about Korean public servant systems

**Don't need to read if**:
- Working on UI-only changes
- General architectural questions
- Testing strategy questions
- Code quality/linting issues
