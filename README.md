# Fakr — Faker as a Service

Design mock APIs visually, generate realistic fake data, and share production-ready endpoints with your team.

Built with Elixir, Phoenix LiveView, and the Faker library.

## Features

- **Visual API Designer** — Define resources and fields through a GUI. Pick from 100+ data generators.
- **Custom Generators** — Integer ranges, prices with currency symbols, pick-from-list, templates, nanoid, ulid, and more.
- **Nested Objects & Arrays** — Group fields into nested JSON objects. Configure groups as single objects or arrays.
- **Pre-generated Data** — Publish to generate mock records stored in the database. Stable IDs for detail endpoints.
- **Real REST API** — `GET /@username/:collection/api/:resource` with pagination, filtering, sorting, search.
- **Filtering** — `?column=value` exact match, `?search_column=name&search_term=john` ilike search.
- **Sorting** — `?sort=price&order=desc`
- **API Simulation** — `?delay=2000` response delay, `?status=500` error simulation.
- **OpenAPI 3.0 Spec** — Auto-generated from resource definitions. Swagger UI link included.
- **Code Snippets** — cURL, JavaScript (fetch), Python (requests) on every public collection page.
- **Explore Page** — Browse public collections shared by other users.
- **Revision System** — Track field definition changes. Revert to published revision.
- **CORS** — All API endpoints include CORS headers for frontend app usage.
- **Rate Limiting** — 100 requests/minute per IP.
- **Docker Ready** — Multi-stage Dockerfile with auto-migration on startup.

## Quick Start (Development)

Prerequisites: Elixir 1.18+, Erlang/OTP 27+, PostgreSQL

```bash
mix setup
mix phx.server
```

Visit [http://localhost:4000](http://localhost:4000)

## Quick Start (Docker)

```bash
docker compose up
```

Visit [http://localhost:4000](http://localhost:4000)

Emails are captured locally — visit [http://localhost:4000/dev/mailbox](http://localhost:4000/dev/mailbox) to view them.

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DATABASE_URL` | Yes (prod) | — | PostgreSQL connection URL |
| `SECRET_KEY_BASE` | Yes (prod) | — | 64+ byte secret (`mix phx.gen.secret`) |
| `PHX_HOST` | No | `localhost` | Hostname for URL generation |
| `PHX_SCHEME` | No | `https` | `http` or `https` |
| `PHX_URL_PORT` | No | `443`/`80` | Port for URL generation |
| `PORT` | No | `4000` | HTTP server port |
| `MAIL_ADAPTER` | No | `local` | `local` or `mailgun` |
| `MAILGUN_API_KEY` | If mailgun | — | Mailgun API key |
| `MAILGUN_DOMAIN` | If mailgun | — | Mailgun domain |

## API Endpoints

For a collection at `/@johndoe/shop-api` with a `products` resource:

```
GET  /@johndoe/shop-api/api/products           # List with pagination
GET  /@johndoe/shop-api/api/products/3          # Detail by ID
GET  /@johndoe/shop-api/openapi.json            # OpenAPI 3.0 spec
GET  /health                                    # Health check
```

### Query Parameters

| Param | Description |
|-------|-------------|
| `page` | Page number (default: 1) |
| `limit` | Items per page (default: 10, max: 100) |
| `sort` | Sort by field name |
| `order` | `asc` or `desc` |
| `<column>=<value>` | Exact match filter |
| `search_column` | Field to search |
| `search_term` | Search keyword (case-insensitive) |
| `delay` | Response delay in ms (max: 10000) |
| `status` | Simulate HTTP error (e.g. 500, 401) |

## Tech Stack

- **Elixir** 1.18 + **Phoenix** 1.8 + **LiveView** 1.1
- **PostgreSQL** with JSONB for flexible record storage
- **Faker** library for realistic data generation
- **Tailwind CSS** + **daisyUI** for styling
- **SortableJS** for drag & drop field ordering

## License

MIT
