import { createClient } from "@supabase/supabase-js";
import { GoogleGenerativeAI } from "@google/generative-ai";
import { ChatGoogleGenerativeAI } from "@langchain/google-genai";
import { HumanMessage, AIMessage } from "@langchain/core/messages";
import cld3 from "cld3-asm";
import dotenv from "dotenv";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

// Ensure environment variables are loaded before using them
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, "..", "..");
const rootEnvPath = path.join(projectRoot, ".env");
if (fs.existsSync(rootEnvPath)) {
  dotenv.config({ path: rootEnvPath });
} else {
  dotenv.config();
}

let cldFactory = null;
let identifier = null;

async function initLanguageIdentifier() {
  cldFactory = await cld3.loadModule({ timeout: 5000 });
  identifier = cldFactory.create(0, 512);
}

// Call this once at server startup
initLanguageIdentifier();

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// Initialize Google GenAI client for embeddings
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);
const embeddingModel = genAI.getGenerativeModel({
  model: "text-embedding-004",
});

// Set up Gemini LLM for chat
const model = new ChatGoogleGenerativeAI({
  model: "gemini-1.5-flash",
  temperature: 0.3,
  apiKey: process.env.GEMINI_API_KEY,
});

// ----------------- Gemini Chat via LangChain -----------------
async function askGeminiWithLangchain({
  user,
  history,
  message,
  language = "en",
  lastUserMessage,
}) {
  const isReturning = message === "__resume__";
  const name = user?.displayName || "Guest";
  const country = user?.country || "an unknown country";
  let systemPrompt;
  if (isReturning) {
    systemPrompt = `
    You are a wise, very kind Islamic advisor helping ${name} from ${country}. 
    Guide users with sincere care, rooted in authentic Islamic teachings.
    
    Support each user based on their background, past questions, and spiritual needs. 
    This user is returning to continue a previous conversation. Their last message was: "${lastUserMessage}".
    
    Welcome them warmly, for example:
    "As-salamu alaykum, ${name}. I was waiting for you."
    
    Ask if they would like to continue where they left off. 
    If they had a personal goal (e.g., prayer, behavior, emotion), gently follow up with encouragement.
    
    At the end of your answer, follow these steps:
    1. Understand the user's last concern.
    2. Predict 2–3 **Islamic questions** they might naturally ask next.
    3. Keep suggestions relevant to their situation — not general advice.
    
    Use this exact format (no bold, no markdown, no extra newlines):
    Suggestions:
    - suggestion 1
    - suggestion 2
    - suggestion 3
    
    Suggestions must not include apps, links, or full sentences.
    Each suggestion must be under 12 words.  
    Reply only in ${language}. No transliteration. No English. No too long answers.
    IMPORTANT: Your answer must be less than 50 words. Do not exceed this limit.
     IMPORTANT: Do NOT use any Markdown, asterisks (), or bold. Use only plain text.
    `.trim();
  } else {
    //greeting a new user
    systemPrompt = `
You are a wise, kind Islamic advisor helping ${name} from ${country}. 
Guide users with sincere care, rooted in authentic Islamic teachings.
Support each user based on their background, questions, and needs. 

explain a little about the app and how it can help them. eg.Hidaya app is a platform that helps you learn about Islam and connect with others who share your faith.
Your role spreads goodness, Islam, and peace. 
You are essential to our app and valued for your guidance.

Reply only in ${language}. No transliteration.
IMPORTANT: Your answer must be less than 50 words. Do not exceed this limit.
 IMPORTANT: Do NOT use any Markdown, asterisks (), or bold. Use only plain text.
`.trim();
  }

  const chatHistory = history.map((item) =>
    item.sender === "user"
      ? new HumanMessage(item.message)
      : new AIMessage(item.message)
  );

  if (message && message.trim() && !isReturning) {
    chatHistory.push(new HumanMessage(message));
  } else if (isReturning && lastUserMessage && lastUserMessage.trim()) {
    chatHistory.push(new HumanMessage("..."));
  }

  const prompt = [new AIMessage(systemPrompt), ...chatHistory];
  console.log("prompt", prompt);
  const result = await model.invoke(prompt);
  return result.content;
}

