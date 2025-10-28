import nodemailer from "nodemailer";

const transporter = nodemailer.createTransport({
  service: "Gmail",
  auth: {
    user: "hidayaislamicapp@gmail.com",
    pass: "plxf ziie wivk omil",
  },
});

// Reset Password Email
async function sendResetPasswordEmail(email, token) {
  console.log("--- token ---", token);
  console.log("--- email ---", email);
  const link = `http://localhost:5000/reset-password/${token}`;
  await transporter.sendMail({
    from: '"Islamic AI" <hidayaislamicapp@gmail.com>',
    to: email,
    subject: "Reset your password",
    html: `<h3>Reset your password</h3><p>Please click the link below to reset your password:</p><a href="${link}">Reset Password</a>`,
  });
}

export default sendResetPasswordEmail;
