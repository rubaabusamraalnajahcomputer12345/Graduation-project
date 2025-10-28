# Hidaya Frontend Components Documentation

## Overview

This document provides comprehensive documentation for all Flutter widgets and components used in the Hidaya mobile/web application. The app is built using Flutter with Provider for state management.

## Architecture

The app follows a modular architecture with the following structure:

```
lib/
├── main.dart              # App entry point
├── config.dart           # Configuration settings
├── constants/            # App constants and colors
├── providers/            # State management (Provider pattern)
├── services/             # API services and utilities
├── utils/                # Helper utilities
└── widgets/              # UI components
    ├── Admin/            # Admin-specific components
    └── Stories/          # Story-related components
```

## Core Components

### 1. QuestionCard Widget

A comprehensive widget for displaying questions with answers, voting, and interaction features.

**File:** `lib/widgets/QuestionCard.dart`

**Purpose:** Display questions in a card format with support for answers, voting, reporting, and AI responses.

**Properties:**
```dart
class QuestionCard extends StatefulWidget {
  final Map<String, dynamic> question;     // Question data
  final VoidCallback? onRefresh;           // Refresh callback
  final void Function(Map<String, dynamic> updatedFields)? onUpdate;  // Update callback
  final VoidCallback? onReportSuccess;     // Report success callback
  final VoidCallback? onReportAnswerSuccess; // Report answer success callback
}
```

**Key Features:**
- Responsive design for mobile, tablet, and desktop
- Answer submission and voting
- Question reporting functionality
- AI-generated answer display
- User profile navigation
- Save/bookmark functionality

**Usage Example:**
```dart
QuestionCard(
  question: {
    'id': 'question123',
    'question': 'What are the five pillars of Islam?',
    'category': 'pillars',
    'userName': 'Ahmed Hassan',
    'userGender': 'male',
    'createdAt': '2024-01-15T10:30:00Z',
    'topAnswerId': 'answer456',
    'answersCount': 3,
    'aiAnswer': 'The five pillars of Islam are...'
  },
  onRefresh: () {
    // Refresh questions list
    _loadQuestions();
  },
  onUpdate: (updatedFields) {
    // Handle question updates
    setState(() {
      // Update question data
    });
  },
)
```

**Responsive Methods:**
```dart
// Font size adaptation
double _getResponsiveFontSize(double baseSize) {
  final screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth >= 1200) return baseSize * 1.2;      // Desktop
  else if (screenWidth >= 768) return baseSize * 1.1;  // Tablet
  else return baseSize;                                 // Mobile
}

// Icon size adaptation
double _getResponsiveIconSize(double baseSize) {
  final screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth >= 1200) return baseSize * 1.3;      // Desktop
  else if (screenWidth >= 768) return baseSize * 1.15; // Tablet
  else return baseSize;                                 // Mobile
}
```

### 2. ResponsiveLayout Widget

Main layout component that adapts to different screen sizes.

**File:** `lib/widgets/ResponsiveLayou.dart`

**Purpose:** Provide responsive navigation and layout structure for the entire app.

**Features:**
- Adaptive navigation (bottom bar for mobile, side drawer for desktop)
- Multi-page support with navigation
- User authentication integration
- Responsive breakpoints

**Usage Example:**
```dart
ResponsiveLayout(
  currentIndex: 0,
  onPageChanged: (index) {
    setState(() {
      currentPageIndex = index;
    });
  },
)
```

### 3. HomePage Widget

Main dashboard displaying questions, stories, and user activity.

**File:** `lib/widgets/HomePage.dart`

**Features:**
- Question feed with infinite scrolling
- Category filtering
- Search functionality
- User activity tracking
- Pull-to-refresh

**Key Methods:**
```dart
// Load questions with pagination
Future<void> _loadQuestions({bool refresh = false}) async {
  // Implementation for loading questions
}

// Filter questions by category
void _filterByCategory(String category) {
  // Implementation for category filtering
}

// Search questions
void _searchQuestions(String query) {
  // Implementation for search functionality
}
```

### 4. RegisterPage Widget

User registration form with validation and role selection.

**File:** `lib/widgets/RegisterPage.dart`

**Features:**
- Multi-step registration process
- Form validation
- Role selection (user/volunteer)
- Volunteer certification upload
- Country and language selection

**Form Fields:**
```dart
final _formKey = GlobalKey<FormState>();
final TextEditingController _nameController = TextEditingController();
final TextEditingController _emailController = TextEditingController();
final TextEditingController _passwordController = TextEditingController();
final TextEditingController _bioController = TextEditingController();
```

