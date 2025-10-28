import cron from "node-cron";
import AnswerModel from "../models/Answers.js";
import UserModel from "../models/User.js";
import { sendNotification } from "./notificationService.js";
import { createClient } from "@supabase/supabase-js";
import { ChatGoogleGenerativeAI } from "@langchain/google-genai";
import { HumanMessage, AIMessage } from "@langchain/core/messages";
import { saveLongTermMemory } from "./aiservices.js";

class CronService {
  constructor() {
    this.initScheduledJobs();
  }

  initScheduledJobs() {
    // Schedule weekly volunteer summary (every Sunday at 9:00 AM)
    cron.schedule(
      "0 9 * * 0",
      async () => {
        console.log("Running weekly volunteer summary job...");
        await this.sendWeeklyVolunteerSummary();
      },
      {
        scheduled: true,
        timezone: "UTC",
      }
    );

    // Schedule bi-weekly Islamic reminders (every 2 weeks on Sunday at 10:00 AM)
    cron.schedule(
      "0 10 */2 * 0",
      async () => {
        console.log("Running bi-weekly Islamic reminder job...");
        await this.sendIslamicReminders();
      },
      {
        scheduled: true,
        timezone: "UTC",
      }
    );

    // Schedule Jumu'ah (Friday) notifications (every Friday at 9:00 AM)
    cron.schedule(
      "0 9 * * 5",
      async () => {
        console.log("Running Jumu'ah notification job...");
        await this.sendJumuahNotifications();
      },
      {
        scheduled: true,
        timezone: "UTC",
      }
    );

    // Nightly memory compaction (every day at 02:00 AM UTC)
    cron.schedule(
      "0 2 * * *",
      async () => {
        console.log("Running nightly long-term memory compaction job...");
        await this.compactLongTermMemories();
      },
      {
        scheduled: true,
        timezone: "UTC",
      }
    );

    console.log("Cron jobs initialized:");
    console.log("- Weekly volunteer summary: Sundays at 9:00 AM UTC");
    console.log(
      "- Bi-weekly Islamic reminders: Every 2 weeks on Sunday at 10:00 AM UTC"
    );
    console.log("- Jumu'ah notifications: Every Friday at 9:00 AM UTC");
    console.log("- Nightly memory compaction: Daily at 02:00 AM UTC");
  }

