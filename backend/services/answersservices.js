import AnswerModel from "../models/Answers.js";
import VoteModel from "../models/Votes.js";
import QuestionModel from "../models/Questions.js";
import UserModel from "../models/User.js";
import FlagServices from './flagsservices.js';

import { sendNotification } from "../services/notificationService.js";
import { v4 as uuidv4 } from "uuid";

class AnswerServices {
  static async UpVoteOnAnswer(answerId, userId) {
    try {
      // 1. Find the answer being upvoted
      const answer = await AnswerModel.findOne({ answerId }).lean();
      if (!answer) return null;

      const questionId = answer.questionId;

      // 2. Find if user already voted on this question
      const existingVote = await VoteModel.findOne({
        votedBy: userId,
        questionId,
      });

      if (existingVote) {
        if (existingVote.answerId === answerId) {
          // Unvote
          await VoteModel.deleteOne({ voteId: existingVote.voteId });
          await AnswerModel.updateOne(
            { answerId },
            { $inc: { upvotesCount: -1 } }
          );
        } else {
          // Change vote to different answer
          await VoteModel.updateOne(
            { voteId: existingVote.voteId },
            { $set: { answerId, updatedAt: new Date() } }
          );
          await AnswerModel.updateOne(
            { answerId: existingVote.answerId },
            { $inc: { upvotesCount: -1 } }
          );
          await AnswerModel.updateOne(
            { answerId },
            { $inc: { upvotesCount: 1 } }
          );
        }
      } else {
        // First time vote
        await VoteModel.create({
          voteId: uuidv4(),
          answerId,
          questionId,
          votedBy: userId,
          createdAt: new Date(),
        });
        await AnswerModel.updateOne(
          { answerId },
          { $inc: { upvotesCount: 1 } }
        );
      }

      // 3. Always recalculate top answer
      const top = await AnswerModel.find({ questionId })
        .sort({ upvotesCount: -1, createdAt: 1 })
        .limit(1)
        .lean();

      // Fetch the question ONCE
      const question = await QuestionModel.findOne({ questionId });
      const previousTopAnswerId = question.topAnswerId;
      const newTopAnswerId = top.length > 0 ? top[0].answerId : null;

      // 4. If the top answer has changed, update and notify
      if (newTopAnswerId && previousTopAnswerId !== newTopAnswerId) {
        await QuestionModel.updateOne(
          { questionId },
          { $set: { topAnswerId: newTopAnswerId } }
        );

        // Notify question owner
        const questionOwner = await UserModel.findOne({
          userId: question.askedBy,
        });
        if (questionOwner) {
          await sendNotification({
            userId: questionOwner.userId,
            type: "top_answer_changed",
            title: "Your question has a new top answer!",
            message: `A new answer is now the top answer for your question: "${question.text.substring(
              0,
              50
            )}..."`,
            data: {
              questionId: questionId,
              answerId: newTopAnswerId,
            },
          });
        }
      }

      // 5. Notify answer author if their answer was upvoted (and not by themselves)
      if (answer.answeredBy && answer.answeredBy !== userId) {
        const answerAuthor = await UserModel.findOne({
          userId: answer.answeredBy,
        }).lean();
        if (answerAuthor) {
          await sendNotification({
            userId: answerAuthor.userId,
            type: "answer_upvoted",
            title: "Your answer received an upvote! ",
            message: `Someone upvoted your answer to: "${question.text.substring(
              0,
              50
            )}..."`,
            data: {
              questionId: answer.questionId,
              answerId: answerId,
              // You may want to re-fetch upvotesCount if needed
            },
          });
        }
      }

      // Return updated state of the answer that was clicked
      return await AnswerModel.findOne({ answerId }).lean();
    } catch (err) {
      throw err;
    }
  }

  static async SubmitAnswer(data) {
    console.log("Answer to submit:", data);

    try {
      const newAnswer = new AnswerModel({
        answerId: uuidv4(),
        questionId: data.questionId,
        text: data.text,
        answeredBy: data.answeredBy,
        createdAt: new Date(),
        language: data.language,
        upvotesCount: data.upvotesCount,
      });

      await newAnswer.save();
      //edited by manal
      // Set as top answer if this is the first answer for the question
      const answerCount = await AnswerModel.countDocuments({
        questionId: data.questionId,
      });
      if (answerCount === 1) {
        await QuestionModel.updateOne(
          { questionId: data.questionId },
          { $set: { topAnswerId: newAnswer.answerId } }
        );
        // Send notification to answer author when their answer is upvoted
        try {
          if (updatedAnswer.answeredBy && updatedAnswer.answeredBy !== userId) {
            const answerAuthor = await UserModel.findOne({
              userId: updatedAnswer.answeredBy,
            }).lean();

            if (answerAuthor) {
              // Send notification using the service
              const upvoteResult = await sendNotification({
                userId: answerAuthor.userId,
                type: "answer_upvoted",
                title: "Your answer received an upvote! 👍",
                message: `Someone upvoted your answer to: "${question.text.substring(
                  0,
                  50
                )}..."`,
                data: {
                  questionId: updatedAnswer.questionId,
                  answerId: answerId,
                  upvotesCount: updatedAnswer.upvotesCount,
                },
              });

              console.log("Upvote notification result:", upvoteResult);
            }
          }
        } catch (notificationError) {
          console.log("Failed to send upvote notification:", notificationError);
          // Don't fail the upvote if notification fails
        }
      }
      return { newAnswer };
    } catch (err) {
      throw err;
    }
  }

