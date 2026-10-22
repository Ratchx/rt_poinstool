export interface Point {
  x: number
  y: number
  z: number
  h: number
  r: number
  label: string
  model: string
  blip: boolean
  sprite: number
  color: number
  scale: number
  area: boolean
}

export interface BlipRule {
  spriteMax: number
  colorMax: number
  scaleMin: number
  scaleMax: number
}

export interface Keys {
  add: string
  menu: string
}

export interface RadiusRule {
  default: number
  min: number
  max: number
  step: number
}

export interface Bootstrap {
  scale?: number
  locale?: Record<string, string> | unknown[]
  keys?: Partial<Keys>
  precision?: number
  radius?: Partial<RadiusRule>
  limit?: number
  labelLength?: number
  modelLength?: number
  blip?: Partial<BlipRule>
  visible?: boolean
  points?: unknown
}

export interface OpenPayload {
  keys?: Partial<Keys>
}

export interface AddPayload {
  index?: number
  point?: unknown
  keys?: Partial<Keys>
}

export interface ExportOptions {
  vec4: boolean
  radius: boolean
  label: boolean
  model: boolean
  blip: boolean
}

export type Tab = 'list' | 'export'
