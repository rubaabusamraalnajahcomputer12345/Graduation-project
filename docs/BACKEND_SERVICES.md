# Backend Services Documentation

## Overview

This document provides comprehensive documentation for all backend services and utilities in the Hidaya project. The backend is built with Node.js/Express and provides various services including user management, AI integration, notifications, and content management.

## Service Architecture

```
backend/
├── services/
│   ├── aiservices.js              # AI/ML integration services
│   ├── userserviceslog&registeration.js  # User authentication & management
│   ├── notificationService.js     # Push notifications
│   ├── cronService.js            # Scheduled tasks
│   ├── meetingRequestService.js   # Meeting management
│   ├── adminservices.js          # Admin functionality
│   ├── questionsservices.js      # Q&A management
│   ├── answersservices.js        # Answer management
│   ├── storyservices.js          # Story management
│   ├── lessonservices.js         # Lesson management
│   ├── flagsservices.js          # Content reporting
│   ├── langchainGemini.js        # LangChain AI integration
│   ├── zoomService.js            # Video meeting integration
│   └── authMiddleware.js         # Authentication middleware
├── utils/
│   ├── sendEmail.js              # Email utilities
│   └── resetPassword.js         # Password reset utilities
└── models/                       # Database models
```

## Core Services

### 1. AI Services

**File:** `services/aiservices.js`

**Purpose:** Handles AI-powered chat functionality, embeddings generation, and language detection.

#### Key Components

##### Initialization & Configuration

```javascript
import { createClient } from "@supabase/supabase-js";
import { GoogleGenerativeAI } from "@google/generative-ai";
import cld3 from "cld3-asm";

// Supabase client for chat storage
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// Google GenAI for embeddings
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const embeddingModel = genAI.getGenerativeModel({
  model: "text-embedding-004",
});
```

##### Language Detection

```javascript
/**
 * Detects the language of a text message using CLD3
 * @param {string} message - Text to analyze
 * @returns {string} - ISO 639-1 language code
 */
function detectLanguage(message) {
  if (!identifier) return "en";
  const result = identifier.findLanguage(message);
  if (result && result.is_reliable && result.language) {
    return result.language;
  }
  return "en";
}
```

**Usage Example:**

```javascript
const language = detectLanguage("مرحبا بك في تطبيق هداية");
console.log(language); // Output: "ar"
```

##### Chat Session Management

###### `getLastSession(userId)`

Retrieves the most recent chat session for a user.

**Parameters:**

- `userId` (string): User's unique identifier

**Returns:**

- `session` (object|null): Session data or null if none found

```javascript
const session = await getLastSession("user123");
if (session) {
  console.log(`Found session: ${session.id}`);
}
```

###### `createNewSupabaseSession(userId)`

Creates a new chat session for a user.

**Parameters:**

- `userId` (string): User's unique identifier

**Returns:**

- `session` (object): New session data

```javascript
const newSession = await createNewSupabaseSession("user123");
console.log(`Created session: ${newSession.id}`);
```

###### `saveChatMessage(sessionId, sender, message)`

Saves a chat message to the database.

**Parameters:**

- `sessionId` (string): Session identifier
- `sender` (string): "user" or "ai"
- `message` (string): Message content

```javascript
await saveChatMessage(sessionId, "user", "What is Islam?");
await saveChatMessage(sessionId, "ai", "Islam is a monotheistic religion...");
```

###### `fetchRecentMessages(sessionId, limit = 10)`

Retrieves recent messages from a chat session.

**Parameters:**

- `sessionId` (string): Session identifier
- `limit` (number): Maximum number of messages to retrieve

**Returns:**

- `messages` (array): Array of message objects

```javascript
const recentMessages = await fetchRecentMessages(sessionId, 20);
console.log(`Retrieved ${recentMessages.length} messages`);
```

##### Embedding Services

###### `generateEmbedding(text)`

Generates vector embeddings for text using Google's embedding model.

