import { SvelteSet } from 'svelte/reactivity'
import type { Point } from '../lib/types'

class PointsStore {
  list = $state<Point[]>([])
  selected = $state(0)
  visible = $state(true)
  checked = new SvelteSet<number>()
  anchor = 0

  count = $derived(this.list.length)
  current = $derived(this.selected > 0 ? (this.list[this.selected - 1] ?? null) : null)
  checkedCount = $derived(this.checked.size)

  load(list: Point[]) {
    this.list = list
    if (this.selected > list.length) this.selected = 0
    this.uncheckAll()
  }

  append(index: number, point: Point) {
    if (index > this.list.length) {
      this.list.push(point)
      return
    }

    this.list[index - 1] = point
  }

  replace(index: number, point: Point) {
    this.list[index - 1] = point
  }

  toggleCheck(index: number) {
    if (this.checked.has(index)) this.checked.delete(index)
    else this.checked.add(index)

    this.anchor = index
  }

  checkRange(index: number) {
    const from = Math.min(this.anchor || index, index)
    const to = Math.max(this.anchor || index, index)

    for (let i = from; i <= to; i++) this.checked.add(i)

    this.anchor = index
  }

  checkAll() {
    for (let i = 1; i <= this.list.length; i++) this.checked.add(i)
  }

  uncheckAll() {
    this.checked.clear()
    this.anchor = 0
  }

  removeMany(indexes: number[]) {
    const removed = new Set(indexes)

    this.list = this.list.filter((_, i) => !removed.has(i + 1))

    if (removed.has(this.selected)) this.selected = 0
    else this.selected -= indexes.filter((index) => index < this.selected).length

    this.uncheckAll()
  }

  clear() {
    this.list = []
    this.selected = 0
    this.uncheckAll()
  }
}

export const points = new PointsStore()