  async sendWeeklyVolunteerSummary() {
    try {
      // Get the start and end of the current week (Monday to Sunday)
      const now = new Date();
      const startOfWeek = new Date(now);
      startOfWeek.setDate(now.getDate() - now.getDay() + 1); // Monday
      startOfWeek.setHours(0, 0, 0, 0);

      const endOfWeek = new Date(startOfWeek);
      endOfWeek.setDate(startOfWeek.getDate() + 6); // Sunday
      endOfWeek.setHours(23, 59, 59, 999);

      console.log(
        `Sending weekly summary for period: ${startOfWeek.toISOString()} to ${endOfWeek.toISOString()}`
      );

      // Get all certified volunteers
      const volunteers = await UserModel.find({
        role: { $in: ["certified_volunteer", "volunteer_pending"] },
        onesignalId: { $exists: true, $ne: null },
      }).lean();

      let totalNotificationsSent = 0;
      let totalErrors = 0;

      for (const volunteer of volunteers) {
        try {
          // Count answers by this volunteer in the current week
          const weeklyAnswers = await AnswerModel.countDocuments({
            answeredBy: volunteer.userId,
            createdAt: {
              $gte: startOfWeek,
              $lte: endOfWeek,
            },
          });

          // Only send notification if volunteer has answered at least one question
          if (weeklyAnswers > 0) {
            // Get upvotes count for this volunteer's answers this week
            const weeklyUpvotes = await AnswerModel.aggregate([
              {
                $match: {
                  answeredBy: volunteer.userId,
                  createdAt: {
                    $gte: startOfWeek,
                    $lte: endOfWeek,
                  },
                },
              },
              {
                $group: {
                  _id: null,
                  totalUpvotes: { $sum: "$upvotesCount" },
                },
              },
            ]);

            const totalUpvotes =
              weeklyUpvotes.length > 0 ? weeklyUpvotes[0].totalUpvotes : 0;

            // Create personalized message based on performance
            let personalizedMessage = "";
            if (totalUpvotes > 0 && weeklyAnswers > 0) {
              personalizedMessage = `Your answers received ${totalUpvotes} upvote${
                totalUpvotes > 1 ? "s" : ""
              } this week. Great job guiding others! 🌟`;
            } else if (weeklyAnswers > 0) {
              const messages = [
                `You've helped ${weeklyAnswers} person${
                  weeklyAnswers > 1 ? "s" : ""
                } this week. May Allah reward your efforts! 🤲`,
                `You’ve answered ${weeklyAnswers} question${
                  weeklyAnswers > 1 ? "s" : ""
                } this week. Can you make it ${weeklyAnswers + 2}?`,
                `Great work! ${weeklyAnswers} answer${
                  weeklyAnswers > 1 ? "s" : ""
                } shared this week. Keep inspiring others!`,
                `Your dedication shows! ${weeklyAnswers} question${
                  weeklyAnswers > 1 ? "s" : ""
                } answered. JazakAllah khair!`,
                `MashAllah! ${weeklyAnswers} person${
                  weeklyAnswers > 1 ? "s" : ""
                } benefited from your help this week.`,
              ];
              personalizedMessage =
                messages[Math.floor(Math.random() * messages.length)];
            }

            const result = await sendNotification({
              userId: volunteer.userId,
              type: "weekly_summary",
              title: " Your Weekly Volunteer Summary",
              message: personalizedMessage,
              data: {
                weekStart: startOfWeek.toISOString(),
                weekEnd: endOfWeek.toISOString(),
                answersCount: weeklyAnswers,
                upvotesCount: totalUpvotes,
                volunteerId: volunteer.userId,
              },
              saveToDatabase: true,
            });

            if (result.pushSent || result.databaseSaved) {
              totalNotificationsSent++;
              console.log(
                `Weekly summary sent to ${
                  volunteer.displayName || volunteer.userId
                }: ${weeklyAnswers} answers`
              );
            } else {
              totalErrors++;
              console.error(
                `Failed to send weekly summary to ${volunteer.userId}:`,
                result.errors
              );
            }
          } else {
            console.log(
              `No answers this week for ${
                volunteer.displayName || volunteer.userId
              }, skipping notification`
            );
          }
        } catch (error) {
          totalErrors++;
          console.error(
            `Error processing weekly summary for ${volunteer.userId}:`,
            error
          );
        }
      }

      console.log(
        `Weekly volunteer summary completed: ${totalNotificationsSent} sent, ${totalErrors} errors`
      );
    } catch (error) {
      console.error("Error in sendWeeklyVolunteerSummary:", error);
    }
  }

  async compactLongTermMemories() {
    try {
      const supabase = createClient(
        process.env.SUPABASE_URL,
        process.env.SUPABASE_ANON_KEY
      );

      const summarizer = new ChatGoogleGenerativeAI({
        model: "gemini-1.5-flash",
        temperature: 0.2,
        apiKey: process.env.GEMINI_API_KEY,
      });

      // 1) Get distinct user_ids that have memories
      const { data: userRows, error: usersError } = await supabase
        .from("user_memory")
        .select("user_id")
        .order("user_id", { ascending: true });

      if (usersError) throw usersError;
      const uniqueUserIds = Array.from(
        new Set((userRows || []).map((r) => r.user_id))
      );

      const MAX_MEMORIES_TO_KEEP = 80; // keep latest
      const MAX_CONTEXT_CHARS = 12000; // cap summarization input size

      for (const userId of uniqueUserIds) {
        // 2) Fetch all memories for the user
        const { data: memories, error: memErr } = await supabase
          .from("user_memory")
          .select("id, content, created_at")
          .eq("user_id", userId)
          .order("created_at", { ascending: true });

        if (memErr) {
          console.error("Failed fetching memories for user:", userId, memErr);
          continue;
        }

        if (!memories || memories.length <= MAX_MEMORIES_TO_KEEP) continue;

        // 3) Determine which to compact (oldest N, keep latest MAX_MEMORIES_TO_KEEP)
        const numToCompact = memories.length - MAX_MEMORIES_TO_KEEP;
        const toCompact = memories.slice(0, numToCompact);
        const toKeep = memories.slice(numToCompact);

        // 4) Build summarization context (cap length)
        let context = toCompact.map((m) => `- ${m.content}`).join("\n");
        if (context.length > MAX_CONTEXT_CHARS) {
          context = context.slice(0, MAX_CONTEXT_CHARS);
        }

        const system = `You are summarizing a user's long-term preferences, goals, constraints, and biographical details for future personalization.\n- Extract only stable, recurring facts and themes.\n- Remove duplicates and trivialities.\n- Prefer short bullets (4-8), under 120 words total.\n- No sensitive data.`;

        const prompt = [new AIMessage(system), new HumanMessage(context)];

        // 5) Generate summary
        let summaryText = "";
        try {
          const result = await summarizer.invoke(prompt);
          summaryText =
            typeof result?.content === "string"
              ? result.content
              : String(result?.content ?? "");
        } catch (summErr) {
          console.error("Summarization failed for user:", userId, summErr);
          continue;
        }

        if (!summaryText || summaryText.trim().length === 0) continue;

        // 6) Save summary as a new long-term memory (will embed and store)
        await saveLongTermMemory(userId, summaryText);

        // 7) Delete compacted rows
        const idsToDelete = toCompact.map((m) => m.id);
        const { error: delErr } = await supabase
          .from("user_memory")
          .delete()
          .in("id", idsToDelete);

        if (delErr) {
          console.error(
            "Failed deleting compacted rows for user:",
            userId,
            delErr
          );
        } else {
          console.log(
            `Compacted ${idsToDelete.length} memories for user ${userId}; kept ${toKeep.length} and added 1 summary.`
          );
        }
      }
    } catch (error) {
      console.error("Error in compactLongTermMemories:", error);
    }
  }