**Validation Example:**
```dart
String? _validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
    return 'Please enter a valid email';
  }
  return null;
}

String? _validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}
```

### 5. ProfilePage Widget

Comprehensive user profile management.

**File:** `lib/widgets/ProfilePage.dart`

**Features:**
- Profile information display and editing
- Settings management
- Volunteer status and certification
- User statistics
- Account management

**Profile Sections:**
- Personal Information
- Statistics (questions asked, answers given)
- Settings (notifications, language)
- Volunteer Dashboard (if applicable)
- Account Actions (logout, delete account)

### 6. LessonsPage Widget

Islamic lessons and educational content.

**File:** `lib/widgets/LessonsPage.dart`

**Features:**
- Lesson categories and filtering
- Progress tracking
- Video playback
- Interactive content
- Completion certificates

**Lesson Data Structure:**
```dart
class Lesson {
  final String id;
  final String title;
  final String description;
  final String category;
  final String difficulty;
  final String duration;
  final String? videoUrl;
  final List<String> content;
  final bool completed;
  final double progress;
}
```

### 7. NotificationCenter Widget

Notification management and display.

**File:** `lib/widgets/NotificationCenter.dart`

**Features:**
- Real-time notification display
- Notification categories
- Mark as read/unread
- Notification settings

**Notification Types:**
- New answers to questions
- Question status updates
- Meeting requests
- System announcements
- Volunteer approvals

### 8. PrayerTimesWidget

Islamic prayer times display.

**File:** `lib/widgets/PrayerTimesWidget.dart`

**Features:**
- Location-based prayer times
- Next prayer countdown
- Qibla direction
- Prayer notifications

**Usage Example:**
```dart
PrayerTimesWidget(
  location: UserLocation(
    latitude: 30.0444,
    longitude: 31.2357,
    city: 'Cairo',
    country: 'Egypt'
  ),
  onPrayerTimeUpdate: (nextPrayer) {
    // Handle prayer time updates
  },
)
```

## State Management

### UserProvider

Manages user authentication and profile state.

**File:** `lib/providers/UserProvider.dart`

**Key Methods:**
```dart
class UserProvider with ChangeNotifier {
  User? _user;
  bool _isLoggedIn = false;
  
  // Getters
  User? get user => _user;
  bool get isLoggedIn => _isLoggedIn;
  
  // Methods
  Future<void> login(String email, String password, String role);
  Future<void> logout();
  Future<void> updateProfile(Map<String, dynamic> profileData);
  Future<void> loadUserFromPrefs();
}
```

**Usage in Widgets:**
```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoggedIn) {
          return AuthenticatedView();
        } else {
          return LoginView();
        }
      },
    );
  }
}
```

### NavigationProvider

Manages app navigation state.

**File:** `lib/providers/NavigationProvider.dart`

```dart
class NavigationProvider with ChangeNotifier {
  int _currentIndex = 0;
  
  int get currentIndex => _currentIndex;
  
  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }
}
```

## Services

### API Service

HTTP client for backend communication.

**File:** `lib/services/api_service.dart`

**Key Methods:**
```dart
class ApiService {
  static const String baseUrl = 'https://api.hidaya.com';
  
  static Future<Map<String, dynamic>> get(String endpoint);
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> data);
  static Future<Map<String, dynamic>> put(String endpoint, Map<String, dynamic> data);
  static Future<bool> delete(String endpoint);
}
```

### Meeting Request Service

Manages meeting requests between users and volunteers.

**File:** `lib/services/meeting_request_service.dart`

**Features:**
- Create meeting requests
- Manage time slots
- Volunteer assignment
- Meeting status tracking

## Utility Components

### Custom Widgets

#### CustomTextField
Reusable text input field with validation.

```dart
class CustomTextField extends StatelessWidget {
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscureText;
  final TextInputType keyboardType;
  
  const CustomTextField({
    required this.label,
    required this.controller,
    this.hintText,
    this.validator,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });
}
```

#### ReportModal
Modal dialog for reporting content.

```dart
class ReportModal extends StatefulWidget {
  final String contentType; // 'question' or 'answer'
  final String contentId;
  final VoidCallback? onReportSuccess;
}
```

#### AIResponseCard
Display AI-generated responses.

```dart
class AIResponseCard extends StatelessWidget {
  final String response;
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;
}
```

## Styling and Theming

