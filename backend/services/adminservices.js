import moment from "moment-timezone";
import User from "../models/User.js";
import Question from "../models/Questions.js";
import Story from "../models/Stories.js";
import Flag from "../models/Flags.js";
import Answer from "../models/Answers.js";
import { v4 as uuidv4 } from "uuid";
import cron from "node-cron";

import FlagServices from "./flagsservices.js";
import { sendNotification } from "./notificationService.js";

import e from "express";
const timezone = "Asia/Palestine";

const categories = [
  "Worship",
  "Prayer",
  "Fasting",
  "Hajj & Umrah",
  "Islamic Finance",
  "Family & Marriage",
  "Daily Life",
  "Quran & Sunnah",
  "Islamic History",
  "Etiquette",
  "Other",
];

class AdminServices {
  static async getCumulativeMonthlyUsers(users) {
    const monthlyCounts = {};
    //reset the monthlyCounts object
    const monthOrder = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    monthOrder.forEach((month) => (monthlyCounts[month] = 0));

    // count the users for each month
    users.forEach((user) => {
      const month = moment(user.createdAt).format("MMM");
      monthlyCounts[month] = (monthlyCounts[month] || 0) + 1;
    });

    // sort the months

    let cumulative = 0;
    let previousMonthCount = 0;

    const result = monthOrder.map((month) => {
      const currentMonthCount = monthlyCounts[month];
      cumulative += currentMonthCount;
      let percentChange = null;
      if (previousMonthCount > 0) {
        percentChange = (
          ((currentMonthCount - previousMonthCount) / previousMonthCount) *
          100
        ).toFixed(2);
      } else if (currentMonthCount > 0) {
        percentChange = "100.00";
      } else {
        percentChange = "0.00";
      }
      const monthData = {
        month,
        users: cumulative,
        newUsers: currentMonthCount,
        percentChange: `${percentChange}%`,
      };

      previousMonthCount = currentMonthCount;
      return monthData;
    });
    console.log(result);
    return result;
  }

