import type { BlipRule, Keys, MarkerRule, Point, Poly, PolyRule, RadiusRule, Vertex } from './types'

const finite = (value: unknown): value is number => typeof value === 'number' && Number.isFinite(value)

export const numberOf = (value: unknown, fallback = 0): number => (finite(value) ? value : fallback)

export const textOf = (value: unknown, fallback = ''): string => (typeof value === 'string' ? value : fallback)

const flagOf = (value: unknown): boolean => value === true

const DEFAULT_SIZE = [1.5, 1.5, 0.5]
const DEFAULT_TINT = [255, 255, 255, 90]

function numbersOf(value: unknown, fallback: number[]): number[] {
  if (!Array.isArray(value) || value.length !== fallback.length || !value.every(finite)) return [...fallback]

  return [...value]
}

export function pointOf(value: unknown): Point | null {
  if (!value || typeof value !== 'object') return null

  const raw = value as Record<string, unknown>
  if (!finite(raw.x) || !finite(raw.y) || !finite(raw.z)) return null

  return {
    x: raw.x,
    y: raw.y,
    z: raw.z,
    h: numberOf(raw.h),
    r: numberOf(raw.r, 1),
    label: textOf(raw.label),
    model: textOf(raw.model),
    blip: flagOf(raw.blip),
    sprite: numberOf(raw.sprite, 1),
    color: numberOf(raw.color),
    scale: numberOf(raw.scale, 0.8),
    area: flagOf(raw.area),
    size: numbersOf(raw.size, DEFAULT_SIZE),
    tint: numbersOf(raw.tint, DEFAULT_TINT),
  }
}

const DEFAULT_POLY_COLOR = [255, 42, 24, 90]

function vertexOf(value: unknown): Vertex | null {
  if (!value || typeof value !== 'object') return null

  const raw = value as Record<string, unknown>
  if (!finite(raw.x) || !finite(raw.y) || !finite(raw.z)) return null

  return { x: raw.x, y: raw.y, z: raw.z }
}

export function polyOf(value: unknown): Poly | null {
  if (!value || typeof value !== 'object') return null

  const raw = value as Record<string, unknown>
  const vertices: Vertex[] = []

  if (Array.isArray(raw.points)) {
    for (const item of raw.points) {
      const vertex = vertexOf(item)
      if (vertex) vertices.push(vertex)
    }
  }

  return {
    label: textOf(raw.label),
    thickness: numberOf(raw.thickness, 4),
    color: numbersOf(raw.color, DEFAULT_POLY_COLOR),
    points: vertices,
  }
}

export function polysOf(value: unknown): Poly[] {
  if (!Array.isArray(value)) return []

  const list: Poly[] = []

  for (const item of value) {
    const poly = polyOf(item)
    if (poly) list.push(poly)
  }

  return list
}

export function polyRuleOf(value: Partial<PolyRule> | undefined, current: PolyRule): PolyRule {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return current

  return {
    thicknessMin: numberOf(value.thicknessMin, current.thicknessMin),
    thicknessMax: numberOf(value.thicknessMax, current.thicknessMax),
    limit: numberOf(value.limit, current.limit),
    vertices: numberOf(value.vertices, current.vertices),
  }
}

export function markerRuleOf(value: Partial<MarkerRule> | undefined, current: MarkerRule): MarkerRule {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return current

  return {
    sizeMin: numberOf(value.sizeMin, current.sizeMin),
    sizeMax: numberOf(value.sizeMax, current.sizeMax),
  }
}

export function blipRuleOf(value: Partial<BlipRule> | undefined, current: BlipRule): BlipRule {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return current

  return {
    spriteMax: numberOf(value.spriteMax, current.spriteMax),
    colorMax: numberOf(value.colorMax, current.colorMax),
    scaleMin: numberOf(value.scaleMin, current.scaleMin),
    scaleMax: numberOf(value.scaleMax, current.scaleMax),
  }
}

export function pointsOf(value: unknown): Point[] {
  if (!Array.isArray(value)) return []

  const list: Point[] = []

  for (const item of value) {
    const point = pointOf(item)
    if (point) list.push(point)
  }

  return list
}

export function keysOf(value: Partial<Keys> | undefined, current: Keys): Keys {
  if (!value || typeof value !== 'object') return current

  return {
    add: textOf(value.add, current.add),
    menu: textOf(value.menu, current.menu),
    place: textOf(value.place, current.place),
    undo: textOf(value.undo, current.undo),
  }
}

export function radiusOf(value: Partial<RadiusRule> | undefined, current: RadiusRule): RadiusRule {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return current

  return {
    default: numberOf(value.default, current.default),
    min: numberOf(value.min, current.min),
    max: numberOf(value.max, current.max),
    step: numberOf(value.step, current.step),
  }
}
