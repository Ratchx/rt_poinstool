import type { Poly } from '../lib/types'
import { config } from './config.svelte'

class PolysStore {
  list = $state<Poly[]>([])
  selected = $state(0)
  vertex = $state(0)
  placing = $state(false)
  target = $state(0)

  count = $derived(this.list.length)
  current = $derived(this.selected > 0 ? (this.list[this.selected - 1] ?? null) : null)

  load(list: Poly[]) {
    this.list = list
    if (this.selected > list.length) this.selected = 0
    this.vertex = 0
  }

  upsert(index: number, poly: Poly) {
    if (index > this.list.length) {
      this.list.push(poly)
      return
    }

    this.list[index - 1] = poly
    if (index === this.selected && this.vertex > poly.points.length) this.vertex = 0
  }

  removeAt(index: number) {
    this.list.splice(index - 1, 1)

    if (this.selected === index) {
      this.selected = 0
      this.vertex = 0
    } else if (this.selected > index) {
      this.selected -= 1
    }

    if (this.target === index) this.target = 0
    else if (this.target > index) this.target -= 1
  }

  removeVertex(index: number, vertex: number) {
    const poly = this.list[index - 1]
    if (!poly) return

    poly.points.splice(vertex - 1, 1)

    if (this.selected !== index) return

    if (this.vertex === vertex) this.vertex = 0
    else if (this.vertex > vertex) this.vertex -= 1
  }

  nameOf(index: number): string {
    return this.list[index - 1]?.label || config.t('poly_name', index)
  }
}

export const polys = new PolysStore()