  static async getQuestionCategories(allQuestions) {
    const categoryCountMap = {};
    categories.forEach((cat) => (categoryCountMap[cat] = 0));

    allQuestions.forEach((question) => {
      const categoriesList = Array.isArray(question.category)
        ? question.category
        : [question.category]; // handle the case where category is a string directly

      categoriesList.forEach((category) => {
        if (category && categoryCountMap.hasOwnProperty(category)) {
          categoryCountMap[category]++;
        }
      });
    });

    const result = categories.map((category) => ({
      category,
      count: categoryCountMap[category] || 0,
    }));
    console.log(result);
    return result;
  }
  static async getGenderDistribution(allUsers) {
    const genderDistribution = {};
    genderDistribution.male = 0;
    genderDistribution.female = 0;
    genderDistribution.other = 0;
    allUsers.forEach((user) => {
      if (user.gender === "Male") {
        genderDistribution.male++;
      } else if (user.gender === "Female") {
        genderDistribution.female++;
      } else {
        genderDistribution.other++;
      }
    });
    console.log(genderDistribution);
    return genderDistribution;
  }
  static async getDashboardStats() {
    const dashinfo = {};
    const today = new Date();
    const currentDay = today.getDay(); // 0 = Sunday, 1 = Monday, ..., 6 = Saturday
    const startOfThisWeek = new Date(today);
    startOfThisWeek.setDate(today.getDate() - currentDay); // Sunday
    startOfThisWeek.setHours(0, 0, 0, 0);

    const startOfLastWeek = new Date(startOfThisWeek);
    startOfLastWeek.setDate(startOfThisWeek.getDate() - 7);

    const endOfLastWeek = new Date(startOfThisWeek);
    endOfLastWeek.setSeconds(-1);

    const startOfToday = moment.tz(timezone).startOf("day").toDate();
    const startOfYesterday = moment
      .tz(timezone)
      .subtract(1, "day")
      .startOf("day")
      .toDate();
    const endOfYesterday = moment
      .tz(timezone)
      .subtract(1, "day")
      .endOf("day")
      .toDate();

    dashinfo.totalusers = await User.countDocuments();

    // Calculate monthly increase in users
    const startOfThisMonth = moment.tz(timezone).startOf("month").toDate();
    const startOfLastMonth = moment
      .tz(timezone)
      .subtract(1, "month")
      .startOf("month")
      .toDate();
    const endOfLastMonth = moment
      .tz(timezone)
      .subtract(1, "month")
      .endOf("month")
      .toDate();

    const usersThisMonth = await User.countDocuments({
      createdAt: { $gte: startOfThisMonth },
    });
    const usersLastMonth = await User.countDocuments({
      createdAt: { $gte: startOfLastMonth, $lte: endOfLastMonth },
    });

    dashinfo.monthlyincreaseinusers = usersThisMonth - usersLastMonth;
    dashinfo.totalquestions = await Question.countDocuments();
    const questionToday = await Question.countDocuments({
      createdAt: { $gte: startOfYesterday },
    });
    const questionYesterday = await Question.countDocuments({
      createdAt: { $gte: startOfYesterday, $lte: endOfYesterday },
    });
    dashinfo.dailyincreaseinquestions = questionToday - questionYesterday;
    console.log(
      "questionToday: " + questionToday,
      "questionYesterday: " + questionYesterday
    );

    dashinfo.totalstories = await Story.countDocuments();
    dashinfo.totalflags = await Flag.countDocuments();
    dashinfo.totalcertifiedvolunteers = await User.countDocuments({
      role: "certified_volunteer",
    });
    const CertifiedThisWeek = await User.countDocuments({
      role: "certified_volunteer",
      createdAt: { $gte: startOfLastWeek },
    });

    const CertifiedLastWeek = await User.countDocuments({
      role: "certified_volunteer",
      createdAt: { $gte: startOfLastWeek, $lte: endOfLastWeek },
    });
    console.log(CertifiedThisWeek, CertifiedLastWeek);

    dashinfo.weeklyincreaseincertifiedvolunteers =
      CertifiedThisWeek - CertifiedLastWeek;

    dashinfo.totalpendingvolunteers = await User.countDocuments({
      role: "volunteer_pending",
    });
    const pendingToday = await User.countDocuments({
      role: "volunteer_pending",
      createdAt: { $gte: startOfYesterday },
    });
    const pendingYesterday = await User.countDocuments({
      role: "volunteer_pending",
      createdAt: { $gte: startOfYesterday, $lte: endOfYesterday },
    });
    dashinfo.dailyincreaseinpendingvolunteers = pendingToday - pendingYesterday;

    dashinfo.totalansweredquestions = await Question.countDocuments({
      topAnswerId: { $exists: true, $ne: null, $ne: "" },
    });
    dashinfo.totalunansweredquestions = await Question.countDocuments({
      $or: [
        { topAnswerId: "" },
        { topAnswerId: { $exists: false } },
        { topAnswerId: null },
      ],
    });

    return dashinfo;
  }

  static async getTodayActivity() {
    const today = new Date();
    const todayActivity = {};
    todayActivity.newusers = await User.countDocuments({
      createdAt: { $gte: today },
    });
    todayActivity.newquestions = await Question.countDocuments({
      createdAt: { $gte: today },
    });
    todayActivity.newstories = await Story.countDocuments({
      createdAt: { $gte: today },
    });
    todayActivity.newflags = await Flag.countDocuments({
      createdAt: { $gte: today },
    });
    console.log(todayActivity);
    return todayActivity;
  }
  static async GetTopContent() {
    const topcontent = {};
    const [topLikedStory] = await Story.aggregate([
      {
        $addFields: {
          likeCountNum: { $toInt: "$likeCount" },
        },
      },
      { $sort: { likeCountNum: -1 } },
      { $limit: 1 },
    ]);
    const [topSavedStory] = await Story.aggregate([
      {
        $addFields: {
          saveCountNum: { $toInt: "$SaveCount" },
        },
      },
      { $sort: { saveCountNum: -1 } },
      { $limit: 1 },
    ]);
    topcontent.toplikedstories = topLikedStory || null;
    topcontent.topsavedstories = topSavedStory || null;

    const users = await User.find({}, "savedQuestions");
    const questionSaveMap = {};
    users.forEach((user) => {
      user.savedQuestions.forEach((questionId) => {
        questionSaveMap[questionId] = (questionSaveMap[questionId] || 0) + 1;
      });
    });
    let mostSavedQuestionId = null;
    let maxSaves = 0;

    for (const [id, count] of Object.entries(questionSaveMap)) {
      if (count > maxSaves) {
        mostSavedQuestionId = id;
        maxSaves = count;
      }
    }
    let mostSavedQuestion = null;
    if (mostSavedQuestionId) {
      mostSavedQuestion = await Question.findOne({
        questionId: mostSavedQuestionId,
      });
    }
    topcontent.mostsavedquestion = mostSavedQuestion || null;

    console.log(topcontent);
    return topcontent;
  }
  static async getUsersData() {
    const usersdata = await User.find({}); //i want to get all the information of the users
    const questions = await Question.find({});
    const answers = await Answer.find({});

    //i want to to get the number of the questions that asked by the user and the question that answered by the volunteer (not only the top answer)
    const userStats = usersdata.map((user) => {
      const userId = user.userId;

      const questionsAsked = questions.filter(
        (q) => q.askedBy === userId
      ).length;
      const questionsAnswered = answers.filter(
        (a) => a.answeredBy === userId
      ).length;

      return {
        ...user.toObject(),
        questionsAsked,
        questionsAnswered,
      };
    });
    console.log(userStats);
    return userStats;
  }

