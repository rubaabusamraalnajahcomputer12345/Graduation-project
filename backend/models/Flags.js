import mongoose, { model } from "mongoose";
const { Schema } = mongoose;

const flagSchema = new Schema({
  flagId: { type: String, required: true, unique: true },
  itemType: {
    type: String,
    required: true,
    enum: ["question", "answer", "message"],
  },
  itemId: { type: String, required: true },
  reportedBy: { type: String, required: true },
  reason: { type: String, required: true },
  status: {
    type: String,
    required: true,
    enum: ["pending", "dismissed", "resolved", "rejected"],
    default: "pending",
  },
  createdAt: { type: Date, required: true, default: Date.now },
  sleepmode: {
    type: Boolean,
    default: false,
  },
  notificationSentAt: { type: Date, default: null },
    notificationSentAtDismissed: { type: Date, default: null },//store the timestamp when notification is sent for dismissed flags
});

export default model("Flag", flagSchema, "Flags");