// Helpers: memory gating and deduplication
function isMemoryWorthy(text) {
  if (!text) return false;
  const trimmed = text.trim();
  if (trimmed.length < 30) return false;
  const stopPhrases = [
    /^(hi|hello|thanks|thank you|ok|okay|bye|السلام|مرحبا)/i,
  ];
  let cleaned = trimmed;
  stopPhrases.forEach((regex) => {
    cleaned = cleaned.replace(regex, "").trim();
  });
  const keywords = [
    /\bi (prefer|like|love|live|work|study|plan|aim|goal|struggle|face|suffer|need|want)\b/i,
  ];
  keywords.forEach((regex) => {
    cleaned = cleaned.replace(regex, "").trim();
  });
  return cleaned.length > 0;
}

async function maybeSaveLongTermMemory(userId, text) {
  try {
    if (!isMemoryWorthy(text)) return;
    const { embedding } = await embeddingModel.embedContent(text);

    const vector = embedding?.values || [];

    const matches = await getRelevantMemory(userId, text, 1, vector);

    if (Array.isArray(matches) && matches.length > 0) return;

    await saveLongTermMemory(userId, text, vector);
  } catch (err) {
    // Do not block chat flow on memory errors
    console.error("maybeSaveLongTermMemory error:", err);
  }
}

// New function: integrates short-term history with long-term memory (Supabase + embeddings)
async function askGeminiWithLangGraph({ user, message }) {
  let session = await getLastSession(user.id);
  if (!session) {
    session = await createNewSupabaseSession(user.id);
  }
  const name = user?.displayName || "Guest";
  const country = user?.country || "an unknown country";
  const language = "en";
  const shortTermMessages = await fetchRecentMessages(session.id, 10);

  const longTermMemory = await getRelevantMemory(user.id, message, 3);

  const systemPrompt = `
You are a wise, kind Islamic advisor helping ${name} from ${country}. 
Guide users with sincere care, rooted in authentic Islamic teachings.
 don't greet user. you are in the middle of a chat.
Support each user based on their background, questions, and needs. 
If they face problems, offer Islamic solutions and, when helpful, share real-life-inspired stories.

Your role spreads goodness, Islam, and peace. 
You are essential to our app and valued for your guidance.

At the end of your answer, follow these steps :
1-understand the current message topic
2- Predict 2 or 3 **next Islamic questions** the user might naturally ask.
3-These should be short, practical, and follow from their current concern — not general themes.
Use this exact format (no bold, no markdown, no extra newlines):
Suggestions:
- suggestion 1
- suggestion 2
- suggestion 3

Each suggestion must be under 15 words.  
Suggestions must have no apps suggestions, or links.
Reply only in ${language}. No transliteration.
IMPORTANT: Your answer must be less than 50 words. Do not exceed this limit.
 IMPORTANT: Do NOT use any Markdown, asterisks (), or bold. Use only plain text.
`.trim();

  const prompt = [
    new AIMessage(systemPrompt),
    ...longTermMemory.map((m) => new AIMessage(`Remember: ${m}`)),
    ...shortTermMessages.map((m) =>
      m.sender === "user"
        ? new HumanMessage(m.message)
        : new AIMessage(m.message)
    ),
    new HumanMessage(message),
  ];

  const result = await model.invoke(prompt);

  await saveChatMessage(session.id, "user", message);
  await saveChatMessage(session.id, "ai", result.content);

  await maybeSaveLongTermMemory(user.id, message);

  // User Matching System - Find similar users and record matches
  try {
    const similarUsers = await findSimilarUsers(user.id, message, 3);
    for (const similarUser of similarUsers) {
      if (similarUser.user_id && similarUser.user_id !== user.id) {
        await recordUserMatch(user.id, similarUser.user_id);
      }
    }
  } catch (err) {
    console.error("User matching error:", err);
  }

  return result.content;
}

async function getLastSession(userId) {
  const { data, error } = await supabase
    .from("chat_sessions")
    .select("*")
    .eq("user_id", userId)
    .order("created_at", { ascending: false })
    .limit(1);

  if (error) {
    console.error("Error fetching last session:", error);
    return null;
  }

  // Return the first session if it exists, otherwise null
  return data && data.length > 0 ? data[0] : null;
}

async function createNewSupabaseSession(userId) {
  const { data, error } = await supabase
    .from("chat_sessions")
    .insert([{ user_id: userId }])
    .select()
    .single();

  if (error) {
    console.error("Error creating new session:", error);
    throw new Error("Failed to create session");
  }
  console.log("created new sessionid:", data.id, "for the userid:", userId);
  return data; // new session row with id
}

