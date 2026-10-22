const TOAST_MS = 2600

class ToastStore {
  message = $state('')
  detail = $state('')
  id = $state(0)

  #timer = 0

  show(message: string, detail = '') {
    this.message = message
    this.detail = detail
    this.id += 1

    clearTimeout(this.#timer)
    this.#timer = window.setTimeout(() => this.clear(), TOAST_MS)
  }

  clear() {
    clearTimeout(this.#timer)
    this.message = ''
    this.detail = ''
  }
}

export const toast = new ToastStore()