  static async approveVoulnteer(volunteerId) {
    console.log(volunteerId);
    const user = await User.findOneAndUpdate(
      { userId: volunteerId },
      { role: "certified_volunteer" },
      { new: true }
    ); //i want to update the role of the user to certified_volunteer
    console.log(user);
    return user;
  }

  static async getallstories() {
    const stories = await Story.find({});
    console.log(stories);
    return stories;
  }
  static async AddNewStory(storyData) {
    if (
      !storyData.title ||
      !storyData.description ||
      !storyData.journeyToIslam ||
      !storyData.background ||
      !storyData.afterIslam ||
      !storyData.type ||
      !storyData.mediaUrl ||
      !storyData.name ||
      !storyData.country ||
      !storyData.tags ||
      !storyData.quote
    ) {
      throw new Error("Missing required fields");
    }
    const newstory = {
      title: storyData.title,
      description: storyData.description,
      background: storyData.background,
      journeyToIslam: storyData.journeyToIslam,
      afterIslam: storyData.afterIslam,
      type: storyData.type,
      mediaUrl: storyData.mediaUrl,
      name: storyData.name,
      country: storyData.country,
      tags: storyData.tags,
      quote: storyData.quote,
      SaveCount: 0,
      likeCount: 0,
      views: 0,
    };
    const story = await Story.create(newstory);
    if (!story) {
      throw new Error("Failed to add story");
    } else {
      console.log(story);
      return {
        success: true,
        message: "Story added successfully",
        story: story,
      };
    }
  }
  static async updateStory(storyId, storyData) {
    console.log(storyId, storyData);
    const story = await Story.findOneAndUpdate({ _id: storyId }, storyData, {
      new: true,
    });
    console.log(story);
    if (!story) {
      throw new Error("Failed to update story");
    } else {
      console.log(story);
      return story;
    }
  }

  static async deleteStory(storyId) {
    const story = await Story.findOneAndDelete({ _id: storyId });
    console.log(story);
    return story;
  }

