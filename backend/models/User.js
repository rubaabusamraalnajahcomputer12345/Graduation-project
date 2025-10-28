import mongoose from "../config/db.js";
import bcrypt from "bcrypt";

const { Schema } = mongoose;

const certificateSchema = new Schema({
  title: String,
  institution: String,
  url: String,
  uploadedAt: Date,
});

const volunteerProfileSchema = new Schema({
  certificate: certificateSchema,
  languages: [String],
  bio: String,
});

const notificationSchema = new Schema({
  id: { type: String, required: true },
  type: { type: String, required: true }, // 'question_answered', 'answer_upvoted', 'new_question', etc.
  title: { type: String, required: true },
  message: { type: String, required: true },
  data: { type: Schema.Types.Mixed }, // Additional data like questionId, answerId, etc.
  read: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now },
});

const lessonProgressSchema = new Schema({
  lessonId: { type: String, required: true },
  currentStep: { type: Number, default: 0 },
  completed: { type: Boolean, default: false }
});









const userSchema = new Schema({
  userId: { type: String, required: true },
  displayName: String,
  gender: { type: String, enum: ["Male", "Female"] },
  email: { type: String, unique: true },
  password: String,
  country: String,
  city: String,
  role: {
    type: String,
    enum: ["user", "volunteer_pending", "certified_volunteer", "admin"],
    default: "user",
  },
  language: String,
  savedQuestions: [String],
  savedLessons: [String],
  savedStories: [String],
  likedStories: [String],
  //edited by manal
  // Add ai_session_id for AI chat sessions
  ai_session_id: { type: String },

  // Add OneSignal ID for push notifications
  onesignalId: { type: String },

  // Add in-app notifications
  notifications: [notificationSchema],

  createdAt: { type: Date, default: Date.now },
  volunteerProfile: volunteerProfileSchema,
  isEmailVerified: { type: Boolean, default: false },
  verificationToken: { type: String },
  verificationTokenExpires: { type: Date },
    lessonsProgress: [lessonProgressSchema],

});

userSchema.pre("save", async function () {
  var user = this;
  if (!user.isModified("password")) {
    return;
  }
  try {
    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash(user.password, salt);
    user.password = hash;
  } catch (err) {
    throw err;
  }
});

userSchema.methods.comparePassword = async function (candidatePassword) {
  try {
    console.log("----------------no password", this.password);
    // @ts-ignore
    const isMatch = await bcrypt.compare(candidatePassword, this.password);
    return isMatch;
  } catch (error) {
    throw error;
  }
};

export default mongoose.model("User", userSchema, "Users");
