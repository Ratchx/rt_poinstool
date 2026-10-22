<script lang="ts">
  import { logPosition, logValue, roundTo } from '../lib/format'

  const RESOLUTION = 1000
  const MARKS = [0.1, 0.25, 0.5, 1, 2, 5, 10, 25, 50, 100, 250, 500]
  const MINOR = [0.2, 0.3, 0.4, 0.75, 1.5, 3, 4, 7.5, 15, 20, 30, 40, 75, 150, 200, 300, 400]

  let {
    value,
    min,
    max,
    step,
    digits,
    onchange,
  }: { value: number; min: number; max: number; step: number; digits: number; onchange: (value: number) => void } = $props()

  const position = $derived(Math.round(logPosition(value, min, max) * RESOLUTION))
  const marks = $derived(MARKS.filter((mark) => mark >= min && mark <= max).map((mark) => ({ mark, at: logPosition(mark, min, max) * 100 })))
  const minors = $derived(MINOR.filter((mark) => mark > min && mark < max).map((mark) => logPosition(mark, min, max) * 100))

  const incrementOf = (raw: number) => Math.max(step, raw < 5 ? 0 : raw < 20 ? 0.5 : raw < 100 ? 1 : 5)

  function snap(raw: number): number {
    const increment = incrementOf(raw)
    const snapped = increment > 0 ? Math.round(raw / increment) * increment : raw

    return roundTo(Math.min(Math.max(snapped, min), max), digits)
  }

  function oninput(event: Event & { currentTarget: HTMLInputElement }) {
    const next = snap(logValue(Number(event.currentTarget.value) / RESOLUTION, min, max))
    if (next !== value) onchange(next)
  }
</script>

<div class="ruler">
  <div class="scale" aria-hidden="true">
    {#each minors as at, index (index)}
      <span class="tick minor" style:left="{at}%"></span>
    {/each}
    {#each marks as item (item.mark)}
      <span class="tick major" style:left="{item.at}%"></span>
      <span class="mark num" style:left="{item.at}%">{item.mark}</span>
    {/each}
    <span class="fill" style:width="{position / 10}%"></span>
  </div>
  <input type="range" min="0" max={RESOLUTION} step="1" value={position} {oninput} />
</div>

<style>
  .ruler {
    position: relative;
    height: calc(46 * var(--px));
    margin: 0 calc(6 * var(--px));
  }

  .scale {
    position: absolute;
    inset: 0;
  }

  .tick {
    position: absolute;
    top: calc(10 * var(--px));
    width: calc(1 * var(--px));
    background: var(--ash);
    transform: translateX(-50%);
  }

  .tick.major {
    height: calc(14 * var(--px));
    background: var(--graphite);
  }

  .tick.minor {
    top: calc(14 * var(--px));
    height: calc(6 * var(--px));
  }

  .mark {
    position: absolute;
    top: calc(28 * var(--px));
    font-size: calc(11 * var(--px));
    color: var(--ash);
    transform: translateX(-50%);
  }

  .fill {
    position: absolute;
    top: calc(22 * var(--px));
    left: 0;
    height: calc(2 * var(--px));
    background: var(--paper);
  }

  .scale::before {
    content: '';
    position: absolute;
    top: calc(22 * var(--px));
    left: 0;
    right: 0;
    height: calc(2 * var(--px));
    background: var(--rule);
  }

  input {
    position: absolute;
    inset: 0;
    width: 100%;
    height: 100%;
    margin: 0;
    background: transparent;
    cursor: ew-resize;
    appearance: none;
    -webkit-appearance: none;
  }

  input::-webkit-slider-runnable-track {
    height: 100%;
    background: transparent;
  }

  input::-webkit-slider-thumb {
    width: calc(4 * var(--px));
    height: calc(20 * var(--px));
    margin-top: calc(6 * var(--px));
    border-radius: calc(2 * var(--px));
    background: var(--paper);
    box-shadow: 0 0 0 calc(3 * var(--px)) var(--black);
    -webkit-appearance: none;
  }

  input:focus-visible {
    outline: none;
  }

  input:focus-visible::-webkit-slider-thumb {
    box-shadow:
      0 0 0 calc(3 * var(--px)) var(--black),
      0 0 0 calc(5 * var(--px)) var(--paper);
  }
</style>
