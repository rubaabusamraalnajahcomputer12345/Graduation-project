import FlagModel from "../models/Flags.js";
import AnswerModel from "../models/Answers.js";
import QuestionModel from "../models/Questions.js";
import { v4 as uuidv4 } from "uuid";

class FlagServices {
  static async SubmitFlag(data) {
    try {
      const newFlag = new FlagModel({
        flagId: data.flagId,
        itemType: data.itemType,
        itemId: data.itemId,
        reportedBy: data.reportedBy,
        reason: data.description,
        status: "pending",
        createdAt: new Date(),
      });

      await newFlag.save();

      // Safely update the flagged item
      try {
        if (data.itemType.toLowerCase() === "question") {
          const question = await QuestionModel.findOne({ questionId: data.itemId });
          if (question) {
            question.isFlagged = true;
            await question.save();
          } else {
            console.warn(`Question with ID ${data.itemId} not found for flagging`);
          }
        }

        if (data.itemType.toLowerCase() === "answer") {
          const answer = await AnswerModel.findOne({ answerId: data.itemId });
          if (answer) {
            answer.isFlagged = true;
            await answer.save();
            
            if (answer.questionId) {
              await this.recalculateTopAnswer(answer.questionId);
            }
          } else {
            console.warn(`Answer with ID ${data.itemId} not found for flagging`);
          }
        }
      } catch (updateError) {
        console.warn("Error updating flagged item:", updateError);
        // Don't throw the error - the flag was already saved successfully
      }

      return { newFlag };
    } catch (err) {
      throw err;
    }
  }

  static async recalculateTopAnswer(questionId) {
    try {
      console.log("🔍 Recalculating top answer for question:", questionId);
      const answers = await AnswerModel.find({
        questionId: questionId,
        isFlagged: { $ne: true },
        isHidden: { $ne: true }, // <-- ignore hidden answers
        hiddenTemporary: { $ne: true } // <-- ignore temporarily hidden answers
      }).sort({ upvotesCount: -1 });
      
      const question = await QuestionModel.findOne({ questionId: questionId });
      if (!question) {
        console.warn(`🏆🏆Question with ID ${questionId} not found for top answer recalculation`);
        return;
      }

      if (answers.length > 0) {
        question.topAnswerId = answers[0].answerId;
        console.log(`🏆🏆🏆Top answer for question ${questionId} is now ${question.topAnswerId}`);
      } else {
        question.topAnswerId = '';// Set to empty string if no valid answers
         console.log(`🏆🏆🏆No valid answers found for question ${questionId}, setting topAnswerId to null`);
      }

      await question.save();
    } catch (error) {
      console.warn("Error recalculating top answer:", error);
    }
  }
}

export default FlagServices;

