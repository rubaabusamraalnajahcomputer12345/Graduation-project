import mongoose from "mongoose";
const { Schema } = mongoose;

const storySchema = new Schema({
  id: { type: String }, // optional unless you want to make it required/unique manually
  title: { type: String, required: true },
  description: { type: String, required: true, maxlength: 500 },
  background: { type: String },
  journeyToIslam: { type: String },
  afterIslam: { type: String },
  type: {
    type: String,
    enum: ["video", "image", "text"],
    required: true,
  },
  mediaUrl: {
    type: String,
    required: function () {
      return this.type === "video" || this.type === "audio";
    },
  },
  name: { type: String, default: "Anonymous" },
  country: { type: String },
  tags: [{ type: String }],
  quote: { type: String, required: true, maxlength: 200 },
  SaveCount: { type: String, required: true },
  likeCount: { type: String },
  views: { type: String },
  createdAt: { type: Date, default: Date.now },
});

export default mongoose.model("Story", storySchema, "Stories");
