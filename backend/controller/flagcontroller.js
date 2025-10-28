import FlagServices from "../services/flagsservices.js";
import { v4 as uuidv4 } from "uuid";

export async function reportquestion(req, res, next) {
  try {
    const { questionId, reportType, description, itemType } = req.body;
    console.log("request body is:", req.body);
    const reportedBy = req.userId; //from token
    if (!questionId || !reportType || !description) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    const Newflag = {
      flagId: uuidv4(),
      itemType,
      itemId: questionId,
      reportedBy,
      description,
      status: "pending",
      createdAt: new Date(),
    };

    const { newFlag } = await FlagServices.SubmitFlag(Newflag);

    const flagToReturn = newFlag.toObject();
    console.log("flagToReturn is:", flagToReturn);
    res.status(201).json({
      status: true,
      success: "flag submitted successfully",
      flag: flagToReturn,
    });
  } catch (err) {
    console.log("---> err -->", err);
    next(err);
  }
}
