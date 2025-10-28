import UserServices from "../services/questionsservices.js";
import QuestionModel from "../models/Questions.js";
import AnswerModel from "../models/Answers.js";
import UserModel from "../models/User.js";
import admin from "firebase-admin";
import { sendNotificationToMultiple } from "../services/notificationService.js";

export async function submitquestion(req, res, next) {
  const userId = req.userId; // coming from token middleware

  try {
    console.log("--- req body ---", req.body);
    const { text, isPublic, category, tags, aiAnswer } = req.body;
    if (!text || !category) {
      return res.status(400).json({
        status: false,
        message: "Text and category are required",
      });
    }
    const Newquestion = {
      text,
      isPublic,
      category,
      tags,
      aiAnswer,
      askedBy: req.userId || "anonymous",
    };

    const { newQuestion, user } = await UserServices.SubmitQuestion(
      Newquestion,
      userId
    );

    const questionToReturn = newQuestion.toObject();
    questionToReturn.askedBy = {
      id: userId,
      displayName: user?.displayName || "Anonymous",
    };

    // Send notification to volunteers about new question
    try {
      // Get all certified volunteers who haven't answered recently
      const oneWeekAgo = new Date();
      oneWeekAgo.setDate(oneWeekAgo.getDate() - 7);

      const volunteers = await UserModel.find({
        role: { $in: ["certified_volunteer", "volunteer_pending"] },
        onesignalId: { $exists: true, $ne: null },
      }).lean();

      // Check which volunteers haven't answered recently
      const inactiveVolunteers = [];
      for (const volunteer of volunteers) {
        const lastAnswer = await AnswerModel.findOne({
          answeredBy: volunteer.userId,
        })
          .sort({ createdAt: -1 })
          .lean();

        if (!lastAnswer || lastAnswer.createdAt < oneWeekAgo) {
          inactiveVolunteers.push(volunteer);
        }
      }

      // Send notification to inactive volunteers
      if (inactiveVolunteers.length > 0) {
        const volunteerIds = inactiveVolunteers.map((v) => v.userId);

        const notificationResults = await sendNotificationToMultiple(
          volunteerIds,
          {
            type: "new_question_for_volunteers",
            title: "New question needs your expertise! 🤔",
            message: `A new question about "${category}" was asked. Your knowledge is needed!`,
            data: {
              questionId: newQuestion.questionId,
              category: category,
            },
          }
        );

        console.log(
          "Volunteer notifications sent to",
          inactiveVolunteers.length,
          "volunteers:",
          notificationResults
        );
      }
    } catch (notificationError) {
      console.log("Failed to send volunteer notification:", notificationError);
      // Don't fail the question submission if notification fails
    }

    res.status(201).json({
      status: true,
      success: "Question submitted successfully",
      question: questionToReturn,
    });
  } catch (err) {
    console.log("---> err -->", err);
    next(err);
  }
};
export async function getpublicquestions(req, res, next) {
    const {page,limit} = req.query;
    const { questions, totalCount } = await UserServices.GetPublicQuestions(page, limit);
  res.status(200).json({
    status: true,
    success: "Getting public Questions  successfully",
    question: questions,
    totalCount: totalCount,
    currentPage: page,
    totalPages: Math.ceil(totalCount / limit),
  });
};
export async function getquestionandanswers(req, res, next) {
  console.log("🍯🍯🍯 getquestionandanswers function called with id:", req.params.id);
  const { id } = req.params;

  try {
    // Get the question
    const question = await QuestionModel.findOne({ questionId: id }).lean();
    if (!question) return res.status(404).json({ error: "Question not found" });

    // Get all answers to the question
    const rawAnswers = await AnswerModel.find({ questionId: id }).lean();

    // Collect unique userIds from answers and topAnswerId (in case it's not in answers list)
    const answerUserIds = rawAnswers.map((ans) => ans.answeredBy);
    const topAnswerUserId = question.topAnswerId
      ? rawAnswers.find((a) => a.answerId === question.topAnswerId)?.answeredBy
      : null;

    const userIds = [
      ...new Set([...answerUserIds, topAnswerUserId].filter(Boolean)),
    ];

    // Fetch user info
    const users = await UserModel.find(
      { userId: { $in: userIds } },
      {
        userId: 1,
        displayName: 1,
        country: 1,
        gender: 1,
        email: 1,
        language: 1,
        role: 1,
        savedQuestions: 1,
        savedLessons: 1,
        createdAt: 1,
      }
    ).lean();

    // Map userId => user info
    const userMap = {};
    users.forEach((user) => {
      userMap[user.userId] = {
        id: user.userId,
        displayName: user.displayName,
        country: user.country,
        gender: user.gender,
        email: user.email,
        language: user.language,
        role: user.role,
        savedQuestions: user.savedQuestions,
        savedLessons: user.savedLessons,
        createdAt: user.createdAt,
      };
    });

    // Build the answers array with full answeredBy info
    const answers = rawAnswers.map((ans) => {
      console.log(`🔍 🍯🍯Answer ${ans.answerId}: isFlagged=${ans.isFlagged}, isHidden=${ans.isHidden}`);
      return {
        answerId: ans.answerId,
        questionId: ans.questionId,
        text: ans.text,
        createdAt: ans.createdAt,
        language: ans.language,
        upvotesCount: ans.upvotesCount,
        answeredBy: userMap[ans.answeredBy] || null,
        isFlagged: ans.isFlagged || false,
        isHidden: ans.isHidden || false,
      };
    });

    // Build the topAnswer if available
    let topAnswer = null;
    if (question.topAnswerId) {
      const top = answers.find((ans) => ans.answerId === question.topAnswerId);
      if (top) topAnswer = top;
    }

    // Send final response
    res.json({
      questionId: question.questionId,
      text: question.text,
      answers,
      topAnswer,
    });
  } catch (err) {
    console.error("Error in getquestionandanswers:", err);
    res.status(500).json({ error: "Internal server error" });
  }
};