  async sendIslamicReminders() {
    try {
      // Get all users with OneSignal IDs
      const allUsers = await UserModel.find({
        onesignalId: { $exists: true, $ne: null },
      }).lean();

      if (allUsers.length === 0) {
        console.log("No users with OneSignal IDs found for Islamic reminders");
        return;
      }

      // Select random 50% of users
      const randomUsers = this.getRandomUsers(
        allUsers,
        Math.ceil(allUsers.length * 0.5)
      );

      console.log(
        `Sending Islamic reminders to ${randomUsers.length} random users out of ${allUsers.length} total users`
      );

      // Array of Islamic reminders
      const islamicReminders = [
        {
          title: " Islamic Reminder",
          message:
            "Reminder: Islam is a journey, not a destination. We're here for your questions anytime.",
        },
        {
          title: " Daily Reflection",
          message:
            "Take a moment to reflect on your faith today. Every question brings you closer to understanding.",
        },
        {
          title: " Knowledge is Light",
          message:
            "Seeking knowledge is a form of worship. Don't hesitate to ask questions about your faith.",
        },
        {
          title: " Community Support",
          message:
            "Remember, you're not alone in your spiritual journey. Our community is here to support you.",
        },
        {
          title: " Faith & Growth",
          message:
            "Every step in learning about Islam is a step toward spiritual growth. Keep asking, keep learning.",
        },
        {
          title: " Peace & Guidance",
          message:
            "May Allah guide you in your journey of faith. We're here to help with any questions you have.",
        },
        {
          title: " Spiritual Connection",
          message:
            "Strengthen your connection with Allah through knowledge. Every question is a step forward.",
        },
        {
          title: " Learning Together",
          message:
            "In seeking knowledge, we grow together as a community. Your questions help others learn too.",
        },
      ];

      let totalNotificationsSent = 0;
      let totalErrors = 0;

      for (const user of randomUsers) {
        try {
          // Select a random reminder
          const randomReminder =
            islamicReminders[
              Math.floor(Math.random() * islamicReminders.length)
            ];

          const result = await sendNotification({
            userId: user.userId,
            type: "islamic_reminder",
            title: randomReminder.title,
            message: randomReminder.message,
            data: {
              reminderType: "islamic",
              sentAt: new Date().toISOString(),
              userId: user.userId,
            },
            saveToDatabase: true,
          });

          if (result.pushSent || result.databaseSaved) {
            totalNotificationsSent++;
            console.log(
              `Islamic reminder sent to ${user.displayName || user.userId}`
            );
          } else {
            totalErrors++;
            console.error(
              `Failed to send Islamic reminder to ${user.userId}:`,
              result.errors
            );
          }
        } catch (error) {
          totalErrors++;
          console.error(
            `Error sending Islamic reminder to ${user.userId}:`,
            error
          );
        }
      }

      console.log(
        `Islamic reminders completed: ${totalNotificationsSent} sent, ${totalErrors} errors`
      );
    } catch (error) {
      console.error("Error in sendIslamicReminders:", error);
    }
  }

