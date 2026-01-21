const express = require("express");
const app = express();

const PORT = process.env.PORT || 3000;

// Health check endpoint (useful for DevOps & monitoring)
app.get("/health", (req, res) => {
  res.status(200).json({ status: "UP" });
});

// Redirect to your portfolio
app.get("/", (req, res) => {
  res.redirect("https://kotadurga-portfolio.netlify.app/");
});

// Start server
app.listen(PORT, () => {
  console.log(`Portfolio app running on port ${PORT}`);
});