**Parameters:**

- `text` (string): Text to embed

**Returns:**

- `embedding` (array): Vector embedding

```javascript
const embedding = await generateEmbedding("What are the pillars of Islam?");
console.log(`Generated ${embedding.length}-dimensional embedding`);
```

###### `searchSimilarContent(queryEmbedding, threshold = 0.7)`

Searches for similar content using vector similarity.

**Parameters:**

- `queryEmbedding` (array): Query vector
- `threshold` (number): Similarity threshold

**Returns:**

- `results` (array): Similar content items

### 2. User Services

**File:** `services/userserviceslog&registeration.js`

**Purpose:** Handles user registration, authentication, profile management, and email verification.

#### Core Functions

##### User Registration

###### `registerUser(userData)`

Registers a new user with email verification.

**Parameters:**

- `userData` (object): User registration data

**User Data Structure:**

```javascript
{
  displayName: "Ahmed Hassan",
  email: "ahmed@example.com",
  password: "securePassword123",
  gender: "male|female|other",
  country: "Egypt",
  city: "Cairo", // optional
  role: "user|volunteer_pending|certified_volunteer|admin",
  language: "ar",
  certification_title: "Islamic Studies", // for volunteers
  certification_institution: "Al-Azhar University", // for volunteers
  certification_url: "https://...", // for volunteers
  bio: "Brief bio", // for volunteers
  spoken_languages: ["ar", "en"] // for volunteers
}
```

**Process:**

1. Generate unique user ID and verification token
2. Hash verification token for security
3. Create user document with volunteer profile if applicable
4. Save to database
5. Send verification email

**Example:**

```javascript
const userData = {
  displayName: "Ahmed Hassan",
  email: "ahmed@example.com",
  password: "securePassword123",
  gender: "male",
  country: "Egypt",
  role: "user",
  language: "ar",
};

const newUser = await UserServices.registerUser(userData);
console.log(`User registered: ${newUser.userId}`);
```

##### User Authentication

###### `checkUser(email)`

Finds user by email address.

**Parameters:**

- `email` (string): User's email

**Returns:**

- `user` (object|null): User document or null

```javascript
const user = await UserServices.checkUser("ahmed@example.com");
if (user) {
  console.log(`Found user: ${user.displayName}`);
}
```

###### `verifyPassword(plainPassword, hashedPassword)`

Verifies password using bcrypt.

**Parameters:**

- `plainPassword` (string): Plain text password
- `hashedPassword` (string): Hashed password from database

**Returns:**

- `isValid` (boolean): True if password matches

```javascript
const isValid = await UserServices.verifyPassword(
  "userPassword",
  user.password
);
```

###### `generateAccessToken(tokenData, secret, expiry)`

Generates JWT access token.

**Parameters:**

- `tokenData` (object): Token payload
- `secret` (string): JWT secret
- `expiry` (string): Token expiry time

**Returns:**

- `token` (string): JWT token

```javascript
const tokenData = {
  _id: user.userId,
  email: user.email,
  role: user.role,
};

const token = await UserServices.generateAccessToken(tokenData, "secret", "1h");
```

##### Profile Management

###### `updateUserById(userId, updateData)`

Updates user profile information.

**Parameters:**

- `userId` (string): User's unique identifier
- `updateData` (object): Fields to update

**Example:**

```javascript
const updateData = {
  displayName: "Ahmed Hassan Updated",
  city: "Alexandria",
  bio: "Updated bio information",
};

const updatedUser = await UserServices.updateUserById("user123", updateData);
```

###### `verifyEmail(token)`

Verifies user's email address using verification token.

**Parameters:**

- `token` (string): Email verification token

**Process:**

1. Hash the provided token
2. Find user with matching token and check expiry
3. Update user's verification status
4. Clear verification token

```javascript
const result = await UserServices.verifyEmail("verification_token_here");
console.log("Email verified successfully");
```

##### Password Management