export async function getquestionsofaspecificuser(req, res, next) {
  try {
    const userId = req.userId;
    if (!userId) {
      return res
        .status(401)
        .json({ status: false, error: "Unauthorized. userId not found." });
    }
    console.log("userid is:", userId);

    const QuestionsofUser = await UserServices.GetQuestionOfUser(userId);
    res.status(200).json({
      status: true,
      success: "Getting user questions successfully",
      question: QuestionsofUser,
    });
  } catch (err) {
    console.error("Error fetching user questions:", err);
    next(err);
  }
};

export async function savequestion(req, res, next) {
  const userId = req.userId;
  const { questionId } = req.body;
  if (!questionId) {
    return res
      .status(400)
      .json({ success: false, message: "questionId is required" });
  }
  try {
    const result = await UserServices.SaveQuestion(userId, questionId);
    if (!result) {
      return res
        .status(404)
        .json({ success: false, message: "User not found" });
    }

    const message =
      result === "saved"
        ? "Question added to saved list"
        : "Question removed from saved list";

    res.status(200).json({ success: true, message });
  } catch (err) {
    console.error("Error saving question:", err);
    res.status(500).json({ success: false, message: "Server error" });
  }
};

export async function deletequestion(req, res, next) {
  const userId = req.userId;
  const { id } = req.params;
  console.log('🍓🫕🍫 Deleting question with ID:', id);
  console.log('🍓🫕🍫 User ID:', userId);
  if (!id){
    return res.status(400).json({ success: false, message: 'questionId is required to delete a question'})
  }
  try {
    const question = await UserServices.DeleteQuestion(userId, id);
    if (!question) {
      return res
        .status(404)
        .json({ success: false, message: "Question not found" });
    }
    return res
      .status(200)
      .json({ success: true, message: "Question deleted successfully" });
  } catch (err) {
    console.error("Error deleting question:", err);
  }
};

export async function updatequestion(req, res, next) {
  const userId = req.userId;
  const questionId = req.params.id;
  const { text, category, isPublic, aiAnswer } = req.body;
  if (!questionId || !text || !category || isPublic === undefined) {
    return res
      .status(400)
      .json({ success: false, message: "All fields are required" });
  }
  try {
    const question = await UserServices.UpdateQuestion(
      userId,
      questionId,
      text,
      category,
      isPublic,
      aiAnswer
    );
    if (!question) {
      return res
        .status(404)
        .json({ success: false, message: "Question not found" });
    }
    return res
      .status(200)
      .json({ success: true, message: "Question updated successfully" });
  } catch (err) {
    console.error("Error updating question:", err);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};

// PATCH /questions/:id/ai-answer
export async function updateAIAnswer(req, res, next) {
  const questionId = req.params.id;
  const { aiAnswer } = req.body;
  if (!aiAnswer) {
    return res
      .status(400)
      .json({ success: false, message: "aiAnswer is required" });
  }
  try {
    const question = await QuestionModel.findOne({ questionId });
    if (!question) {
      return res
        .status(404)
        .json({ success: false, message: "Question not found" });
    }
    question.aiAnswer = aiAnswer;
    await question.save();
    return res.status(200).json({ success: true, message: 'AI answer updated successfully', question });
  } catch (err) {
    console.error("Error updating AI answer:", err);
    return res.status(500).json({ success: false, message: "Server error" });
  }
};
