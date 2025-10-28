import nodemailer from "nodemailer";

const transporter = nodemailer.createTransport({
  service: "Gmail",
  auth: {
    user: "hidayaislamicapp@gmail.com",
    pass: "plxf ziie wivk omil",
  },
});

async function sendVerificationEmail(email, token) {
  const link = `http://localhost:5000/verify/${token}`;
  await transporter.sendMail({
    from: '"Islamic AI" <hidayaislamicapp@gmail.com>',
    to: email,
    subject: "Verify your email",
    html: `<h3>Welcome!</h3><p>Please verify your email by clicking below:</p><a href="${link}">Verify Email</a>`,
  });
}

export default sendVerificationEmail;
