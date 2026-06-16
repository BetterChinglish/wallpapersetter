import { defineConfig } from "prisma/config";
import dotenv from "dotenv";

// Load environment variables
dotenv.config();

export default defineConfig({
  datasources: [
    {
      name: "db",
      url: process.env.DATABASE_URL,
    },
  ],
});
