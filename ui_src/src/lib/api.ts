import { config } from '../stores/config.svelte'
import { panel } from '../stores/panel.svelte'
import { points } from '../stores/points.svelte'
import { toast } from '../stores/toast.svelte'
import { indexLabel } from './format'
import type { Point } from './types'
import { copyText } from './utils/clipboard'
import { fetchNui, inNui } from './utils/fetchNui'
import { pointOf } from './wire'

const UPDATE_DELAY = 40

const pending = new Set<Point>()
let updateTimer = 0

export async function request<T>(event: string, data?: object): Promise<T | null> {
  if (inNui) return fetchNui<T>(event, data)
  if (!import.meta.env.DEV) return null

  const { mockCall } = await import('./mock')

  return (await mockCall(event, data as Record<string, unknown>)) as T
}

export function flushUpdates() {
  clearTimeout(updateTimer)
  updateTimer = 0

  for (const point of pending) {
    const index = points.list.indexOf(point) + 1
    if (index === 0) continue

    request('update', {
      index,
      x: point.x,
      y: point.y,
      z: point.z,
      h: point.h,
      r: point.r,
      label: point.label,
      blip: point.blip,
      sprite: point.sprite,
      color: point.color,
      scale: point.scale,
      area: point.area,
      size: [...point.size],
      tint: [...point.tint],
    })
  }

  pending.clear()
}

export function queueUpdate(point: Point) {
  pending.add(point)
  if (updateTimer) return

  updateTimer = window.setTimeout(flushUpdates, UPDATE_DELAY)
}

export function close() {
  flushUpdates()
  panel.hide()
  request('close')
}

export function select(index: number) {
  points.selected = points.selected === index ? 0 : index
  request('select', { index: points.selected })
}

export function setVisible(value: boolean) {
  points.visible = value
  request('visible', { value })
}

export async function remove(index: number) {
  flushUpdates()

  const result = await request<number>('remove', { index })
  if (result !== 1) return toast.show(config.t('failed'))

  points.removeAt(index)
  toast.show(config.t('removed', indexLabel(index)))
}

export async function clearAll() {
  flushUpdates()

  const result = await request<number>('clear')
  if (result !== 1) return toast.show(config.t('failed'))

  points.clear()
  toast.show(config.t('cleared'))
}

export async function moveHere(index: number) {
  flushUpdates()

  const point = pointOf(await request('here', { index }))
  if (!point) return toast.show(config.t('failed'))

  points.replace(index, point)
  toast.show(config.t('moved', indexLabel(index)))
}

export async function setModel(index: number, model: string): Promise<boolean> {
  flushUpdates()

  const result = await request<number>('model', { index, model })
  const point = points.list[index - 1]

  if (result !== 1 || !point) {
    toast.show(config.t('prop_invalid', model))
    return false
  }

  point.model = model
  toast.show(model === '' ? config.t('prop_removed', indexLabel(index)) : config.t('prop_set', model, indexLabel(index)))

  return true
}

export async function snapGround(index: number) {
  flushUpdates()

  const point = pointOf(await request('ground', { index }))
  if (!point) return toast.show(config.t('ground_failed'))

  points.replace(index, point)
  toast.show(config.t('grounded', indexLabel(index)))
}

export function teleport(index: number) {
  flushUpdates()
  request('teleport', { index })
}

export function copy(text: string, message: string) {
  toast.show(copyText(text) ? message : config.t('failed'))
}
