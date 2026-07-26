"use client";
import React, { useState, useEffect } from "react";
import Logo from "@/components/Logo";
import Link from "next/link";

import BrandName from "@/app/data/BrandName";
import { usePathname } from "next/navigation";

interface NavbarProps {
    links: any[];
}

/**
 * Home navigation, built to match DocsNavbar: a solid 56px bar pinned to the
 * top, flat links, logo and wordmark on the left, actions on the right.
 *
 * It used to be a floating pill that stayed hidden until the page scrolled,
 * with the whole link row set to `max-sm:hidden` - so on a phone there was no
 * way to reach the docs from the top of the site at all.
 */
export default function Navbar({ links }: NavbarProps) {
    const pathname = usePathname();

    const [isDark, setIsDark] = useState(false);
    const [isScrolled, setIsScrolled] = useState(false);

    useEffect(() => {
        const getSaved = () => localStorage.getItem("theme");
        const prefersDark = () =>
            window.matchMedia &&
            window.matchMedia("(prefers-color-scheme: dark)").matches;

        const shouldBeDark =
            getSaved() === "dark" || (getSaved() === null && prefersDark());
        document.documentElement.classList.toggle("dark", shouldBeDark);
        setIsDark(shouldBeDark);

        const mq = window.matchMedia("(prefers-color-scheme: dark)");
        const mqHandler = (e: MediaQueryListEvent) => {
            if (getSaved() !== null) return;
            document.documentElement.classList.toggle("dark", e.matches);
            setIsDark(e.matches);
        };

        // Only drives the bar's background, so the hero shows through at rest.
        const onScroll = () => setIsScrolled(window.scrollY > 10);
        onScroll();

        mq.addEventListener("change", mqHandler);
        window.addEventListener("scroll", onScroll, { passive: true });

        return () => {
            mq.removeEventListener("change", mqHandler);
            window.removeEventListener("scroll", onScroll);
        };
    }, []);

    // After the hooks: bailing out earlier changed the hook count between
    // routes that share this layout, which React rejects.
    if (
        pathname === "/about" ||
        pathname === "/playground" ||
        pathname.startsWith("/about/") ||
        pathname.startsWith("/playground/")
    ) {
        return null;
    }

    const toggleTheme = () => {
        const newTheme = isDark ? "light" : "dark";
        document.documentElement.classList.toggle("dark", newTheme === "dark");
        localStorage.setItem("theme", newTheme);
        setIsDark(newTheme === "dark");
    };

    const docsLink = links.find((link) => link.url === "/docs");
    const externalLinks = links.filter(
        (link) => link.text === "Github" || link.text === "Discord",
    );

    return (
        <nav
            className={`fixed top-0 z-999 flex h-14 w-full items-center justify-between px-4 transition-colors duration-300 lg:px-8 ${
                isScrolled
                    ? "border-b border-white/8 bg-[#05070b]/85 backdrop-blur-xl"
                    : "border-b border-transparent bg-transparent"
            }`}
        >
            <Link
                href="/"
                className="flex flex-row items-center gap-1 text-white opacity-90 transition hover:opacity-100"
            >
                <Logo className="h-5! text-brand" />
                <span className="text-[22px] font-semibold tracking-tight">
                    {BrandName}
                </span>
            </Link>

            <div className="flex flex-row items-center gap-3.5 text-sm font-medium">
                {/* Kept visible at every width: reaching the docs from the top
                    of the landing page is the whole job of this bar. */}
                {docsLink ? (
                    <Link
                        href={docsLink.url}
                        className="text-white/70 transition hover:text-white"
                    >
                        Docs
                    </Link>
                ) : null}

                {externalLinks.map((link) => (
                    <Link
                        key={link.url}
                        href={link.url}
                        className="text-white/70 transition hover:text-white max-sm:hidden"
                    >
                        {link.text}
                    </Link>
                ))}

                <Link
                    href="/getting-started"
                    className="rounded-full bg-brand px-3.5 py-1.5 text-white transition hover:brightness-110 max-sm:hidden"
                >
                    Get Script
                </Link>

                <button
                    onClick={toggleTheme}
                    aria-label="Toggle colour theme"
                    className="text-white opacity-35 transition hover:opacity-100"
                >
                    <svg
                        className="h-5"
                        viewBox="0 0 24 24"
                        fill="none"
                        xmlns="http://www.w3.org/2000/svg"
                    >
                        <path
                            className={isDark ? "" : "hidden"}
                            d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z"
                            stroke="currentColor"
                            strokeWidth="2.3"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                        />
                        <path
                            className={isDark ? "hidden" : ""}
                            d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z"
                            stroke="currentColor"
                            strokeWidth="2.3"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                        />
                    </svg>
                </button>
            </div>
        </nav>
    );
}