  static async getAllQuestionsForAdmin() {
    const questions = await Question.find({});
    //Get all questions id
    const questionsId = questions.map((question) => question.questionId);

    // Get all unique user IDs from questions and answers
    const questionUserIds = questions.map((q) => q.askedBy).filter(Boolean);
    const answers = await Answer.find({ questionId: { $in: questionsId } });
    const answerUserIds = answers.map((a) => a.answeredBy).filter(Boolean);
    const allUserIds = [...new Set([...questionUserIds, ...answerUserIds])];

    // Fetch all users in one query
    const users = await User.find({ userId: { $in: allUserIds } });
    const userMap = {};
    users.forEach((user) => {
      userMap[user.userId] = user;
    });

    // Group answers by questionId for faster lookup
    const answersMap = {};
    answers.forEach((answer) => {
      if (!answersMap[answer.questionId]) {
        answersMap[answer.questionId] = [];
      }

      // Get the display name for the answer author
      const answerUser = userMap[answer.answeredBy];
      const answerAuthorName = answerUser
        ? answerUser.displayName || answerUser.email
        : "Unknown User";

      answersMap[answer.questionId].push({
        id: answer.answerId || answer._id.toString(),
        text: answer.text,
        shortText:
          answer.text.length > 100
            ? answer.text.substring(0, 100) + "..."
            : answer.text,
        volunteer: {
          name: answerAuthorName,
          rating: 0, // Placeholder, adjust if you have ratings
        },
        questionText: "", // Will set this later
        createdAt: answer.createdAt,
        upvotes: answer.upvotesCount || 0,
        language: answer.language || "Unknown",
        isFlagged: answer.isFlagged || false,
        isHidden: answer.isHidden || false,
        isTopAnswer: false, // We can mark the topAnswer separately
      });
    });
    // Transform the questions to match the frontend expected structure
    const transformedQuestions = questions.map((question) => {
      const allAnswers = answersMap[question.questionId] || [];

      // Get the display name for the question author
      const questionUser = userMap[question.askedBy];
      const questionAuthorName = questionUser
        ? questionUser.displayName || questionUser.email
        : "Anonymous User";

      if (question.aiAnswer) {
        allAnswers.unshift({
          id: "ai-answer",
          text: question.aiAnswer,
          shortText:
            question.aiAnswer.length > 100
              ? question.aiAnswer.substring(0, 100) + "..."
              : question.aiAnswer,
          volunteer: {
            name: "AI Assistant",
            rating: 4.5,
          },
          questionText: question.text,
          createdAt: question.createdAt,
          upvotes: 0,
          language: "English",
          isFlagged: false,
          isHidden: false,
          isTopAnswer: true,
        });
      }
      allAnswers.forEach((ans) => (ans.questionText = question.text));
      return {
        id: question.questionId,
        text: question.text,
        shortText:
          question.text.length > 100
            ? question.text.substring(0, 100) + "..."
            : question.text,
        user: {
          name: questionAuthorName,
          avatar: null,
        },
        createdAt: question.createdAt,
        isPublic: question.isPublic,
        isFlagged: question.isFlagged,
        isAnswered: question.topAnswerId ? true : false, // Check if there's an AI answer
        category: question.category || "General",
        language: "English",
        likes: 0,
        shares: 0,
        views: 0,
        answers: allAnswers,
      };
    });
    return transformedQuestions;
  }

  static async getAllAnswersForAdmin() {
    try {
      const answers = await Answer.find({});
      console.log("Answers found:", answers);

      const transformedAnswers = await Promise.all(
        answers.map(async (answer) => {
          const question = await Question.findOne({
            questionId: answer.questionId,
          });

          let volunteerName = "Anonymous Volunteer";
          if (answer.answeredBy) {
            try {
              const user = await User.findOne({ userId: answer.answeredBy });
              if (user && user.displayName) {
                volunteerName = user.displayName;
              }
            } catch (innerErr) {
              console.error(
                `Failed to fetch user for answeredBy=${answer.answeredBy}:`,
                innerErr
              );
            }
          }

          return {
            id: answer.answerId,
            text: answer.text,
            shortText:
              answer.text.length > 100
                ? answer.text.substring(0, 100) + "..."
                : answer.text,
            volunteer: {
              name: volunteerName,
              rating: 4.0,
            },
            questionText: question ? question.text : "Question not available",
            createdAt: answer.createdAt,
            upvotes: answer.upvotesCount || 0,
            language: answer.language || "English",
            isFlagged: answer.isFlagged || false,
            isHidden: answer.isHidden || false,
            isTopAnswer: false,
          };
        })
      );

      return transformedAnswers;
    } catch (err) {
      console.error("Failed to retrieve answers:", err);
      throw new Error("Answers retrieval failed");
    }
  }
  static async updateQuestionByAdmin(questionId, text, category) {
    console.log("Updating question:", questionId, text, category);
    if (!questionId || !text || !category) {
      throw new Error("Missing required fields");
    }
    const updatedQuestion = await Question.findOneAndUpdate(
      { questionId: questionId },
      { text: text, category: category },
      { new: true }
    );
    if (!updatedQuestion) {
      throw new Error("Failed to update question");
    } else {
      console.log("Updated question:", updatedQuestion);
      //send notification to the  all volunteers who answered the question
      const answers = await Answer.find({ questionId: questionId });
      const results = [];

      for (const answer of answers) {
        const volunteerId = answer.answeredBy;
        const notification = {
          userId: volunteerId,
          type: "question_updated",
          title: "Question Updated 🔄",
          message: `The question you answered has been updated by the admin: "${updatedQuestion.text}". Please review and update your answer if needed, tab here to review and update your answer`,
          data: {
            questionId: updatedQuestion.questionId,
            answerId: answer.answerId,
            questionText: updatedQuestion.text,
            answerText: answer.text,
          },
          saveToDatabase: true,
        };

        console.log(`📣 Sending to ${volunteerId}:`, notification);

        try {
          const result = await sendNotification(notification);
          results.push({ userId: volunteerId, ...result });
        } catch (err) {
          console.error(`❌ Failed to notify ${volunteerId}:`, err);
        }
      }

      console.log("✅ All notification results:", results);

      // Hide all answers temporarily
      await Answer.updateMany(
        { questionId: questionId },
        { hiddenTemporary: true }
      );
      // Removed extraneous 'else' and misplaced code to fix syntax error
      return updatedQuestion;
    }
  }

