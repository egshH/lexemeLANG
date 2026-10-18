# Lexeme Website

The website for **Lexeme** — a small interpreted programming language written in Go and inspired by Thorsten Ball's book *Writing an Interpreter in Go*.

This repository contains the website project for Lexeme. The goal is to make the language easier to explore, learn, and use by bringing its documentation and examples together in one place.

## About Lexeme

Lexeme is a lightweight, dynamically typed language with familiar, JavaScript-like syntax.

It supports:

- Variables declared with `let` and constants declared with `const`
- Strings, integers, booleans, arrays, and hash maps
- Functions, closures, and return values
- Conditionals with `if` and `else`
- Loops with `for`, `break`, and `continue`
- Error handling with `try` and `catch`
- Built-in functions for input, output, and working with data

## Website Goals

The website is being built as a home for:

- **Getting started** — install Lexeme and run your first program
- **Language guide** — learn the syntax and core concepts
- **Code examples** — see Lexeme in action
- **Reference** — look up language features and built-in functions

> The website is a work in progress. Its content and features may change during development.

## Quick Example

```js
const greeting = "Hello, world!"
print(greeting)

let add = fn(a, b) {
    return a + b
}

print(add(5, 10)) // 15
```

## Run Lexeme Locally

Install the interpreter with Go:

```bash
git clone https://github.com/egshH/Lexeme.git
cd Lexeme/cmd/lexeme
go install
```

Run a `.lex` script:

```bash
lexeme hello.lex
```

Or launch Lexeme without arguments to start the interactive REPL:

```bash
lexeme
```

## Related Project

- [Lexeme — interpreter source code and language documentation](https://github.com/egshH/Lexeme)

## License

See the repository's license file, if provided.
