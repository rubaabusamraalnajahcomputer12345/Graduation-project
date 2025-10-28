import mongoose, { model } from "mongoose";
const { Schema } = mongoose;

const stepSchema = new Schema({
  stepNumber: { type: Number, required: true },
  title: { type: String, required: true },
  description: { type: String, required: true },
  mediaUrl: { type: String, required: true },
  mediaType: {
    type: String,
    required: true,
    enum: ["image", "video"],
  },
});

const lessonSchema = new Schema({
  lessonId: {
    type: String,
    required: true,
    unique: true,
    default: function () {
      const randomFiveDigits = Math.floor(10000 + Math.random() * 90000);
      return `L${randomFiveDigits}`;
    },
  },
  title: { type: String, required: true },
  description: { type: String, required: true },
  category: { type: String, required: true },
  level: {
    type: String,
    required: true,
    enum: ["beginner", "intermediate", "advanced"],
  },
  icon: { type: String, required: true },
  estimatedTime: { type: Number, required: true },
  createdAt: { type: Date, required: true, default: Date.now },
  steps: { type: [stepSchema], required: true },
});

export default model("Lesson", lessonSchema, "Lessons");
