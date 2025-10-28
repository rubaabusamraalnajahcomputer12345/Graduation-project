import express from "express";
import { acceptConnection, ignoreConnection } from "../services/aiservices.js";

const router = express.Router();

// Accept connection: expects query params userA, userB (original pair, any order)
router.get("/accept", async (req, res) => {
  try {
    const { userA, userB } = req.query;
    if (!userA || !userB) {
      return res
        .status(400)
        .json({ success: false, message: "Missing userA or userB" });
    }
    // Assume userB is the acting user (receiving notification). Swap if needed based on your client logic.
    const result = await acceptConnection(userB, userA);
    return res.json({ success: true, result });
  } catch (err) {
    console.error("/connections/accept error:", err);
    return res.status(500).json({ success: false, message: err.message });
  }
});

// Ignore connection: expects query params userA, userB
router.get("/ignore", async (req, res) => {
  try {
    const { userA, userB } = req.query;
    if (!userA || !userB) {
      return res
        .status(400)
        .json({ success: false, message: "Missing userA or userB" });
    }
    const result = await ignoreConnection(userB, userA);
    return res.json({ success: true, result });
  } catch (err) {
    console.error("/connections/ignore error:", err);
    return res.status(500).json({ success: false, message: err.message });
  }
});

export default router;
