import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./app/**/*.{ts,tsx}", "./components/**/*.{ts,tsx}", "./lib/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        body: "#F2F4F7",
        card: "#FFFFFF",
        border: "#DBDBDB",
        primary: "#FF7200",
        positive: "#33732E",
        negative: "#BF3030"
      },
      fontFamily: {
        sans: [
          "Pretendard",
          "Apple SD Gothic Neo",
          "Noto Sans KR",
          "Malgun Gothic",
          "system-ui",
          "sans-serif"
        ]
      }
    }
  },
  plugins: []
};

export default config;
