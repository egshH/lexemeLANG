"use client";

import { useEffect, useRef, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { DM_Mono, Instrument_Serif, Syne } from "next/font/google";

const display = Syne({ subsets: ["latin"], display: "swap" });
const editorial = Instrument_Serif({ subsets: ["latin"], weight: "400", style: "italic", display: "swap" });
const mono = DM_Mono({ subsets: ["latin"], weight: ["400", "500"], display: "swap" });

const terminalExamples = [
  {
    file: "implicit.lex",
    detail: "Implicit returns",
    code: `const divide = fn(x, y) {
    if (y == 0) {
        return;
    }

    x / y;
}

const result = divide(48, 6)
const empty = divide(48, 0)

print(result, empty)`,
  },
  {
    file: "dynamic.lex",
    detail: "Dynamic values",
    code: `let value = 42
value = "Lexeme"
value = [1, "beta", true]

value = push(value, "nightly")

let metadata = {"name": "Lexeme"}
metadata["channel"] = value
metadata["ready"] = true

print(value)
print(metadata)`,
  },
  {
    file: "recovery.lex",
    detail: "Error handling",
    code: `try {
    const data = read("missing.lex")
    print(data)
} catch(error) {
    print(error)
}

try {
    read("optional.lex")
}

print("Interpreter is still running")`,
  },
  {
    file: "forever.lex",
    detail: "Loops without while",
    code: `let ticks = 0

for {
    ticks = ticks + 1

    if (ticks < 3) {
        continue
    }

    print(ticks)

    if (ticks == 5) {
        break
    }
}

print("Loop finished")`,
  },
  {
    file: "guess.lex",
    detail: "Functions & control flow",
    code: `const target = 55

const hint = fn(n) {
    if (n == target) {
        return "correct"
    } else {
        if (n < target) {
            return "too low"
        } else {
            return "too high"
        }
    }
}

let value = 0

for (value != target) {
    value = atoi(scanln())
    print(hint(value))
}`,
  },
];

const navigation = [
  { href: "/docs", title: "Documentation", detail: "Learn the language" },
  { href: "/early-access", title: "Early Access", detail: "Request a build" },
  { href: "/register", title: "Create account", detail: "Join the project" },
];

const lines = Array.from({ length: 12 }, (_, index) => index);
const selectionDuration = 1650;

type SelectionLine = {
  top: number;
  left: number;
  width: number;
  height: number;
  delay: number;
  duration: number;
};

function SyntaxWeave() {
  return (
    <svg
      viewBox="0 0 800 620"
      fill="none"
      aria-hidden="true"
      className="absolute left-1/2 top-1/2 h-[105%] w-[125%] max-w-none -translate-x-1/2 -translate-y-1/2"
    >
      <circle cx="400" cy="310" r="248" stroke="#5B4D74" strokeOpacity="0.18" />
      <circle cx="400" cy="310" r="195" stroke="#5B4D74" strokeOpacity="0.16" />
      {lines.map((line) => (
        <g key={line}>
          <path
            d={`M 65 310 C 180 ${20 + line * 19} 278 ${20 + line * 19} 400 310 C 525 ${600 - line * 19} 610 ${600 - line * 19} 735 310`}
            stroke={line > 7 ? "#66529F" : "#28212F"}
            strokeWidth="1.8"
            strokeOpacity={line > 7 ? "0.76" : "0.82"}
          />
          <path
            d={`M 65 310 C 180 ${600 - line * 19} 278 ${600 - line * 19} 400 310 C 525 ${20 + line * 19} 610 ${20 + line * 19} 735 310`}
            stroke={line > 7 ? "#66529F" : "#28212F"}
            strokeWidth="1.8"
            strokeOpacity={line > 7 ? "0.76" : "0.82"}
          />
        </g>
      ))}
      <path d="M 25 310 H 90 M 710 310 H 775" stroke="#28212F" strokeWidth="2" />
      <circle cx="400" cy="310" r="5.5" fill="#28212F" />
      <circle cx="65" cy="310" r="3" fill="#28212F" />
      <circle cx="735" cy="310" r="3" fill="#28212F" />
    </svg>
  );
}

export default function Home() {
  const [exampleIndex, setExampleIndex] = useState(0);
  const [text, setText] = useState("");
  const [isSelecting, setIsSelecting] = useState(false);
  const [selectionLines, setSelectionLines] = useState<SelectionLine[]>([]);
  const codeRef = useRef<HTMLPreElement>(null);
  const textRef = useRef<HTMLSpanElement>(null);
  const currentExample = terminalExamples[exampleIndex];

  useEffect(() => {
    if (codeRef.current) {
      codeRef.current.scrollTop = codeRef.current.scrollHeight;
    }
  }, [text]);

  useEffect(() => {
    if (isSelecting) return;

    const fullText = currentExample.code;
    const timeout = setTimeout(() => {
      if (text === fullText) {
        setIsSelecting(true);
      } else {
        setText(fullText.slice(0, text.length + 1));
      }
    }, text === fullText ? 1400 : 24);

    return () => clearTimeout(timeout);
  }, [text, isSelecting, currentExample.code]);

  useEffect(() => {
    if (!isSelecting) return;

    const pre = codeRef.current;
    const content = textRef.current;
    if (!pre || !content) return;

    const range = document.createRange();
    range.selectNodeContents(content);
    const container = pre.getBoundingClientRect();
    const boxes = Array.from(range.getClientRects())
      .filter((box) => box.width > 1 && box.height > 1)
      .map((box) => ({
        top: box.top - container.top + pre.scrollTop,
        left: box.left - container.left + pre.scrollLeft,
        width: box.width,
        height: box.height,
      }))
      .sort((a, b) => b.top - a.top || b.left - a.left);

    const totalWidth = boxes.reduce((sum, box) => sum + box.width, 0);
    let elapsed = 0;
    const selection = boxes.map((box) => {
      const duration = totalWidth ? selectionDuration * box.width / totalWidth : 0;
      const line = { ...box, delay: elapsed, duration };
      elapsed += duration;
      return line;
    });

    setSelectionLines(selection);

    const startingScroll = pre.scrollTop;
    let frame = 0;
    let startedAt = 0;

    const scrollWithSelection = (time: number) => {
      if (!startedAt) startedAt = time;
      const progress = Math.min((time - startedAt) / selectionDuration, 1);
      pre.scrollTop = startingScroll * (1 - progress);
      if (progress < 1) frame = requestAnimationFrame(scrollWithSelection);
    };

    frame = requestAnimationFrame(scrollWithSelection);

    const timeout = setTimeout(() => {
      setSelectionLines([]);
      setText("");
      setIsSelecting(false);
      setExampleIndex((previous) => (previous + 1) % terminalExamples.length);
    }, selectionDuration + 260);

    return () => {
      cancelAnimationFrame(frame);
      clearTimeout(timeout);
    };
  }, [isSelecting]);

  return (
    <main className={`${display.className} min-h-screen overflow-x-hidden bg-[#F0EEE7] text-[#191820]`}>
      <style>{`@keyframes lexeme-select-flow { from { transform: scaleX(0); } to { transform: scaleX(1); } }`}</style>
      <header className="bg-[#191820] text-[#F0EEE7]">
        <div className="mx-auto flex min-h-[94px] max-w-[1500px] items-center justify-between gap-6 px-5 sm:px-10 lg:px-14">
          <Link href="/" aria-label="Lexeme — Home" className="inline-flex shrink-0 items-center">
            <Image
              src="/lexeme-logo-horizontal.png"
              alt="Lexeme"
              width={737}
              height={142}
              priority
              className="h-auto w-[188px] sm:w-[232px]"
            />
          </Link>
          <span className={`${mono.className} hidden text-[10px] uppercase tracking-[0.19em] text-[#B9B3BF] md:block`}>
            Independent language project / Written in Go
          </span>
          <Link
            href="/early-access"
            className={`${mono.className} group border-b border-[#AB92E1] pb-1 text-[10px] font-medium uppercase tracking-[0.08em] text-[#D2BBFF] transition hover:text-white sm:text-[11px]`}
          >
            Join early access <span className="inline-block transition-transform group-hover:translate-x-1">↗</span>
          </Link>
        </div>
      </header>

      <section className="mx-auto max-w-[1500px] border-x border-[#191820]/15">
        <div className="grid lg:grid-cols-[minmax(0,1.08fr)_minmax(0,0.92fr)]">
          <div className="flex min-h-[560px] flex-col px-6 pb-10 pt-10 sm:px-10 sm:pb-12 sm:pt-12 lg:min-h-[665px] lg:px-14 lg:pt-14">
            <div className={`${mono.className} flex flex-wrap items-center justify-between gap-3 text-[10px] font-medium uppercase tracking-[0.17em] text-[#66616D]`}>
              <span>Programming language</span>
              <span>Edition / 2026</span>
            </div>
            <div className="mt-14 sm:mt-16 lg:mt-20">
              <h1 className="max-w-[870px] text-[clamp(3.55rem,6.9vw,7.35rem)] font-semibold leading-[0.88] tracking-[-0.095em]">
                Make room
                <span className="block">for another</span>
                <span className={`${editorial.className} mt-1 block font-normal tracking-[-0.065em] text-[#7659AE]`}>
                  syntax.
                </span>
              </h1>
              <p className="mt-10 max-w-[480px] text-[15px] leading-[1.75] text-[#5C5663] sm:text-[17px]">
                Lexeme is a small interpreted language written in Go. An open experiment in
                expression, structure and the way code comes to life.
              </p>
            </div>
            <div className={`${mono.className} mt-auto grid grid-cols-2 gap-6 border-t border-[#191820]/25 pt-5 text-[10px] uppercase leading-6 tracking-[0.12em] text-[#635D68] lg:pt-6`}>
              <span>Designed to explore</span>
              <span className="text-right">Made to be curious ↘</span>
            </div>
          </div>

          <div className="relative isolate flex min-h-[390px] flex-col overflow-hidden border-t border-[#191820]/20 bg-[#D6CBED] px-7 py-8 sm:min-h-[500px] sm:px-10 lg:min-h-[665px] lg:border-l lg:border-t-0">
            <div className={`${mono.className} relative z-10 flex items-center justify-between text-[10px] uppercase tracking-[0.2em] text-[#4C405D]`}>
              <span>Visual study / Lexeme</span>
              <span>Source ↔ Output</span>
            </div>
            <SyntaxWeave />
            <div className="relative z-10 mt-auto flex items-end justify-between gap-3 border-t border-[#191820]/25 pt-5">
              <div className={`${mono.className} text-[10px] uppercase leading-6 tracking-[0.15em] text-[#51455F]`}>
                A study in<br />
                flow and interpretation
              </div>
              <span className="text-[60px] font-medium leading-[0.7] tracking-[-0.1em] text-[#292230] sm:text-[76px]">
                &gt;
              </span>
            </div>
          </div>
        </div>
      </section>

      <div className="border-y border-[#191820]/20 bg-[#E7E2D9]">
        <div className={`${mono.className} mx-auto flex max-w-[1500px] flex-wrap items-center justify-between gap-3 px-6 py-4 text-[10px] uppercase tracking-[0.17em] text-[#625A67] sm:px-10 lg:px-14`}>
          <span>Source → Tokens → Meaning</span>
          <span>Build in public / Work in progress</span>
        </div>
      </div>

      <section className="bg-[#191820] text-[#F3F0E9]">
        <div className="mx-auto max-w-[1500px] px-5 pb-20 pt-16 sm:px-10 sm:pt-20 lg:px-14 lg:pb-24">
          <div className="mb-10 flex flex-wrap items-end justify-between gap-6 lg:mb-12">
            <div>
              <p className={`${mono.className} mb-5 text-[10px] uppercase tracking-[0.2em] text-[#BCA6EE]`}>
                Live syntax / A collection of examples
              </p>
              <h2 className="text-[clamp(2.6rem,5.2vw,5.4rem)] font-semibold leading-[1] tracking-[-0.075em]">
                Source, in <span className={`${editorial.className} font-normal text-[#C6AFF3]`}>motion.</span>
              </h2>
            </div>
            <span className={`${mono.className} max-w-[230px] text-[10px] uppercase leading-5 tracking-[0.1em] text-[#938A9E]`}>
              An animated preview of Lexeme syntax, not a live execution environment
            </span>
          </div>

          <div className="grid overflow-hidden border border-[#77717F]/35 lg:grid-cols-[minmax(0,1.2fr)_minmax(0,0.8fr)]">
            <div className="flex min-h-[570px] min-w-0 flex-col bg-[#101017]">
              <div className={`${mono.className} flex flex-wrap items-center justify-between gap-3 border-b border-white/15 px-5 py-5 text-[10px] uppercase tracking-[0.14em] text-[#B4ACBE] sm:px-8`}>
                <div className="flex items-center gap-3">
                  <span className="h-2 w-2 rounded-full bg-[#C6AFF3]" />
                  <span>Lexeme / Syntax studies</span>
                </div>
                <span className="text-[#9D86CA]">{currentExample.detail}</span>
              </div>

              <div className="flex min-h-0 flex-1 flex-col px-5 pb-6 pt-6 sm:px-8 sm:pt-8">
                <div className={`${mono.className} flex flex-wrap items-center gap-2 border-b border-white/10 pb-5 text-[15px] text-[#D6CEDD]`}>
                  <span className="text-[#C6AFF3]">›</span>
                  <span>lexeme {currentExample.file}</span>
                </div>
                <pre
                  ref={codeRef}
                  className={`${mono.className} relative isolate mt-6 h-[380px] min-h-0 w-full overflow-x-hidden overflow-y-auto whitespace-pre-wrap break-words text-[18px] leading-[1.8] text-[#EAE6EE] sm:h-[405px] sm:text-[19px]`}
                >
                  {selectionLines.map((line, index) => (
                    <span
                      key={index}
                      aria-hidden="true"
                      className="pointer-events-none absolute z-0 bg-[#695393]"
                      style={{
                        top: line.top,
                        left: line.left,
                        width: line.width,
                        height: line.height,
                        transformOrigin: "right center",
                        transform: "scaleX(0)",
                        animation: `lexeme-select-flow ${line.duration}ms linear ${line.delay}ms forwards`,
                      }}
                    />
                  ))}
                  <code className="relative z-10">
                    <span ref={textRef}>{text}</span>
                    {!isSelecting && <span aria-hidden="true" className="animate-pulse text-[#C6AFF3]">▌</span>}
                  </code>
                </pre>
                <div className={`${mono.className} mt-auto flex flex-wrap items-center justify-between gap-4 border-t border-white/10 pt-4 text-[10px] uppercase tracking-[0.1em] text-[#8C8395]`}>
                  <span>File / {currentExample.file}</span>
                  <div className="flex items-center gap-1.5" aria-label={`Example ${exampleIndex + 1} of ${terminalExamples.length}`}>
                    {terminalExamples.map((example, index) => (
                      <span
                        key={example.file}
                        className={`h-[3px] w-7 transition-colors duration-500 ${index === exampleIndex ? "bg-[#C6AFF3]" : "bg-[#56505D]"}`}
                      />
                    ))}
                  </div>
                </div>
              </div>
            </div>

            <nav className="relative flex min-h-[570px] flex-col bg-[#D6CBED] px-7 py-8 text-[#191820] sm:px-10 sm:py-10" aria-label="Explore Lexeme">
              <span className={`${mono.className} text-[10px] uppercase tracking-[0.17em] text-[#554866]`}>
                Continue exploring
              </span>
              <h3 className="mt-9 text-[clamp(2.8rem,4vw,5rem)] font-medium leading-[0.95] tracking-[-0.08em]">
                Where to
                <span className={`${editorial.className} mt-1 block font-normal text-[#6E529E]`}>next?</span>
              </h3>
              <div className="mt-10 border-t border-[#211A2C]/30">
                {navigation.map((item) => (
                  <Link
                    key={item.href}
                    href={item.href}
                    className="group flex items-center justify-between gap-4 border-b border-[#211A2C]/30 py-5 transition-all hover:pl-2"
                  >
                    <div>
                      <div className="text-[20px] font-semibold tracking-[-0.055em] sm:text-[22px]">{item.title}</div>
                      <div className={`${mono.className} mt-1 text-[10px] text-[#6A6175]`}>{item.detail}</div>
                    </div>
                    <span className="text-3xl leading-none transition-transform group-hover:-translate-y-1 group-hover:translate-x-1">↗</span>
                  </Link>
                ))}
              </div>
              <div className={`${mono.className} mt-auto flex justify-between border-t border-[#211A2C]/25 pt-5 text-[10px] uppercase tracking-[0.13em] text-[#675A73]`}>
                <span>Choose your path</span>
                <span>LEXEME ↗</span>
              </div>
            </nav>
          </div>
        </div>
      </section>

      <footer className="border-t border-white/10 bg-[#191820] text-[#A7A0AD]">
        <div className={`${mono.className} mx-auto flex max-w-[1500px] flex-wrap items-center justify-between gap-4 px-6 py-7 text-[10px] uppercase tracking-[0.15em] sm:px-10 lg:px-14`}>
          <span>Lexeme / Independent programming language</span>
          <span>Curiosity is part of the syntax.</span>
        </div>
      </footer>
    </main>
  );
}
