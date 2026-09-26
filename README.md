# ScamReg

A modern React web app for the **ScamReg** platform — a scam-identification tool
that uses on-device AI to flag scams and a centralized reporting system that warns
the community. This project is the marketing landing page plus the community forum.

Users land on a descriptive landing page, then head into the forum to search
tag-filterable posts with infinite scroll. Signing in unlocks commenting, and
everyone can toggle dark/light mode, font family, and font size — with a large base
font and wide layout tuned for readability (including users with low vision).

## Pages

- **Landing page** (`/`) — introduces ScamReg with a large hero, a scroll-driven
  "app pops out of the device" animation, feature sections (on-device AI detection,
  centralized reporting, privacy, real-time warnings), a "how it works" walkthrough,
  and a call-to-action into the forum. New visitors start here.
- **Forum** (`/forum`)
  - Debounced text search across posts and authors
  - Filter posts by a single tag (tags loaded from an API)
  - Infinite scroll (loads more posts as you scroll)
  - Expandable comments per post — **you must be logged in to comment**
  - Scroll-reveal animations and skeleton loading states
- **Auth** (`/auth`)
  - Toggle between login and signup with client-side validation
  - On submit, the (scaffolded) auth state flips to logged-in and redirects to the forum

## Features

- **Login-to-comment** — comment boxes prompt logged-out users to sign in. Auth is
  currently **scaffolded** (a fake session in `localStorage`); wire it to a real API
  when ready. See `src/context/AuthContext.tsx`.
- **Appearance settings** (persisted to `localStorage`)
  - Dark / light mode (respects system preference by default)
  - Font family: sans / serif / mono
  - Font size: small / medium / large
- **Accessibility-minded** — large base font size, wide layout that uses most of the
  screen, and `prefers-reduced-motion` support.

## Tech Stack

- [React](https://react.dev/) + [TypeScript](https://www.typescriptlang.org/)
- [Vite](https://vite.dev/) (build tool + dev server)
- [React Router](https://reactrouter.com/) (routing)
- [Tailwind CSS](https://tailwindcss.com/) v3 (styling)
- [TanStack Query](https://tanstack.com/query) (data fetching, caching, infinite scroll)
- [Framer Motion](https://www.framer.com/motion/) (animations, scroll effects)
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
| `npm test`        | Run the test suite once                                |
| `npm run test:watch` | Run tests in watch mode                             |
| `npm run coverage`   | Run tests and generate a coverage report            |

## Testing

Tests are written with [Vitest](https://vitest.dev/) and
[React Testing Library](https://testing-library.com/docs/react-testing-library/intro/).
Run them with:

```bash
npm test
```

Coverage includes the debounce hook, the mock API layer (search, tag filtering,
pagination), the form validation schemas, the appearance and auth contexts, and the
key UI components (`SearchBar`, `TagFilter`, `PostCard`, `CommentBox` auth gating).

## Adding Your Own Assets (landing animation)

The landing hero uses a **placeholder phone mockup** for the "app pops out of the
device" animation. To drop in real assets, edit
`src/components/landing/DeviceMockup.tsx`:

- Replace the contents of `PlaceholderScreen` with your app screenshot(s), e.g.
  `<img src="/assets/scamreg-screen-1.png" alt="ScamReg app" />`.
- The element that lifts out of the screen is `PopOutCard` (marked
  `data-slot="popout"`); replace it with the graphic you want to "pop out".

The scroll timing lives in `src/routes/LandingPage.tsx` (the `useTransform` calls).

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
`src/types/index.ts` to match your API's shapes. Auth is scaffolded in
`src/context/AuthContext.tsx` — replace `login`/`logout` with real calls.

## Project Structure

```
src/
├── api/           # API client + mock data (posts, tags)
├── components/
│   ├── auth/      # Login/signup forms + validation schemas
│   ├── forum/     # SearchBar, TagFilter, PostCard, PostList, CommentBox
│   ├── landing/   # DeviceMockup (landing hero animation)
│   └── layout/    # Navbar, Footer, SettingsPanel
├── context/       # AppearanceContext (theme/font) + AuthContext (scaffolded)
├── hooks/         # usePosts, useTags, useDebounce
├── routes/        # LandingPage, ForumPage, AuthPage
├── test/          # Vitest setup + render helpers
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
