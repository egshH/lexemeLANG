
export default function Home() {
  return (
    <main className="min-h-screen bg-[#0a0a0f] text-white">
      <header className="mx-auto flex max-w-6xl items-center justify-between px-6 py-8">
        <span className="text-2xl font-bold tracking-tight">
          Lexeme<span className="text-violet-500">.</span>
        </span>

        <a
          href="https://github.com/egshH/Lexeme"
          target="_blank"
          rel="noopener noreferrer"
          className="text-sm text-zinc-400 transition hover:text-white"
        >
          GitHub ↗
        </a>
      </header>

      <section className="mx-auto max-w-6xl px-6 py-24">
        <div className="mb-8 inline-block rounded-full border border-violet-500/30 bg-violet-500/10 px-4 py-2 text-sm text-violet-400">
          Currently in development
        </div>

        <h1 className="max-w-4xl text-5xl font-bold tracking-tight sm:text-7xl">
          Programming,
          <br />
          made <span className="text-violet-500">simple.</span>
        </h1>

        <p className="mt-8 max-w-2xl text-lg leading-8 text-zinc-400">
          Lexeme is a lightweight interpreted programming language
          written in Go. Built for learning, experimenting, and
          exploring how programming languages work.
        </p>

        <div className="mt-12 max-w-2xl overflow-hidden rounded-xl border border-white/10 bg-[#12121a]">
          <div className="flex items-center gap-2 border-b border-white/10 px-5 py-4">
            <div className="h-3 w-3 rounded-full bg-red-400" />
            <div className="h-3 w-3 rounded-full bg-yellow-400" />
            <div className="h-3 w-3 rounded-full bg-green-400" />
            <span className="ml-4 text-sm text-zinc-500">
              hello.lex
            </span>
          </div>

          <pre className="overflow-x-auto p-6 text-sm leading-7 text-zinc-200">
            <code>{`const message = "Hello, world!"

print(message)`}</code>
          </pre>

          <div className="border-t border-white/10 px-6 py-4 font-mono text-sm text-green-400">
            Hello, world!
          </div>
        </div>
      </section>

      <footer className="mx-auto max-w-6xl border-t border-white/10 px-6 py-8 text-sm text-zinc-500">
        Lexeme Programming Language
      </footer>
    </main>
  );
}
