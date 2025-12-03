<script setup lang="ts">
import { ref } from 'vue'

const MAX_PASSWORD_LENGTH = 1024
const REQUEST_TIMEOUT = 10000
const DEBOUNCE_DELAY = 500
const MIN_REQUEST_INTERVAL = 5000
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000'

const password = ref('')
const breachResult = ref<{ pwned: boolean; count: number } | null>(null)
const loading = ref(false)
const error = ref<string | null>(null)

let lastRequestTime = 0
let debounceTimer: ReturnType<typeof setTimeout> | null = null
let abortController: AbortController | null = null

const sanitizeInput = (input: string): string => {
  let sanitized = input.trim()
  
  if (sanitized.length > MAX_PASSWORD_LENGTH) {
    sanitized = sanitized.substring(0, MAX_PASSWORD_LENGTH)
  }
  
  return sanitized
}

const canMakeRequest = (): boolean => {
  const now = Date.now()
  const timeSinceLastRequest = now - lastRequestTime
  return timeSinceLastRequest >= MIN_REQUEST_INTERVAL
}

const checkPasswordDebounced = () => {
  if (debounceTimer) {
    clearTimeout(debounceTimer)
  }

  debounceTimer = setTimeout(() => {
    checkPassword()
  }, DEBOUNCE_DELAY)
}

const checkPassword = async () => {
  if (!password.value) {
    error.value = null
    breachResult.value = null
    return
  }

  if (!canMakeRequest()) {
    error.value = 'Por favor, aguarde antes de fazer outra verificação.'
    return
  }

  const sanitizedPassword = sanitizeInput(password.value)
  
  if (!sanitizedPassword) {
    error.value = 'Por favor, insira uma senha válida.'
    return
  }

  if (abortController) {
    abortController.abort()
  }

  abortController = new AbortController()
  const timeoutId = setTimeout(() => abortController?.abort(), REQUEST_TIMEOUT)

  loading.value = true
  breachResult.value = null
  error.value = null
  lastRequestTime = Date.now()

  try {
    const response = await fetch(`${API_URL}/hibp/password`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ password: sanitizedPassword }),
      signal: abortController.signal,
    })

    clearTimeout(timeoutId)

    if (response.ok) {
      const data = await response.json()
      
      if (typeof data.pwned === 'boolean' && typeof data.count === 'number') {
        breachResult.value = data
      } else {
        throw new Error('Invalid response format')
      }
    } else if (response.status === 429) {
      error.value = 'Muitas requisições. Por favor, tente novamente mais tarde.'
    } else {
      error.value = 'Erro ao verificar a senha. Tente novamente.'
    }
  } catch (err) {
    clearTimeout(timeoutId)
    
    if (err instanceof Error) {
      if (err.name === 'AbortError') {
        error.value = 'A requisição demorou muito. Tente novamente.'
      } else {
        error.value = 'Erro de conexão. Verifique se o servidor está rodando.'
      }
    } else {
      error.value = 'Erro desconhecido. Tente novamente.'
    }
  } finally {
    loading.value = false
    abortController = null
  }
}
</script>

