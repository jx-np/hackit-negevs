# ScamWatch

A modern React web app for the **ScamWatch** platform — a scam-identification tool
that uses on-device AI to flag scams and a centralized reporting system that warns
the community. This project is the marketing landing page plus the community forum.

Users land on a descriptive landing page, then head into the forum to search
tag-filterable posts with infinite scroll. Signing in unlocks commenting, and
everyone can toggle dark/light mode, font family, and font size — with a large base
font and wide layout tuned for readability (including users with low vision).

## Pages

- **Landing page** (`/`) — introduces ScamWatch with a large hero, a scroll-driven
  "app pops out of the device" animation, feature sections (on-device AI detection,
  centralized reporting, privacy, real-time warnings), a "how it works" walkthrough,
  and a call-to-action into the forum. New visitors start here.
- **Forum** (`/forum`) — an image-forward media feed
  - Debounced text search across posts and authors
  - Filter posts by a single tag via a **draggable tag panel** you can snap to
    the left or right side of the screen (position persists in `localStorage`)
  - **Sort** by newest / most comments / most likes
  - Posts can include **redacted screenshots** (evidence) with a risk badge and
    a click-to-reveal blur, plus a full-size lightbox viewer
  - Infinite scroll (loads more posts as you scroll)
  - Expandable comments per post — **you must be logged in to comment**
  - Scroll-reveal animations and skeleton loading states
- **Post detail / thread** (`/forum/:id`)
  - Full report view (screenshots, tags, risk, author, body) with the comment thread
  - Reached by clicking a post's title or image in the forum
  - **Live comments over SSE** — the page subscribes to
    `GET /community/posts/{id}/sse` and new comments appear in the thread
    without a reload, with a small "live updates" status pill
  - **NegevAI assistant** — mentioning `@help` in a comment makes the AI
    assistant answer it. The triggering comment shows a "NegevAI is thinking…"
    indicator while the bot works, and the reply is badge-marked with an **AI** chip
- **Report a scam** (`/report`) — **login-gated**
  - Fleshed-out form: title, **incident date** (date picker, no future dates),
    description, single **category** picker, **risk** level, and a screenshot
    **media picker** (click or drag-and-drop, any number of images)
  - Screenshots are uploaded to `POST /uploads`, which schedules OCR + PII
    redaction; the picker polls until the **redacted** copy is ready and only
    previews that copy. Submit is held until redaction finishes, then the upload
    ids are attached to the post
  - Validation throughout; redirects to the new post on submit
  - Logged-out users see a prompt to sign in — or use **"Continue as demo
    user"** on the auth page to try reporting without an account
- **Number check** (`/check`)
  - Look up a phone number to see how many times it's been reported
  - **Validates** the input and treats `+prefix` and non-`+` forms of the same
    number as identical (canonical digits-only key)
  - Shows a status verdict — **trusted / scam / unknown** — with a scam vs.
    trusted report-count breakdown, plus the backend's classification label when
    one applies
  - The report action is a mobile-first flow (`POST /detection/phone-number/report`)
    and is not surfaced on the web client
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
  `<img src="/assets/scamwatch-screen-1.png" alt="ScamWatch app" />`.
- The element that lifts out of the screen is `PopOutCard` (marked
  `data-slot="popout"`); replace it with the graphic you want to "pop out".

The scroll timing lives in `src/routes/LandingPage.tsx` (the `useTransform` calls).

## Connecting a Real API

The app talks to the ScamWatch backend (`API.docs.md`) through a Vite dev-server
proxy. Point the app at the backend with an environment variable:

1. Create a `.env` file in the project root:

   ```bash
   VITE_API_BASE_URL=https://your-api.example.com
   ```

2. Restart the dev server. Requests go to `/api/v1/...` on the same origin and Vite
   forwards them to `VITE_API_BASE_URL` (set `VITE_API_PROXY_TARGET` to override the
   proxy target). This avoids CORS and injects the `ngrok-skip-browser-warning`
   header the tunnel needs.

The API layer lives in `src/api/`:

- `client.ts` — base URL, the shared JSON/multipart/blob fetch helpers, token refresh
- `posts.ts` — feed, search, post detail, create/edit/delete, reactions, flags
- `media.ts` — screenshot upload (`POST /uploads`), redaction polling, redacted images
- `sse.ts` — URL builder for the post discussion stream (`/community/posts/{id}/sse`)
- `tags.ts`, `comments.ts`, `numbers.ts`, `auth.ts`, `guidance.ts`

## Project Structure

```
src/
├── api/           # HTTP client + per-resource API modules
├── components/
│   ├── auth/      # Login/signup forms + validation schemas
│   ├── forum/     # PostCard, PostList, PostImages (lightbox), CommentList, ...
│   ├── landing/   # DeviceMockup (landing hero animation)
│   ├── report/    # MediaPicker (upload + redaction preview)
│   └── layout/    # Navbar, Footer, SettingsPanel
├── context/       # Appearance, Auth, SavedFeeds contexts
├── hooks/         # usePosts, usePost, useComments, usePostCommentsStream, ...
├── routes/        # LandingPage, ForumPage, PostDetailPage, ReportPage, ...
├── test/          # Vitest setup + render helpers
├── types/         # Shared TypeScript types (UI + backend wire shapes)
├── App.tsx        # Router + providers
└── main.tsx       # Entry point
```

## Building for Production

```bash
npm run build
```

The optimized output is written to `dist/`. Serve it with any static host, or preview
it locally with `npm run preview`.
