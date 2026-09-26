# Forum Website

A modern, two-page forum web app built with React. It features a forum page with
searchable, tag-filterable posts and infinite scroll, plus a login/signup page with
validation. Users can toggle dark/light mode, font family, and font size — and their
choices persist across visits.

## Features

- **Forum page** (`/`)
  - Debounced text search across posts and authors
  - Filter posts by a single tag (tags loaded from an API)
  - Infinite scroll (loads more posts as you scroll)
  - Scroll-reveal animations and skeleton loading states
- **Auth page** (`/auth`)
  - Toggle between login and signup
  - Client-side validation (email format, password strength, matching passwords)
- **Appearance settings** (persisted to `localStorage`)
  - Dark / light mode (respects system preference by default)
  - Font family: sans / serif / mono
  - Font size: small / medium / large

## Tech Stack

- [React](https://react.dev/) + [TypeScript](https://www.typescriptlang.org/)
- [Vite](https://vite.dev/) (build tool + dev server)
- [React Router](https://reactrouter.com/) (routing)
- [Tailwind CSS](https://tailwindcss.com/) v3 (styling)
- [TanStack Query](https://tanstack.com/query) (data fetching, caching, infinite scroll)
- [Framer Motion](https://www.framer.com/motion/) (animations)
- [React Hook Form](https://react-hook-form.com/) + [Zod](https://zod.dev/) (forms + validation)
- [lucide-react](https://lucide.dev/) (icons)

## Prerequisites

- **Node.js 18+** (Node 20 or 22 recommended)
- **npm** (bundled with Node)

Check your version:

```bash
node --version
```

## Getting Started

1. **Clone the repository**

   ```bash
   git clone https://github.com/Qwertyuiop176g/kirostuff.git
   cd kirostuff
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Start the development server**

   ```bash
   npm run dev
   ```

   Vite prints a local URL (default: <http://localhost:5173>). Open it in your browser.

## Available Scripts

| Command           | Description                                            |
| ----------------- | ------------------------------------------------------ |
| `npm run dev`     | Start the dev server with hot reloading                |
| `npm run build`   | Type-check and build for production into `dist/`       |
| `npm run preview` | Preview the production build locally                   |
| `npm run lint`    | Run the linter                                         |

## Connecting a Real API

The app ships with **mock data** so it runs out of the box. When your real backend is
ready, point the app at it with an environment variable:

1. Create a `.env` file in the project root:

   ```bash
   VITE_API_BASE_URL=https://your-api.example.com
   ```

2. Restart the dev server. Setting `VITE_API_BASE_URL` automatically switches the app
   from mock data to live requests.

The API layer lives in `src/api/`:

- `client.ts` — base URL, `USE_MOCK` flag, and the shared fetch helper
- `posts.ts` — `getPosts({ query, tagId, page, pageSize })`
- `tags.ts` — `getTags()`

Each of these has a real-API branch already stubbed out. Adjust the request paths and
query-parameter names to match your backend, and update the response types in
`src/types/index.ts` to match your API's shapes.

## Project Structure

```
src/
├── api/           # API client + mock data (posts, tags)
├── components/
│   ├── auth/      # Login/signup forms + validation schemas
│   ├── forum/     # SearchBar, TagFilter, PostCard, PostList
│   ├── layout/    # Navbar, SettingsPanel
├── context/       # AppearanceContext (theme, font, font size)
├── hooks/         # usePosts, useTags, useDebounce
├── routes/        # ForumPage, AuthPage
├── types/         # Shared TypeScript types
├── App.tsx        # Router + providers
└── main.tsx       # Entry point
```

## Building for Production

```bash
npm run build
```

The optimized output is written to `dist/`. Serve it with any static host, or preview
it locally with `npm run preview`.