  static async FlagQuestion(questionId, isFlagged) {
    try {
      const updatedQuestion = await Question.findOneAndUpdate(
        { questionId: questionId },
        { isFlagged: isFlagged },
        { new: true }
      );
      if (!updatedQuestion) {
        throw new Error("Failed to flag question");
      }
      return updatedQuestion;
    } catch (error) {
      console.error("Error flagging question:", error);
      throw new Error("Flagging question failed");
    }
  }

  static async updateAnswerByAdmin(answerId, text) {
    console.log("Searching for answerId:", answerId, typeof answerId);
    console.log("Updating answer:", answerId, text);
    if (!answerId || !text) {
      throw new Error("Missing required fields");
    } //make isHidden false and upvotesCount 0
    // Find the answer by answerId and update it
    const updatedAnswer = await Answer.findOneAndUpdate(
      { answerId: answerId },
      { text: text, upvotesCount: 0 },
      { new: true }
    );
    if (!updatedAnswer) {
      throw new Error("Failed to update answer");
    } else {
      // Recalculate top answer for the question
      const question = await Question.findOne({
        questionId: updatedAnswer.questionId,
      });
      if (question && question.topAnswerId === answerId) {
        console.log(
          "🎻🎻🎻Recalculating top answer for question:",
          question.questionId
        );
        await FlagServices.recalculateTopAnswer(question.questionId);
      }
      console.log("Updated answer:", updatedAnswer);
      return updatedAnswer;
    }
  }

  static async HideAnswer(answerId, isHidden) {
    console.log("Hiding answer:", answerId);
    if (!answerId) {
      throw new Error("Missing required fields");
    }
    const updatedAnswer = await Answer.findOneAndUpdate(
      { answerId: answerId },
      { isHidden: isHidden },
      { new: true }
    );
    if (!updatedAnswer) {
      throw new Error("Failed to hide answer");
    } else {
      // Recalculate top answer for the question
      if (updatedAnswer.questionId) {
        await FlagServices.recalculateTopAnswer(updatedAnswer.questionId);
      }
      console.log("Updated answer:", updatedAnswer);
      return updatedAnswer;
    }
  }

  static async ResolveFlag(flagId) {
    let contentOwnerId = null;
    let flaggedContent = null;

    console.log("Resolving flag:", flagId);
    if (!flagId) {
      throw new Error("Missing required fields");
    }
    const updatedFlag = await Flag.findOneAndUpdate(
      { flagId: flagId },
      { status: "resolved" },
      { new: true }
    );
    if (!updatedFlag) {
      throw new Error("Failed to resolve flag");
    } else {
      console.log("Updated flag:", updatedFlag);
      //Delete the answer or question based on the flag
      if (updatedFlag.itemType === "answer") {
        console.log("Deleting answer for flag:", updatedFlag.itemId);
        const answer = await Answer.findOne({ answerId: updatedFlag.itemId });
        console.log("Answer found:", answer);
        if (answer) {
          contentOwnerId = answer.answeredBy;
          flaggedContent = answer.text?.substring(0, 200) || "";
          await Answer.deleteOne({ answerId: updatedFlag.itemId }); // Delete the answer
          console.log("Answer deleted:", answer.answerId);
          //recalculate top answer
          await FlagServices.recalculateTopAnswer(answer.questionId);
        }
      } else if (updatedFlag.itemType === "question") {
        console.log("Deleting question for flag:", updatedFlag.itemId);
        const question = await Question.findOne({
          questionId: updatedFlag.itemId,
        });
        if (question) {
          contentOwnerId = question.askedBy;
          flaggedContent = question.text?.substring(0, 200) || "";
          await Question.deleteOne({ questionId: updatedFlag.itemId }); // Delete the question and all its answers
          // Also delete all answers related to this question
          await Answer.deleteMany({ questionId: updatedFlag.itemId });
          console.log("Question deleted:", question.questionId);
        }
      }

      // Notify the reporter about the resolution
      const reporter = await User.findOne({ userId: updatedFlag.reportedBy });
      console.log(" ✅Reporter found:", reporter);
      if (reporter) {
        await sendNotification({
          userId: reporter.userId,
          message: `Your report for flag(${flagId}) has been resolved.`,
          title: "Flag Resolved ✅",
          type: "flag_resolved",
          data: {
            flagId: flagId,
            ...updatedFlag.toObject(),
            flaggedContent,
            reporterName: reporter.displayName || "Unknown Reporter",
          },
        });
        console.log("Notification sent to reporter:", reporter.userId);
        // Save notificationSentAt timestamp
        await Flag.updateOne(
          { flagId: flagId },
          { notificationSentAt: new Date() }
        );
        console.log(`notificationSentAt set for flag: ${flagId}`);
      }
      //send the notification for the owner of the question or answer
      if (contentOwnerId) {
        const owner = await User.findOne({ userId: contentOwnerId });

        if (owner) {
          await sendNotification({
            userId: owner.userId,
            message: `Your ${updatedFlag.itemType} has been removed due to a resolved flag & you can see the flag details when tab on this notification.`,
            title: "Content Removed 🚫",
            type: "flag_resolved",
            data: {
              flagId: flagId,
              ...updatedFlag.toObject(),
              flaggedContent,
              reporterName: reporter.displayName || "Unknown Reporter",
            },
          });
          console.log(`Notification sent to content owner: ${owner.userId}`);
        }
      }

      return updatedFlag;
    }
  }

