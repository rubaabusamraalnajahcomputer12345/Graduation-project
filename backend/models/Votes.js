import mongoose, { model } from "mongoose";
const { Schema } = mongoose;

const voteSchema = new Schema({
  voteId: { type: String, required: true, unique: true },
  answerId: { type: String, required: true },
  questionId: { type: String, required: true },
  votedBy: { type: String, required: true },
  createdAt: { type: Date, required: true, default: Date.now },
});

export default model("Vote", voteSchema, "Votes");
