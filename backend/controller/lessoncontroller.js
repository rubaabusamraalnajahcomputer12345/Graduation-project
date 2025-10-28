import LessonServices from "../services/lessonservices.js";

export async function getalllesson(req, res, next) {
  try {
    const alllesson = await LessonServices.GetAllLessons();
    res.status(200).json({
      status: true,
      success: "Getting all lessons  successfully",
      lesson: alllesson,
    });
  } catch (err) {
    console.error("Error fetching lessons:", err);
    res.status(500).json({
      status: false,
      message: "Failed to fetch lessons",
      error: err.message,
    });
  }
}

export async function getlessonbyid(req, res, next) {
  try {
    const lessonId = req.params.id;
    const lesson = await LessonServices.GetLessonById(lessonId);
    if (!lesson) {
      return res.status(404).json({
        status: false,
        message: "Lesson not found",
      });
    }
    res.status(200).json({
      status: true,
      success: "Getting lesson successfully",
      lesson: lesson,
    });
  } catch (err) {
    console.error("Error fetching lesson:", err);
    res.status(500).json({
      status: false,
      message: "Failed to fetch lesson",
      error: err.message,
    });
  }
}

export async function updateLessonProgressInUser(req, res, next) {
  try {
    const userId = req.userId; // take the userId from the token
    const lessonId = req.params.id;
    const { currentStep } = req.body;

    // Validate progress
    if (typeof currentStep !== "number" || currentStep < 0 || currentStep > 100) {
      return res.status(400).json({
        status: false,
        message: "Invalid progress value. Progress must be a number between 0 and 100.",
      });
    }
    console.log("Updating lesson progress:", {
      userId,
      lessonId,
      currentStep
    });

    // Call service to update lesson progress
    const result = await LessonServices.UpdateLessonProgressInUser(userId, lessonId, currentStep);
    if (!result) {
      return res.status(404).json({
        status: false,
        message: "Lesson not found or user not enrolled in lesson.",
      });
    }

    res.status(200).json({
      status: true,
      success: "Lesson progress updated successfully.",
      result: result,
    });
  } catch (err) {
    console.error("Error updating lesson progress:", err);
    res.status(500).json({
      status: false,
      message: "Failed to update lesson progress",
      error: err.message,
    });
  }
}

export async function addlesson(req, res, next) {
  try {
    const lessonData = req.body;
    const newLesson = await LessonServices.AddLesson(lessonData);
    res.status(201).json({
      status: true,
      success: "Lesson added successfully",
      lesson: newLesson,
    });
  } catch (err) {
    console.error("Error adding lesson:", err);
    res.status(500).json({
      status: false,
      message: "Failed to add lesson",
      error: err.message,
    });
  }
}
export async function updatelesson(req, res, next) {
  try {
    const lessonId = req.params.id;
    const lessonData = req.body;
    const updatedLesson = await LessonServices.UpdateLesson(lessonId, lessonData);
    if (!updatedLesson) {
      return res.status(404).json({
        status: false,
        message: "Lesson not found",
      });
    }
    res.status(200).json({
      status: true,
      success: "Lesson updated successfully",
      lesson: updatedLesson,
    });
  } catch (err) {
    console.error("Error updating lesson:", err);
    res.status(500).json({
      status: false,
      message: "Failed to update lesson",
      error: err.message,
    });
  }
}

export async function deletelesson(req, res, next) {
       const lessonId = req.params.id;
  try {
    const result = await LessonServices.DeleteLesson(lessonId);
    if (!result) {
      return res.status(404).json({
        status: false,
        message: "Lesson not found",
      });
    }
    res.status(200).json({
      status: true,
      success: "Lesson deleted successfully",
    });
  } catch (err) {
    console.error("Error deleting lesson:", err);
    res.status(500).json({
      status: false,
      message: "Failed to delete lesson",
      error: err.message,
    });
  }
}