import { svelte } from '@sveltejs/vite-plugin-svelte'
import { defineConfig } from 'vite'

export default defineConfig({
  base: './',
  plugins: [svelte()],
  server: {
    port: Number(process.env.PORT) || 5249,
    strictPort: true,
  },
  build: {
    outDir: '../web/build',
    emptyOutDir: true,
    target: 'chrome108',
    assetsInlineLimit: 0,
    rollupOptions: {
      output: {
        entryFileNames: 'assets/[name].js',
        chunkFileNames: 'assets/[name].js',
        assetFileNames: 'assets/[name][extname]',
        minify: { compress: { dropConsole: true } },
      },
    },
  },
})
