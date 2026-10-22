import type { Point } from '../lib/types'

class PointsStore {
  list = $state<Point[]>([])
  selected = $state(0)
  visible = $state(true)

  count = $derived(this.list.length)
  current = $derived(this.selected > 0 ? (this.list[this.selected - 1] ?? null) : null)

  load(list: Point[]) {
    this.list = list
    if (this.selected > list.length) this.selected = 0
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

  removeAt(index: number) {
    this.list.splice(index - 1, 1)

    if (this.selected === index) this.selected = 0
    else if (this.selected > index) this.selected -= 1
  }

  clear() {
    this.list = []
    this.selected = 0
  }
}

export const points = new PointsStore()
