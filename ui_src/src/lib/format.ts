import type { ExportOptions, Point, Poly } from './types'

const INDENT = '    '

export function fmt(template: string, ...args: (string | number)[]): string {
  let index = 0

  return template.replace(/%s/g, () => String(args[index++] ?? ''))
}

export function fixed(value: number, digits: number): string {
  const unit = 0.5 / 10 ** digits

  return (Math.abs(value) < unit ? 0 : value).toFixed(digits)
}

export function roundTo(value: number, digits: number): number {
  const scale = 10 ** digits

  return Math.round(value * scale) / scale
}

export function vec3Of(point: Point, digits: number): string {
  return `vec3(${fixed(point.x, digits)}, ${fixed(point.y, digits)}, ${fixed(point.z, digits)})`
}

export function vec4Of(point: Point, digits: number): string {
  return `vec4(${fixed(point.x, digits)}, ${fixed(point.y, digits)}, ${fixed(point.z, digits)}, ${fixed(point.h, digits)})`
}

const escapeLua = (text: string) => text.replace(/\\/g, '\\\\').replace(/'/g, "\\'")

export function blipOf(point: Point, digits: number): string {
  const fields: string[] = []

  if (point.blip) fields.push(`sprite = ${point.sprite}`)
  fields.push(`color = ${point.color}`)
  if (point.blip) fields.push(`scale = ${fixed(point.scale, digits)}`)
  if (point.area) fields.push('area = true')

  return `{ ${fields.join(', ')} }`
}

export function markerOf(point: Point, digits: number): string {
  const [x, y, z] = point.size

  return `{ size = vec3(${fixed(x, digits)}, ${fixed(y, digits)}, ${fixed(z, digits)}), color = { ${point.tint.join(', ')} } }`
}

export function lineOf(point: Point, options: ExportOptions, digits: number): string {
  const vector = options.vec4 ? vec4Of(point, digits) : vec3Of(point, digits)
  const head: string[] = []
  const tail: string[] = []

  if (options.label && point.label !== '') head.push(`label = '${escapeLua(point.label)}'`)
  if (options.radius) tail.push(`radius = ${fixed(point.r, digits)}`)
  if (options.marker) tail.push(`marker = ${markerOf(point, digits)}`)
  if (options.model && point.model !== '') tail.push(`model = \`${point.model}\``)
  if (options.blip && (point.blip || point.area)) tail.push(`blip = ${blipOf(point, digits)}`)

  if (head.length === 0 && tail.length === 0) return `${INDENT}${vector},`

  return `${INDENT}{ ${[...head, `coords = ${vector}`, ...tail].join(', ')} },`
}

export function exportOf(points: Point[], options: ExportOptions, digits: number): string {
  return points.map((point) => lineOf(point, options, digits)).join('\n')
}

export function polyBlockOf(poly: Poly, digits: number, withLabel: boolean): string {
  const inner = INDENT.repeat(2)
  const lines = [`${INDENT}{`]

  if (withLabel && poly.label !== '') lines.push(`${inner}label = '${escapeLua(poly.label)}',`)
  lines.push(`${inner}points = {`)

  for (const vertex of poly.points) {
    lines.push(`${INDENT.repeat(3)}vec3(${fixed(vertex.x, digits)}, ${fixed(vertex.y, digits)}, ${fixed(vertex.z, digits)}),`)
  }

  lines.push(`${inner}},`, `${inner}thickness = ${fixed(poly.thickness, digits)},`, `${INDENT}},`)

  return lines.join('\n')
}

export function exportPolysOf(list: Poly[], digits: number, withLabel: boolean): string {
  return list
    .filter((poly) => poly.points.length > 0)
    .map((poly) => polyBlockOf(poly, digits, withLabel))
    .join('\n')
}

export function indexLabel(index: number): string {
  return `#${index}`
}

export function logPosition(value: number, min: number, max: number): number {
  const safe = Math.min(Math.max(value, min), max)

  return Math.log(safe / min) / Math.log(max / min)
}

export function logValue(position: number, min: number, max: number): number {
  return min * (max / min) ** Math.min(Math.max(position, 0), 1)
}
