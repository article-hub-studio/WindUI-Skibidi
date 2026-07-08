import { RootProvider } from "fumadocs-ui/provider";
import { Inter } from "next/font/google";
import type { Metadata, Viewport } from "next";
import type { ReactNode } from "react";
import "./global.css";
import { Body } from "./body";
import { GeistSans } from "geist/font/sans";
import { SquircleNoScript } from "@squircle-js/react";

const inter = Inter({
    subsets: ["latin"],
});

export const viewport: Viewport = {
    width: "device-width",
    initialScale: 1,
    viewportFit: "cover",
};

export const metadata: Metadata = {
    metadataBase: new URL("https://article-hub-studio.github.io/WindUI-Skibidi"),
    title: {
        template: "%s",
        default: "WindUI Skibidi Docs",
    },
    description:
        "Documentation for the WindUI Skibidi Roblox UI library fork.",
};

export default function Layout({ children }: { children: ReactNode }) {
    return (
        <html
            lang="en"
            className={GeistSans.className}
            suppressHydrationWarning
        >
            <Body>
                <SquircleNoScript />
                <RootProvider search={{ enabled: false }}>
                    {children}
                </RootProvider>
            </Body>
        </html>
    );
}
