import mongoose from "../config/db.js";

const { Schema } = mongoose;

const meetingRequestSchema = new Schema({
  meetingId: {
    type: String,
    required: true,
    unique: true,
  },
  userId: {
    type: String,
    required: true,
  },
  volunteerId: {
    type: String,
    required: true,
  },
  preferredSlots: [
    {
      start: { type: Date, required: true },
      end: { type: Date, required: true },
    },
  ],
  selectedSlot: {
    start: { type: Date },
    end: { type: Date },
  },
  status: {
    type: String,
    enum: ["pending", "accepted", "rejected"],
    default: "pending",
  },
  rejectReason: {
    type: String,
  },
  zoomLink: {
    type: String,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

// Validate preferredSlots array has 1-5 entries
meetingRequestSchema.pre("save", function (next) {
  if (this.preferredSlots.length < 1 || this.preferredSlots.length > 5) {
    return next(new Error("Preferred slots must have between 1 and 5 entries"));
  }

  // Validate each slot is 30 minutes
  for (let slot of this.preferredSlots) {
    const duration = slot.end.getTime() - slot.start.getTime();
    const thirtyMinutes = 30 * 60 * 1000; // 30 minutes in milliseconds
    if (duration !== thirtyMinutes) {
      return next(new Error("Each time slot must be exactly 30 minutes"));
    }
  }

  next();
});

export default mongoose.model(
  "MeetingRequest",
  meetingRequestSchema,
  "MeetingRequests"
);
