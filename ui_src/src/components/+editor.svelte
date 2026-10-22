<script lang="ts">
  import { copy, moveHere, queueUpdate, remove, setModel, snapGround, teleport } from '../lib/api'
  import { indexLabel, vec3Of, vec4Of } from '../lib/format'
  import { config } from '../stores/config.svelte'
  import { points } from '../stores/points.svelte'
  import Check from './+check.svelte'
  import Confirm from './+confirm.svelte'
  import ModelField from './+modelfield.svelte'
  import NumberField from './+numberfield.svelte'
  import Plan from './+plan.svelte'
  import Ruler from './+ruler.svelte'

  type NumberKey = 'x' | 'y' | 'z' | 'h' | 'r' | 'sprite' | 'color' | 'scale'
  type FlagKey = 'blip' | 'area'

  const AXIS_STEP = 0.1
  const HEADING_STEP = 1
  const BLIP_SCALE_STEP = 0.1

  const point = $derived(points.current)
  const index = $derived(points.selected)
  const digits = $derived(config.precision)
  const radius = $derived(config.radius)
  const blipRule = $derived(config.blip)
  const vec3 = $derived(point ? vec3Of(point, digits) : '')
  const vec4 = $derived(point ? vec4Of(point, digits) : '')

  function set(key: NumberKey, value: number) {
    if (!point) return

    point[key] = value
    queueUpdate(point)
  }

  function setFlag(key: FlagKey, value: boolean) {
    if (!point) return

    point[key] = value
    queueUpdate(point)
  }

  function setLabel(event: Event & { currentTarget: HTMLInputElement }) {
    if (!point) return

    point.label = event.currentTarget.value
    queueUpdate(point)
  }
</script>

