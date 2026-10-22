import type { ExportOptions, Tab } from '../lib/types'

const OPTIONS_KEY = 'poinstool:export'

function loadOptions(): ExportOptions {
  const fallback: ExportOptions = { vec4: false, radius: true, label: false, model: true, marker: false, blip: false }

  try {
    const raw = JSON.parse(localStorage.getItem(OPTIONS_KEY) ?? 'null')
    if (!raw || typeof raw !== 'object') return fallback

    return {
      vec4: raw.vec4 === true,
      radius: raw.radius !== false,
      label: raw.label === true,
      model: raw.model !== false,
      marker: raw.marker === true,
      blip: raw.blip === true,
    }
  } catch {
    return fallback
  }
}

class PanelStore {
  open = $state(false)
  tab = $state<Tab>('list')
  options = $state<ExportOptions>(loadOptions())

  show() {
    this.open = true
  }

  hide() {
    this.open = false
  }

  setOption(key: keyof ExportOptions, value: boolean) {
    this.options[key] = value

    try {
      localStorage.setItem(OPTIONS_KEY, JSON.stringify(this.options))
    } catch {
      return
    }
  }
}

export const panel = new PanelStore()
