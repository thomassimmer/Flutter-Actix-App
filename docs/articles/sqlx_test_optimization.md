# `#[sqlx::test]`: A Powerful Example of Macros and Traits in Rust

When writing integration tests for the Rust web APIs of [the Flutter-Actix app](https://github.com/thomassimmer/Flutter-Actix-App) and [ReallyStick](https://github.com/thomassimmer/reallystick), I discovered that SQLx's `#[sqlx::test]` macro not only simplified my code but also solved a disk space problem. More importantly, I learned a valuable lesson: **always read the crate documentation instead of blindly following tutorials**. But beyond that, `#[sqlx::test]` is a perfect example of how Rust's macro system and trait system work together to create powerful abstractions.

I had been following the [zero2prod](https://www.lpalmieri.com/posts/2020-08-31-zero-to-production-3-5-html-forms-databases-integration-tests/#3-2-choosing-a-database-crate) book's approach of manually creating databases for each test. While this worked, it led to hundreds of orphaned databases consuming gigabytes of disk space. SQLx's `#[sqlx::test]` macro solves this elegantly. Let's dive into how it works under the hood.

## The Problem (Briefly)

The original approach manually created a database for each test:

```rust
#[tokio::test]
async fn user_can_login() {
    let app = spawn_app().await;  // Creates DB using a UUID, runs migrations
    // test code
}
```

This worked but had two critical issues: **no automatic cleanup** (databases accumulated indefinitely) and **verbose boilerplate** (30+ lines of setup code). After running my tests multiple times, I had hundreds of orphaned databases.

## The Solution: `#[sqlx::test]`

The fix was simple: just change the attribute and add a parameter:

```rust
#[sqlx::test]
async fn user_can_login(pool: PgPool) {
    let app = spawn_app(pool).await;
    // test code
}
```

But what makes this work? Let's examine SQLx's implementation to understand the magic.

## How `#[sqlx::test]` Works: A Deep Dive

### Step 1: Macro Expansion

When you write `#[sqlx::test]`, the procedural macro in `sqlx-macros-core/src/test_attr.rs` transforms your function. Here's the key expansion logic:

**File:** `sqlx-macros-core-0.7.4/src/test_attr.rs`

```rust
Ok(quote! {
    #[::core::prelude::v1::test]
    #(#attrs)*
    fn #name() #ret {
        async fn #name(#inputs) #ret {
            #body
        }

        let mut args = ::sqlx::testing::TestArgs::new(
            concat!(module_path!(), "::", stringify!(#name))
        );

        #migrations  // Adds migrator if migrations/ directory exists

        args.fixtures(&[#(#fixtures),*]);

        let f: fn(#(#fn_arg_types),*) -> _ = #name;
        ::sqlx::testing::TestFn::run_test(f, args)
    }
})
```

The macro:

1. Wraps your async function in a regular `#[test]` function
2. Creates a `TestArgs` struct with your test's full path (for tracking)
3. Automatically detects and includes migrations from `./migrations/`
4. Creates a function pointer to your async function
5. Calls `TestFn::run_test()` which handles the entire lifecycle

The key line is `let f: fn(#(#fn_arg_types),*) -> _ = #name;`. This extracts your function signature (including the `pool: PgPool` parameter) and creates a function pointer. For your test, this becomes `let f: fn(PgPool) -> _ = user_can_login;`.

### Step 1.5: How the PgPool Parameter Works

You might wonder: how does SQLx know to create a `PgPool` and pass it to your function? This is where Rust's trait system shines.

When the macro calls `TestFn::run_test(f, args)`, it relies on trait implementations that match your function signature. SQLx provides a `TestFn` trait with implementations for specific function signatures:

**File:** `sqlx-core-0.7.4/src/testing/mod.rs`

```rust
impl<DB, Fut> TestFn for fn(Pool<DB>) -> Fut
where
    DB: TestSupport + Database,
    DB::Connection: Migrate,
    for<'c> &'c mut DB::Connection: Executor<'c, Database = DB>,
    Fut: Future,
    Fut::Output: TestTermination,
{
    type Output = Fut::Output;

    fn run_test(self, args: TestArgs) -> Self::Output {
        run_test_with_pool(args, self)  // self is your function!
    }
}
```

When you write `async fn user_can_login(pool: PgPool)`, the function pointer type is `fn(PgPool) -> impl Future`. Rust's trait resolution matches this to the `TestFn` implementation above (since `PgPool` is `Pool<Postgres>`).

The implementation then calls `run_test_with_pool`, which creates the pool and calls your function:

**File:** `sqlx-core-0.7.4/src/testing/mod.rs`

```rust
fn run_test_with_pool<DB, F, Fut>(args: TestArgs, test_fn: F) -> Fut::Output
where
    F: FnOnce(Pool<DB>) -> Fut,  // Your function matches this!
    // ...
{
    run_test::<DB, _, _>(args, |pool_opts, connect_opts| async move {
        // Create the actual pool
        let pool = pool_opts
            .connect_with(connect_opts)
            .await
            .expect("failed to connect test pool");

        // Call your function with the pool!
        let res = test_fn(pool.clone()).await;
        //     ^^^^^^^^^^^^
        //     This is your function being called

        // ... cleanup code ...
        res
    })
}
```

The critical line is `test_fn(pool.clone()).await`. This invokes your function, passing the freshly created pool as the argument.

**The Magic**: Rust's trait system connects your function signature to the pool creation logic. The macro extracts your function signature, the trait system matches it to the right implementation, and that implementation creates the pool and calls your function. This is why you can write `async fn my_test(pool: PgPool)`. The plumbing is handled automatically.

### Step 2: Test Execution Flow

The `run_test` function orchestrates the test lifecycle:

**File:** `sqlx-core-0.7.4/src/testing/mod.rs`

```rust
fn run_test<DB, F, Fut>(args: TestArgs, test_fn: F) -> Fut::Output
where
    DB: TestSupport,
    DB::Connection: Migrate,
    // ... trait bounds
{
    crate::rt::test_block_on(async move {
        // 1. Create test database context
        let test_context = DB::test_context(&args)
            .await
            .expect("failed to connect to setup test database");

        // 2. Setup database (migrations + fixtures)
        setup_test_db::<DB>(&test_context.connect_opts, &args).await;

        // 3. Execute your test function
        let res = test_fn(test_context.pool_opts, test_context.connect_opts).await;

        // 4. Cleanup: delete database if test succeeded
        if res.is_success() {
            if let Err(e) = DB::cleanup_test(&test_context.db_name).await {
                eprintln!("failed to delete database {:?}: {}", test_context.db_name, e);
            }
        }

        res
    })
}
```

This is the heart of the system. Notice that cleanup only happens if `res.is_success()`. Failed tests keep their databases for debugging.

### Step 3: Database Creation

The PostgreSQL-specific implementation creates unique databases using a sequence:

**File:** `sqlx-postgres-0.7.4/src/testing/mod.rs`

```rust
async fn test_context(args: &TestArgs) -> Result<TestContext<Postgres>, Error> {
    let url = dotenvy::var("DATABASE_URL").expect("DATABASE_URL must be set");
    let master_opts = PgConnectOptions::from_str(&url)
        .expect("failed to parse DATABASE_URL");

    // Create a "master" pool for database management
    let master_pool = PoolOptions::new()
        .max_connections(20)
        .after_release(|_conn, _| Box::pin(async move { Ok(false) }))
        .connect_lazy_with(master_opts);

    let mut conn = master_pool.acquire().await?;

    // Create tracking schema and table
    conn.execute(r#"
        lock table pg_catalog.pg_namespace in share row exclusive mode;
        create schema if not exists _sqlx_test;
        create table if not exists _sqlx_test.databases (
            db_name text primary key,
            test_path text not null,
            created_at timestamptz not null default now()
        );
        create sequence if not exists _sqlx_test.database_ids;
    "#).await?;

    // Cleanup old databases (only on first test run)
    let now = SystemTime::now().duration_since(SystemTime::UNIX_EPOCH).unwrap();
    if DO_CLEANUP.swap(false, Ordering::SeqCst) {
        do_cleanup(&mut conn, now).await?;
    }

    // Generate unique database name using PostgreSQL sequence
    let new_db_name: String = query_scalar(r#"
        insert into _sqlx_test.databases(db_name, test_path)
        select '_sqlx_test_' || nextval('_sqlx_test.database_ids'), $1
        returning db_name
    "#)
    .bind(&args.test_path)
    .fetch_one(&mut *conn)
    .await?;

    // CREATE THE ACTUAL DATABASE
    conn.execute(&format!("create database {new_db_name:?}")[..])
        .await?;

    Ok(TestContext {
        pool_opts: PoolOptions::new()
            .max_connections(5)
            .idle_timeout(Some(Duration::from_secs(1)))
            .parent(master_pool.clone()),
        connect_opts: master_opts.clone().database(&new_db_name),
        db_name: new_db_name,
    })
}
```

Key design decisions:

- **Sequence-based naming**: Uses PostgreSQL's `nextval()` to generate unique names (`_sqlx_test_1`, `_sqlx_test_2`, etc.)
- **Tracking table**: Records all test databases with their test paths and creation times
- **Automatic cleanup**: On the first test run, deletes databases older than the current time
- **Parent pool**: Test pools share a "parent" pool to manage connection limits globally

### Step 4: Migration Application

After creating the database, migrations are applied automatically:

**File:** `sqlx-core-0.7.4/src/testing/mod.rs`

```rust
async fn setup_test_db<DB: Database>(
    copts: &<DB::Connection as Connection>::Options,
    args: &TestArgs,
) where
    DB::Connection: Migrate + Sized,
    // ... trait bounds
{
    let mut conn = copts
        .connect()
        .await
        .expect("failed to connect to test database");

    // Apply migrations if migrator was provided
    if let Some(migrator) = args.migrator {
        migrator
            .run_direct(&mut conn)
            .await
            .expect("failed to apply migrations");
    }

    // Apply test fixtures (SQL scripts)
    for fixture in args.fixtures {
        (&mut conn)
            .execute(fixture.contents)
            .await
            .unwrap_or_else(|e| panic!("failed to apply test fixture {:?}: {:?}", fixture.path, e));
    }

    conn.close().await.expect("failed to close setup connection");
}
```

The macro automatically detects your `./migrations/` directory and includes it in `TestArgs`. The `migrator.run_direct()` method applies all migrations in order.

### Step 5: Automatic Cleanup

The cleanup happens automatically after successful tests:

**File:** `sqlx-postgres-0.7.4/src/testing/mod.rs`

```rust
fn cleanup_test(db_name: &str) -> BoxFuture<'_, Result<(), Error>> {
    Box::pin(async move {
        let mut conn = MASTER_POOL
            .get()
            .expect("cleanup_test() invoked outside `#[sqlx::test]")
            .acquire()
            .await?;

        // Drop the database
        conn.execute(&format!("drop database if exists {db_name:?};")[..])
            .await?;

        // Remove from tracking table
        query("delete from _sqlx_test.databases where db_name = $1")
            .bind(&db_name)
            .execute(&mut *conn)
            .await?;

        Ok(())
    })
}
```

This is the critical piece that solves the disk space problem. Each database is automatically deleted after its test completes, preventing accumulation.

## The Architecture: Why It Works So Well

SQLx's design is elegant:

1. **Database-per-test isolation**: Each test gets a completely fresh database, enabling safe parallel execution
2. **Automatic migration management**: No need to manually run migrations
3. **Resource tracking**: The `_sqlx_test.databases` table tracks all test databases, enabling cleanup of orphaned ones
4. **Failure handling**: Failed tests keep their databases for debugging, successful ones are cleaned up immediately
5. **Connection pooling**: Smart pool management prevents connection exhaustion across parallel tests

## The Lesson: Read the Documentation

Here's what I learned: **Don't follow tutorials blindly**. The [zero2prod](https://www.lpalmieri.com/posts/2020-08-31-zero-to-production-3-5-html-forms-databases-integration-tests/#3-2-choosing-a-database-crate) book showed a valid approach, but it wasn't the best one for my use case. SQLx's documentation clearly describes `#[sqlx::test]` and its benefits, but I hadn't checked it.

A few minutes reading the SQLx docs would have saved me some lines of boilerplate code, gigabytes of disk space, and manual cleanup scripts.

**Always check the crate's documentation for built-in solutions before implementing your own**. Library authors often provide utilities specifically designed for common use cases like testing. The `#[sqlx::test]` macro is a perfect example of how Rust's macro system can make testing both simpler and more robust.

---

_Sometimes the best code is the code you don't have to write—and sometimes it's already written in the crate's documentation._
