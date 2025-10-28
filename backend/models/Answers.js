import mongoose from "mongoose";
const { Schema } = mongoose;

const answerSchema = new Schema({
  answerId: { type: String, required: true, unique: true },
  questionId: { type: String, required: true },
  text: { type: String, required: true },
  answeredBy: { type: String, required: true },
  createdAt: { type: Date, required: true },
  language: { type: String, required: true },
  upvotesCount: { type: Number, default: 0 },
  isFlagged: { type: Boolean, default: false },
  isHidden: { type: Boolean, default: false },
  //add hiddenTemporary field to hide answers temporarily when the questions updates
  hiddenTemporary: { type: Boolean, default: false },
});

export default mongoose.model("Answer", answerSchema, "Answers");
