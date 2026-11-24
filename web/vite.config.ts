import { defineConfig, loadEnv, type PreviewServer, type ViteDevServer } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { VitePWA } from 'vite-plugin-pwa'
import { fileURLToPath } from 'node:url'

function forcarCharset(server: ViteDevServer | PreviewServer) {
  server.middlewares.use((_req, res, next) => {
    const original = res.setHeader.bind(res)
    res.setHeader = ((name: string, value: string | number | readonly string[]) => {
      if (
        name.toLowerCase() === 'content-type' &&
        typeof value === 'string' &&
        value.toLowerCase().startsWith('text/html') &&
        !/charset=/i.test(value)
      ) {
        value = `${value}; charset=utf-8`
      }
      return original(name, value)
    }) as typeof res.setHeader
    next()
  })
}

export default defineConfig(({ mode }) => {
  const target = loadEnv(mode, process.cwd(), '').VITE_SUPABASE_URL || 'https://egqgskjjointbgkncjtf.supabase.co'
  const proxy = {
    '/functions/v1': {
      target,
      changeOrigin: true,
      secure: true,
    },
  }

  return {
    plugins: [
      react(),
      tailwindcss(),
      {
        name: 'charset-html',
        configureServer: forcarCharset,
        configurePreviewServer: forcarCharset,
      },
      VitePWA({
        registerType: 'autoUpdate',
        includeAssets: ['favicon.ico', 'icons/*.png'],
        manifest: {
          name: 'VozUL',
          short_name: 'VozUL',
          description: 'Canal de Denúncia Anónima - Universidade Licungo',
          theme_color: '#1b5e20',
          background_color: '#ffffff',
          display: 'standalone',
          start_url: '/',
          icons: [
            { src: '/icons/icon-192.png', sizes: '192x192', type: 'image/png' },
            { src: '/icons/icon-512.png', sizes: '512x512', type: 'image/png' },
          ],
        },
      }),
    ],
    server: {
      port: 5174,
      strictPort: true,
      proxy,
    },
    preview: {
      port: 5174,
      strictPort: true,
      proxy,
    },
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url)),
      },
    },
  }
})