  static async RejectFlag(flagId) {
    console.log("Rejecting flag:", flagId);
    let flaggedContent = null;
    let contentOwnerId = null; // Initialize contentOwnerId
    if (!flagId) {
      throw new Error("Missing required fields");
    }
    const updatedFlag = await Flag.findOneAndUpdate(
      { flagId: flagId },
      { status: "rejected" },
      { new: true }
    );
    //isFlagged is false in the answer or question
    if (updatedFlag.itemType === "answer") {
      const answer = await Answer.findOne({ answerId: updatedFlag.itemId });

      if (answer) {
        contentOwnerId = answer.answeredBy; // Get the owner of the answer
        flaggedContent = answer.text?.substring(0, 200) || "";
        answer.isFlagged = false; // Set isFlagged to false
        await answer.save(); // Save the updated answer
      }
    } else if (updatedFlag.itemType === "question") {
      const question = await Question.findOne({
        questionId: updatedFlag.itemId,
      });
      if (question) {
        contentOwnerId = question.askedBy; // Get the owner of the question
        flaggedContent = question.text?.substring(0, 200) || "";
        question.isFlagged = false; // Set isFlagged to false
        await question.save(); // Save the updated question
      }
    }

    console.log("Updated flag:", updatedFlag);
    if (!updatedFlag) {
      throw new Error("Failed to reject flag");
    } else {
      console.log("Updated flag:", updatedFlag);
      //recalculate the top Answer for the question if the flag of the answer rejected
      if (updatedFlag.itemType === "answer") {
        const answer = await Answer.findOne({ answerId: updatedFlag.itemId });
        if (answer) {
          const question = await Question.findOne({ questionId: answer.questionId });
          if (question) {
            // Recalculate the top answer for the question using recalculate function
        await FlagServices.recalculateTopAnswer(question.questionId);
            await question.save();
          }
        }
      }
      // Notify the reporter about the rejection
      const reporter = await User.findOne({ userId: updatedFlag.reportedBy });
      if (reporter) {
        await sendNotification({
          userId: reporter.userId,
          message: `Your report for flag (${flagId}) has been rejected.`,
          title: "Flag Rejected ❌",
          type: "flag_rejected",
          data: {
            flagId: flagId,
            ...updatedFlag.toObject(),
            flaggedContent,
            reporterName: reporter.displayName || "Unknown Reporter",
          },
        });
      }
      // Save notificationSentAt timestamp
      await Flag.updateOne(
        { flagId: flagId },
        { notificationSentAt: new Date() }
      );
      //Send notification to the owner of the content
      if (contentOwnerId) {
        console.log("🚫🚫🚫🚫Content owner ID:", contentOwnerId);
        const owner = await User.findOne({ userId: contentOwnerId });
        if (owner) {
          await sendNotification({
            userId: owner.userId,
            message: `Your ${updatedFlag.itemType} has been flagged but the flag has been rejected.`,
            title: "Content Removed 🚫",
            type: "flag_rejected",
            data: {
              flagId: flagId,
              ...updatedFlag.toObject(),
              flaggedContent,
              reporterName: reporter.displayName || "Unknown Reporter",
            },
          });
          // Save notificationSentAt timestamp
          await Flag.updateOne(
            { flagId: flagId },
            { notificationSentAt: new Date() }
          );
          console.log(`Notification sent to content owner: ${owner.userId}`);
        }
      }

      return updatedFlag;
    }
  }