  async sendJumuahNotifications() {
    try {
      // Get all regular users (role = "user") with OneSignal IDs
      const regularUsers = await UserModel.find({
        role: "user",
        onesignalId: { $exists: true, $ne: null },
      }).lean();

      if (regularUsers.length === 0) {
        console.log(
          "No regular users with OneSignal IDs found for Jumu'ah notifications"
        );
        return;
      }

      console.log(
        `Sending Jumu'ah notifications to ${regularUsers.length} regular users`
      );

      // Array of Jumu'ah notifications
      const jumuahNotifications = [
        {
          title: "(￣▽￣) It's Jumu'ah today!",
          message: "Muslims read Surah Al-Kahf. Give it a try! ",
        },
        {
          title: "（*＾-＾*） It's Jumu'ah today!",
          message: "Ask Allah what you need - it's good today! ",
        },
        {
          title: "^_~ Blessed Friday",
          message:
            "Today is Jumu'ah - a blessed day for dua and worship. Make the most of it! ",
        },
        {
          title: "(✿◡‿◡) Jumu'ah Mubarak",
          message:
            "It's Friday! Read Surah Al-Kahf and make lots of dua. May Allah accept your prayers! 📿",
        },
        {
          title: "(❁´◡`❁) Special Day",
          message:
            "Jumu'ah is here! It's a great time to ask Allah for what you need. Don't miss this opportunity! ",
        },
      ];

      let totalNotificationsSent = 0;
      let totalErrors = 0;

      for (const user of regularUsers) {
        try {
          // Select a random Jumu'ah notification
          const randomNotification =
            jumuahNotifications[
              Math.floor(Math.random() * jumuahNotifications.length)
            ];

          const result = await sendNotification({
            userId: user.userId,
            type: "jumuah_reminder",
            title: randomNotification.title,
            message: randomNotification.message,
            data: {
              reminderType: "jumuah",
              sentAt: new Date().toISOString(),
              userId: user.userId,
              dayOfWeek: "Friday",
            },
            saveToDatabase: true,
          });

          if (result.pushSent || result.databaseSaved) {
            totalNotificationsSent++;
            console.log(
              `Jumu'ah notification sent to ${user.displayName || user.userId}`
            );
          } else {
            totalErrors++;
            console.error(
              `Failed to send Jumu'ah notification to ${user.userId}:`,
              result.errors
            );
          }
        } catch (error) {
          totalErrors++;
          console.error(
            `Error sending Jumu'ah notification to ${user.userId}:`,
            error
          );
        }
      }

      console.log(
        `Jumu'ah notifications completed: ${totalNotificationsSent} sent, ${totalErrors} errors`
      );
    } catch (error) {
      console.error("Error in sendJumuahNotifications:", error);
    }
  }

  // Helper function to get random users
  getRandomUsers(users, count) {
    const shuffled = [...users].sort(() => 0.5 - Math.random());
    return shuffled.slice(0, count);
  }

  // Method to manually trigger weekly summary (for testing)
  async triggerWeeklySummary() {
    console.log("Manually triggering weekly volunteer summary...");
    await this.sendWeeklyVolunteerSummary();
  }

  // Method to manually trigger Islamic reminders (for testing)
  async triggerIslamicReminders() {
    console.log("Manually triggering Islamic reminders...");
    await this.sendIslamicReminders();
  }

  // Method to manually trigger Jumu'ah notifications (for testing)
  async triggerJumuahNotifications() {
    console.log("Manually triggering Jumu'ah notifications...");
    await this.sendJumuahNotifications();
  }

  // Method to get volunteer statistics for a specific period
  async getVolunteerStats(startDate, endDate) {
    try {
      const volunteers = await UserModel.find({
        role: { $in: ["certified_volunteer", "volunteer_pending"] },
      }).lean();

      const stats = [];

      for (const volunteer of volunteers) {
        const answersCount = await AnswerModel.countDocuments({
          answeredBy: volunteer.userId,
          createdAt: {
            $gte: startDate,
            $lte: endDate,
          },
        });

        stats.push({
          userId: volunteer.userId,
          displayName: volunteer.displayName,
          role: volunteer.role,
          answersCount,
          hasOneSignalId: !!volunteer.onesignalId,
        });
      }

      return stats.sort((a, b) => b.answersCount - a.answersCount);
    } catch (error) {
      console.error("Error getting volunteer stats:", error);
      throw error;
    }
  }
}

export default CronService;
