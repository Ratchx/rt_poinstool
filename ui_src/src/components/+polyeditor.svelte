<script lang="ts">
  import { copy } from '../lib/api'
  import { fixed, polyBlockOf } from '../lib/format'
  import { flattenPoly, placeInto, queuePoly, queueVertex, removePoly, removeVertex, selectVertex } from '../lib/polyApi'
  import { config } from '../stores/config.svelte'
  import { polys } from '../stores/polys.svelte'
  import ColorField from './+colorfield.svelte'
  import Confirm from './+confirm.svelte'
  import NumberField from './+numberfield.svelte'

  type Axis = 'x' | 'y' | 'z'

  const THICKNESS_STEP = 0.5
  const AXIS_STEP = 0.1
  const Z_WHEEL_STEP = 0.5

  const poly = $derived(polys.current)
  const index = $derived(polys.selected)
  const vertex = $derived(poly && polys.vertex > 0 ? (poly.points[polys.vertex - 1] ?? null) : null)
  const digits = $derived(config.precision)
  const rule = $derived(config.poly)
  const name = $derived(polys.nameOf(index))
  const empty = $derived(!poly || poly.points.length === 0)

  function setLabel(event: Event & { currentTarget: HTMLInputElement }) {
    if (!poly) return

    poly.label = event.currentTarget.value
    queuePoly(poly)
  }

  function setThickness(value: number) {
    if (!poly) return

    poly.thickness = value
    queuePoly(poly)
  }

  function setColor(color: number[]) {
    if (!poly) return

    poly.color = color
    queuePoly(poly)
  }

  function setAxis(key: Axis, value: number) {
    if (!poly || !vertex) return

    vertex[key] = value
    queueVertex(poly, vertex)
  }
</script>

{#if poly}
  <section class="editor">
    <header>
      <h2>{config.t('poly_edit', name)}</h2>
      <Confirm label={config.t('poly_remove')} confirmLabel={config.t('poly_remove_confirm')} onconfirm={() => removePoly(index)} />
    </header>

    <label class="name">
      <span>{config.t('name')}</span>
      <input
        type="text"
        spellcheck="false"
        maxlength={config.labelLength}
        placeholder={config.t('name_hint')}
        value={poly.label}
        oninput={setLabel}
      />
    </label>

    <NumberField
      label={config.t('thickness')}
      value={poly.thickness}
      {digits}
      step={THICKNESS_STEP}
      min={rule.thicknessMin}
      max={rule.thicknessMax}
      wheel={THICKNESS_STEP}
      unit="m"
      onchange={setThickness}
    />

    <ColorField label={config.t('tint')} alphaLabel={config.t('alpha')} tint={poly.color} onchange={setColor} />

    <div class="actions">
      <button class="btn solid" onclick={() => placeInto(index)}>{config.t('place')}</button>
      <button class="btn" disabled={empty} onclick={() => flattenPoly(index)}>{config.t('flatten')}</button>
      <button class="btn" disabled={empty} onclick={() => copy(polyBlockOf(poly, digits, true), config.t('copied', name))}>
        {config.t('copy')}
      </button>
    </div>

    <div class="section-head">
      <span class="caption">{config.t('vertices', poly.points.length)}</span>
      {#if vertex}
        <button class="btn small" onclick={() => removeVertex(index, polys.vertex)}>{config.t('vertex_remove')}</button>
      {/if}
    </div>

    {#if empty}
      <p class="hint">{config.t('vertex_none')}</p>
    {:else}
      <ol class="vertices">
        {#each poly.points as point, i (point)}
          <li>
            <button class="vertex" class:selected={polys.vertex === i + 1} onclick={() => selectVertex(i + 1)}>
              <span class="index num">{i + 1}</span>
              <span class="coords num">{fixed(point.x, digits)}&ensp;{fixed(point.y, digits)}&ensp;{fixed(point.z, digits)}</span>
            </button>
          </li>
        {/each}
      </ol>

      {#if vertex}
        <div class="axes">
          <NumberField label="X" value={vertex.x} {digits} step={AXIS_STEP} onchange={(value) => setAxis('x', value)} />
          <NumberField label="Y" value={vertex.y} {digits} step={AXIS_STEP} onchange={(value) => setAxis('y', value)} />
          <NumberField label="Z" value={vertex.z} {digits} step={AXIS_STEP} wheel={Z_WHEEL_STEP} onchange={(value) => setAxis('z', value)} />
        </div>
      {:else}
        <p class="hint">{config.t('vertex_pick')}</p>
      {/if}
    {/if}
  </section>
{:else if polys.count > 0}
  <p class="pick">{config.t('poly_pick')}</p>
{/if}

<style>
  .editor {
    display: flex;
    flex: 0 1 auto;
    flex-direction: column;
    gap: calc(12 * var(--px));
    min-height: 0;
    padding: calc(16 * var(--px)) calc(20 * var(--px)) calc(20 * var(--px));
    overflow-y: auto;
    border-top: calc(1 * var(--px)) solid var(--rule);
  }

  .editor > :global(*) {
    flex: none;
  }

  header {
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  h2 {
    margin: 0;
    font-size: var(--text-lg);
    font-weight: 700;
  }

  .name {
    display: flex;
    align-items: center;
    gap: calc(8 * var(--px));
    height: calc(36 * var(--px));
    padding: 0 calc(10 * var(--px));
    border: calc(1 * var(--px)) solid transparent;
    border-radius: var(--radius-field);
    background: var(--smoke);
  }

  .name:hover {
    border-color: var(--rule);
  }

  .name:focus-within {
    border-color: var(--paper);
  }

  .name span {
    flex: none;
    font-size: var(--text-xs);
    font-weight: 700;
    color: var(--ash);
  }

  .name input {
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

  .name input::placeholder {
    color: var(--ash);
  }

  .actions {
    display: grid;
    grid-template-columns: 1.4fr 1fr 1fr;
    gap: calc(8 * var(--px));
  }

  .actions .btn {
    padding: 0 calc(8 * var(--px));
  }

  .actions .btn:disabled {
    opacity: 0.35;
  }

  .vertices {
    max-height: calc(176 * var(--px));
    margin: 0;
    padding: calc(4 * var(--px));
    overflow-y: auto;
    border: calc(1 * var(--px)) solid var(--rule);
    border-radius: var(--radius-block);
    list-style: none;
  }

  .vertex {
    display: grid;
    grid-template-columns: calc(28 * var(--px)) minmax(0, 1fr);
    align-items: center;
    gap: calc(10 * var(--px));
    width: 100%;
    padding: calc(6 * var(--px)) calc(10 * var(--px));
    border: 0;
    border-radius: var(--radius-field);
    background: transparent;
    text-align: left;
  }

  .vertex:hover {
    background: var(--smoke);
  }

  .vertex.selected {
    background: var(--paper);
    color: var(--black);
  }

  .index {
    font-size: var(--text-sm);
    font-weight: 700;
    text-align: right;
  }

  .coords {
    font-size: var(--text-sm);
    color: var(--graphite);
    white-space: nowrap;
  }

  .vertex.selected .coords {
    color: var(--ink-graphite);
  }

  .axes {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: calc(8 * var(--px));
  }

  .hint,
  .pick {
    margin: 0;
    font-size: var(--text-sm);
    color: var(--ash);
  }

  .pick {
    padding: calc(16 * var(--px)) calc(20 * var(--px));
    border-top: calc(1 * var(--px)) solid var(--rule);
  }
</style>
