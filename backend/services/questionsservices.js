import AnswerModel from "../models/Answers.js";
import QuestionModel from "../models/Questions.js";
import UserModel from "../models/User.js";
import { sendNotification } from './notificationService.js';
import { v4 as uuidv4 } from "uuid";
class QuestionServices {
  static async SubmitQuestion(data, id) {
    const user = await UserModel.findOne({ userId: id });
    console.log("User ID passed to SubmitQuestion:", user);

    try {
      const newQuestion = new QuestionModel({
        questionId: uuidv4(),
        text: data.text,
        isPublic: data.isPublic ?? true,
        askedBy: id,
        aiAnswer: data.aiAnswer || "",
        topAnswerId: data.topAnswerId || "",
        tags: data.tags || [],
        category: data.category || "",
        createdAt: new Date(),
      });

      await newQuestion.save();
      console.log("Saved question:", newQuestion);

      return { newQuestion, user };
    } catch (err) {
      throw err;
    }
  }

  static async GetPublicQuestions(page = 1, limit = 3) {
    try {
      const skip = (page - 1) * limit;
      console.log("skip:", skip);
      const [publicQuestions, totalCount] = await Promise.all([
        QuestionModel.find({ isPublic: true })
          .sort({ createdAt: -1 })
          .skip(skip)
          .limit(limit),
        QuestionModel.countDocuments({ isPublic: true }),
      ]);

      const questionUserIds = [
        ...new Set(publicQuestions.map((q) => q.askedBy)),
      ];
      const topAnswerIds = publicQuestions
        .map((q) => q.topAnswerId)
        .filter(Boolean);

      const topAnswers = await AnswerModel.find(
        { answerId: { $in: topAnswerIds }, isFlagged: { $ne: true }, isHidden: { $ne: true } },
        {
          answerId: 1,
          questionId: 1,
          text: 1,
          answeredBy: 1,
          createdAt: 1,
          language: 1,
          upvotesCount: 1,
          isFlagged: 1,
          isHidden: 1,
          hiddenTemporary: 1,
        }
      );
      console.log("🔍 Top Answers with isFlagged:", topAnswers);
      const answerUserIds = [...new Set(topAnswers.map((a) => a.answeredBy))];
      const allUserIds = [...new Set([...questionUserIds, ...answerUserIds])];

      const users = await UserModel.find(
        { userId: { $in: allUserIds } },
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
          isFlagged: 1,
        }
      );

      const userMap = {};
      users.forEach((user) => {
        userMap[user.userId] = user;
      });

      const answerMap = {};
      topAnswers.forEach((ans) => {
        const ansUser = userMap[ans.answeredBy];
        answerMap[ans.answerId] = {
          answerId: ans.answerId,
          questionId: ans.questionId,
          text: ans.text,
          createdAt: ans.createdAt,
          language: ans.language,
          upvotesCount: ans.upvotesCount,
          isFlagged: ans.isFlagged || false,
          isHidden: ans.isHidden || false,
          hiddenTemporary: ans.hiddenTemporary || false,
          answeredBy: ansUser
            ? {
                id: ansUser.userId,
                displayName: ansUser.displayName,
                country: ansUser.country,
                gender: ansUser.gender,
                email: ansUser.email,
                language: ansUser.language,
                role: ansUser.role,
                savedQuestions: ansUser.savedQuestions,
                savedLessons: ansUser.savedLessons,
                createdAt: ansUser.createdAt,
                isFlagged: ansUser.isFlagged,
              }
            : null,
        };
      });

      const questionsWithDetails = publicQuestions.map((q) => {
        const qObj = q.toObject();

        const askedUser = userMap[q.askedBy];
        qObj.askedBy = askedUser
          ? {
              id: askedUser.userId,
              displayName: askedUser.displayName,
              country: askedUser.country,
              gender: askedUser.gender,
              email: askedUser.email,
              language: askedUser.language,
              role: askedUser.role,
              savedQuestions: askedUser.savedQuestions,
              savedLessons: askedUser.savedLessons,
              createdAt: askedUser.createdAt,
              isFlagged: askedUser.isFlagged,
            }
          : null;

        qObj.topAnswer = q.topAnswerId
          ? answerMap[q.topAnswerId] || null
          : null;
        delete qObj.topAnswerId;

        return qObj;
      });

      return {
        questions: questionsWithDetails,
        totalCount,
      };
    } catch (err) {
      console.error("Error in GetPublicQuestions:", err);
      throw err;
    }
  }

  static async GetQuestionOfUser(userid) {
    console.log("userid is:", userid);

    try {
      // Get all questions by the user
      const questions = await QuestionModel.find({ askedBy: userid })
        .sort({ createdAt: -1 })
        .lean();

      if (!questions.length) return [];

      // Get askedBy user details once
      const askedByUser = await UserModel.findOne(
        { userId: userid },
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

      const enrichedQuestions = [];

      for (const q of questions) {
        let topAnswer = null;

        if (q.topAnswerId) {
          const rawTopAnswer = await AnswerModel.findOne({
            answerId: q.topAnswerId,
            isFlagged: { $ne: true },
            isHidden: { $ne: true },
            hiddenTemporary: { $ne: true },
          }).lean();

          if (rawTopAnswer) {
            const topAnswerUser = await UserModel.findOne(
              { userId: rawTopAnswer.answeredBy },
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
                isFlagged: 1,
                
              }
            ).lean();

            topAnswer = {
              answerId: rawTopAnswer.answerId,
              questionId: rawTopAnswer.questionId,
              text: rawTopAnswer.text,
              createdAt: rawTopAnswer.createdAt,
              language: rawTopAnswer.language,
              upvotesCount: rawTopAnswer.upvotesCount,
              isFlagged: rawTopAnswer.isFlagged || false,
              isHidden: rawTopAnswer.isHidden || false,
              hiddenTemporary: rawTopAnswer.hiddenTemporary || false,
              answeredBy: topAnswerUser
                ? {
                    id: topAnswerUser.userId,
                    displayName: topAnswerUser.displayName,
                    country: topAnswerUser.country,
                    gender: topAnswerUser.gender,
                    email: topAnswerUser.email,
                    language: topAnswerUser.language,
                    role: topAnswerUser.role,
                    savedQuestions: topAnswerUser.savedQuestions,
                    savedLessons: topAnswerUser.savedLessons,
                    createdAt: topAnswerUser.createdAt,
                    isFlagged: topAnswerUser.isFlagged,
                  }
                : null,
            };
          }
        }

        const { topAnswerId, ...questionWithoutTopAnswerId } = q;

        enrichedQuestions.push({
          ...questionWithoutTopAnswerId,
          askedBy: askedByUser
            ? {
                id: askedByUser.userId,
                displayName: askedByUser.displayName,
                country: askedByUser.country,
                gender: askedByUser.gender,
                email: askedByUser.email,
                language: askedByUser.language,
                role: askedByUser.role,
                savedQuestions: askedByUser.savedQuestions,
                savedLessons: askedByUser.savedLessons,
                createdAt: askedByUser.createdAt,
                isFlagged: askedByUser.isFlagged,
              }
            : null,
          topAnswer,
        });
      }
      console.log("uuuu", enrichedQuestions);
      return enrichedQuestions;
    } catch (err) {
      console.error("Error in GetQuestionOfUser:", err);
      throw err;
    }
  }

  static async SaveQuestion(userId, questionId) {
    const user = await UserModel.findOne({ userId });

    if (!user) return null;

    const index = user.savedQuestions.indexOf(questionId);
    let status;
    if (index === -1) {
      // Not saved yet — add it
      user.savedQuestions.push(questionId);
      status = "saved";
    } else {
      // Already saved — remove it
      user.savedQuestions.splice(index, 1);
      status = "removed";
    }

    await user.save();
    return status;
  }

  static async DeleteQuestion(userId, questionId) {
    const question = await QuestionModel.findOne({ questionId }); //find the question by the questionId
    console.log("Deleting question@@@@:", question);
    if (!question) {
      return null;
    }
    // Check if the user is the one who asked the question or an admin
    const user = await UserModel.findOne({ userId });
     if (!user) {
    return null;
  }
    if (question.askedBy !== userId && user.role !== "admin") {
      console.log("User is not authorized to delete this question");
      return null;
    }
    await QuestionModel.deleteOne({ questionId }); //delete the question from the question table
    await AnswerModel.deleteMany({ questionId }); //delete the answers of this question from the answer table

    await UserModel.updateMany(
      { savedQuestions: questionId }, //find the users who saved this question
      { $pull: { savedQuestions: questionId } } //remove the question from the savedQuestions array of the users
    );
    return true;
  }

  static async UpdateQuestion(
    userId,
    questionId,
    text,
    category,
    isPublic,
    aiAnswer
  ) {
    const question = await QuestionModel.findOne({ questionId });
    if (!question) {
      return null;
    }
    if (question.askedBy !== userId) {
      return null;
    }
    question.text = text;
    question.category = category;
    question.isPublic = isPublic;
    question.aiAnswer = aiAnswer;
    await question.save();
    //send notification to the volunteers who answered the question and hide the answers of the questions
    const answers = await AnswerModel.find({ questionId: questionId });
      const results = [];
      for (const answer of answers) {
        const volunteerId = answer.answeredBy;
        const notification = {
          userId: volunteerId,
          type: "question_updated",
          title: "Question Updated 🔄",
          message: `The question you answered has been updated: "${question.text}". Please review and update your answer if needed, tab here to review and update your answer`,
          data: {
            questionId: question.questionId,
            answerId: answer.answerId,
            questionText: question.text,
            answerText: answer.text,
          },
          saveToDatabase: true
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
      await AnswerModel.updateMany({ questionId: questionId }, { hiddenTemporary: true });

   /* if (answers.length > 0) {
      const volunteerIds = [...new Set(answers.map(a => a.answeredBy))];
      const notification = {
        type: "question_updated",
        title: "Question Updated",
        message: `Question has been updated: "${question.text} ,you can check it and update your answer if needed to appear it for the users"`,
        data: { questionId: question.questionId },
        saveToDatabase: true
      };
      try {
        const results = await sendNotificationToMultiple(volunteerIds, notification);
        console.log("Notification results:", results);
        //hide all the answers of the updated question 
        await AnswerModel.updateMany({ questionId: questionId }, { hiddenTemporary: true });
        console.log("👍👍👍👍👍👍👍Answers hidden successfully");
      } catch (err) {
        console.error("Failed to send notifications:", err);
      }
    }*/
    return question;
  }
}

export default QuestionServices;
