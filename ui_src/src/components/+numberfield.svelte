<script lang="ts">
  import { fixed, roundTo } from '../lib/format'

  let {
    label,
    value,
    digits,
    step,
    min = -Infinity,
    max = Infinity,
    wrap = 0,
    wheel = 0,
    unit = '',
    onchange,
  }: {
    label: string
    value: number
    digits: number
    step: number
    min?: number
    max?: number
    wrap?: number
    wheel?: number
    unit?: string
    onchange: (value: number) => void
  } = $props()

  let focused = $state(false)
  let draft = $state('')

  const shown = $derived(focused ? draft : fixed(value, digits))

  function normalize(next: number): number {
    const wrapped = wrap > 0 ? ((next % wrap) + wrap) % wrap : next
    const rounded = roundTo(Math.min(Math.max(wrapped, min), max), digits)

    return wrap > 0 && rounded >= wrap ? 0 : rounded
  }

  function commit(next: number) {
    const normal = normalize(next)
    if (normal !== value) onchange(normal)
  }

  function oninput(event: Event & { currentTarget: HTMLInputElement }) {
    draft = event.currentTarget.value

    const parsed = Number.parseFloat(draft)
    if (Number.isFinite(parsed)) commit(parsed)
  }

  function onfocus() {
    draft = fixed(value, digits)
    focused = true
  }

  function onblur() {
    focused = false
  }

  function onkeydown(event: KeyboardEvent) {
    if (event.key === 'Enter') return (event.currentTarget as HTMLInputElement).blur()
    if (event.key !== 'ArrowUp' && event.key !== 'ArrowDown') return

    event.preventDefault()

    const scale = event.shiftKey ? 10 : event.altKey ? 0.1 : 1
    const direction = event.key === 'ArrowUp' ? 1 : -1
    const next = normalize(value + step * scale * direction)

    draft = fixed(next, digits)
    if (next !== value) onchange(next)
  }

  function scroll(node: HTMLElement) {
    const listener = (event: WheelEvent) => {
      if (wheel <= 0 || event.deltaY === 0) return

      event.preventDefault()

      const next = normalize(value + (event.deltaY < 0 ? wheel : -wheel))

      draft = fixed(next, digits)
      if (next !== value) onchange(next)
    }

    node.addEventListener('wheel', listener, { passive: false })

    return () => node.removeEventListener('wheel', listener)
  }
</script>

<label class="field" {@attach scroll}>
  <span class="label">{label}</span>
  <input class="num" type="text" inputmode="decimal" spellcheck="false" value={shown} {oninput} {onfocus} {onblur} {onkeydown} />
  {#if unit}<span class="unit">{unit}</span>{/if}
</label>

<style>
  .field {
    display: flex;
    align-items: center;
    gap: calc(8 * var(--px));
    min-width: 0;
    height: calc(36 * var(--px));
    padding: 0 calc(10 * var(--px));
    border: calc(1 * var(--px)) solid transparent;
    border-radius: var(--radius-field);
    background: var(--smoke);
    transition: border-color 120ms var(--ease-out);
  }

  .field:hover {
    border-color: var(--rule);
  }

  .field:focus-within {
    border-color: var(--paper);
  }

  .label {
    flex: none;
    font-size: var(--text-xs);
    font-weight: 700;
    color: var(--ash);
  }

  input {
    flex: 1;
    min-width: 0;
    padding: 0;
    border: 0;
    outline: none;
    background: transparent;
    font-size: var(--text-sm);
    text-align: right;
    user-select: text;
  }

  .unit {
    flex: none;
    font-size: var(--text-xs);
    color: var(--ash);
  }
</style>
