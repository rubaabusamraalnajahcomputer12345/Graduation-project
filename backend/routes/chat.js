import express from "express";
const router = express.Router();
import User from "../models/User.js";
import {
  askGeminiWithLangchain,
  askGeminiWithLangGraph,
} from "../services/aiservices.js";

import {
  getLastSession,
  createNewSupabaseSession,
  saveChatMessage,
  fetchRecentMessages,
} from "../services/aiservices.js";
import { verifyToken } from "../services/authMiddleware.js";
import { StreamChat } from "stream-chat";

// Initialize Stream Chat server client once
const streamClient = (() => {
  const apiKey = process.env.STREAM_API_KEY;
  const apiSecret = process.env.STREAM_API_SECRET;
  if (!apiKey || !apiSecret) {
    console.warn(
      "Stream Chat API key/secret missing. Set STREAM_API_KEY and STREAM_API_SECRET in .env"
    );
    return null;
  }
  return StreamChat.getInstance(apiKey, apiSecret);
})();

router.post("/start", async (req, res) => {
  const { userId } = req.body;

  try {
    console.log("=== CHAT START ROUTE DEBUG ===");
    console.log("User ID:", userId);

    const user = await User.findOne({ userId });
    console.log("User found:", user);
    console.log("User ai_session_id:", user?.ai_session_id);

    let session = await getLastSession(user._id);
    console.log("user id to fetch last session:", user._id);
    console.log("Last session found:", session ? "Yes" : "No");
    console.log("Session ID:", session?.id);

    let greetingMessage;
    let isNewSession = false;

    if (!session) {
      console.log("Creating new session...");
      session = await createNewSupabaseSession(userId);
      await User.updateOne({ userId: userId }, { ai_session_id: session.id });
      isNewSession = true;

      // Use LangChain to generate welcome
      greetingMessage = await askGeminiWithLangchain({
        user,
        history: [],
        message: "start", // trigger for a warm intro
      });

      // Save greeting to Supabase
      await saveChatMessage(session.id, "ai", greetingMessage);
      console.log("New session greeting saved:", greetingMessage);
    } else {
      console.log("Resuming existing session...");
      const recentMessages = await fetchRecentMessages(session.id);
      console.log("Recent messages count:", recentMessages.length);

      const lastUserMessage =
        recentMessages.filter((m) => m.sender === "user").slice(-1)[0]
          ?.message || "Asalamualaikum";
      console.log("Last user message:", lastUserMessage);

      greetingMessage = await askGeminiWithLangchain({
        user,
        history: recentMessages,
        message: "__resume__", // Special marker
        lastUserMessage,
      });

      await saveChatMessage(session.id, "ai", greetingMessage);
      console.log("Resume message saved:", greetingMessage);
    }

    // If this is a new session, also return the ai_session_id so frontend can set it
    const responseData = {
      ai_session_id: session.id,
      greeting: greetingMessage, // Only send greeting for new sessions
      isNewSession: isNewSession,
    };

    if (!user.ai_session_id) {
      responseData.ai_session_id = session.id;
      console.log("Setting new ai_session_id:", session.id);
    }

    console.log("Response data:", responseData);
    console.log("=== END CHAT START ROUTE DEBUG ===");

    res.json(responseData);
  } catch (error) {
    console.error("Error in chat start route:", error);
    res.status(500).json({ error: error.message });
  }
});

router.post("/send", async (req, res) => {
  const { userId, message, ai_session_id } = req.body;

  console.log("=== CHAT SEND ROUTE DEBUG ===");
  console.log("Received /send request:", { userId, message, ai_session_id });

  try {
    // Get user profile from MongoDB
    const user = await User.findOne({ userId });
    console.log("Fetched user profile:", user ? "Yes" : "No");
    console.log("User ai_session_id:", user?.ai_session_id);
    console.log("User ", user);

    // Call Gemini API with integrated short-term + long-term memory
    const aiReply = await askGeminiWithLangGraph({ user, message });
    console.log("AI reply from Gemini:", aiReply);

    console.log("=== END CHAT SEND ROUTE DEBUG ===");
    res.json({ reply: aiReply });
  } catch (error) {
    console.error("Error in /send route:", error);
    res.status(500).json({ error: error.message });
  }
});

// Issue Stream Chat user token for the authenticated user
router.post("/stream-token", verifyToken, async (req, res) => {
  try {
    if (!streamClient) {
      return res
        .status(500)
        .json({ error: "Stream Chat is not configured on the server" });
    }

    const authUserId = req.userId || req.user?._id;
    if (!authUserId) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    // Fetch display name if available
    const user = await User.findOne({ userId: authUserId });
    const displayName = user?.displayName || authUserId;

    // Ensure user exists in Stream and get a token
    await streamClient.upsertUser({ id: authUserId, name: displayName });
    const token = streamClient.createToken(authUserId);

    return res.json({
      token,
      userId: authUserId,
      name: displayName,
      apiKey: process.env.STREAM_API_KEY,
    });
  } catch (error) {
    console.error("Error issuing Stream token:", error);
    return res.status(500).json({ error: error.message });
  }
});

// Ensure user exists in Stream Chat (for other users)
router.post("/ensure-user", verifyToken, async (req, res) => {
  try {
    if (!streamClient) {
      return res
        .status(500)
        .json({ error: "Stream Chat is not configured on the server" });
    }

    const { userId } = req.body;
    if (!userId) {
      return res.status(400).json({ error: "User ID is required" });
    }

    // Check if user exists in our database
    const user = await User.findOne({ userId });
    if (!user) {
      return res.status(404).json({ error: "User not found in database" });
    }

    const displayName = user.displayName || user.userId || userId;

    // Ensure user exists in Stream Chat
    await streamClient.upsertUser({ 
      id: userId, 
      name: displayName,
      // Add any other user properties you want to sync
      image: user.profilePicture || undefined,
    });

    return res.json({ 
      success: true, 
      message: "User ensured in Stream Chat",
      userId: userId,
      name: displayName
    });
  } catch (error) {
    console.error("Error ensuring user in Stream Chat:", error);
    return res.status(500).json({ error: error.message });
  }
});

export default router;
