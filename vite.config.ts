import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueJsx from '@vitejs/plugin-vue-jsx'
import vueDevTools from 'vite-plugin-vue-devtools'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig(() => {
  return {
    plugins: [
      vue(),
      vueJsx(),
      vueDevTools(),
      tailwindcss()
    ],

    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url))
      },
    },

    // Allow all hosts in dev and preview (production preview)
    server: {
      host: true,
      allowedHosts: true
    },
    preview: {
      host: true,
      allowedHosts: true
    },
  };
});
