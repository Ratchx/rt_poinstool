import { config } from '../stores/config.svelte'
import { panel } from '../stores/panel.svelte'
import { polys } from '../stores/polys.svelte'
import { toast } from '../stores/toast.svelte'
import { request } from './api'
import type { Poly, Tab, Vertex } from './types'
import { polyOf } from './wire'

const UPDATE_DELAY = 40

const pendingPolys = new Set<Poly>()
const pendingVertices = new Map<Vertex, Poly>()
let updateTimer = 0

interface Created {
  index?: number
  poly?: unknown
}

export function flushPolys() {
  clearTimeout(updateTimer)
  updateTimer = 0

  for (const poly of pendingPolys) {
    const index = polys.list.indexOf(poly) + 1
    if (index === 0) continue

    request('polyUpdate', { index, label: poly.label, thickness: poly.thickness, color: [...poly.color] })
  }

  for (const [vertex, poly] of pendingVertices) {
    const index = polys.list.indexOf(poly) + 1
    const at = index > 0 ? poly.points.indexOf(vertex) + 1 : 0
    if (at === 0) continue

    request('vertexUpdate', { index, vertex: at, x: vertex.x, y: vertex.y, z: vertex.z })
  }

  pendingPolys.clear()
  pendingVertices.clear()
}

function schedule() {
  if (updateTimer) return

  updateTimer = window.setTimeout(flushPolys, UPDATE_DELAY)
}

export function queuePoly(poly: Poly) {
  pendingPolys.add(poly)
  schedule()
}

export function queueVertex(poly: Poly, vertex: Vertex) {
  pendingVertices.set(vertex, poly)
  schedule()
}

export function syncTarget() {
  const onPoly = panel.tab === 'poly'

  request('polySelect', { index: onPoly ? polys.selected : 0, vertex: onPoly ? polys.vertex : 0 })
}

export function setTab(tab: Tab) {
  panel.tab = tab
  syncTarget()
}

export function selectPoly(index: number) {
  polys.selected = index
  polys.vertex = 0
  syncTarget()
}

export function togglePoly(index: number) {
  selectPoly(polys.selected === index ? 0 : index)
}

export function selectVertex(vertex: number) {
  polys.vertex = polys.vertex === vertex ? 0 : vertex
  syncTarget()
}

export async function createPoly() {
  flushPolys()

  const result = await request<Created | number>('polyCreate')
  const created = result && typeof result === 'object' ? result : null
  const poly = created ? polyOf(created.poly) : null
  const index = Number(created?.index) || 0

  if (!poly || index < 1) return toast.show(config.t('poly_full', config.poly.limit))

  polys.upsert(index, poly)
  selectPoly(index)
}

export async function removePoly(index: number) {
  flushPolys()

  const name = polys.nameOf(index)
  const result = await request<number>('polyRemove', { index })
  if (result !== 1) return toast.show(config.t('failed'))

  polys.removeAt(index)
  toast.show(config.t('poly_removed', name))
}

export async function removeVertex(index: number, vertex: number) {
  flushPolys()

  const result = await request<number>('vertexRemove', { index, vertex })
  if (result !== 1) return toast.show(config.t('failed'))

  polys.removeVertex(index, vertex)
  syncTarget()
}

export async function flattenPoly(index: number) {
  flushPolys()

  const poly = polyOf(await request('polyFlatten', { index }))
  if (!poly) return toast.show(config.t('failed'))

  polys.upsert(index, poly)
  toast.show(config.t('flattened', polys.nameOf(index)))
}

export function placeInto(index: number) {
  flushPolys()
  request('place', { index })
}