  static async GetAnswersOfVolunteer(userId) {
    try {
      if (!userId) {
        throw new Error("Missing userId");
      }

      // Get all answers by this user
      const answers = await AnswerModel.find({ answeredBy: userId }).lean();
      if (!answers.length) return [];

      // Get full user info
      const user = await UserModel.findOne({ userId }).lean();
      if (!user) throw new Error("User not found");

      const fullUser = {
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

      // Extract unique questionIds
      const questionIds = answers.map((a) => a.questionId);
      const questions = await QuestionModel.find({
        questionId: { $in: questionIds },
      }).lean();

      // Create a lookup map for questions
      const questionMap = {};
      for (const q of questions) {
        questionMap[q.questionId] = q;
      }

      // Fetch all askedBy userIds from questions
      const askedByUserIds = questions.map((q) => q.askedBy).filter(Boolean);
      const askedByUsers = await UserModel.find({
        userId: { $in: askedByUserIds },
      }).lean();
      const askedByUserMap = {};
      for (const u of askedByUsers) {
        askedByUserMap[u.userId] = u;
      }

      // Fetch top answers for each question
      const topAnswerIds = questions.map((q) => q.topAnswerId).filter(Boolean);
      const topAnswers = await AnswerModel.find({
        answerId: { $in: topAnswerIds },
      }).lean();
      const topAnswerMap = {};
      const topAnswerUserIds = topAnswers
        .map((a) => a.answeredBy)
        .filter(Boolean);
      const topAnswerUsers = await UserModel.find({
        userId: { $in: topAnswerUserIds },
      }).lean();
      const userMap = {};
      for (const u of topAnswerUsers) {
        userMap[u.userId] = u;
      }
      for (const a of topAnswers) {
        topAnswerMap[a.answerId] = {
          ...a,
          answeredBy: userMap[a.answeredBy] || null,
        };
      }

      // Return enriched answers with full question info + top answer (with full user) + askedBy full info
      const enrichedAnswers = answers.map(({ questionId, ...answer }) => {
        const question = questionMap[questionId] || null;
        let askedByFull = null;
        if (question && question.askedBy) {
          askedByFull = askedByUserMap[question.askedBy] || null;
        }
        return {
          ...answer,
          question,
          topAnswer: question?.topAnswerId
            ? topAnswerMap[question.topAnswerId] || null
            : null,
          askedBy: askedByFull,
        };
      });

      return enrichedAnswers;
    } catch (err) {
      console.error("Error in GetAnswersOfVolunteer:", err);
      throw new Error("Failed to get answers");
    }
  }

  static async GetTheUpvotedAnswerOfVol(questionId, userId) {
    try {
      const vote = await VoteModel.findOne({
        votedBy: userId,
        questionId,
      }).lean();
      if (!vote) return null;

      return vote.answerId;
    } catch (err) {
      console.error("Error in GetTheUpvotedAnswerOfVol:", err);
      throw new Error("Failed to get upvoted answer");
    }
  }

  static async DeleteAnswer(answerId) {
    try {
      // Find the answer to get its questionId
      const answer = await AnswerModel.findOne({ answerId }).lean();
      if (!answer) throw new Error("Answer not found");
      const questionId = answer.questionId;

      // Find the question
      const question = await QuestionModel.findOne({ questionId }).lean();
      if (!question) throw new Error("Question not found");

      // Delete the answer
      const deleted = await AnswerModel.deleteOne({ answerId });

      // If the deleted answer was the top answer, update the question's topAnswerId
      if (question.topAnswerId === answerId) {
        // Find the next top answer (highest upvotes, earliest createdAt)
        const nextTop = await AnswerModel.find({ questionId })
          .sort({ upvotesCount: -1, createdAt: 1 })
          .limit(1)
          .lean();
        if (nextTop.length > 0) {
          await QuestionModel.updateOne(
            { questionId },
            { $set: { topAnswerId: nextTop[0].answerId } }
          );
        } else {
          // No more answers, unset topAnswerId
          await QuestionModel.updateOne(
            { questionId },
            { $set: { topAnswerId: "" } }
          );
        }
      }
      return deleted;
    } catch (err) {
      throw err;
    }
  }

  static async ReviewAndUpdateAnswer(answerId, answerText) {
    try { //i want to update the answer text and make the answer hiddentemporary false
      console.log("🔥🔥🔥ReviewAndUpdateAnswer");
      const answer = await AnswerModel.findOne({ answerId });
      if (!answer) throw new Error("Answer not found");
      answer.text = answerText;
      answer.hiddenTemporary = false;
      answer.upvotesCount =0;
      await answer.save();
          //recalculate the top answer
          const question = await QuestionModel.findOne({ questionId: answer.questionId });
            console.log("🎻🎻🎻Recalculating top answer for question:", question.questionId);
            await FlagServices.recalculateTopAnswer(question.questionId);
          
      return answer;
    } catch (err) {
      throw err;
    }
  }



}

export default AnswerServices;