async function saveChatMessage(sessionId, sender, message) {
  await supabase
    .from("chat_messages")
    .insert([{ session_id: sessionId, sender, message }]);

  // For now, just log and resolve
  console.log(`[${sender}] (${sessionId}): ${message}`);
}

async function fetchRecentMessages(sessionId, limit = 10) {
  const { data, error } = await supabase
    .from("chat_messages")
    .select("sender, message")
    .eq("session_id", sessionId)
    .order("timestamp", { ascending: false })
    .limit(limit);

  if (error) {
    console.error("Error fetching messages:", error);
    return [];
  }
  //console.log("History messages", data);
  return data || [];
}

// ----------------- Long-Term Memory -----------------
async function saveLongTermMemory(userId, text, precomputedEmbedding) {
  try {
    if (!text || !text.trim()) return;
    const vector = precomputedEmbedding;
    const { error } = await supabase.from("user_memory").insert({
      user_id: userId,
      content: text,
      embedding: vector,
    });

    if (error) console.error("Error saving long-term memory:", error);
  } catch (err) {
    console.error("saveLongTermMemory exception:", err);
  }
}

// Fetch top-K relevant memories
async function getRelevantMemory(
  userId,
  query,
  matchCount = 3,
  precomputedEmbedding
) {
  try {
    if (!query || !query.trim()) return [];
    // Generate or reuse embedding
    const vector = precomputedEmbedding
      ? precomputedEmbedding
      : (await embeddingModel.embedContent(query)).embedding?.values || [];

    // Call Supabase function
    const { data, error } = await supabase.rpc("match_user_memory", {
      query_embedding: vector,
      match_threshold: 0.75,
      match_count: matchCount,
      user_id: userId, // text type in your SQL
    });

    if (error) {
      console.error("Error retrieving long-term memory:", error);
      return [];
    }

    // Each row has { id, content, similarity }
    return (
      data?.map((row) => ({
        id: row.id,
        content: row.content,
        similarity: row.similarity,
      })) || []
    );
  } catch (err) {
    console.error("getRelevantMemory exception:", err);
    return [];
  }
}

// ----------------- User Matching System -----------------

async function recordUserMatch(userA, userB) {
  if (!userA || !userB || userA === userB) return null;

  try {
    const { data, error } = await supabase.rpc("increment_user_match", {
      first_user: userA,
      second_user: userB,
    });

    if (error) {
      console.error("Error saving match:", error);
      return null;
    }
    console.log("recordUserMatch data:", data);
    // Threshold check
    if (data && data.length > 0 && data[0].match_count >= 10) {
      console.log(
        "Users reached match threshold:",
        data[0].user_a,
        data[0].user_b
      );

      const connectionStatus = await checkConnectionStatus(
        data[0].user_a,
        data[0].user_b
      );

      // Only send notifications if it's a new connection and not already accepted
      if (!connectionStatus.bothAccepted && connectionStatus.isNewConnection) {
        console.log(
          `Sending notifications for new connection between ${data[0].user_a} and ${data[0].user_b}`
        );
        await sendMatchNotification(data[0].user_a, data[0].user_b);
      } else {
        console.log(
          `Skipping notifications - connection already exists  between ${data[0].user_a} and ${data[0].user_b}`
        );
      }
    }

    return data[0];
  } catch (err) {
    console.error("recordUserMatch error:", err);
    return null;
  }
}

async function checkConnectionStatus(userA, userB) {
  try {
    const [first, second] = [userA, userB].sort();

    const { data, error } = await supabase
      .from("user_connections")
      .select("user_a_accepted, user_b_accepted")
      .eq("user_a", first)
      .eq("user_b", second)
      .single();

    if (error || !data) {
      // Create a new row with both accepted flags set to false
      try {
        console.log("checkConnectionStatus creating new row");
        await supabase.from("user_connections").insert({
          user_a: first,
          user_b: second,
          user_a_accepted: false,
          user_b_accepted: false,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        });
      } catch (e) {
        // Ignore insert errors here and just return defaults
        console.error("checkConnectionStatus error:", e);
      }
      return {
        bothAccepted: false,
        userAAccepted: false,
        userBAccepted: false,
        isNewConnection: true, // Indicates this is a new connection
      };
    }

    const bothAccepted = data.user_a_accepted && data.user_b_accepted;
    return {
      bothAccepted,
      userAAccepted: data.user_a_accepted,
      userBAccepted: data.user_b_accepted,
      isNewConnection: false, // Indicates this connection already existed
    };
  } catch (err) {
    console.error("checkConnectionStatus error:", err);
    return {
      bothAccepted: false,
      userAAccepted: false,
      userBAccepted: false,
      isNewConnection: false,
    };
  }
}