  static async DismissFlag(flagId) {
    console.log("Dismissing flag:", flagId);
    if (!flagId) {
      throw new Error("Missing required fields");
    }
    const updatedFlag = await Flag.findOneAndUpdate(
      { flagId: flagId },
      { status: "dismissed", notificationSentAtDismissed: new Date() }, // Store the timestamp when notification is sent for dismissed flags
      { new: true }
    );
    if (!updatedFlag) {
      throw new Error("Failed to dismiss flag");
    } else {
      console.log("Updated flag:", updatedFlag);
      let flaggedContent = null;
      if (updatedFlag.itemType === "answer") {
        const answer = await Answer.findOne({ answerId: updatedFlag.itemId });
        if (answer) {
          flaggedContent = answer.text?.substring(0, 200) || "";
        }
      } else if (updatedFlag.itemType === "question") {
        const question = await Question.findOne({
          questionId: updatedFlag.itemId,
        });
        if (question) {
          flaggedContent = question.text?.substring(0, 200) || "";
        }
      }
      //get the name of reporter
      let reporterName = null;
      const reporter = await User.findOne({ userId: updatedFlag.reportedBy });
      if (reporter) {
        reporterName = reporter.displayName;
      }
      //notify the admin
      const admin = await User.findOne({ role: "admin" });
      if (admin) {
        await sendNotification({
          userId: admin.userId,
          message: `Flag ${flagId} has been dismissed.`,
          title: "Flag Dismissed 🔕",
          type: "flag_dismissed",
          data: {
            flagId: flagId,
            ...updatedFlag.toObject(),
            flaggedContent,
            reporterName: reporterName || "Unknown Reporter",
          },
        });
      }
      // notify the reporter
      /* if (reporter) {
        await sendNotification({
          userId: reporter.userId,
          message: `Your report for flag ${flagId} has been dismissed.`,
          title: "Flag Dismissed 🔕",
          type: "flag_dismissed",
          data: {
           flagId: flagId,
               ...updatedFlag.toObject(),
               flaggedContent,
             reporterName: reporterName || "Unknown Reporter",

          },
        });
      }*/
      return updatedFlag;
    }
  }

  static async DeleteFlagByAdmin(flagId) {//DeleteFlagByAdmin
    console.log("Deleting flag:", flagId);
    if (!flagId) {
      throw new Error("Missing required fields");
    }
    //first find the flag
    const deletedFlag = await Flag.findOneAndDelete({ flagId: flagId });
    if (!deletedFlag) {
    const error = new Error("Flag Already Deleted");
    error.statusCode = 404;
    throw error;

    }
    console.log("Deleted flag:", deletedFlag);
    return deletedFlag;
  }

