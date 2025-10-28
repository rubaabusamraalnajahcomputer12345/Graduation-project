import jwt from "jsonwebtoken";

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith("Bearer ")) {
    return res
      .status(401)
      .json({ status: false, message: "No token provided" });
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, "secret"); // Same key used to sign
    console.log("Decoded:", decoded);

    if (!decoded || !decoded._id) {
      return res
        .status(401)
        .json({ status: false, message: "Invalid token payload!1!!!1" });
    }

    // Standardized attachments
    req.userId = decoded._id; // stable access to the authenticated user's id
    req.userEmail = decoded.email;
    req.userRole = decoded.role;
    // Backwards compatibility for code expecting req.user._id
    req.user = { _id: decoded._id, email: decoded.email, role: decoded.role };

    next();
  } catch (err) {
    console.log("JWT verification error:", err.message);

    return res
      .status(403)
      .json({ status: false, message: "Invalid or expired token" });
  }
};

// Named export for consistency with existing imports
export const verifyToken = authMiddleware;

export default authMiddleware;