###### `changePassword(userId, currentPassword, newPassword)`

Changes user's password with current password verification.

**Parameters:**

- `userId` (string): User's unique identifier
- `currentPassword` (string): Current password
- `newPassword` (string): New password

```javascript
await UserServices.changePassword(
  "user123",
  "currentPassword",
  "newSecurePassword"
);
```

###### `resetPassword(email)`

Initiates password reset process.

**Parameters:**

- `email` (string): User's email address

**Process:**

1. Generate reset token
2. Set token expiry (1 hour)
3. Save to database
4. Send reset email

```javascript
await UserServices.resetPassword("user@example.com");
```

### 3. Notification Service

**File:** `services/notificationService.js`

**Purpose:** Handles push notifications via OneSignal and in-app notification management.

#### Configuration

```javascript
const ONESIGNAL_APP_ID = "your_onesignal_app_id";
const ONESIGNAL_REST_API_KEY = "your_rest_api_key";
```

#### Core Functions

###### `sendNotification(options)`

Main function for sending notifications.

**Parameters:**

```javascript
{
  userId: "string",           // Target user ID
  type: "string",            // Notification type
  title: "string",           // Notification title
  message: "string",         // Notification message
  data: {},                  // Additional data (optional)
  saveToDatabase: true       // Save to database (default: true)
}
```

**Notification Types:**

- `welcome` - Welcome message for new users
- `question_answered` - When someone answers user's question
- `answer_upvoted` - When user's answer gets upvoted
- `meeting_request` - New meeting request
- `meeting_confirmed` - Meeting time confirmed
- `lesson_completed` - Lesson completion
- `system_announcement` - System-wide announcements

**Example Usage:**

```javascript
// Welcome notification
await sendNotification({
  userId: "user123",
  type: "welcome",
  title: "Welcome to Hidaya!",
  message: "Start your Islamic learning journey with us.",
  data: { screen: "home" },
});

// Question answered notification
await sendNotification({
  userId: "user123",
  type: "question_answered",
  title: "Your Question Was Answered",
  message: "A volunteer has answered your question about prayer.",
  data: {
    questionId: "q456",
    answerId: "a789",
    screen: "question_detail",
  },
});
```

###### `sendOneSignalPush(options)`

Sends push notification via OneSignal.

**Parameters:**

```javascript
{
  playerId: "string",        // OneSignal player ID
  title: "string",           // Push notification title
  message: "string",         // Push notification message
  data: {}                   // Additional data for navigation
}
```

**Implementation:**

```javascript
async function sendOneSignalPush({ playerId, title, message, data = {} }) {
  const notification = {
    app_id: ONESIGNAL_APP_ID,
    include_player_ids: [playerId],
    headings: { en: title },
    contents: { en: message },
    data: data,
  };

  const response = await axios.post(
    "https://onesignal.com/api/v1/notifications",
    notification,
    {
      headers: {
        "Content-Type": "application/json",
        Authorization: ONESIGNAL_REST_API_KEY,
      },
    }
  );

  return {
    success: response.data.id ? true : false,
    id: response.data.id,
    recipients: response.data.recipients,
  };
}
```

##### Specialized Notification Functions

###### `sendWelcomeNotification(userId, userName)`

Sends welcome notification to new users.

```javascript
await sendWelcomeNotification("user123", "Ahmed");
```

###### `sendQuestionAnsweredNotification(userId, questionTitle, volunteerName)`

Notifies when user's question receives an answer.

```javascript
await sendQuestionAnsweredNotification(
  "user123",
  "What are the pillars of Islam?",
  "Dr. Hassan"
);
```

###### `sendAnswerUpvotedNotification(userId, answerText)`

Notifies when user's answer gets upvoted.

```javascript
await sendAnswerUpvotedNotification(
  "volunteer456",
  "The five pillars of Islam are..."
);
```

###### `sendMeetingRequestNotification(volunteerId, requesterName, topic)`

