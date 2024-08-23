# Style

>  "Craftsmanship means dwelling on a task for a long time and going deeply into it, because you want to get it right."
>  — Matthew B. Crawford, Shop Class as Soulcraft

This document is not so much about style as it is about the culture we
want to foster. The focus is on general principles as opposed to
specific guidelines. Each section links to articles that justify and
provide more details.

## Simplicity

Given the product we're building, great emphasis is placed on
**correctness** and **velocity**. These require an emphasis on
simplicity. Problems should be solved in the simplest way possible, with
little code and abstraction so that correctness can be validated and
other engineers can easily audit code. Simplicity helps explore the
solution space faster. We see our emphasis on simplicity as a
competitive advantage over teams that burn engineering hours building
excessively complex software for simple problems.

- [Simple, correct, fast: in that order](https://drewdevault.com/2018/07/09/Simple-correct-fast.html)
- [Software As Liability](https://wiki.c2.com/?SoftwareAsLiability=)

## Readability

Code should be written from the perspective of the reader. Ask yourself

- What tacit assumptions am I making that someone else might not know?
- How would someone with little context interpret this code?
- How can I guard against the reader making a mistake or misunderstanding?

There are many tricks that help with this. Some examples:

- Make heavy use of "obvious" assertions to document tacit assumptions.
- Prefer fully qualified imports except when obviously redundant.
- Keep semantically similar code close, i.e. locality of behaviour.
- Prefer too little abstraction over too much.
- Prefer abstracting too late rather too early, as requirements are better known.
- Keep abstractions hermetic so users aren't exposed to implementation details.
- Use meaningful names, unless clear from convention or context.

Some examples follow.

- [Locality of Behaviour (LoB)](https://htmx.org/essays/locality-of-behaviour/)
- [Joel Spolsky on "Things you should never do, part 1"](https://www.joelonsoftware.com/2000/04/06/things-you-should-never-do-part-i/)

### Example: Localising imports

These are both contrived examples, but illustrate the principles.
Consider the prototypical `clap` example:

```rust
use clap::Parser;

#[derive(Parser)]
struct Cli {
    /* ... */
}

fn main() {
    let cli = Cli::parse();
    /* ... */
}
```

Applying the above principles, the following is a better example:

```rust
#[derive(clap::Parser)]
struct Cli {
    /* ... */
}

fn main() {
    let cli = <Cli as clap::Parser>::parse();
    /* ... */
}
```

Similarly, a nice trick is to move `use` statements to local scopes so
that the reader may easily refer to them without scrolling:

```rust
pub fn sha256(data: &[u8]) -> [u8; 32] {
    use sha2::{Digest as _, Sha256};
    let mut hasher = Sha256::new();
    hasher.update(data);
    hasher.finalize().into()
}
```

## Only Crash-only

Since we write long-running, mission-critical infrastructure code, we
design all our software to be _crash-only_. Instead of a startup and
shutdown procedures, we only have the recovery procedure as the
entrypoint, along with crashes as shutdown. Thus, even in the default
case, software should be able to tolerate a crash and continue running.
This pairs well with emphasis on simplicity and correctness, as well as
asserting liberally, as crash/recovery requires less code, and thanks to
crash-tolerance we are freely able to panic on invariant violations.
This means never handling SIGTERM or SIGINT.

- [Crash-Only Software](https://www.usenix.org/legacy/events/hotos03/tech/full_papers/candea/candea.pdf)
- [Let it Crash](https://wiki.c2.com/?LetItCrash=)

## Error handling

In Rust, errors typically have one of two functions:

1. Provide control flow to the caller.
2. Report errors to a human.

Control flow works when a function has a well-defined error set, which
the caller can choose to handle however they wish. This is typically
done with a `struct` with a `kind` field, or an `enum`. For a complete
coverage, I suggest reviewing "Modular Errors in Rust" article below

For error reporting, it's best to have an opaque, boxed type. The
obvious approach is `Box<dyn Error>`, but `anyhow` or `eyre` should be
used as they are more ergonomic and, more importantly, provide a
backtrace. `RUST_LIB_BACKTRACE=1` should _always_ be set so that
backtraces are captured when using `anyhow` or `eyre`. For a more
complete coverage, see the latter two articles.

- [Modular Errors in Rust](https://sabrinajewson.org/blog/errors)
- [Error Handling in Rust](https://www.lpalmieri.com/posts/error-handling-rust/#summary)
- [Error handling Isn't All About Errors](https://www.youtube.com/watch?v=rAF8mLI0naQ)

Panics are strictly for detecting incorrect code and should not be used
for error handling. This pairs well with "Assert liberally" below as
panics can be used to quickly detect bugs before they cause more harm.

## Assert liberally

Use `assert!` and `debug_assert!` as much as possible. While errors are
for external consumption, asserts are used to enforce that _internal
invariants_ are maintained. This might seem useless, but in practice is
incredibly powerful for debugging and enforcing correctness. Often, code
will be changed in certain ways that affect other components indirectly,
which may go unnoticed. Paired with property-based testing and fuzzing,
asserts are incredible. I'll give some examples to illustrate. These are
all based from code we've written, and many of these have actually
caught bugs.

This holds for both infrastructure and smart contract code, as Solidity
also differentiates between "reverts", which are for external facing
errors, and "panics", which indicate that an internal invariant has been
violated. Asserts can come in a variety of forms, not just `assert!` but
also `.unwrap()`, `.expect()`, `unreachable!()` or simply checking
conditions and panicking if they don't hold

- [LLVM coding standards: "Assert Liberally"](https://llvm.org/docs/CodingStandards.html#assert-liberally)
- [It takes two to contract](https://tigerbeetle.com/blog/2023-12-27-it-takes-two-to-contract)
- [Designing imperative code with properties in mind](https://www.tedinski.com/2018/05/01/designing-imperative-code-with-properties-in-mind.html)

### Example: Enforcing internal postconditions

You have an orderbook which supports Fill-or-Kill (FOK) orders. FOK
orders are orders that are executed only if the entire order can be
filled, and otherwise fail execution.

```rust
let params = OrderParams { size: 100, price: 100, ty: OrderType::FillOrKill };
let (posted, filled): (Option<Order>, Vec<Order>) = orderbook.place(params)?;

// Enforce that a FOK order is never posted.
if ty == OrderType::FillOrKill {
    assert!(posted.is_none());
}
```

This is a simplified version of actual code we've written in which
assertions caught critical bugs.

### Example: Invariants between fields

You have a structure that maintains a bimap:

```rust
struct Users {
    user_key: HashMap<UserId, Key>,
    key_for_user: HashMap<Key, UserId>,
}
```

And some methods to update it:

```rust
impl Users {
    fn insert_user(&mut self, user_id: UserId, key: Key) -> bool {
        if self.user_key.insert(user_id, key).is_none() {
            assert!(self.key_for_user.insert(key, user_id).is_none());
            return true;
        }
        false
    }

    fn remove_user(&mut self, user_id: UserId) -> bool {
        if let Some(key) = self.user_key.remove(&user_id) {
            assert_eq!(self.key_for_user.remove(&key), Some(user_id));
            return true;
        }
        false
    }
}
```

Notice how both functions assert that the bimap invariant is maintained.
Although this check is obviously redundant and this code is
unnecessarily inefficient, this style of coding helps catch bugs and
synergizes with property-based testing and fuzzing.

### Example: Guarding against livelocks

Suppose you send some request that succeeds, and poll to check the
resulting state change; a common pattern in some of our crates.

```rust
let request_id = send_data(&data).await?;

loop {
    if let Some(result) = check_data(request_id).await? {
        break;
    }
}
```

Presume that usually this takes a few seconds. What if it happens to
take an absurd amount of time, like an hour? There is clearly a bug. In
this case, we _bound our loops_ to ensure that we don't livelock. This
is another form of assertions.

```rust
const MAX_TIMEOUT: Duration = Duration::from_secs(3600);

let elapsed = Instant::now();
let request_id = send_data(&data).await?;

loop {
    if let Some(result) = check_data(request_id).await? {
        break;
    }

    if elapsed.elapsed() > MAX_TIMEOUT {
        tracing::error!(?request_id, "checking data timed out");
        panic!("checking data for request {} timed out", request_id);
    }
}
```

## Observe everything

Be thorough in observability. We want to be able to detect problems
early and pin down the causes quickly. Our approach to observability
is to use:

- [`tracing`](https://docs.rs/tracing/latest/tracing/) for emitting
  _events_ as structured logs.

  ```rust
  let result = execute(&action);

  tracing::info!(
      ?action,
      ?result,
      "executed",
  );
  ```

  Some events may be part of a _trace_ which is a sequence of events.
  Traces are great for capturing the flow of an operation as it
  traverses the system. Take the time to familiarize yourself with how
  the crate works.

- [`metrics`](https://docs.rs/metrics/latest/metrics/) for capturing
  measurements of the system and counters for events that would be
  much too repetitive as events.

  ```rust
  let exec_time = metrics::histogram!("exec_time");

  loop {
      let action = rx.recv()?;
      let t = Instant::now();
      let result = execute(&action);
      exec_time.record(t.elapsed().as_secs_f64());
  }
  ```

Both of these crates provide minimal and simple frontends with pluggable
backends, making them great for use in libraries. Strongly recommend
reading the following articles to fully understand the model:

- [All you need is Wide Events, not "Metrics, Logs and
  Traces"](https://isburmistrov.substack.com/p/all-you-need-is-wide-events-not-metrics)

## Always statically link

We statically link binaries for portability during deployments. Static
linking along with nix mostly obviates containers. Note that static
linking with Rust [requires `musl` instead of
`glibc`](https://doc.rust-lang.org/reference/linkage.html#static-and-dynamic-c-runtimes),
which seems to have a [slower
malloc](https://andygrove.io/2020/05/why-musl-extremely-slow/). In
practice, we also use `jemalloc` to avoid the slowdown. `cargo-zigbuild`
can be used for cross-compilation when needed.

Overall, the implementation comes down to

```rust
#[global_allocator]
static GLOBAL: jemallocator::Jemalloc = jemallocator::Jemalloc;
```

in Rust and a `justfile` with

```justfile
build-static-release:
    RUSTFLAGS="-C target-feature=+crt-static" cargo zigbuild --release --target x86_64-unknown-linux-musl
```

If linking against `glibc` is really needed, `cargo-zigbuild` can
parametrize the `glibc` version so prefer using to pin the version.

- [Drew DeVault on Dynamic Linking](https://drewdevault.com/dynlib.html)
- ["Static Linking Considered Harmful" Considered Harmful](https://gavinhoward.com/2021/10/static-linking-considered-harmful-considered-harmful/)
