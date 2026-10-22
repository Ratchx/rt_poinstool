<script lang="ts">
  import { untrack } from 'svelte'
  import { roundTo } from '../lib/format'
  import type { Point } from '../lib/types'
  import { config } from '../stores/config.svelte'
  import Check from './+check.svelte'
  import ColorField from './+colorfield.svelte'
  import NumberField from './+numberfield.svelte'

  const SIZE_STEP = 0.1
  const AXES = ['X', 'Y', 'Z']

  let {
    point,
    onsize,
    ontint,
  }: { point: Point; onsize: (size: number[]) => void; ontint: (tint: number[]) => void } = $props()

  let linked = $state(untrack(() => point.size[0] === point.size[1]))

  const digits = $derived(config.precision)
  const rule = $derived(config.marker)

  function setAxis(axis: number, value: number) {
    const size = [...point.size]
    size[axis] = value
    if (linked && axis < 2) size[1 - axis] = value

    onsize(size)
  }

  function fit() {
    const diameter = roundTo(Math.min(Math.max(point.r * 2, rule.sizeMin), rule.sizeMax), digits)

    onsize([diameter, diameter, point.size[2]])
  }
</script>

<div class="marker">
  <div class="section-head">
    <span class="caption">{config.t('marker')}</span>
    <Check label={config.t('marker_link')} checked={linked} onchange={(value) => (linked = value)} />
    <button class="btn small" onclick={fit}>{config.t('marker_fit')}</button>
  </div>

  <div class="axes">
    {#each AXES as axis, index (axis)}
      <NumberField
        label={axis}
        value={point.size[index]}
        {digits}
        step={SIZE_STEP}
        min={rule.sizeMin}
        max={rule.sizeMax}
        wheel={SIZE_STEP}
        onchange={(value) => setAxis(index, value)}
      />
    {/each}
  </div>

  <ColorField label={config.t('tint')} alphaLabel={config.t('alpha')} tint={point.tint} onchange={ontint} />
</div>

<style>
  .marker {
    display: flex;
    flex-direction: column;
    gap: calc(8 * var(--px));
  }

  .axes {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: calc(8 * var(--px));
  }
</style>
