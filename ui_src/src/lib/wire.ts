import type { BlipRule, Keys, Point, RadiusRule } from './types'

const finite = (value: unknown): value is number => typeof value === 'number' && Number.isFinite(value)

export const numberOf = (value: unknown, fallback = 0): number => (finite(value) ? value : fallback)

export const textOf = (value: unknown, fallback = ''): string => (typeof value === 'string' ? value : fallback)

const flagOf = (value: unknown): boolean => value === true

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