async function sendMatchNotification(userA, userB) {
  try {
    // Import notification service dynamically to avoid circular dependencies
    const { sendNotification } = await import("./notificationService.js");

    // Get user details for personalized messages
    const userADetails = await getUserDetails(userA);
    const userBDetails = await getUserDetails(userB);
    console.log(
      "sendMatchNotification",
      userADetails.userId,
      userBDetails.userId
    );
    if (userADetails && userBDetails) {
      // Send notification to user A
      await sendNotification({
        userId: userADetails.userId,
        type: "user_match",
        title: "Great News!  🌿A Special Connection opportinity",
        message: `We noticed that you and ${
          userBDetails.displayName || "another user"
        } have much in common. Would you like to connect and remind one another of Allah along this journey?`,
        data: {
          matchedUserId: userB,
          currentUserId: userA,
          matchType: "initial",
        },
      });

      // Send notification to user B
      await sendNotification({
        userId: userBDetails.userId,
        type: "user_match",
        title: "Great News!  🌿A Special Connection opportinity",
        message: `We noticed that you and ${
          userADetails.displayName || "another user"
        } have much in common. Would you like to connect and remind one another of Allah along this journey?`,
        data: {
          matchedUserId: userA,
          currentUserId: userB,
          matchType: "initial",
        },
      });
    }
  } catch (err) {
    console.error("sendMatchNotification error:", err);
  }
}

async function getUserDetails(userId) {
  //supabase uses user._id but send notifications uses user.userId
  try {
    // Import the User model from MongoDB
    const User = await import("../models/User.js");

    // Get user details from MongoDB
    const user = await User.default.findOne({ _id: userId });

    if (user) {
      return {
        userId: user.userId,
        displayName: user.displayName || `User ${userId.substring(0, 8)}`,
        email: user.email || `${userId.substring(0, 8)}@hidaya.app`,
        country: user.country || "Unknown",
        language: user.language || "en",
      };
    }

    // Fallback: check if user exists in chat_sessions (Supabase)
    const { data: sessionData, error: sessionError } = await supabase
      .from("chat_sessions")
      .select("user_id")
      .eq("user_id", userId)
      .single();

    if (sessionData) {
      // User exists in chat_sessions, return basic info
      return {
        displayName: `User ${userId.substring(0, 8)}`,
        email: `${userId.substring(0, 8)}@hidaya.app`,
        country: "Unknown",
        language: "en",
      };
    }

    // Final fallback: return basic user info
    return {
      displayName: `User ${userId.substring(0, 8)}`,
      email: `${userId.substring(0, 8)}@hidaya.app`,
      country: "Unknown",
      language: "en",
    };
  } catch (err) {
    console.error("getUserDetails error:", err);
    // Return fallback user info
    return {
      displayName: `User ${userId.substring(0, 8)}`,
      email: `${userId.substring(0, 8)}@hidaya.app`,
      country: "Unknown",
      language: "en",
    };
  }
}

