<script lang="ts">
  import { cubicOut } from 'svelte/easing'
  import { Tween } from 'svelte/motion'
  import { logPosition } from '../lib/format'

  const SIZE = 128
  const CENTER = SIZE / 2
  const INNER = 9
  const OUTER = 58
  const REFERENCES = [1, 10, 100]
  const DEAD_ZONE = 0.06
  const TICK_STEP = 15
  const TICKS = Array.from({ length: 360 / TICK_STEP - 1 }, (_, index) => (index + 1) * TICK_STEP)

  let {
    radius,
    heading,
    min,
    max,
    label,
    onheading,
  }: { radius: number; heading: number; min: number; max: number; label: string; onheading: (value: number) => void } = $props()

  let dragging = $state(false)

  const ringOf = (value: number) => INNER + (OUTER - INNER) * logPosition(value, min, max)

  const ring = Tween.of(() => ringOf(radius), { duration: 260, easing: cubicOut })

  const references = $derived(REFERENCES.filter((value) => value > min && value < max).map((value) => ({ value, ring: ringOf(value) })))

  const wrap = (value: number) => ((value % 360) + 360) % 360

  function commit(value: number) {
    if (value !== heading) onheading(value)
  }

  function step(direction: number) {
    commit(wrap(direction > 0 ? Math.floor(heading + 1) : Math.ceil(heading - 1)))
  }

  function aim(event: PointerEvent) {
    const rect = (event.currentTarget as SVGSVGElement).getBoundingClientRect()
    const dx = event.clientX - (rect.left + rect.width / 2)
    const dy = event.clientY - (rect.top + rect.height / 2)
    if (Math.hypot(dx, dy) < rect.width * DEAD_ZONE) return

    commit(wrap(Math.round((Math.atan2(-dx, -dy) * 180) / Math.PI)))
  }

  function onpointerdown(event: PointerEvent) {
    if (event.button !== 0) return

    dragging = true
    ;(event.currentTarget as SVGSVGElement).setPointerCapture(event.pointerId)
    aim(event)
  }

  function onpointermove(event: PointerEvent) {
    if (dragging) aim(event)
  }

  function onpointerup() {
    dragging = false
  }

  function onkeydown(event: KeyboardEvent) {
    const direction = event.key === 'ArrowUp' || event.key === 'ArrowLeft' ? 1 : event.key === 'ArrowDown' || event.key === 'ArrowRight' ? -1 : 0
    if (direction === 0) return

    event.preventDefault()
    step(direction)
  }

  function wheel(node: SVGSVGElement) {
    const listener = (event: WheelEvent) => {
      event.preventDefault()
      if (event.deltaY !== 0) step(event.deltaY < 0 ? 1 : -1)
    }

    node.addEventListener('wheel', listener, { passive: false })

    return () => node.removeEventListener('wheel', listener)
  }
</script>

<svg
  viewBox="0 0 {SIZE} {SIZE}"
  class:dragging
  role="slider"
  tabindex="0"
  aria-label={label}
  aria-valuemin={0}
  aria-valuemax={359}
  aria-valuenow={Math.round(heading)}
  {onpointerdown}
  {onpointermove}
  {onpointerup}
  onpointercancel={onpointerup}
  {onkeydown}
  {@attach wheel}
>
  <circle class="hit" cx={CENTER} cy={CENTER} r={OUTER + 6} />

  <g class="dial">
    {#each TICKS as angle (angle)}
      <line
        class:major={angle % 90 === 0}
        x1={CENTER}
        y1={CENTER - OUTER - 1}
        x2={CENTER}
        y2={CENTER - OUTER - (angle % 90 === 0 ? 6 : 3.5)}
        transform="rotate({angle} {CENTER} {CENTER})"
      />
    {/each}
  </g>

  {#each references as reference (reference.value)}
    <circle class="reference" cx={CENTER} cy={CENTER} r={reference.ring} />
    <text class="scale" x={CENTER + reference.ring * 0.71 + 2} y={CENTER - reference.ring * 0.71 - 2}>{reference.value}</text>
  {/each}

  <circle class="area" cx={CENTER} cy={CENTER} r={ring.current} />

  <g transform="rotate({-heading} {CENTER} {CENTER})">
    <line class="needle" x1={CENTER} y1={CENTER} x2={CENTER} y2={CENTER - OUTER - 2} />
    <path class="tip" d="M {CENTER} {CENTER - OUTER - 6} l -4 8 l 8 0 z" />
  </g>

  <circle class="dot" cx={CENTER} cy={CENTER} r="2.5" />
  <text class="north" x={CENTER} y="7">N</text>
</svg>

<style>
  svg {
    flex: none;
    width: calc(128 * var(--px));
    height: calc(128 * var(--px));
    overflow: visible;
    cursor: grab;
    touch-action: none;
  }

  svg.dragging {
    cursor: grabbing;
  }

  svg:focus-visible {
    outline: none;
  }

  .hit {
    fill: transparent;
  }

  .dial line {
    stroke: var(--rule);
    stroke-width: 1;
    transition: stroke 120ms var(--ease-out);
  }

  .dial line.major {
    stroke-width: 1.5;
  }

  svg:hover .dial line,
  svg:focus-visible .dial line,
  svg.dragging .dial line {
    stroke: var(--graphite);
  }

  .reference {
    fill: none;
    stroke: var(--rule);
    stroke-dasharray: 2 3;
  }

  .scale {
    fill: var(--ash);
    font-size: 7px;
    font-weight: 700;
  }

  .area {
    fill: rgba(255, 255, 255, 0.12);
    stroke: var(--paper);
    stroke-width: 1.25;
  }

  .needle {
    stroke: var(--paper);
    stroke-width: 1.25;
  }

  .tip,
  .dot {
    fill: var(--paper);
  }

  .north {
    fill: var(--graphite);
    font-size: 8px;
    font-weight: 700;
    text-anchor: middle;
  }

  .hit,
  .dial,
  .reference,
  .scale,
  .area,
  .needle,
  .tip,
  .dot,
  .north {
    pointer-events: none;
  }

  .hit {
    pointer-events: all;
  }
</style>
