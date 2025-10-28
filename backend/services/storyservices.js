import StoryModel from "../models/Stories.js";
import UserModel from "../models/User.js";
import mongoose from "mongoose";

class StoryServices {
  // Get all stories
  static async GetAllStories(page = 1, limit = 10) {
    try {
      const skip = (page - 1) * limit;

      const stories = await StoryModel.find()
        .skip(skip)
        .limit(limit)
        .sort({ createdAt: -1 });

      const total = await StoryModel.countDocuments();

      return {
        status: true,
        message: "Stories fetched successfully",
        data: {
          stories: stories.map((story) => ({
            ...story.toObject(),
            background: story.background || "",
            journeyToIslam: story.journeyToIslam || "",
            afterIslam: story.afterIslam || "",
          })),
          pagination: {
            total,
            page,
            limit,
            totalPages: Math.ceil(total / limit),
          },
        },
      };
    } catch (err) {
      console.log("---> err in GetAllStories -->", err);
      return {
        status: false,
        message: "Failed to fetch stories",
        error: err.message,
      };
    }
  }

  //save story in the array of savesstory in user table
  static async SaveStory(userId, storyId) {
    try {
      const user = await UserModel.findOne({ userId });
      if (!user) throw new Error("User not found");
      //check if the story is already saved
      const index = user.savedStories.indexOf(storyId);
      const story = await StoryModel.findById(
        new mongoose.Types.ObjectId(storyId)
      );
      if (!story) throw new Error("Story not found");

      let action = "";

      if (index === -1) {
        // the story is not saved, so we add it
        user.savedStories.push(storyId);
        story.SaveCount++;
        action = "saved";
      } else {
        // the story is saved, so we remove it
        user.savedStories.splice(index, 1);
        story.SaveCount = Math.max(0, story.SaveCount - 1); // we don't want the save count to be negative
        action = "unsaved";
      }

      await user.save();
      await story.save();

      return {
        status: true,
        message: `Story ${action} successfully`,
        data: user,
      };
    } catch (err) {
      console.error("---> err in SaveStory -->", err);
      return {
        status: false,
        message: "Something went wrong",
        error: err.message,
      };
    }
  }

  //like story in the array of likes in story table
  static async LikeStory(userId, storyId) {
    try {
      let action = "";
      const user = await UserModel.findOne({ userId });
      if (!user) throw new Error("User not found");
      const story = await StoryModel.findById(
        new mongoose.Types.ObjectId(storyId)
      );
      if (!story) throw new Error("Story not found");
      //check if the story is already liked
      const index = user.likedStories.indexOf(storyId);
      if (index === -1) {
        //the story is not liked, so we add it
        user.likedStories.push(storyId);
        story.likeCount++;
        action = "liked";
      } else {
        //the story is already liked, so we remove it
        user.likedStories.splice(index, 1);
        story.likeCount = Math.max(0, story.likeCount - 1);
        action = "unliked";
      }
      await story.save();
      await user.save();
      return {
        status: true,
        message: `Story ${action} successfully`,
        data: user,
      };
    } catch (err) {
      console.error("---> err in LikeStory -->", err);
      return {
        status: false,
        message: "Something went wrong",
        error: err.message,
      };
    }
  }

  static async GetStoryById(storyId, userId) {
    try {
      const story = await StoryModel.findById(
        new mongoose.Types.ObjectId(storyId)
      );
      if (!story) throw new Error("Story not found");
      return {
        status: true,
        message: "Story fetched successfully",
        data: story,
      };
    } catch (err) {
      console.error("---> err in GetStoryById -->", err);
      return {
        status: false,
        message: "Something went wrong",
        error: err.message,
      };
    }
  }
}
export default StoryServices;