async function acceptConnection(acceptingUserId, matchedUserId) {
  try {
    const [first, second] = [acceptingUserId, matchedUserId].sort();

    // Check if connection record exists
    const { data: existingConnection, error: checkError } = await supabase
      .from("user_connections")
      .select("*")
      .eq("user_a", first)
      .eq("user_b", second)
      .single();

    if (checkError && checkError.code !== "PGRST116") {
      // PGRST116 = no rows returned
      throw new Error(`Error checking connection: ${checkError.message}`);
    }

    let connectionData;

    if (existingConnection) {
      // Update existing connection
      const updateField =
        first === acceptingUserId ? "user_a_accepted" : "user_b_accepted";
      const { data, error } = await supabase
        .from("user_connections")
        .update({
          [updateField]: true,
          updated_at: new Date().toISOString(),
        })
        .eq("user_a", first)
        .eq("user_b", second)
        .select()
        .single();

      if (error) throw new Error(`Error updating connection: ${error.message}`);
      connectionData = data;
    } else {
      // Create new connection record
      const { data, error } = await supabase
        .from("user_connections")
        .insert({
          user_a: first,
          user_b: second,
          user_a_accepted: first === acceptingUserId,
          user_b_accepted: second === acceptingUserId,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        })
        .select()
        .single();

      if (error) throw new Error(`Error creating connection: ${error.message}`);
      connectionData = data;
    }

    // Check if both users have now accepted
    const bothAccepted =
      connectionData.user_a_accepted && connectionData.user_b_accepted;

    if (bothAccepted) {
      // Send email exchange notification
      await sendEmailExchangeNotification(first, second);
    }

    return {
      success: true,
      bothAccepted,
      connectionData,
    };
  } catch (err) {
    console.error("acceptConnection error:", err);
    return {
      success: false,
      error: err.message,
    };
  }
}

// Ignore connection: mark false for the acting user and cleanup the relationship
async function ignoreConnection(actingUserId, otherUserId) {
  try {
    const [first, second] = [actingUserId, otherUserId].sort();

    // Set accepted=false for the acting user
    const updateField =
      first === actingUserId ? "user_a_accepted" : "user_b_accepted";
    await supabase
      .from("user_connections")
      .update({ [updateField]: false, updated_at: new Date().toISOString() })
      .eq("user_a", first)
      .eq("user_b", second);

    // Remove the relationship row entirely
    await supabase
      .from("user_connections")
      .delete()
      .eq("user_a", first)
      .eq("user_b", second);

    // Also delete from user_matches for both directions
    await supabase
      .from("user_matches")
      .delete()
      .or(
        `and(user_a.eq.${first},user_b.eq.${second}),and(user_a.eq.${second},user_b.eq.${first})`
      );

    return { success: true };
  } catch (err) {
    console.error("ignoreConnection error:", err);
    return { success: false, error: err.message };
  }
}

async function sendEmailExchangeNotification(userA, userB) {
  try {
    const { sendNotification } = await import("./notificationService.js");

    const userADetails = await getUserDetails(userA);
    const userBDetails = await getUserDetails(userB);

    if (userADetails && userBDetails) {
      // Send notification to user A with user B's email
      await sendNotification({
        userId: userADetails.userId,
        type: "connection_established",
        title: "Connection Established!",
        message: `You're now connected with ${
          userBDetails.displayName || "another user"
        }! Their email: ${userBDetails.email}`,
        data: {
          connectedUserId: userB,
          connectedUserEmail: userBDetails.email,
        },
      });

      // Send notification to user B with user A's email
      await sendNotification({
        userId: userBDetails.userId,
        type: "connection_established",
        title: "Connection Established!",
        message: `You're now connected with ${
          userADetails.displayName || "another user"
        }! Their email: ${userADetails.email}`,
        data: {
          connectedUserId: userA,
          connectedUserEmail: userADetails.email,
        },
      });
    }
  } catch (err) {
    console.error("sendEmailExchangeNotification error:", err);
  }
}

async function findSimilarUsers(userId, messageContent, limit = 5) {
  try {
    // Generate embedding for the message content
    const { embedding } = await embeddingModel.embedContent(messageContent);
    const vector = embedding?.values || [];
    console.log("findSimilarUsers is called for user:", userId);
    // Find users with similar message content using the SQL function
    const { data, error } = await supabase.rpc("find_similar_users", {
      p_query_embedding: vector,
      p_current_user_id: userId,
      p_match_threshold: 0.3,
      p_match_count: limit,
    });
    if (error) {
      console.error("Error finding similar users:", error);
      return [];
    }
    if (data) {
      console.log("findSimilarUsers data:", data);
      return data || [];
    }
  } catch (err) {
    console.error("findSimilarUsers error:", err);
    return [];
  }
}

export {
  getLastSession,
  createNewSupabaseSession,
  saveChatMessage,
  fetchRecentMessages,
  saveLongTermMemory,
  getRelevantMemory,
  // Gemini chat exports
  askGeminiWithLangchain,
  askGeminiWithLangGraph,
  // User matching exports
  recordUserMatch,
  acceptConnection,
  findSimilarUsers,
  checkConnectionStatus,
  ignoreConnection,
};
