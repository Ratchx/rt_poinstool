import { mount } from 'svelte'
import './app.css'
import App from './App.svelte'
import { initNui } from './lib/events/nui'
import { inNui } from './lib/utils/fetchNui'

const BENIGN_ERROR = /^ResizeObserver loop/

window.addEventListener('error', (event) => {
  if (!BENIGN_ERROR.test(event.message)) return

  event.preventDefault()
  event.stopImmediatePropagation()
})

initNui()

if (import.meta.env.DEV && !inNui) {
  document.body.classList.add('standalone')

  import('./lib/mock').then(({ MOCK_POINTS, mockAdd }) => {
    const post = (action: string, payload?: unknown) => window.postMessage({ action, payload }, '*')
    const typing = () => document.activeElement instanceof HTMLInputElement || document.activeElement instanceof HTMLTextAreaElement

    post('hydrate', {
      scale: 1,
      keys: { add: 'J', menu: 'F7' },
      precision: 2,
      radius: { default: 2, min: 0.1, max: 100, step: 0.1 },
      limit: 300,
      labelLength: 32,
      visible: true,
      points: MOCK_POINTS,
    })

    window.addEventListener('keyup', (event) => {
      if (typing()) return

      if (event.code === 'KeyJ') mockAdd(2)
      if (event.code === 'Backquote') post('open', { keys: { add: 'J', menu: 'F7' } })
      if (event.code === 'Digit9') post('full')
      if (event.code === 'Digit0') post('hydrate', { points: [] })
    })
  })
}

const app = mount(App, {
  target: document.getElementById('app')!,
})

export default app