Notifies volunteer of new meeting request.

```javascript
await sendMeetingRequestNotification(
  "volunteer789",
  "Fatima Ahmed",
  "Islamic finance guidance"
);
```

### 4. Authentication Middleware

**File:** `services/authMiddleware.js`

**Purpose:** Validates JWT tokens and user authentication status.

#### Implementation

```javascript
import jwt from "jsonwebtoken";
import UserServices from "./userserviceslog&registeration.js";

const authMiddleware = async (req, res, next) => {
  try {
    const token = req.header("Authorization")?.replace("Bearer ", "");

    if (!token) {
      return res.status(401).json({
        status: false,
        message: "Access denied. No token provided.",
      });
    }

    const decoded = jwt.verify(token, "secret");
    const user = await UserServices.checkUserById(decoded._id);

    if (!user) {
      return res.status(401).json({
        status: false,
        message: "Invalid token. User not found.",
      });
    }

    req.user = user;
    next();
  } catch (error) {
    return res.status(401).json({
      status: false,
      message: "Invalid token.",
    });
  }
};

export default authMiddleware;
```

**Usage in Routes:**

```javascript
import authMiddleware from "../services/authMiddleware.js";

// Protected route
router.get("/profile", authMiddleware, (req, res) => {
  res.json({
    status: true,
    user: req.user,
  });
});
```

### 5. Cron Service

**File:** `services/cronService.js`

**Purpose:** Handles scheduled tasks and background jobs.

#### Scheduled Tasks

##### Daily Tasks

- Prayer time notifications
- Lesson reminders
- Daily Islamic content delivery
- User engagement metrics

##### Weekly Tasks

- Weekly progress reports
- Volunteer activity summaries
- Content moderation reviews

##### Monthly Tasks

- User statistics compilation
- Performance analytics
- Content cleanup

**Example Implementation:**

```javascript
import cron from "node-cron";
import { sendNotification } from "./notificationService.js";

class CronService {
  constructor() {
    this.initializeTasks();
  }

  initializeTasks() {
    // Daily prayer reminders at 6 AM
    cron.schedule("0 6 * * *", async () => {
      await this.sendDailyPrayerReminders();
    });

    // Weekly progress reports on Fridays at 3 PM
    cron.schedule("0 15 * * 5", async () => {
      await this.sendWeeklyReports();
    });

    // Clean up old chat sessions monthly
    cron.schedule("0 0 1 * *", async () => {
      await this.cleanupOldSessions();
    });
  }

  async sendDailyPrayerReminders() {
    // Implementation for prayer reminders
  }

  async sendWeeklyReports() {
    // Implementation for weekly reports
  }

  async cleanupOldSessions() {
    // Implementation for session cleanup
  }
}

export default CronService;
```

### 6. Meeting Request Service

**File:** `services/meetingRequestService.js`

**Purpose:** Manages video meeting requests between users and volunteers.

#### Core Functions

###### `createMeetingRequest(requestData)`

Creates a new meeting request.

**Parameters:**

```javascript
{
  userId: "string",
  topic: "string",
  description: "string",
  preferredLanguage: "string",
  timeSlots: [
    {
      startTime: "ISO date string",
      endTime: "ISO date string"
    }
  ]
}
```

###### `assignVolunteer(requestId, volunteerId)`

Assigns a volunteer to a meeting request.

###### `generateZoomLink(meetingId)`

Generates Zoom meeting link for confirmed meetings.

```javascript
const meetingLink = await generateZoomLink("meeting123");
console.log(`Meeting link: ${meetingLink}`);
```

### 7. Content Management Services

#### Question Services (`questionsservices.js`)

- Question submission and validation
- Category management
- Public/private question handling
- Search and filtering

#### Answer Services (`answersservices.js`)

- Answer submission by volunteers
- Voting system implementation
- Best answer selection
- Answer moderation

#### Story Services (`storyservices.js`)

