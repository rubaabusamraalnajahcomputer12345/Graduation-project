import User from "../models/User.js";

// Middleware to check if user is a certified volunteer
export const requireCertifiedVolunteer = async (req, res, next) => {
  try {
    const userId = req.user._id;

    const user = await User.findOne({ userId: userId });

    if (!user) {
      return res.status(404).json({
        status: false,
        message: "User not found",
      });
    }

    if (user.role !== "certified_volunteer") {
      return res.status(403).json({
        status: false,
        message:
          "Access denied: Only certified volunteers can perform this action",
      });
    }

    next();
  } catch (error) {
    console.error("Error in volunteer middleware:", error);
    res.status(500).json({
      status: false,
      message: "Internal server error",
    });
  }
};

// Middleware to check if user is either a volunteer or certified volunteer
export const requireVolunteer = async (req, res, next) => {
  try {
    const userId = req.user._id;

    const user = await User.findOne({ userId: userId });

    if (!user) {
      return res.status(404).json({
        status: false,
        message: "User not found",
      });
    }

    if (
      user.role !== "volunteer_pending" &&
      user.role !== "certified_volunteer"
    ) {
      return res.status(403).json({
        status: false,
        message: "Access denied: Only volunteers can perform this action",
      });
    }

    next();
  } catch (error) {
    console.error("Error in volunteer middleware:", error);
    res.status(500).json({
      status: false,
      message: "Internal server error",
    });
  }
};
