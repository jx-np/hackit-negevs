/// <reference types="vitest/config" />
import react from '@vitejs/plugin-react'
import { defineConfig, loadEnv } from 'vite'

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')

  // The backend to proxy to during development. The browser talks to the Vite
  // dev server (same origin), which forwards /api requests to this target.
  // This sidesteps the backend's missing CORS headers.
  const proxyTarget =
    env.VITE_API_PROXY_TARGET || env.VITE_API_BASE_URL || ''

  return {
    plugins: [react()],
    server: {
      proxy: proxyTarget
        ? {
            '/api': {
              target: proxyTarget,
              changeOrigin: true,
              secure: false,
              headers: {
                // ngrok free tunnels serve an interstitial HTML page unless
                // this header is present; inject it on every proxied request.
                'ngrok-skip-browser-warning': 'true',
              },
            },
          }
        : undefined,
    },
    test: {
      globals: true,
      environment: 'jsdom',
      setupFiles: './src/test/setup.ts',
      css: false,
    },
  }
})
