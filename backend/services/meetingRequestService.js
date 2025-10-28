import MeetingRequest from "../models/MeetingRequest.js";
import User from "../models/User.js";
import { v4 as uuidv4 } from "uuid";
import zoomService from "./zoomService.js";
import { sendNotification } from "./notificationService.js";

class MeetingRequestService {
  // Create a new meeting request
  async createMeetingRequest(userId, volunteerId, preferredSlots) {
    try {
      // Validate that the volunteer is certified
      const volunteer = await User.findOne({ userId: volunteerId });
      if (!volunteer || volunteer.role !== "certified_volunteer") {
        throw new Error("Volunteer not found or not certified");
      }

      // Validate that the user exists
      const user = await User.findOne({ userId: userId });
      if (!user) {
        throw new Error("User not found");
      }

      // Create meeting request
      const meetingRequest = new MeetingRequest({
        meetingId: uuidv4(),
        userId,
        volunteerId,
        preferredSlots: preferredSlots.map((slot) => ({
          start: new Date(slot.start),
          end: new Date(slot.end),
        })),
      });

      await meetingRequest.save();

      // Send notification to volunteer
      await sendNotification(
        volunteerId,
        "meeting_request",
        "New Meeting Request",
        `${user.displayName} has requested a meeting with you. Please review the available time slots.`,
        { meetingRequestId: meetingRequest.meetingId }
      );

      return meetingRequest;
    } catch (error) {
      throw error;
    }
  }

  // Get meeting requests for a user (as requester or volunteer)
  async getMeetingRequests(userId) {
    try {
      const requests = await MeetingRequest.find({
        $or: [{ userId: userId }, { volunteerId: userId }],
      })
        .populate("userId", "displayName email")
        .populate("volunteerId", "displayName email")
        .sort({ createdAt: -1 });

      return requests;
    } catch (error) {
      throw error;
    }
  }

  // Get a specific meeting request by ID
  async getMeetingRequestById(meetingId) {
    try {
      const request = await MeetingRequest.findOne({ meetingId })
        .populate("userId", "displayName email")
        .populate("volunteerId", "displayName email");

      if (!request) {
        throw new Error("Meeting request not found");
      }

      return request;
    } catch (error) {
      throw error;
    }
  }

  // Volunteer selects a time slot and creates Zoom meeting
  async selectTimeSlot(meetingId, volunteerId, selectedSlotIndex) {
    try {
      const meetingRequest = await MeetingRequest.findOne({ meetingId });

      if (!meetingRequest) {
        throw new Error("Meeting request not found");
      }

      // Verify the volunteer is the one assigned to this request
      if (meetingRequest.volunteerId !== volunteerId) {
        throw new Error("Unauthorized to modify this meeting request");
      }

      // Verify the volunteer is certified
      const volunteer = await User.findOne({ userId: volunteerId });
      if (!volunteer || volunteer.role !== "certified_volunteer") {
        throw new Error("Only certified volunteers can confirm meetings");
      }

      // Verify the request is still pending
      if (meetingRequest.status !== "pending") {
        throw new Error("Meeting request is no longer pending");
      }

      // Validate selected slot index
      if (
        selectedSlotIndex < 0 ||
        selectedSlotIndex >= meetingRequest.preferredSlots.length
      ) {
        throw new Error("Invalid time slot selected");
      }

      const selectedSlot = meetingRequest.preferredSlots[selectedSlotIndex];

      // Create Zoom meeting
      const user = await User.findOne({ userId: meetingRequest.userId });
      const topic = `Meeting between ${user.displayName} and ${volunteer.displayName}`;

      const zoomMeeting = await zoomService.createMeeting(
        topic,
        selectedSlot.start,
        30
      );

      // Update meeting request
      meetingRequest.selectedSlot = selectedSlot;
      meetingRequest.status = "accepted";
      meetingRequest.zoomLink = zoomMeeting.joinUrl;

      await meetingRequest.save();

      // Send notification to user
      await sendNotification(
        meetingRequest.userId,
        "meeting_confirmed",
        "Meeting Confirmed",
        `${volunteer.displayName} has confirmed your meeting request. Check your meeting details.`,
        {
          meetingRequestId: meetingRequest.meetingId,
          zoomLink: zoomMeeting.joinUrl,
        }
      );

      return {
        meetingRequest,
        zoomMeeting,
      };
    } catch (error) {
      throw error;
    }
  }

  // Volunteer rejects a meeting request
  async rejectMeetingRequest(meetingId, volunteerId, rejectReason) {
    try {
      const meetingRequest = await MeetingRequest.findOne({ meetingId });

      if (!meetingRequest) {
        throw new Error("Meeting request not found");
      }

      // Verify the volunteer is the one assigned to this request
      if (meetingRequest.volunteerId !== volunteerId) {
        throw new Error("Unauthorized to modify this meeting request");
      }

      // Verify the volunteer is certified
      const volunteer = await User.findOne({ userId: volunteerId });
      if (!volunteer || volunteer.role !== "certified_volunteer") {
        throw new Error("Only certified volunteers can reject meetings");
      }

      // Verify the request is still pending
      if (meetingRequest.status !== "pending") {
        throw new Error("Meeting request is no longer pending");
      }

      // Update meeting request
      meetingRequest.status = "rejected";
      meetingRequest.rejectReason = rejectReason;

      await meetingRequest.save();

      // Send notification to user
      await sendNotification(
        meetingRequest.userId,
        "meeting_rejected",
        "Meeting Request Rejected",
        `${volunteer.displayName} has declined your meeting request.`,
        {
          meetingRequestId: meetingRequest.meetingId,
          rejectReason: rejectReason,
        }
      );

      return meetingRequest;
    } catch (error) {
      throw error;
    }
  }

  // Get meeting requests for a specific volunteer
  async getVolunteerMeetingRequests(volunteerId) {
    try {
      const requests = await MeetingRequest.find({ volunteerId })
        .populate("userId", "displayName email")
        .sort({ createdAt: -1 });

      return requests;
    } catch (error) {
      throw error;
    }
  }

  // Get meeting requests created by a specific user
  async getUserMeetingRequests(userId) {
    try {
      const requests = await MeetingRequest.find({ userId })
        .populate("volunteerId", "displayName email")
        .sort({ createdAt: -1 });

      return requests;
    } catch (error) {
      throw error;
    }
  }
}

export default new MeetingRequestService();
