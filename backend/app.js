import express from "express";
import bodyParser from "body-parser";
import UserRoute from "./routes/userroutelogandregisteration.js";
import ChatRoute from "./routes/chat.js";
import MeetingRequestRoute from "./routes/meetingRequestRoutes.js";
import ConnectionRouter from "./routes/connections.js";
const app = express();
import cors from "cors";
import admin from "firebase-admin";
import CronService from "./services/cronService.js";
import fs from "fs";
import path from "path";
import dotenv from "dotenv";

// Load .env from the root directory (Hidaya)
dotenv.config();

// Firebase Admin SDK initialization
const serviceAccount = JSON.parse(process.env.SERVICE_ACCOUNT_KEY);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

console.log("process.env.GOOGLE_API_KEY", process.env.GOOGLE_API_KEY);
// Initialize simple cron service
new CronService();

app.use(cors());
app.use(bodyParser.json());
app.use("/", UserRoute);
app.use("/chat", ChatRoute);
app.use("/meeting-requests", MeetingRequestRoute);
app.use("/connections", ConnectionRouter);

export default app;
