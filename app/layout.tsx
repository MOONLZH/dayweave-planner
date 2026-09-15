import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "日序 · 项目与每日安排",
  description: "把项目放在一起，把每一天安排清楚。个人多项目时间轴与每日任务安排。",
  icons: {
    icon: "/favicon.svg",
    shortcut: "/favicon.svg",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="zh-CN">
      <body className="antialiased">{children}</body>
    </html>
  );
}