- Islamic story management
- Story categorization
- Like and save functionality
- Content curation

#### Lesson Services (`lessonservices.js`)

- Educational content delivery
- Progress tracking
- Certificate generation
- Interactive assessments

## Utility Functions

### Email Service

**File:** `utils/sendEmail.js`

**Purpose:** Handles email sending for verification, notifications, and password resets.

```javascript
import nodemailer from "nodemailer";

const transporter = nodemailer.createTransporter({
  service: "gmail",
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD,
  },
});

export default async function sendVerificationEmail(email, token) {
  const verificationUrl = `${process.env.FRONTEND_URL}/verify/${token}`;

  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: "Verify Your Hidaya Account",
    html: `
      <h2>Welcome to Hidaya!</h2>
      <p>Please click the link below to verify your email:</p>
      <a href="${verificationUrl}">Verify Email</a>
      <p>This link expires in 1 hour.</p>
    `,
  };

  await transporter.sendMail(mailOptions);
}
```

### Password Reset Service

**File:** `utils/resetPassword.js`

**Purpose:** Handles password reset email functionality.

```javascript
export default async function sendResetPasswordEmail(email, token) {
  const resetUrl = `${process.env.FRONTEND_URL}/reset-password/${token}`;

  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: "Reset Your Hidaya Password",
    html: `
      <h2>Password Reset Request</h2>
      <p>Click the link below to reset your password:</p>
      <a href="${resetUrl}">Reset Password</a>
      <p>This link expires in 1 hour.</p>
      <p>If you didn't request this, please ignore this email.</p>
    `,
  };

  await transporter.sendMail(mailOptions);
}
```

## Database Models

### User Model

```javascript
const userSchema = new mongoose.Schema({
  userId: { type: String, unique: true, required: true },
  displayName: { type: String, required: true },
  email: { type: String, unique: true, required: true },
  password: { type: String, required: true },
  gender: { type: String, enum: ["male", "female", "other"] },
  country: String,
  city: String,
  role: {
    type: String,
    enum: ["user", "volunteer_pending", "certified_volunteer", "admin"],
    default: "user",
  },
  language: String,
  onesignalId: String,
  ai_session_id: String,
  verificationToken: String,
  verificationTokenExpires: Date,
  emailVerified: { type: Boolean, default: false },
  resetPasswordToken: String,
  resetPasswordExpires: Date,
  volunteerProfile: {
    certificate: {
      title: String,
      institution: String,
      url: String,
      uploadedAt: Date,
    },
    languages: [String],
    bio: String,
    approved: { type: Boolean, default: false },
    approvedAt: Date,
    approvedBy: String,
  },
  notifications: [
    {
      id: String,
      type: String,
      title: String,
      message: String,
      data: Object,
      read: { type: Boolean, default: false },
      createdAt: Date,
    },
  ],
  savedQuestions: [String],
  lessonProgress: [
    {
      lessonId: String,
      progress: { type: Number, default: 0 },
      completed: { type: Boolean, default: false },
      completedAt: Date,
    },
  ],
  createdAt: { type: Date, default: Date.now },
  lastActive: { type: Date, default: Date.now },
});
```

## Error Handling

### Standard Error Response Format

```javascript
{
  status: false,
  message: "Error description",
  error: "Detailed error information",
  code: "ERROR_CODE"
}
```

### Common Error Handling Pattern

```javascript
try {
  // Service operation
  const result = await someServiceFunction(params);

  res.status(200).json({
    status: true,
    message: "Operation successful",
    data: result,
  });
} catch (error) {
  console.error("Service error:", error);

  res.status(500).json({
    status: false,
    message: "Internal server error",
    error: error.message,
  });
}
```

### Validation Middleware

```javascript
const validateRequest = (schema) => {
  return (req, res, next) => {
    const { error } = schema.validate(req.body);

    if (error) {
      return res.status(400).json({
        status: false,
        message: "Validation error",
        errors: error.details.map((detail) => detail.message),
      });
    }

    next();
  };
};
```

