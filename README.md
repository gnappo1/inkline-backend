# Notes API

A Rails **API-only** backend for a note-taking app with social features. It provides cookie-based auth, CRUD for notes, a public notes feed with **cursor (keyset) pagination**, and a friendship system (requests → accept/reject, cancel, unfriend). Built to run fast on **SQLite** for dev/test and swap cleanly to **Postgres** later.

---

## Table of contents

* [Features](#features)
* [Tech stack](#tech-stack)
* [Quick start](#quick-start)
* [Configuration](#configuration)
* [Database](#database)
* [API](#api)

  * [Auth / Session](#auth--session)
  * [Notes](#notes)
  * [Public Feed](#public-feed)
  * [Friendships](#friendships)
  * [My Friends](#my-friends)
* [Pagination contract](#pagination-contract)
* [Models](#models)
* [Indexes](#indexes)
* [Security & CORS](#security--cors)
* [Development tips](#development-tips)
* [Testing ideas](#testing-ideas)
* [Roadmap](#roadmap)
* [License](#license)

---

## Features

* **API-only Rails** with sessions enabled (cookie store)
* **Users & Auth**

  * `has_secure_password`
  * Email normalization with case-insensitive DB uniqueness (`LOWER(email)`)
* **Notes**

  * Validations & profanity filter for titles
  * Owner-scoped CRUD; `public` visibility flag
* **Feeds**

  * Global public notes feed with **keyset pagination**
  * Stable ordering by `created_at DESC, id DESC`
* **Friendships**

  * One row per unordered pair
  * Statuses: `pending`, `accepted`, `rejected`, `canceled`, `blocked`
  * Send, accept/reject, cancel (sender), unfriend (either)
  * Combined index endpoint for the client to split (accepted/pending)
* **Prod-ready DB path**

  * Dev/Test: SQLite
  * Postgres-friendly schema (foreign keys, constraints, partial indexes later)

---

## Tech stack

* Ruby / Rails (API-only)
* Active Record
* SQLite (dev/test), Postgres ready
* `rack-cors` (CORS), cookies + cookie store for sessions

---

## Quick start

```bash
# install gems
bundle install

# database (SQLite by default)
bin/rails db:drop db:create db:migrate
bin/rails db:seed   # optional env-specific seeds

# run server
bin/rails s

# inspect routes
bin/rails routes --expanded
```

> Tip: To run commands for a specific environment without prefixing `RAILS_ENV=...` every time, export it in your shell or use `direnv`.

---

## Configuration

Sessions & cookies (API-only needs these middleware):

```ruby
# config/application.rb
config.api_only = true
config.middleware.use ActionDispatch::Cookies
config.middleware.use ActionDispatch::Session::CookieStore, key: "_app_session", same_site: :lax
```

CORS (adjust `origins` to your frontend):

```ruby
# config/initializers/cors.rb
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://localhost:5173"
    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      credentials: true
  end
end
```

Environment variables: keep credentials out of the repo. A simple `.env` (via `dotenv-rails` in dev/test) can hold **non-secret** toggles. Use Rails credentials for secrets in real deployments.

---

## Database

Default `config/database.yml` uses SQLite for `development` and `test`. When you’re ready, swap to Postgres (add `pg` gem and update `database.yml`). Keep the Ruby schema (`schema.rb`) unless you adopt Postgres-specific features that require `:sql`.

Seeding: environment-aware seed files can live under `db/seeds/<env>.rb`, loaded from `db/seeds.rb`. Seeds are written to be idempotent for dev/test.

---

## API

Base path: `/` (JSON only).
All endpoints return predictable JSON and status codes. When sessions are required, send requests with cookies (`credentials: "include"` in the browser).

### Auth / Session

| Method | Path      | Body                                                   | Notes                                            |
| -----: | --------- | ------------------------------------------------------ | ------------------------------------------------ |
|   POST | `/signup` | `{ user: { first_name, last_name, email, password } }` | Creates a user and logs in (sets session cookie) |
|   POST | `/login`  | `{ user: { email, password } }`                        | Logs in; returns current user                    |
| DELETE | `/logout` | –                                                      | Logs out (clears session)                        |
|    GET | `/me`     | –                                                      | Returns the current user                         |

### Notes

| Method | Path         | Body / Params                          | Notes                              |
| -----: | ------------ | -------------------------------------- | ---------------------------------- |
|    GET | `/notes`     | –                                      | Current user’s notes (owner scope) |
|    GET | `/notes/:id` | –                                      | Owner or public can view           |
|   POST | `/notes`     | `{ note: { title, body, public } }`    | Create                             |
|  PATCH | `/notes/:id` | `{ note: { title?, body?, public? } }` | Update (owner)                     |
| DELETE | `/notes/:id` | –                                      | Destroy (owner)                    |

### Public Feed

| Method | Path           | Params                                  | Notes                                    |
| -----: | -------------- | --------------------------------------- | ---------------------------------------- |
|    GET | `/feed/public` | `limit?`, `before?`, `after?` (cursors) | Public notes only, **cursor pagination** |

### Friendships

| Method | Path               | Body / Params                      | Notes                                                        |
| -----: | ------------------ | ---------------------------------- | ------------------------------------------------------------ |
|    GET | `/friendships`     | `limit?`, `before?`, `after?`      | Combined list (involving me); client splits by status/role   |
|   POST | `/friendships`     | `{ receiver_id }`                  | Send request (idempotent; revive `canceled`/`rejected`)      |
|  PATCH | `/friendships/:id` | `{ action: "accept" \| "reject" }` | Receiver accepts or rejects                                  |
| DELETE | `/friendships/:id` | –                                  | Sender cancels pending **or** either side unfriends accepted |

### My Friends

| Method | Path          | Params                        | Notes                                          |
| -----: | ------------- | ----------------------------- | ---------------------------------------------- |
|    GET | `/me/friends` | `limit?`, `before?`, `after?` | Only **my** accepted friends (no public lists) |

---

## Pagination contract

**Order:** `created_at DESC, id DESC`
**Request params:** `limit` (default 20, capped 100), and **one of** `before` or `after` (opaque cursors).
**Cursor format:** base64 of `"ISO8601_TIMESTAMP,id"` (client treats it as opaque).

**Response envelope (example):**

```json
{
  "data": [ /* items */ ],
  "next_cursor": "eyIyMDI1LTA5LTMwVDE0OjIwOjAwWiIsIjEyMyJ9",  // pass back as ?before=
  "prev_cursor": "eyIyMDI1LTA5LTMwVDE0OjMwOjAwWiIsIjk4NyJ9"    // pass back as ?after=
}
```

**Why keyset:** avoids slow `OFFSET` scans and keeps ordering stable under inserts.

---

## Models

**User**

* Names normalized with `String#squish`
* Email normalized (`NFKC`, trim, lowercase, strip whitespace)
* `has_secure_password`
* Enum `role`: `client`, `admin`, `superadmin`
* Scopes: `recent`, `by_email`

**Note**

* `belongs_to :user`
* Validations for `title` and `body`, taboo-title validation (compiled regex)
* Scopes: `publicly_visible`, `feed_order`, `recent`
* Indices to support owner lists and global feed

**Friendship**

* `belongs_to :sender, :receiver` (both `User`)
* Single row per unordered pair using normalized pair columns: `user_low_id`, `user_high_id`
* Enum `status`: `pending`, `accepted`, `rejected`, `canceled`, `blocked`
* Constraints: **no self friendship**, **unique normalized pair**
* Scopes: `between(a_id, b_id)`, `involving(user_id)`, `accepted`, `pending`

---

## Indexes

**Users**

* Unique functional index: `LOWER(email)` (case-insensitive uniqueness)

**Notes**

* `(user_id, created_at)` – owner lists
* `(created_at, id)` – global feed
* `(public, created_at, id)` – public feed (SQLite); later a Postgres partial index `WHERE public = true`

**Friendships**

* Unique: `(user_low_id, user_high_id)` – one row per unordered pair
* Check: `sender_id <> receiver_id`
* Lookups: `(sender_id, status)`, `(receiver_id, status)`
* `(created_at, id)` – keyset ordering on lists

---

## Security & CORS

* **Sessions**: cookie store with proper `SameSite` and `Secure` flags depending on your deployment.
  For cross-origin frontends in development, use `credentials: true` in the client and configure CORS.
* **Error handling**: centralized `rescue_from` for `RecordInvalid`, `RecordNotFound`, `RecordNotUnique`, returning JSON with appropriate status codes (`422`, `404`, `409`).
* **Authorization**: controller guards (e.g., owner checks for notes; role checks for admin endpoints).
* **Do not** commit secrets. Use Rails credentials or environment variables managed by your platform.

---

## Development tips

* See routes:

  ```bash
  bin/rails routes -g notes
  bin/rails routes --expanded
  ```
* Open DB console:

  ```bash
  bin/rails db   # sqlite3 / psql depending on adapter
  ```
* Rails console one-offs:

  ```bash
  bin/rails runner 'puts User.count'
  ```
* Performance: prefer keyset over offset for large feeds. Add the matching composite indexes early.

---

## Testing ideas

* Request specs for:

  * Auth: signup/login/logout/me
  * Notes: owner CRUD, public visibility on `show`
  * Feed: cursor pagination (no duplicates, stable order)
  * Friendships: send/accept/reject/cancel/unfriend (both roles)
* Model specs:

  * Email normalization, uniqueness at DB level
  * Taboo title validator
  * Friendship constraints (`no self`, unique pair)

---

## Roadmap

* Swap dev/test to Postgres when needed (`pg` gem), add partial indexes (e.g., public notes)
* JSON serializers for stable payloads
* Rate limiting on friendship actions
* Avatars & profiles
* Optional `citext` for case-insensitive emails on Postgres

---

## License

MIT License
