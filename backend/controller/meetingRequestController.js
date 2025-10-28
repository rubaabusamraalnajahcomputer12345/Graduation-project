import meetingRequestService from "../services/meetingRequestService.js";

// POST /meeting-requests - Create a new meeting request
export async function createMeetingRequest(req, res, next) {
  try {
    const { volunteerId, preferredSlots } = req.body;
    const userId = req.userId || (req.user && req.user._id);

    // Validate required fields
    if (!volunteerId || !preferredSlots) {
      return res.status(400).json({
        status: false,
        message: "volunteerId and preferredSlots are required",
      });
    }

    // Validate preferredSlots array
    if (
      !Array.isArray(preferredSlots) ||
      preferredSlots.length < 1 ||
      preferredSlots.length > 5
    ) {
      return res.status(400).json({
        status: false,
        message: "preferredSlots must be an array with 1-5 entries",
      });
    }

    // Validate each slot has start and end times
    for (let i = 0; i < preferredSlots.length; i++) {
      const slot = preferredSlots[i];
      if (!slot.start || !slot.end) {
        return res.status(400).json({
          status: false,
          message: `Slot ${i + 1} must have both start and end times`,
        });
      }

      // Validate that end time is after start time
      const startTime = new Date(slot.start);
      const endTime = new Date(slot.end);
      if (endTime <= startTime) {
        return res.status(400).json({
          status: false,
          message: `Slot ${i + 1} end time must be after start time`,
        });
      }

      // Validate 30-minute duration
      const duration = endTime.getTime() - startTime.getTime();
      const thirtyMinutes = 30 * 60 * 1000;
      if (duration !== thirtyMinutes) {
        return res.status(400).json({
          status: false,
          message: `Slot ${i + 1} must be exactly 30 minutes`,
        });
      }
    }
    console.log(userId, volunteerId, preferredSlots);
    const meetingRequest = await meetingRequestService.createMeetingRequest(
      userId,
      volunteerId,
      preferredSlots
    );

    res.status(201).json({
      status: true,
      message: "Meeting request created successfully",
      meetingRequest: {
        meetingId: meetingRequest.meetingId,
        status: meetingRequest.status,
        createdAt: meetingRequest.createdAt,
      },
    });
  } catch (error) {
    console.error("Error creating meeting request:", error);
    res.status(400).json({
      status: false,
      message: error.message,
    });
  }
}

// GET /meeting-requests - Get meeting requests for the authenticated user
export async function getMeetingRequests(req, res, next) {
  try {
    const userId = req.userId || (req.user && req.user._id); // From auth middleware
    console.log(userId);
    const requests = await meetingRequestService.getMeetingRequests(userId);

    res.status(200).json({
      status: true,
      message: "Meeting requests retrieved successfully",
      meetingRequests: requests,
    });
  } catch (error) {
    console.error("Error getting meeting requests:", error);
    res.status(500).json({
      status: false,
      message: "Failed to retrieve meeting requests",
    });
  }
}

// GET /meeting-requests/:id - Get a specific meeting request
export async function getMeetingRequestById(req, res, next) {
  try {
    const { id } = req.params;
    const userId = req.userId || (req.user && req.user._id); // From auth middleware

    const meetingRequest = await meetingRequestService.getMeetingRequestById(
      id
    );

    // Check if user is authorized to view this request
    if (
      meetingRequest.userId !== userId &&
      meetingRequest.volunteerId !== userId
    ) {
      return res.status(403).json({
        status: false,
        message: "Unauthorized to view this meeting request",
      });
    }

    res.status(200).json({
      status: true,
      message: "Meeting request retrieved successfully",
      meetingRequest,
    });
  } catch (error) {
    console.error("Error getting meeting request:", error);
    res.status(404).json({
      status: false,
      message: error.message,
    });
  }
}

// PATCH /meeting-requests/:id/select-time - Volunteer selects a time slot
export async function selectTimeSlot(req, res, next) {
  try {
    const { id } = req.params;
    const { selectedSlotIndex } = req.body;
    const volunteerId = req.userId || (req.user && req.user._id); // From auth middleware

    // Validate selectedSlotIndex
    if (selectedSlotIndex === undefined || selectedSlotIndex < 0) {
      return res.status(400).json({
        status: false,
        message: "selectedSlotIndex is required and must be non-negative",
      });
    }

    const result = await meetingRequestService.selectTimeSlot(
      id,
      volunteerId,
      selectedSlotIndex
    );

    res.status(200).json({
      status: true,
      message: "Time slot selected and Zoom meeting created successfully",
      meetingRequest: result.meetingRequest,
      zoomMeeting: {
        joinUrl: result.zoomMeeting.joinUrl,
        meetingId: result.zoomMeeting.meetingId,
      },
    });
  } catch (error) {
    console.error("Error selecting time slot:", error);
    res.status(400).json({
      status: false,
      message: error.message,
    });
  }
}

// PATCH /meeting-requests/:id/reject - Volunteer rejects a meeting request
export async function rejectMeetingRequest(req, res, next) {
  try {
    const { id } = req.params;
    const { rejectReason } = req.body;
    const volunteerId = req.userId || (req.user && req.user._id); // From auth middleware

    // Validate rejectReason
    if (!rejectReason || rejectReason.trim() === "") {
      return res.status(400).json({
        status: false,
        message: "rejectReason is required",
      });
    }

    const meetingRequest = await meetingRequestService.rejectMeetingRequest(
      id,
      volunteerId,
      rejectReason
    );

    res.status(200).json({
      status: true,
      message: "Meeting request rejected successfully",
      meetingRequest,
    });
  } catch (error) {
    console.error("Error rejecting meeting request:", error);
    res.status(400).json({
      status: false,
      message: error.message,
    });
  }
}

// GET /meeting-requests/volunteer - Get meeting requests for a volunteer
export async function getVolunteerMeetingRequests(req, res, next) {
  try {
    console.log("getVolunteerMeetingRequests");
    const volunteerId = req.userId || (req.user && req.user._id); // From auth middleware
    const requests = await meetingRequestService.getVolunteerMeetingRequests(
      volunteerId
    );

    res.status(200).json({
      status: true,
      message: "Volunteer meeting requests retrieved successfully",
      meetingRequests: requests,
    });
  } catch (error) {
    console.error("Error getting volunteer meeting requests:", error);
    res.status(500).json({
      status: false,
      message: "Failed to retrieve volunteer meeting requests",
    });
  }
}

// GET /meeting-requests/user - Get meeting requests created by a user
export async function getUserMeetingRequests(req, res, next) {
  try {
    const userId = req.userId || (req.user && req.user._id); // From auth middleware
    const requests = await meetingRequestService.getUserMeetingRequests(userId);

    res.status(200).json({
      status: true,
      message: "User meeting requests retrieved successfully",
      meetingRequests: requests,
    });
  } catch (error) {
    console.error("Error getting user meeting requests:", error);
    res.status(500).json({
      status: false,
      message: "Failed to retrieve user meeting requests",
    });
  }
}
