import express from "express";
const router = express.Router();
import {
  register,
  login,
  updateprofile,
  updateCity,
  verifyEmail,
  changepassword,
  updateOneSignalId,
  forgotpassword,
  changePassword,
  deleteAccount,
  resetpassword,
  changeresetpassword,
} from "../controller/usercontroller.js";
import authMiddleware from "../services/authMiddleware.js";
import {
  submitquestion,
  getpublicquestions,
  getquestionandanswers,
  getquestionsofaspecificuser,
  savequestion,
  deletequestion,
  updatequestion,
  updateAIAnswer,
} from "../controller/questioncontroller.js";
import {
  submitanswerbyvolunteer,
  voteonanswer,
  getanswersofvolunteer,
  getanswerupvotedbyvolunteer,
  deleteAnswer,
  reviewandupdateanswer,
} from "../controller/answercontroller.js";
import { reportquestion } from "../controller/flagcontroller.js";
import {
  getalllesson,
  getlessonbyid,
  updateLessonProgressInUser,
  addlesson,
  updatelesson,
  deletelesson,
} from "../controller/lessoncontroller.js";
import notificationRoutes from "./notificationroutes.js";
import {
  getallstories,
  savestory,
  likestory,
  getstorybyid,
  updatestory,
} from "../controller/StoryController.js";

import {
  getusersgrowth,
  getquestioncategories,
  getgenderdistribution,
  getdashboardstats,
  gettodayactivity,
  gettopcontent,
  getusersdata,
  approvevoulnteer,
  adminEditUser,
  getflags,
  getallstoriesforadmin,
  addstory,
  updateStory,
  deleteStory,
  getAllQuestions,
  getAllAnswers,
  updatequestionbyadmin,
  flagQuestion,
  adminUpdateAnswer,
  hideanswer,
  resolveFlag,
  rejectFlag,
  dismissFlag,
  deleteFlagByAdmin,
} from "../controller/AdminController.js";

router.post("/register", register);
router.post("/login", login);
router.put("/profile", authMiddleware, updateprofile);

router.put("/city", authMiddleware, updateCity);
router.put("/onesignal-id", authMiddleware, updateOneSignalId);
router.put("/change-password", authMiddleware, changePassword);
router.delete("/delete-account", authMiddleware, deleteAccount);
// Use notification routes
router.use("/notifications", notificationRoutes);
router.post("/questions", authMiddleware, submitquestion);
router.get("/public-questions", getpublicquestions);
router.get("/questions/:id", getquestionandanswers);
router.post("/answers", authMiddleware, submitanswerbyvolunteer);
router.put("/answers/vote", authMiddleware, voteonanswer);
//router.post("/flags", authMiddleware, FlagController.flagitem);
router.get("/myquestion", authMiddleware, getquestionsofaspecificuser);
router.get("/my-questions", authMiddleware, getquestionsofaspecificuser);
router.post("/saveQuestion", authMiddleware, savequestion);
router.get("/myAnwers", authMiddleware, getanswersofvolunteer);
router.get("/upvotedAnswer", authMiddleware, getanswerupvotedbyvolunteer);
router.delete("/deletequestions/:id", authMiddleware, deletequestion);
router.put("/updatequestions/:id", authMiddleware, updatequestion);
router.patch("/questions/:id/ai-answer", authMiddleware, updateAIAnswer);

router.post("/reportquestion", authMiddleware, reportquestion);
router.get("/verify/:token", verifyEmail);
router.post("/change-password", authMiddleware, changepassword);
router.post("/forgot-password", forgotpassword);
router.get("/reset-password/:token", resetpassword);
router.post("/reset-password", authMiddleware, changeresetpassword);
router.delete("/answers/delete/:answerId", deleteAnswer);
router.get("/story", getallstories);
//save story
router.post("/story/savestory", authMiddleware, savestory);
//like story
router.post("/story/likestory", authMiddleware, likestory);
//get story by id
router.get("/getstorybyid", authMiddleware, getstorybyid);
// update story (user/admin depending on auth & policy)
router.put("/story/:id", authMiddleware, updatestory);

// Admin routes for questions and answers
router.get("/admin/questions", getAllQuestions);
router.get("/admin/answers", getAllAnswers);
//admin routes
//admin/usersgrowth
router.get("/admin/user-growth", getusersgrowth);
router.get("/admin/question-categories", getquestioncategories);
router.get("/admin/gender-distribution", getgenderdistribution);
router.get("/admin/dashboard-stats", getdashboardstats);
router.get("/admin/today-activity", gettodayactivity);
router.get("/admin/top-content", gettopcontent);
//admin/usersdata

router.put("/admin/edit-user", authMiddleware, adminEditUser);

router.get("/admin/users", getusersdata);
router.post("/admin/approve-voulnteer", approvevoulnteer);
router.get("/admin/flags", getflags);
//get all the stories
router.get("/admin/getallstories", getallstoriesforadmin);
//Add new story
router.post("/admin/addstory", addstory);
//update story
router.patch("/admin/updatestory/:id", updateStory);
//delete story
router.delete("/admin/deletestory/:id", deleteStory);
router.get("/admin/questions", getAllQuestions);
router.get("/admin/answers", getAllAnswers);
router.put("/admin/update-question/:id", updatequestionbyadmin);
// Flag a question
router.post("/admin/flag-question/:id", flagQuestion);
// Update an answer by admin
router.put("/admin/update-answer/:id", adminUpdateAnswer);
//hide answer by the admin
router.put("/admin/hide-answer/:id", hideanswer);
//review and update answer by the volunteer
router.put("/review-and-update-answer/:id", reviewandupdateanswer);
// flag actions by admin
router.put("/admin/flags/resolve/:flagId", resolveFlag);
router.put("/admin/flags/reject/:flagId", rejectFlag);
router.put("/admin/flags/dismiss/:flagId", dismissFlag);
router.delete("/admin/flags/delete/:flagId", deleteFlagByAdmin);
//Lesson Steps Routes
router.get("/lessons", getalllesson);
//get lesson by id
router.get("/lesson/:id", getlessonbyid);
router.patch(
  "/lesson/progress/:id",
  authMiddleware,
  updateLessonProgressInUser
);
//Add lesson By admin
router.post("/admin/addlesson", addlesson);
//update lesson by admin
router.put("/admin/updatelesson/:id", updatelesson);
//delete lesson by admin
router.delete("/admin/deletelesson/:id", deletelesson);
export default router;
