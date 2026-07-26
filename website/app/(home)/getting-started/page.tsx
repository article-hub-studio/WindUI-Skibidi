import AnimatedList from "@/components/AnimatedList";
import loadstring from "@/lib/loadstring";
import { DynamicCodeBlock } from "fumadocs-ui/components/dynamic-codeblock";
import Link from "next/link";

export default function GettingStartedPage() {
    return (
        <main className="flex min-h-dvh flex-1 flex-col items-center justify-center bg-[#05070b] px-4 pt-14 text-white sm:px-[10%] lg:px-[20%]">
            {/* w-full: without it the column sizes to the widest child's
                max-content, so the heading pushed the page sideways on phones. */}
            <AnimatedList
                className="flex w-full max-w-3xl flex-col items-center justify-center gap-4"
                staggerDelay={150}
            >
                <p className="rounded-full border border-white/12 bg-white/8 px-3 py-1 text-sm font-medium text-white/64">
                    WindUI Modded
                </p>
                <h1 className="max-w-full text-center text-3xl font-semibold tracking-tight text-balance">
                    Getting Started With Loadstring
                </h1>

                <p className="max-w-xl text-center text-sm leading-6 text-white/58">
                    Use the current article-hub-studio repo build. The API still
                    exposes the `WindUI` variable in examples, so existing
                    scripts stay familiar.
                </p>

                {/* min-w-0: the code block is a flex item, and a flex item
                    will not shrink below its content. The loadstring URL is one
                    long unbreakable token, so without this the row grows past
                    the viewport instead of letting the block scroll itself. */}
                <div className="flex w-full min-w-0 flex-row items-center justify-center">
                    <div className="w-full min-w-0 max-w-2xl">
                        <DynamicCodeBlock lang="luau" code={loadstring} />
                    </div>
                </div>

                <div className="flex flex-col gap-2 sm:flex-row">
                    <Link
                        href="/docs/windui/elements-overview"
                        className="rounded-full bg-white px-5 py-2 text-sm font-semibold text-black"
                    >
                        Elements overview
                    </Link>
                    <Link
                        href="/docs/windui/loadstring"
                        className="rounded-full border border-white/12 bg-white/8 px-5 py-2 text-sm font-semibold text-white"
                    >
                        Loadstring docs
                    </Link>
                </div>
            </AnimatedList>
        </main>
    );
}
