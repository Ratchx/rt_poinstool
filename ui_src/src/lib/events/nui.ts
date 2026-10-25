import { config } from '../../stores/config.svelte'
import { panel } from '../../stores/panel.svelte'
import { points } from '../../stores/points.svelte'
import { polys } from '../../stores/polys.svelte'
import { toast } from '../../stores/toast.svelte'
import { flushUpdates } from '../api'
import { flushPolys } from '../polyApi'
import { indexLabel, vec3Of } from '../format'
import type { AddPayload, Bootstrap, OpenPayload, PlacePayload, PolyPayload, RemovedPayload, ToastPayload } from '../types'
import { fetchNui } from '../utils/fetchNui'
import { numberOf, pointOf, pointsOf, polyOf, polysOf } from '../wire'

const handlers: Record<string, (payload: never) => void> = {
  hydrate: (payload: Bootstrap) => {
    const data = payload ?? {}

    config.apply(data)
    points.load(pointsOf(data.points))
    polys.load(polysOf(data.polys))
    if (typeof data.visible === 'boolean') points.visible = data.visible
  },

  open: (payload: OpenPayload) => {
    config.setKeys(payload?.keys)
    toast.clear()
    panel.show()
  },

  close: () => {
    flushUpdates()
    flushPolys()
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

  place: (payload: PlacePayload) => {
    config.setKeys(payload?.keys)
    polys.placing = payload?.active === true
    polys.target = numberOf(payload?.target)
  },

  poly: (payload: PolyPayload) => {
    const poly = polyOf(payload?.poly)
    const index = numberOf(payload?.index)
    if (!poly || index < 1) return

    polys.upsert(index, poly)

    const added = numberOf(payload.added)
    if (added > 0) toast.show(config.t('vertex_added', added, polys.nameOf(index)))
  },

  removed: (payload: RemovedPayload) => {
    const indexes = Array.isArray(payload?.indexes) ? payload.indexes.filter((index): index is number => typeof index === 'number') : []
    if (indexes.length > 0) points.removeMany(indexes)
  },

  toast: (payload: ToastPayload) => {
    if (typeof payload?.key !== 'string') return

    const args = Array.isArray(payload.args) ? payload.args.filter((arg): arg is string | number => typeof arg === 'string' || typeof arg === 'number') : []
    toast.show(config.t(payload.key, ...args))
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