### Colors
**File:** `lib/constants/colors.dart`

```dart
class AppColors {
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color lightGreen = Color(0xFFE8F5E8);
  static const Color darkGreen = Color(0xFF2E7D32);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
}
```

### Typography
Using Google Fonts for Arabic and Latin text support.

```dart
TextStyle get headingStyle => GoogleFonts.amiri(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: AppColors.textPrimary,
);

TextStyle get bodyStyle => GoogleFonts.openSans(
  fontSize: 16,
  color: AppColors.textSecondary,
);
```

## Responsive Design Guidelines

### Breakpoints
- Mobile: < 768px
- Tablet: 768px - 1199px  
- Desktop: ≥ 1200px

### Responsive Implementation
```dart
// Screen size detection
bool isMobile = MediaQuery.of(context).size.width < 768;
bool isTablet = MediaQuery.of(context).size.width >= 768 && 
                MediaQuery.of(context).size.width < 1200;
bool isDesktop = MediaQuery.of(context).size.width >= 1200;

// Adaptive padding
EdgeInsets getResponsivePadding() {
  if (isDesktop) return EdgeInsets.all(24);
  if (isTablet) return EdgeInsets.all(20);
  return EdgeInsets.all(16);
}

// Adaptive grid columns
int getGridColumns() {
  if (isDesktop) return 3;
  if (isTablet) return 2;
  return 1;
}
```

## Configuration

### App Configuration
**File:** `lib/config.dart`

```dart
class Config {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.hidaya.com'
  );
  
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
}
```

### Environment Variables
Required environment variables for the app:

```bash
API_BASE_URL=https://api.hidaya.com
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
GEMINI_API_KEY=your_gemini_api_key
```

## Testing

### Widget Testing Examples

```dart
// Test QuestionCard widget
testWidgets('QuestionCard displays question data correctly', (WidgetTester tester) async {
  final question = {
    'id': 'test123',
    'question': 'Test question?',
    'userName': 'Test User',
    'createdAt': '2024-01-15T10:30:00Z'
  };

  await tester.pumpWidget(
    MaterialApp(
      home: QuestionCard(question: question),
    ),
  );

  expect(find.text('Test question?'), findsOneWidget);
  expect(find.text('Test User'), findsOneWidget);
});

// Test user login flow
testWidgets('User can login successfully', (WidgetTester tester) async {
  await tester.pumpWidget(MyApp());
  
  // Navigate to login
  await tester.tap(find.text('Login'));
  await tester.pumpAndSettle();
  
  // Enter credentials
  await tester.enterText(find.byType(TextField).first, 'test@example.com');
  await tester.enterText(find.byType(TextField).last, 'password123');
  
  // Submit login
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
  
  // Verify navigation to home
  expect(find.text('Welcome'), findsOneWidget);
});
```

## Performance Optimization

### Best Practices

1. **Lazy Loading:** Use pagination for large lists
2. **Image Caching:** Use `cached_network_image` for efficient image loading
3. **State Management:** Minimize widget rebuilds with proper Provider usage
4. **Memory Management:** Dispose controllers and subscriptions properly

```dart
// Efficient list building
ListView.builder(
  itemCount: questions.length,
  itemBuilder: (context, index) {
    if (index == questions.length - 1 && hasMoreData) {
      _loadMoreQuestions();
    }
    return QuestionCard(question: questions[index]);
  },
)

// Proper disposal
@override
void dispose() {
  _controller.dispose();
  _scrollController.dispose();
  super.dispose();
}
```

## Accessibility

### Implementation Guidelines

1. **Semantic Labels:** Add semantic labels for screen readers
2. **Color Contrast:** Ensure sufficient color contrast ratios
3. **Text Scaling:** Support dynamic text scaling
4. **Navigation:** Provide keyboard navigation support

```dart
// Accessibility example
Semantics(
  label: 'Submit question button',
  hint: 'Double tap to submit your question',
  child: ElevatedButton(
    onPressed: _submitQuestion,
    child: Text('Submit'),
  ),
)
```

## Deployment

### Build Configuration

```bash
# Build for web
flutter build web --release

# Build for Android
flutter build apk --release
flutter build appbundle --release



### Platform-Specific Considerations

- **Web:** Configure CORS for API calls
- **Android:** Set up proper permissions and ProGuard rules
- **iOS:** Configure App Transport Security and permissions

This documentation serves as a comprehensive guide for developers working with the Hidaya Flutter application. For specific implementation details, refer to the individual widget files in the codebase.