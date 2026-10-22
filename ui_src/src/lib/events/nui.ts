import { config } from '../../stores/config.svelte'
import { panel } from '../../stores/panel.svelte'
import { points } from '../../stores/points.svelte'
import { toast } from '../../stores/toast.svelte'
import { flushUpdates } from '../api'
import { indexLabel, vec3Of } from '../format'
import type { AddPayload, Bootstrap, OpenPayload } from '../types'
import { fetchNui } from '../utils/fetchNui'
import { numberOf, pointOf, pointsOf } from '../wire'

const handlers: Record<string, (payload: never) => void> = {
  hydrate: (payload: Bootstrap) => {
    const data = payload ?? {}

    config.apply(data)
    points.load(pointsOf(data.points))
    if (typeof data.visible === 'boolean') points.visible = data.visible
  },

  open: (payload: OpenPayload) => {
    config.setKeys(payload?.keys)
    toast.clear()
    panel.show()
  },

  close: () => {
    flushUpdates()
    panel.hide()
  },

  add: (payload: AddPayload) => {
    const point = pointOf(payload?.point)
    const index = numberOf(payload?.index)
    if (!point || index < 1) return

    config.setKeys(payload.keys)
    points.append(index, point)
    toast.show(config.t('added', indexLabel(index)), vec3Of(point, config.precision))
  },

  full: () => {
    toast.show(config.t('full', config.limit))
  },

  visible: (payload: boolean) => {
    points.visible = payload === true
  },
}

export function initNui() {
  const listener = (event: MessageEvent) => {
    const { action, payload } = (event.data ?? {}) as { action?: string; payload?: never }
    if (!action) return

    handlers[action]?.(payload as never)
  }

  window.addEventListener('message', listener)
  fetchNui('uiReady')

  return () => window.removeEventListener('message', listener)
}
