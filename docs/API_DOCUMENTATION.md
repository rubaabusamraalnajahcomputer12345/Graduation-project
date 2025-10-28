# Hidaya API Documentation

## Overview

Hidaya is an Islamic app providing Q&A functionality, lessons, volunteers, meeting requests, stories, and AI-powered chat assistance. This documentation covers all public APIs, endpoints, and their usage.

## Base URL
```
Production: https://your-production-url.com
Development: http://localhost:3000
```

## Authentication

Most endpoints require authentication using JWT tokens. Include the token in the Authorization header:

```
Authorization: Bearer <your-jwt-token>
```

## Response Format

All API responses follow this standard format:

```json
{
  "status": true|false,
  "message": "Description of the result",
  "data": {} // Response data (when applicable)
}
```

---

## Authentication Endpoints

### POST /register
Register a new user account.

**Request Body:**
```json
{
  "displayName": "string",
  "email": "string",
  "password": "string",
  "gender": "male|female|other",
  "country": "string",
  "role": "user|volunteer_pending|certified_volunteer|admin",
  "language": "string",
  "certification_title": "string (optional, for volunteers)",
  "certification_institution": "string (optional)",
  "certification_url": "string (optional)",
  "bio": "string (optional)",
  "spoken_languages": ["array of strings"]
}
```

**Response:**
```json
{
  "status": true,
  "success": "User registered successfully",
  "user": {
    "id": "string",
    "displayName": "string",
    "email": "string",
    "role": "string",
    "country": "string",
    "gender": "string"
  }
}
```

**Example Usage:**
```javascript
const response = await fetch('/register', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    displayName: "Ahmed Hassan",
    email: "ahmed@example.com",
    password: "securePassword123",
    gender: "male",
    country: "Egypt",
    role: "user",
    language: "ar"
  })
});
```

### POST /login
Authenticate user and receive JWT token.

**Request Body:**
```json
{
  "email": "string",
  "password": "string",
  "role": "user|volunteer_pending|certified_volunteer|admin"
}
```

**Response:**
```json
{
  "status": true,
  "success": "sendData",
  "token": "jwt-token-string",
  "user": {
    "id": "string",
    "displayName": "string",
    "email": "string",
    "role": "string"
  }
}
```

### GET /verify/:token
Verify email address using verification token.

**Parameters:**
- `token` (path): Email verification token

**Response:**
```json
{
  "status": true,
  "message": "Email verified successfully"
}
```

---

## User Management Endpoints

### PUT /profile
Update user profile information. Requires authentication.

**Request Body:**
```json
{
  "displayName": "string (optional)",
  "bio": "string (optional)",
  "spoken_languages": ["array of strings (optional)"]
}
```

### PUT /city
Update user's city. Requires authentication.

**Request Body:**
```json
{
  "city": "string"
}
```

### PUT /change-password
Change user password. Requires authentication.

**Request Body:**
```json
{
  "currentPassword": "string",
  "newPassword": "string"
}
```

### DELETE /delete-account
Delete user account. Requires authentication.

---

## Questions & Answers API

### POST /questions
Submit a new question. Requires authentication.

**Request Body:**
```json
{
  "question": "string",
  "category": "string",
  "isPublic": boolean,
  "language": "string (optional)"
}
```

**Response:**
```json
{
  "status": true,
  "message": "Question submitted successfully",
  "question": {
    "id": "string",
    "question": "string",
    "category": "string",
    "userId": "string",
    "createdAt": "ISO date string"
  }
}
```

