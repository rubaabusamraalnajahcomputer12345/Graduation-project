import User from "../models/User.js";
import moment from "moment";
import AdminServices from "../services/adminservices.js";
import Question from "../models/Questions.js";
import UserServices from "../services/userserviceslog&registeration.js";
import e from "express";

/*const fakeusers=[
    { "createdAt": "2024-12-28T14:03:00Z" },
    { "createdAt": "2025-01-03T09:22:00Z" },
    { "createdAt": "2025-01-15T11:30:00Z" },
    { "createdAt": "2025-02-10T16:05:00Z" },
    { "createdAt": "2025-02-21T18:50:00Z" },
    { "createdAt": "2025-03-01T08:45:00Z" },
    { "createdAt": "2025-03-14T13:30:00Z" },
    { "createdAt": "2025-04-05T07:20:00Z" },
    { "createdAt": "2025-05-22T10:00:00Z" },
    { "createdAt": "2025-05-25T21:10:00Z" },
    { "createdAt": "2025-06-18T15:00:00Z" },
    { "createdAt": "2025-07-10T04:45:00Z" },
    { "createdAt": "2025-07-14T09:00:00Z" },
    { "createdAt": "2025-07-21T12:20:00Z" },
    { "createdAt": "2025-08-02T13:11:00Z" },
    { "createdAt": "2025-08-19T17:45:00Z" },
    { "createdAt": "2025-09-30T08:30:00Z" },
    { "createdAt": "2025-10-12T22:00:00Z" },
    { "createdAt": "2025-11-03T07:25:00Z" },
    { "createdAt": "2025-12-25T06:15:00Z" }
];*/