  static async getFlags() {
    console.log("Fetching all flags with details...");
    try {
      const flags = await Flag.find({});

      const flagsWithDetails = await Promise.all(
        flags.map(async (flag) => {
          // Get reporter details
          const reporterUser = await User.findOne({
            userId: flag.reportedBy,
          }).lean();
          let reporter = null;
          if (reporterUser) {
            reporter = {
              displayName: reporterUser.displayName,
              email: reporterUser.email,
              id: reporterUser.userId,
              gender: reporterUser.gender,
              role: reporterUser.role,
              country: reporterUser.country,
            };
          }

          let itemDetails = null;
          if (flag.itemType === "answer") {
            const answer = await Answer.findOne({
              answerId: flag.itemId,
            }).lean();
            if (answer) {
              // Get answeredBy user details
              const answeredByUser = await User.findOne({
                userId: answer.answeredBy,
              }).lean();
              let answeredBy = null;
              if (answeredByUser) {
                answeredBy = {
                  displayName: answeredByUser.displayName,
                  email: answeredByUser.email,
                  id: answeredByUser.userId,
                  gender: answeredByUser.gender,
                  role: answeredByUser.role,
                  country: answeredByUser.country,
                };
              }
              itemDetails = {
                ...answer,
                answeredBy: answeredBy,
              };
            }
          } else if (flag.itemType === "question") {
            const question = await Question.findOne({
              questionId: flag.itemId,
            }).lean();
            if (question) {
              // Get askedBy user details
              const askedByUser = await User.findOne({
                userId: question.askedBy,
              }).lean();
              let askedBy = null;
              if (askedByUser) {
                askedBy = {
                  displayName: askedByUser.displayName,
                  email: askedByUser.email,
                  id: askedByUser.userId,
                  gender: askedByUser.gender,
                  role: askedByUser.role,
                  country: askedByUser.country,
                };
              }
              itemDetails = {
                ...question,
                askedBy: askedBy,
              };
            }
          }

          // If either reporter or itemDetails is null, delete the flag and skip returning it
          if (!reporter || !itemDetails) {
            await Flag.deleteOne({ flagId: flag.flagId });
            return null;
          }

          return {
            ...flag.toObject(),
            reporter,
            itemDetails,
          };
        })
      );

      // Filter out any nulls (deleted flags)
      return flagsWithDetails.filter((f) => f !== null);
    } catch (error) {
      console.error("Error fetching flags:", error);
      return [];
    }
  }
}
// Schedule a cron job to delete flags older than 7 days, excluding pending / dismissed flags
// This will run every hour
cron.schedule("0 * * * *", async () => {
  const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
  try {
    const result = await Flag.deleteMany({
      notificationSentAt: { $lte: cutoff },
      status: { $ne: "pending", $ne: "dismissed" }, // exclude pending / dismissed flags
    });
    if (result.deletedCount > 0) {
      console.log(
        `Deleted ${result.deletedCount} flags older than 48h (excluding pending / dismissed)`
      );
    }
  } catch (error) {
    console.error("Error deleting old flags:", error);
  }
});

//send the notification to the admin each hour about the dismissed flags
cron.schedule("0 * * * *", async () => {
  const tenMinutesAgo = new Date(Date.now() - 60 * 60 * 1000);
  try {
    const flagsToNotify = await Flag.find({
      status: "dismissed", //dismissed
      $or: [
        { notificationSentAtDismissed: { $exists: false } },
        { notificationSentAtDismissed: { $lte: tenMinutesAgo } },
      ],
    });
    if (flagsToNotify.length === 0) {
      console.log("No dismissed flags to notify.");
      return;
    }
    console.log(`Notifying about ${flagsToNotify.length} dismissed flags...`);
    for (const flag of flagsToNotify) {
      const reporter = await User.findOne({ userId: flag.reportedBy });
      //get the text of answer or question
      let flaggedContent = null;
      if (flag.itemType === "answer") {
        const answer = await Answer.findOne({ answerId: flag.itemId });
        if (answer) {
          flaggedContent = answer.text?.substring(0, 200) || "";
        }
      } else if (flag.itemType === "question") {
        const question = await Question.findOne({ questionId: flag.itemId });
        if (question) {
          flaggedContent = question.text?.substring(0, 200) || "";
        }
      }
      //notify the admin each hour about the dismissed flags
      const admin = await User.findOne({ role: "admin" });
      if (admin) {
        await sendNotification({
          userId: admin.userId,
          message: `Flag with ID (${flag.flagId}) has been dismissed.`,
          title: "Flag Dismissed 🔕",
          type: "flag_dismissed",
          data: {
            flagId: flag.flagId,
            ...flag.toObject(),
            flaggedContent,
            reporterName: reporter.displayName || "Unknown Reporter",
          },
        });
        flag.notificationSentAtDismissed = new Date();
        await flag.save();
      }
      /* if (reporter) {
        await sendNotification({
          userId: reporter.userId,
          message: `Your report for flag ${flag.flagId} is still dismissed.`,
          title: "Flag Dismissed 🔕",
          type: "flag_dismissed",
          data: {
           flagId: flag.flagId,
               ...flag.toObject(),
               flaggedContent,
             reporterName: reporter.displayName || "Unknown Reporter",
          },
        });

        
        flag.notificationSentAtDismissed = new Date();
        await flag.save();
      }*/
    }
  } catch (err) {
    console.error("Error sending dismissed flag notifications:", err);
  }
});

export default AdminServices;