**Example Usage:**
```javascript
const submitQuestion = async (questionText, category) => {
  const response = await fetch('/questions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${userToken}`
    },
    body: JSON.stringify({
      question: questionText,
      category: category,
      isPublic: true,
      language: 'ar'
    })
  });
  return response.json();
};
```

### GET /public-questions
Get all public questions with pagination.

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10)
- `category` (optional): Filter by category
- `search` (optional): Search query

**Response:**
```json
{
  "status": true,
  "questions": [
    {
      "id": "string",
      "question": "string",
      "category": "string",
      "userName": "string",
      "userGender": "string",
      "createdAt": "ISO date string",
      "topAnswerId": "string (optional)",
      "topAnswer": "object (optional)",
      "answersCount": number,
      "aiAnswer": "string (optional)"
    }
  ],
  "pagination": {
    "currentPage": number,
    "totalPages": number,
    "totalItems": number,
    "hasNextPage": boolean,
    "hasPrevPage": boolean
  }
}
```

### GET /questions/:id
Get specific question with all answers.

**Parameters:**
- `id` (path): Question ID

**Response:**
```json
{
  "status": true,
  "question": {
    "id": "string",
    "question": "string",
    "category": "string",
    "answers": [
      {
        "id": "string",
        "answer": "string",
        "volunteerName": "string",
        "upvotes": number,
        "createdAt": "ISO date string"
      }
    ]
  }
}
```

### POST /answers
Submit answer to a question. Requires volunteer authentication.

**Request Body:**
```json
{
  "questionId": "string",
  "answer": "string"
}
```

### PUT /answers/vote
Vote on an answer. Requires authentication.

**Request Body:**
```json
{
  "answerId": "string",
  "vote": "upvote|downvote"
}
```

---

## Chat API

### POST /chat/start
Start or resume AI chat session. Requires authentication.

**Request Body:**
```json
{
  "userId": "string"
}
```

**Response:**
```json
{
  "ai_session_id": "string",
  "greeting": "string",
  "isNewSession": boolean
}
```

**Example Usage:**
```javascript
const startChat = async (userId) => {
  const response = await fetch('/chat/start', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${userToken}`
    },
    body: JSON.stringify({ userId })
  });
  return response.json();
};
```

### POST /chat/send
Send message to AI assistant. Requires authentication.

**Request Body:**
```json
{
  "userId": "string",
  "message": "string",
  "ai_session_id": "string"
}
```

**Response:**
```json
{
  "reply": "string"
}
```

---

## Meeting Requests API

### POST /meeting-requests
Create a new meeting request. Requires authentication.

**Request Body:**
```json
{
  "topic": "string",
  "description": "string",
  "preferredLanguage": "string",
  "timeSlots": [
    {
      "startTime": "ISO date string",
      "endTime": "ISO date string"
    }
  ]
}
```

### GET /meeting-requests
Get meeting requests for authenticated user.

**Query Parameters:**
- `status` (optional): Filter by status (pending|accepted|rejected|completed)
- `page` (optional): Page number
- `limit` (optional): Items per page

### GET /meeting-requests/volunteer
Get meeting requests available for volunteers. Requires volunteer authentication.

### PATCH /meeting-requests/:id/select-time
Volunteer selects time slot for meeting. Requires certified volunteer authentication.

**Request Body:**
```json
{
  "selectedTimeSlot": {
    "startTime": "ISO date string",
    "endTime": "ISO date string"
  }
}
```

---

## Stories API

### GET /story
Get all public stories.

**Response:**
```json
{
  "status": true,
  "stories": [
    {
      "id": "string",
      "title": "string",
      "content": "string",
      "author": "string",
      "likes": number,
      "createdAt": "ISO date string"
    }
  ]
}
```

### POST /story/savestory
Save/bookmark a story. Requires authentication.

**Request Body:**
```json
{
  "storyId": "string"
}
```

### POST /story/likestory
Like a story. Requires authentication.

**Request Body:**
```json
{
  "storyId": "string"
}
```

---

## Lessons API

### GET /lessons
Get all available lessons.

**Response:**
```json
{
  "status": true,
  "lessons": [
    {
      "id": "string",
      "title": "string",
      "description": "string",
      "category": "string",
      "difficulty": "beginner|intermediate|advanced",
      "duration": "string",
      "content": "string",
      "videoUrl": "string (optional)"
    }
  ]
}
```

### GET /lesson/:id
Get specific lesson details.

### PATCH /lesson/progress/:id
Update lesson progress for user. Requires authentication.

**Request Body:**
```json
{
  "progress": number, // 0-100
  "completed": boolean
}
```

---

## Admin API

### GET /admin/dashboard-stats
Get dashboard statistics. Requires admin authentication.

**Response:**
```json
{
  "totalUsers": number,
  "totalQuestions": number,
  "totalAnswers": number,
  "totalStories": number,
  "activeVolunteers": number
}
```

### GET /admin/users
Get all users with pagination. Requires admin authentication.

### POST /admin/approve-voulnteer
Approve volunteer application. Requires admin authentication.

**Request Body:**
```json
{
  "userId": "string",
  "approved": boolean
}
```

---

## Error Codes

| Code | Description |
|------|-------------|
| 400 | Bad Request - Invalid input data |
| 401 | Unauthorized - Invalid or missing token |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource not found |
| 409 | Conflict - Resource already exists |
| 422 | Unprocessable Entity - Validation error |
| 500 | Internal Server Error |

## Rate Limiting

API endpoints are rate limited to prevent abuse:
- Authentication endpoints: 5 requests per minute
- General endpoints: 100 requests per minute per user
- Admin endpoints: 1000 requests per minute

## SDKs and Libraries

### JavaScript/Node.js Example

```javascript
class HidayaAPI {
  constructor(baseUrl, token = null) {
    this.baseUrl = baseUrl;
    this.token = token;
  }

  setToken(token) {
    this.token = token;
  }

  async request(endpoint, options = {}) {
    const url = `${this.baseUrl}${endpoint}`;
    const config = {
      headers: {
        'Content-Type': 'application/json',
        ...options.headers
      },
      ...options
    };

    if (this.token) {
      config.headers.Authorization = `Bearer ${this.token}`;
    }

    const response = await fetch(url, config);
    return response.json();
  }

  // Authentication
  async register(userData) {
    return this.request('/register', {
      method: 'POST',
      body: JSON.stringify(userData)
    });
  }

  async login(email, password, role) {
    return this.request('/login', {
      method: 'POST',
      body: JSON.stringify({ email, password, role })
    });
  }

  // Questions
  async getPublicQuestions(page = 1, limit = 10) {
    return this.request(`/public-questions?page=${page}&limit=${limit}`);
  }

  async submitQuestion(question, category, isPublic = true) {
    return this.request('/questions', {
      method: 'POST',
      body: JSON.stringify({ question, category, isPublic })
    });
  }

  // Chat
  async startChat(userId) {
    return this.request('/chat/start', {
      method: 'POST',
      body: JSON.stringify({ userId })
    });
  }

  async sendMessage(userId, message, ai_session_id) {
    return this.request('/chat/send', {
      method: 'POST',
      body: JSON.stringify({ userId, message, ai_session_id })
    });
  }
}

// Usage
const api = new HidayaAPI('https://api.hidaya.com');
await api.login('user@example.com', 'password', 'user');
const questions = await api.getPublicQuestions();
```

### Flutter/Dart Example

```dart
class HidayaApiService {
  final String baseUrl;
  String? token;

  HidayaApiService(this.baseUrl);

  void setToken(String newToken) {
    token = newToken;
  }

  Future<Map<String, dynamic>> request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final defaultHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?headers,
    };

    http.Response response;
    switch (method.toUpperCase()) {
      case 'POST':
        response = await http.post(
          url,
          headers: defaultHeaders,
          body: body != null ? json.encode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          url,
          headers: defaultHeaders,
          body: body != null ? json.encode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(url, headers: defaultHeaders);
        break;
      default:
        response = await http.get(url, headers: defaultHeaders);
    }

    return json.decode(response.body);
  }

  Future<Map<String, dynamic>> login(String email, String password, String role) {
    return request('/login', 
      method: 'POST',
      body: {'email': email, 'password': password, 'role': role}
    );
  }

  Future<Map<String, dynamic>> getPublicQuestions({int page = 1, int limit = 10}) {
    return request('/public-questions?page=$page&limit=$limit');
  }

  Future<Map<String, dynamic>> submitQuestion(String question, String category) {
    return request('/questions',
      method: 'POST',
      body: {'question': question, 'category': category, 'isPublic': true}
    );
  }
}
```