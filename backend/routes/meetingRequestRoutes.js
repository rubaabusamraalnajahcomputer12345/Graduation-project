import express from "express";
import { requireCertifiedVolunteer } from "../middlewares/volunteerMiddleware.js";
import {
  createMeetingRequest,
  getMeetingRequests,
  getMeetingRequestById,
  selectTimeSlot,
  rejectMeetingRequest,
  getVolunteerMeetingRequests,
  getUserMeetingRequests,
} from "../controller/meetingRequestController.js";
import authMiddleware from "../services/authMiddleware.js";

const router = express.Router();

// POST /meeting-requests - Create a new meeting request
router.post("/", authMiddleware, createMeetingRequest);

// GET /meeting-requests - Get all meeting requests for the authenticated user
router.get("/", authMiddleware, getMeetingRequests);

// GET /meeting-requests/volunteer - Get meeting requests for a volunteer
router.get("/volunteer", authMiddleware, getVolunteerMeetingRequests);

// GET /meeting-requests/user - Get meeting requests created by a user
router.get("/user", authMiddleware, getUserMeetingRequests);

// GET /meeting-requests/:id - Get a specific meeting request
router.get("/:id", authMiddleware, getMeetingRequestById);

// PATCH /meeting-requests/:id/select-time - Volunteer selects a time slot (requires certified volunteer)
router.patch("/:id/select-time", authMiddleware, selectTimeSlot);

// PATCH /meeting-requests/:id/reject - Volunteer rejects a meeting request (requires certified volunteer)
router.patch("/:id/reject", authMiddleware, rejectMeetingRequest);

export default router;
