<script lang="ts">
  import NumberField from './+numberfield.svelte'

  const ALPHA_STEP = 5
  const HEX = /^#?([0-9a-f]{6})$/i
  const PRESETS = [
    [255, 255, 255],
    [20, 20, 20],
    [255, 69, 58],
    [255, 159, 10],
    [255, 214, 10],
    [48, 209, 88],
    [100, 210, 255],
    [10, 132, 255],
    [191, 90, 242],
  ]

  let {
    label,
    alphaLabel,
    tint,
    onchange,
  }: { label: string; alphaLabel: string; tint: number[]; onchange: (tint: number[]) => void } = $props()

  let focused = $state(false)
  let draft = $state('')

  const hexOf = (rgb: number[]) => `#${rgb.map((channel) => channel.toString(16).padStart(2, '0')).join('').toUpperCase()}`

  const hex = $derived(hexOf(tint.slice(0, 3)))
  const shown = $derived(focused ? draft : hex)
  const fill = $derived(`rgba(${tint[0]}, ${tint[1]}, ${tint[2]}, ${tint[3] / 255})`)
  const solid = $derived(`rgb(${tint[0]}, ${tint[1]}, ${tint[2]})`)

  function oninput(event: Event & { currentTarget: HTMLInputElement }) {
    draft = event.currentTarget.value

    const match = HEX.exec(draft.trim())
    if (!match) return

    const value = Number.parseInt(match[1], 16)
    onchange([(value >> 16) & 255, (value >> 8) & 255, value & 255, tint[3]])
  }

  function onfocus() {
    draft = hex
    focused = true
  }

  function onkeydown(event: KeyboardEvent) {
    if (event.key === 'Enter') (event.currentTarget as HTMLInputElement).blur()
  }

  const same = (rgb: number[]) => rgb[0] === tint[0] && rgb[1] === tint[1] && rgb[2] === tint[2]
</script>

<div class="color">
  <div class="row">
    <span class="swatch" aria-hidden="true"><span style:background={fill}></span><span style:background={solid}></span></span>
    <label class="hex">
      <span>{label}</span>
      <input class="num" type="text" spellcheck="false" maxlength="7" value={shown} {oninput} {onfocus} onblur={() => (focused = false)} {onkeydown} />
    </label>
    <NumberField
      label={alphaLabel}
      value={tint[3]}
      digits={0}
      step={ALPHA_STEP}
      min={0}
      max={255}
      wheel={ALPHA_STEP}
      onchange={(value) => onchange([tint[0], tint[1], tint[2], value])}
    />
  </div>

  <div class="presets">
    {#each PRESETS as rgb, index (index)}
      <button
        class="preset"
        class:on={same(rgb)}
        style:background="rgb({rgb[0]}, {rgb[1]}, {rgb[2]})"
        aria-label={hexOf(rgb)}
        title={hexOf(rgb)}
        onclick={() => onchange([rgb[0], rgb[1], rgb[2], tint[3]])}
      ></button>
    {/each}
  </div>
</div>

<style>
  .color {
    display: flex;
    flex-direction: column;
    gap: calc(8 * var(--px));
  }

  .row {
    display: grid;
    grid-template-columns: calc(36 * var(--px)) minmax(0, 1.4fr) minmax(0, 1fr);
    gap: calc(8 * var(--px));
  }

  .swatch {
    position: relative;
    display: flex;
    overflow: hidden;
    height: calc(36 * var(--px));
    border: calc(1 * var(--px)) solid var(--rule);
    border-radius: var(--radius-field);
    background:
      repeating-conic-gradient(rgba(255, 255, 255, 0.22) 0 25%, rgba(255, 255, 255, 0.04) 0 50%) 0 0 / calc(10 * var(--px)) calc(10 * var(--px));
  }

  .swatch span {
    flex: 1;
  }

  .hex {
    display: flex;
    align-items: center;
    gap: calc(8 * var(--px));
    min-width: 0;
    height: calc(36 * var(--px));
    padding: 0 calc(10 * var(--px));
    border: calc(1 * var(--px)) solid transparent;
    border-radius: var(--radius-field);
    background: var(--smoke);
  }

  .hex:hover {
    border-color: var(--rule);
  }

  .hex:focus-within {
    border-color: var(--paper);
  }

  .hex span {
    flex: none;
    font-size: var(--text-xs);
    font-weight: 700;
    color: var(--ash);
  }

  .hex input {
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

  .presets {
    display: flex;
    justify-content: space-between;
  }

  .preset {
    width: calc(28 * var(--px));
    height: calc(20 * var(--px));
    padding: 0;
    border: calc(1 * var(--px)) solid var(--rule);
    border-radius: calc(5 * var(--px));
  }

  .preset:hover {
    border-color: var(--graphite);
  }

  .preset.on {
    outline: calc(2 * var(--px)) solid var(--paper);
    outline-offset: calc(2 * var(--px));
  }
</style>