export const getusersgrowth = async (req, res) => {
  try {
    const users = await User.find({}, "createdAt");
    //i want to make a function that will return each month with the # of users created in that month
    const monthlyUsers = await AdminServices.getCumulativeMonthlyUsers(users);

    res.status(200).json(monthlyUsers);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const getquestioncategories = async (req, res) => {
  try {
    const allquestion = await Question.find();
    console.log(allquestion);
    //i want to make a function that will return the number of questions for each category
    const questioncategories = await AdminServices.getQuestionCategories(
      allquestion
    );
    res.status(200).json(questioncategories);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const getgenderdistribution = async (req, res) => {
  try {
    const allusers = await User.find();
    const genderdistribution = await AdminServices.getGenderDistribution(
      allusers
    );
    res.status(200).json(genderdistribution);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const getdashboardstats = async (req, res) => {
  try {
    const dashinfo = await AdminServices.getDashboardStats();
    console.log(dashinfo);
    res.status(200).json(dashinfo);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const gettodayactivity = async (req, res) => {
  try {
    const todayactivity = await AdminServices.getTodayActivity();
    res.status(200).json(todayactivity);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const gettopcontent = async (req, res) => {
  try {
    const topcontent = await AdminServices.GetTopContent();
    res.status(200).json(topcontent);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

export const getusersdata = async (req, res) => {
  try {
    const usersdata = await AdminServices.getUsersData();
    res.status(200).json({ success: true, usersdata });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

export const approvevoulnteer = async (req, res) => {
  //to convert this volunteer from pending to certified
  try {
    console.log("approvevoulnteer");
    console.log("req.body:", req.body);
    const { volunteerId } = req.body;
    if (!volunteerId) {
      return res
        .status(400)
        .json({ success: false, message: "volunteerId is required" });
    }
    const usersdata = await AdminServices.approveVoulnteer(volunteerId);
    console.log("usersdata:", usersdata);
    if (!usersdata) {
      return res
        .status(404)
        .json({ success: false, message: "User not found" });
    }
    res
      .status(200)
      .json({ success: true, message: "Volunteer approved successfully" });
  } catch (error) {
    res
      .status(500)
      .json({ success: false, message: "Volunteer approval failed" });
  }
};

export const adminEditUser = async (req, res) => {
  try {
    console.log("=== ADMIN EDIT USER DEBUG ===");
    console.log("req.body:", req.body);

    const { userId } = req.body; // Get userId from request body
    const {
      displayName,
      gender,
      email,
      country,
      language,
      role,
      savedQuestions,
      savedLessons,
      bio,
      spoken_languages,
      certification_title,
      certification_institution,
      certification_url,
    } = req.body;

    if (!userId) {
      return res
        .status(400)
        .json({ status: false, message: "userId is required in URL params" });
    }

    if (!role) {
      return res
        .status(400)
        .json({ status: false, message: "Role is required in request body" });
    }

    // Get current user to check if email is being changed
    const currentUser = await UserServices.getUserById(userId);
    if (!currentUser) {
      return res.status(404).json({
        status: false,
        message: "User not found",
      });
    }

    // Check if email is being changed and if the new email already exists
    if (email && email !== currentUser.email) {
      console.log("email:", email);
      console.log("currentUser.email:", currentUser.email);
      console.log("userId:", userId);
      const existingUser = await UserServices.getUserByEmail(email);
      if (existingUser && existingUser.userId !== userId) {
        return res.status(400).json({
          status: false,
          message: "Email already exists",
        });
      }
    }

    // Base data for all users
    let updateData = {
      displayName,
      gender,
      email, // Use normalized email
      country,
      language,
      role,
    };

    // Add role-specific data
    if (role === "user") {
      updateData.savedQuestions = savedQuestions || [];
      updateData.savedLessons = savedLessons || [];
    }

    if (role === "certified_volunteer" || role === "volunteer_pending") {
      updateData.volunteerProfile = {
        bio: bio || "",
        languages: spoken_languages || [],
        certificate: {
          title: certification_title || "",
          institution: certification_institution || "",
          url: certification_url || "",
          uploadedAt: new Date(),
        },
      };
    }

    console.log("ADMIN UPDATE DATA:", updateData);
    console.log("User ID being updated:", userId);

    const updatedUser = await UserServices.updateUserById(userId, updateData);

    if (!updatedUser) {
      return res.status(404).json({
        status: false,
        message: "User not found or update failed",
      });
    }

    const userToReturn = updatedUser.toObject
      ? updatedUser.toObject()
      : updatedUser;
    delete userToReturn.password;

    console.log("=== END ADMIN EDIT USER DEBUG ===");

    return res.status(200).json({
      status: true,
      success: "User updated successfully by admin",
      user: userToReturn,
    });
  } catch (err) {
    console.log("---> err in adminEditUser -->", err);
    return res.status(500).json({
      status: false,
      message: "Internal server error",
      error: err.message,
    });
  }
};


export const getflags = async (req, res) => {
  try {
    const flags = await AdminServices.getFlags();
    res.status(200).json(flags);
  } catch (error) {
    res.status(500).json({ success:false,message: "Flags retrieval failed" });}
};

export const getallstoriesforadmin = async (req, res) => {
  try {
    const stories = await AdminServices.getallstories();
    res.status(200).json(stories);
  } catch (error) {
    res.status(500).json({ success:false,message: "Stories retrieval failed" });}
};
export const addstory = async (req, res) => {
  try {
    const story = await AdminServices.AddNewStory(req.body);
    res.status(200).json(story);
  } catch (error) {
    res.status(500).json({ success:false,message: "Story addition failed" });}
};

export const updateStory = async (req, res) => {
  try {
    if (!req.body || Object.keys(req.body).length === 0) {
      return res.status(400).json({ success: false, message: "No data provided for update" });
    }
    const story = await AdminServices.updateStory(req.params.id,req.body);
    if (!story) {
      return res.status(404).json({ success: false, message: "Story not found" });
    } 
    res.status(200).json({success:true,message:"Story updated successfully",story:story});
  } catch (error) {
    res.status(500).json({ success:false,message: "Story update failed" });}
};

export const deleteStory = async (req, res) => {
  try {
    const story = await AdminServices.deleteStory(req.params.id);
    if (!story) {
      return res.status(404).json({ success: false, message: "Story not found" });
    }
    res.status(200).json({success:true,message:"Story deleted successfully",story:story});
  } catch (error) {
    res.status(500).json({ success:false,message: "Story deletion failed" });}
};
 

 export const getAllQuestions = async (req, res) => {
  try {
    const questions = await AdminServices.getAllQuestionsForAdmin();
    res.status(200).json(questions);
  } catch (error) {
    res.status(500).json({ success:false,message: "Questions retrieval failed" });}
};

export const getAllAnswers = async (req, res) => {
  try {
    const answers = await AdminServices.getAllAnswersForAdmin();
    res.status(200).json(answers);
  } catch (error) {
    res.status(500).json({ success:false,message: "Answers retrieval failed" });}
};
export const updatequestionbyadmin = async (req, res) => {
  try {
    const { id } = req.params;
    const { text, category } = req.body;

    if (!id || !text || !category) {
      return res.status(400).json({ success: false, message: "Invalid input" });
    }

    const updatedQuestion = await AdminServices.updateQuestionByAdmin(id, text, category);
    
    if (!updatedQuestion) {
      return res.status(404).json({ success: false, message: "Question not found" });
    }

    res.status(200).json({ success: true, message: "Question updated successfully", question: updatedQuestion });
  } catch (error) {
    res.status(500).json({ success: false, message: "Question update failed" });
  }
};

 export const flagQuestion = async (req, res) => {    
  try {
    //extract question id from the parameters
    const questionId = req.params.id;
        const { isFlagged } = req.body;

    if (!questionId ) {
      return res.status(400).json({ success: false, message: "Invalid input" });
    }

    const flag = await AdminServices.FlagQuestion(questionId, isFlagged);

    if (!flag) {
      return res.status(404).json({ success: false, message: "Question not found or already flagged" });
    }

    res.status(200).json({ success: true, message: "Question flagged successfully", flag });
  } catch (error) {
    res.status(500).json({ success: false, message: "Flagging question failed" });
  }
 };

 export const adminUpdateAnswer = async (req, res) => {
  try {
    console.log("🧨 Admin Update Answer Called");
    const { id } = req.params;
    const { text } = req.body;
    console.log("🍳🍳Admin update answer called with id:", id, "and text:", text);
    if (!id || !text) {
      return res.status(400).json({ success: false, message: "Invalid input" });
    }

    const updatedAnswer = await AdminServices.updateAnswerByAdmin(id, text);
    
    if (!updatedAnswer) {
      return res.status(404).json({ success: false, message: "Answer not found" });
    }

    res.status(200).json({ success: true, message: "Answer updated successfully", answer: updatedAnswer });
  } catch (error) {
    console.error("Update Answer Error:", error);
    res.status(500).json({ success: false, message: "Answer update failed" });
  }
};

export const hideanswer = async (req, res) => {
  try {
    const { id } = req.params;
    //extract the body of the request
    const { isHidden } = req.body;

    if (!id) {
      return res.status(400).json({ success: false, message: "Invalid input" });
    }

    const hiddenAnswer = await AdminServices.HideAnswer(id, isHidden);

    if (!hiddenAnswer) {
      return res.status(404).json({ success: false, message: "Answer not found" });
    }

    res.status(200).json({ success: true, message: "Answer hidden successfully", answer: hiddenAnswer });
  } catch (error) {
    res.status(500).json({ success: false, message: "Hiding answer failed" });
  }
};

export const resolveFlag = async (req, res) => {
  try {
    const { flagId } = req.params;

    if (!flagId ) {
      return res.status(400).json({ success: false, message: "Invalid input" });
    }

    const resolvedFlag = await AdminServices.ResolveFlag(flagId);

    if (!resolvedFlag) {
      return res.status(404).json({ success: false, message: "Flag not found" });
    }

    res.status(200).json({ success: true, message: "Flag resolved successfully", flag: resolvedFlag });
  } catch (error) {
    res.status(500).json({ success: false, message: "Resolving flag failed" });
  }
};

export const rejectFlag = async (req, res) => {
  try {
    const { flagId } = req.params;

    if (!flagId ) {
      return res.status(400).json({ success: false, message: "Invalid input" });
    }

    const rejectedFlag = await AdminServices.RejectFlag(flagId);

    if (!rejectedFlag) {
      return res.status(404).json({ success: false, message: "Flag not found" });
    }

    res.status(200).json({ success: true, message: "Flag rejected successfully", flag: rejectedFlag });
  } catch (error) {
    res.status(500).json({ success: false, message: "Rejecting flag failed" });
  }
};

export const dismissFlag = async (req, res) => {
  try {
    const { flagId } = req.params;
     console.log("Dismiss Flag Called with flagId:", flagId);

    if (!flagId ) {
      return res.status(400).json({ success: false, message: "Invalid input" });
    }

    const dismissedFlag = await AdminServices.DismissFlag(flagId);

    if (!dismissedFlag) {
      return res.status(404).json({ success: false, message: "Flag not found" });
    }

    res.status(200).json({ success: true, message: "Flag dismissed successfully", flag: dismissedFlag });
  } catch (error) {
    res.status(500).json({ success: false, message: "Dismissing flag failed" });
  }
};

export const deleteFlagByAdmin = async (req, res) => {
  try {
    const { flagId } = req.params;

    if (!flagId) {
      return res.status(400).json({ success: false, message: "Invalid input" });
    }

    const deletedFlag = await AdminServices.DeleteFlagByAdmin(flagId);

    if (!deletedFlag) {
      return res.status(404).json({ success: false, message: "Flag not found" });
    }

    res.status(200).json({ success: true, message: "Flag deleted successfully", flag: deletedFlag });
  } catch (error) {
       if (error.statusCode === 404) {
      return res.status(404).json({ success: false, message: error.message });
    }
    res.status(500).json({ success: false, message: "Deleting flag failed" });
  }
};