<template>
  <div class="min-h-screen bg-gray-50 flex flex-col items-center">
    <header
      class="w-full bg-linear-to-r from-green-600 to-green-700 px-6 sm:px-10 py-6 flex justify-start items-center shadow-2xl shadow-green-800/40"
    >
      <h1
        class="text-4xl sm:text-5xl font-extrabold text-white tracking-wider animate-fade-in-down title-font"
      >
        Minha Senha Vazou?
      </h1>
    </header>
    a

    <main class="flex grow w-full justify-center items-center px-4 py-12">
      <div
        class="flex flex-col gap-5 w-full max-w-lg p-8 sm:p-10 bg-white rounded-3xl shadow-2xl shadow-green-900/10 border border-gray-100 backdrop-blur-sm animate-fade-in"
      >
        <div class="text-xl sm:text-2xl font-medium text-gray-700 mb-8 text-center">
          Verifique se seu email ou senha foi vazado na internet
        </div>

        <input
          v-model="password"
          type="text"
          placeholder="Digite seu email ou senha..."
          class="w-full px-5 py-4 rounded-xl border-2 border-green-300 bg-white text-gray-800 text-lg sm:text-xl transition-all duration-300 focus:outline-none focus:ring-4 focus:ring-green-100 focus:border-green-600 shadow-inner hover:border-green-400"
          @keyup.enter="checkPassword"
        />

        <button
          @click="checkPassword"
          :disabled="loading"
          class="mt-6 w-full px-8 py-4 bg-green-600 text-white rounded-xl text-xl sm:text-2xl font-bold tracking-wide hover:bg-green-700 hover:shadow-green-900/40 active:scale-[0.98] transition-all duration-300 shadow-lg shadow-green-900/30 transform hover:-translate-y-0.5 disabled:opacity-70 disabled:cursor-not-allowed"
        >
          {{ loading ? 'Verificando...' : 'Verificar' }}
        </button>

        <!-- Error message -->
        <div v-if="error" class="mt-4 p-4 rounded-xl text-center animate-fade-in">
          <div class="text-orange-600 bg-orange-50 border border-orange-200 p-4 rounded-lg">
            <p class="text-lg font-semibold">{{ error }}</p>
          </div>
        </div>

        <!-- Results -->
        <div v-if="breachResult" class="mt-6 p-4 rounded-xl text-center animate-fade-in">
          <div v-if="breachResult.pwned" class="text-red-600 bg-red-50 border border-red-200 p-4 rounded-lg">
            <p class="text-xl font-bold mb-2">⚠️ Atenção!</p>
            <p>Esta senha apareceu em <strong>{{ breachResult.count.toLocaleString() }}</strong> vazamentos de dados.</p>
            <p class="mt-2 text-sm">Recomendamos não utilizar esta senha.</p>
          </div>
          <div v-else class="text-green-700 bg-green-50 border border-green-200 p-4 rounded-lg">
            <p class="text-xl font-bold mb-2">✅ Boas notícias!</p>
            <p>Esta senha não foi encontrada em nenhum vazamento de dados conhecido.</p>
          </div>
        </div>
      </div>
    </main>

    <footer
      class="fixed bottom-4 right-4 flex flex-col items-start gap-3 p-4 rounded-2xl bg-white/90 backdrop-blur-md shadow-xl border border-gray-200 transition-all hover:bg-white"
    >
      <div class="text-xl font-semibold text-gray-700">Desenvolvido por:</div>

      <div class="flex gap-4">
        <!-- Joaquim -->
        <a
          href="https://www.linkedin.com/in/joa-aquim-maia-592355356/"
          target="_blank"
          rel="noopener noreferrer"
          class="flex items-center gap-2 group"
        >
          <div
            class="w-10 h-10 flex items-center justify-center rounded-xl bg-green-600 text-white shadow-md transition-all duration-300 group-hover:bg-green-700 group-hover:scale-[1.07]"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="w-6 h-6 fill-current"
              viewBox="0 0 24 24"
            >
              <path
                d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.535-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z"
              />
            </svg>
          </div>
          <span
            class="hidden sm:block text-sm font-medium text-gray-700 group-hover:text-green-700"
          >
            Joaquim
          </span>
        </a>

        <!-- Guilherme -->
        <a
          href="https://www.linkedin.com/in/guilhermemataveli/"
          target="_blank"
          rel="noopener noreferrer"
          class="flex items-center gap-2 group"
        >
          <div
            class="w-10 h-10 flex items-center justify-center rounded-xl bg-green-600 text-white shadow-md transition-all duration-300 group-hover:bg-green-700 group-hover:scale-[1.07]"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="w-6 h-6 fill-current"
              viewBox="0 0 24 24"
            >
              <path
                d="M19 0h-14c-2.761 0-5 2.239-5 5v14c0 2.761 2.239 5 5 5h14c2.762 0 5-2.239 5-5v-14c0-2.761-2.238-5-5-5zm-11 19h-3v-11h3v11zm-1.5-12.268c-.966 0-1.75-.79-1.75-1.764s.784-1.764 1.75-1.764 1.75.79 1.75 1.764-.783 1.764-1.75 1.764zm13.5 12.268h-3v-5.604c0-3.368-4-3.535-4 0v5.604h-3v-11h3v1.765c1.396-2.586 7-2.777 7 2.476v6.759z"
              />
            </svg>
          </div>
          <span
            class="hidden sm:block text-sm font-medium text-gray-700 group-hover:text-green-700"
          >
            Guilherme
          </span>
        </a>
      </div>
    </footer>
  </div>
</template>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Shadows+Into+Light&display=swap');
.title-font {
  font-family: 'Shadows Into Light', cursive;
}

@import url('https://fonts.googleapis.com/css2?family=Roboto:ital,wght@0,100..900;1,100..900&display=swap');
input {
  font-family: 'Roboto', sans-serif;
}

.animate-fade-in {
  animation: fadeIn 0.8s ease-out forwards;
  opacity: 0;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(10px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-in-down {
  animation: fadeInDown 0.6s ease-out forwards;
  opacity: 0;
}

@keyframes fadeInDown {
  from {
    opacity: 0;
    transform: translateY(-20px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}
</style>
