import { points } from '../stores/points.svelte'
import { polys } from '../stores/polys.svelte'
import { roundTo } from './format'
import type { Point } from './types'

const ORIGIN = { x: 195.17, y: -933.77, z: 30.69 }
const SPREAD = 24
const BLIP_DEFAULT = { blip: false, sprite: 1, color: 0, scale: 0.8, area: false, size: [1.5, 1.5, 0.5], tint: [255, 255, 255, 90] }

const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms))

const post = (action: string, payload?: unknown) => window.postMessage({ action, payload }, '*')

export const MOCK_POINTS: Point[] = [
  { x: 195.17, y: -933.77, z: 30.69, h: 144.5, r: 2, label: 'จุดรับงาน', model: '', ...BLIP_DEFAULT, blip: true, sprite: 280, color: 5 },
  { x: 213.64, y: -924.41, z: 29.69, h: 238, r: 1.5, label: 'atm_legion', model: 'prop_atm_01', ...BLIP_DEFAULT },
  { x: 177.02, y: -952.18, z: 29.92, h: 0, r: 8, label: '', model: '', ...BLIP_DEFAULT },
  { x: 160.88, y: -987.3, z: 30.09, h: 321.25, r: 25, label: 'โซนรวมตัว', model: '', ...BLIP_DEFAULT, area: true, color: 1 },
  { x: 230.4, y: -879.66, z: 30.49, h: 90, r: 0.75, label: '', model: '', ...BLIP_DEFAULT },
]

function jitter(): Pick<Point, 'x' | 'y' | 'z' | 'h'> {
  return {
    x: roundTo(ORIGIN.x + (Math.random() - 0.5) * SPREAD * 2, 2),
    y: roundTo(ORIGIN.y + (Math.random() - 0.5) * SPREAD * 2, 2),
    z: roundTo(ORIGIN.z + Math.random() * 2, 2),
    h: roundTo(Math.random() * 360, 2),
  }
}

export function mockAdd(defaultRadius: number) {
  const index = points.count + 1

  post('add', { index, point: { ...jitter(), r: defaultRadius, label: '', model: '', ...BLIP_DEFAULT }, keys: { add: 'J', menu: 'F7' } })
}

export async function mockCall(event: string, data: Record<string, unknown> = {}): Promise<unknown> {
  await delay(event === 'update' ? 0 : 120)

  const current = points.list[Number(data.index) - 1]

  if (event === 'here') {
    if (!current) return 0

    return { ...current, ...jitter() }
  }

  if (event === 'ground') {
    if (!current) return 0

    return { ...current, z: roundTo(current.z - 0.98, 2) }
  }

  if (event === 'model') return typeof data.model === 'string' && !data.model.includes('bad') ? 1 : 0

  if (event === 'teleport') post('close')

  if (event === 'polyCreate') {
    return { index: polys.count + 1, poly: { label: '', thickness: 4, color: [255, 42, 24, 90], points: [] } }
  }

  if (event === 'polyFlatten') {
    const poly = polys.list[Number(data.index) - 1]
    if (!poly || poly.points.length === 0) return 0

    const z = roundTo(poly.points.reduce((sum, vertex) => sum + vertex.z, 0) / poly.points.length, 2)

    return { ...poly, points: poly.points.map((vertex) => ({ ...vertex, z })) }
  }

  if (event === 'place') {
    post('close')
    post('place', { active: true, target: Number(data.index) || 0 })
  }

  return 1
}