{#if point}
  <section class="editor">
    <header>
      <h2>{config.t('edit', indexLabel(index))}</h2>
      <Confirm label={config.t('remove')} confirmLabel={config.t('remove_confirm')} onconfirm={() => remove(index)} />
    </header>

    <div class="top">
      <Plan
        radius={point.r}
        heading={point.h}
        min={radius.min}
        max={radius.max}
        label={config.t('heading')}
        onheading={(value) => set('h', value)}
      />

      <div class="side">
        <label class="name">
          <span>{config.t('name')}</span>
          <input
            type="text"
            spellcheck="false"
            maxlength={config.labelLength}
            placeholder={config.t('name_hint')}
            value={point.label}
            oninput={setLabel}
          />
        </label>
        <NumberField
          label={config.t('radius')}
          value={point.r}
          {digits}
          step={radius.step}
          min={radius.min}
          max={radius.max}
          unit="m"
          onchange={(value) => set('r', value)}
        />
        <NumberField
          label={config.t('heading')}
          value={point.h}
          {digits}
          step={HEADING_STEP}
          wrap={360}
          unit="°"
          onchange={(value) => set('h', value)}
        />
      </div>
    </div>

    <Ruler value={point.r} min={radius.min} max={radius.max} step={radius.step} {digits} onchange={(value) => set('r', value)} />

    <div class="axes">
      <NumberField label="X" value={point.x} {digits} step={AXIS_STEP} onchange={(value) => set('x', value)} />
      <NumberField label="Y" value={point.y} {digits} step={AXIS_STEP} onchange={(value) => set('y', value)} />
      <NumberField label="Z" value={point.z} {digits} step={AXIS_STEP} onchange={(value) => set('z', value)} />
    </div>

    <div class="actions">
      <button class="btn" onclick={() => moveHere(index)}>{config.t('here')}</button>
      <button class="btn" onclick={() => snapGround(index)}>{config.t('ground')}</button>
      <button class="btn" onclick={() => teleport(index)}>{config.t('teleport')}</button>
    </div>

    {#key index}
      <ModelField
        label={config.t('prop')}
        value={point.model}
        placeholder={config.t('prop_hint')}
        maxlength={config.modelLength}
        oncommit={(model) => setModel(index, model)}
      />
    {/key}

    <div class="map">
      <div class="switches">
        <span class="caption">{config.t('map')}</span>
        <Check label={config.t('blip')} checked={point.blip} onchange={(value) => setFlag('blip', value)} />
        <Check label={config.t('area')} checked={point.area} onchange={(value) => setFlag('area', value)} />
      </div>

      {#if point.blip || point.area}
        <div class="blip" class:full={point.blip}>
          {#if point.blip}
            <NumberField
              label={config.t('sprite')}
              value={point.sprite}
              digits={0}
              step={1}
              min={0}
              max={blipRule.spriteMax}
              onchange={(value) => set('sprite', value)}
            />
          {/if}
          <NumberField
            label={config.t('color')}
            value={point.color}
            digits={0}
            step={1}
            min={0}
            max={blipRule.colorMax}
            onchange={(value) => set('color', value)}
          />
          {#if point.blip}
            <NumberField
              label={config.t('scale')}
              value={point.scale}
              {digits}
              step={BLIP_SCALE_STEP}
              min={blipRule.scaleMin}
              max={blipRule.scaleMax}
              onchange={(value) => set('scale', value)}
            />
          {/if}
        </div>
      {/if}
    </div>

    <div class="copies">
      <button class="copy" onclick={() => copy(vec3, config.t('copied', 'vec3'))}>
        <strong>vec3</strong>
        <span class="num">{vec3}</span>
      </button>
      <button class="copy" onclick={() => copy(vec4, config.t('copied', 'vec4'))}>
        <strong>vec4</strong>
        <span class="num">{vec4}</span>
      </button>
    </div>
  </section>
{:else if points.count > 0}
  <p class="pick">{config.t('pick')}</p>
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

  .top {
    display: flex;
    align-items: center;
    gap: calc(18 * var(--px));
  }

  .side {
    display: flex;
    flex: 1;
    flex-direction: column;
    gap: calc(8 * var(--px));
    min-width: 0;
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

  .axes {
    display: grid;
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: calc(8 * var(--px));
  }

  .actions {
    display: grid;
    grid-template-columns: 1.25fr 0.8fr 1.25fr;
    gap: calc(8 * var(--px));
  }

  .actions .btn {
    padding: 0 calc(8 * var(--px));
  }

  .map {
    display: flex;
    flex-direction: column;
    gap: calc(8 * var(--px));
  }

  .switches {
    display: flex;
    align-items: center;
    gap: calc(16 * var(--px));
    height: calc(28 * var(--px));
  }

  .caption {
    margin-right: auto;
    font-size: var(--text-xs);
    font-weight: 700;
    color: var(--ash);
  }

  .blip {
    display: grid;
    grid-template-columns: minmax(0, 1fr);
    gap: calc(8 * var(--px));
  }

  .blip.full {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }

  .copies {
    display: flex;
    flex-direction: column;
    gap: calc(6 * var(--px));
  }

  .copy {
    display: flex;
    align-items: center;
    gap: calc(12 * var(--px));
    height: calc(38 * var(--px));
    padding: 0 calc(12 * var(--px));
    border: calc(1 * var(--px)) dashed var(--rule);
    border-radius: var(--radius-field);
    background: transparent;
    text-align: left;
    transition:
      background-color 120ms var(--ease-out),
      color 120ms var(--ease-out);
  }

  .copy strong {
    flex: none;
    font-size: var(--text-xs);
  }

  .copy span {
    overflow: hidden;
    font-size: var(--text-sm);
    color: var(--graphite);
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .copy:hover {
    border-color: var(--paper);
    border-style: solid;
  }

  .copy:active {
    background: var(--paper);
    color: var(--black);
  }

  .copy:active span {
    color: var(--ink-graphite);
  }

  .pick {
    margin: 0;
    padding: calc(16 * var(--px)) calc(20 * var(--px));
    border-top: calc(1 * var(--px)) solid var(--rule);
    font-size: var(--text-sm);
    color: var(--ash);
  }
</style>
