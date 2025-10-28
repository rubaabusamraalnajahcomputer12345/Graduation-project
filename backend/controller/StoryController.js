import StoryServices from "../services/storyservices.js";
import StoryModel from "../models/Stories.js";

export async function getallstories(req, res, next) {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;

    const result = await StoryServices.GetAllStories(page, limit);

    if (!result.status) {
      return res.status(500).json({ status: false, message: result.message });
    }

    res.status(200).json(result);
  } catch (err) {
    console.log("---> err in getallstories -->", err);
    next(err);
  }
}

export async function savestory(req, res, next) {
  console.log("---> req.body in savestory -->", req.body);
  const storyId = req.body.id;
  const userId = req.userId; //from token
  console.log("---> userId in savestory -->", userId);
  console.log("---> storyId in savestory -->", storyId);
  //userId of the user who see the story and save it in the array of savesstory in user table(userId from the token)
  try {
    const result = await StoryServices.SaveStory(userId, storyId);
    res.status(200).json(result);
  } catch (err) {
    console.log("---> err in savestory -->", err);
    next(err);
  }
}

export async function likestory(req, res, next) {
  const storyId = req.body.id;
  const userId = req.userId;

  try {
    const result = await StoryServices.LikeStory(userId, storyId);
    res.status(200).json(result);
  } catch (err) {
    console.log("---> err in likestory -->", err);
    next(err);
  }
}

export async function getstorybyid(req, res, next) {
  const storyId = req.body.id;
  const userId = req.userId;
  console.log("---> userId in getstorybyid -->", userId);
  console.log("---> storyId in getstorybyid -->", storyId);
  try {
    const result = await StoryServices.GetStoryById(storyId, userId);
    res.status(200).json(result);
  } catch (err) {
    console.log("---> err in getstorybyid -->", err);
    next(err);
  }
}

export async function updatestory(req, res, next) {
  try {
    const { id } = req.params;
    const updateData = req.body || {};

    if (!id) {
      return res
        .status(400)
        .json({ status: false, message: "Story id is required" });
    }

    if (Object.keys(updateData).length === 0) {
      return res
        .status(400)
        .json({ status: false, message: "No data provided for update" });
    }

    const updated = await StoryModel.findByIdAndUpdate(id, updateData, {
      new: true,
      runValidators: true,
    });

    if (!updated) {
      return res
        .status(404)
        .json({ status: false, message: "Story not found" });
    }

    return res.status(200).json({
      status: true,
      message: "Story updated successfully",
      data: updated,
    });
  } catch (err) {
    console.log("---> err in updatestory -->", err);
    next(err);
  }
}