## Performance Optimization

### Caching Strategy

```javascript
import NodeCache from "node-cache";

const cache = new NodeCache({ stdTTL: 600 }); // 10 minutes default

// Cache frequently accessed data
const getCachedQuestions = async (category) => {
  const cacheKey = `questions_${category}`;
  let questions = cache.get(cacheKey);

  if (!questions) {
    questions = await Question.find({ category }).limit(50);
    cache.set(cacheKey, questions);
  }

  return questions;
};
```

### Database Optimization

```javascript
// Index optimization for common queries
userSchema.index({ email: 1 });
userSchema.index({ userId: 1 });
userSchema.index({ role: 1, emailVerified: 1 });

questionSchema.index({ category: 1, isPublic: 1 });
questionSchema.index({ userId: 1, createdAt: -1 });

// Compound indexes for complex queries
answerSchema.index({ questionId: 1, upvotes: -1 });
```

## Testing

### Unit Tests Example

```javascript
import { expect } from "chai";
import UserServices from "../services/userserviceslog&registeration.js";

describe("UserServices", () => {
  describe("registerUser", () => {
    it("should create a new user with valid data", async () => {
      const userData = {
        displayName: "Test User",
        email: "test@example.com",
        password: "password123",
        gender: "male",
        country: "Test Country",
        role: "user",
        language: "en",
      };

      const user = await UserServices.registerUser(userData);

      expect(user).to.have.property("userId");
      expect(user.email).to.equal(userData.email);
      expect(user.emailVerified).to.be.false;
    });
  });

  describe("verifyPassword", () => {
    it("should return true for correct password", async () => {
      const plainPassword = "password123";
      const hashedPassword = await bcrypt.hash(plainPassword, 10);

      const result = await UserServices.verifyPassword(
        plainPassword,
        hashedPassword
      );
      expect(result).to.be.true;
    });
  });
});
```

### Integration Tests

```javascript
import request from "supertest";
import app from "../app.js";

describe("Authentication API", () => {
  it("should register a new user", async () => {
    const response = await request(app).post("/register").send({
      displayName: "Test User",
      email: "test@example.com",
      password: "password123",
      gender: "male",
      country: "Test Country",
      role: "user",
      language: "en",
    });

    expect(response.status).toBe(201);
    expect(response.body.status).toBe(true);
    expect(response.body.user).toHaveProperty("userId");
  });

  it("should login with valid credentials", async () => {
    const response = await request(app).post("/login").send({
      email: "test@example.com",
      password: "password123",
      role: "user",
    });

    expect(response.status).toBe(200);
    expect(response.body).toHaveProperty("token");
  });
});
```

## Deployment Configuration

### Environment Variables

```bash
# Database
MONGODB_URI=mongodb://localhost:27017/hidaya
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key

# Authentication
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRE=1h

# Email Service
EMAIL_USER=your_email@gmail.com
EMAIL_PASSWORD=your_app_password

# OneSignal
ONESIGNAL_APP_ID=your_onesignal_app_id
ONESIGNAL_REST_API_KEY=your_rest_api_key

# AI Services
GEMINI_API_KEY=your_gemini_api_key
GOOGLE_API_KEY=your_google_api_key

# Frontend
FRONTEND_URL=https://your-frontend-url.com

# Zoom Integration (optional)
ZOOM_API_KEY=your_zoom_api_key
ZOOM_API_SECRET=your_zoom_api_secret
```

### Production Considerations

1. **Security**: Use environment variables for sensitive data
2. **Monitoring**: Implement logging and error tracking
3. **Scaling**: Consider microservices architecture for high load
4. **Backup**: Regular database backups and disaster recovery
5. **Rate Limiting**: Implement rate limiting for API endpoints

This comprehensive documentation provides developers with all necessary information to understand, maintain, and extend the Hidaya backend services.
