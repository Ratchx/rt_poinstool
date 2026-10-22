<script lang="ts">
  import { clearAll, copy } from '../lib/api'
  import { exportOf } from '../lib/format'
  import type { ExportOptions } from '../lib/types'
  import { config } from '../stores/config.svelte'
  import { panel } from '../stores/panel.svelte'
  import { points } from '../stores/points.svelte'
  import Check from './+check.svelte'
  import Confirm from './+confirm.svelte'

  const CHECKS: { key: Exclude<keyof ExportOptions, 'vec4'>; label: string }[] = [
    { key: 'radius', label: 'with_radius' },
    { key: 'label', label: 'with_label' },
    { key: 'model', label: 'with_model' },
    { key: 'marker', label: 'with_marker' },
    { key: 'blip', label: 'with_blip' },
  ]

  const text = $derived(exportOf(points.list, panel.options, config.precision))
  const lines = $derived(text.split('\n').map((line) => line.trimStart()))
</script>

<section class="export">
  <div class="options">
    <div class="group" role="radiogroup" aria-label={config.t('format')}>
      <span class="caption">{config.t('format')}</span>
      <div class="segmented">
        <button role="radio" aria-checked={!panel.options.vec4} class:on={!panel.options.vec4} onclick={() => panel.setOption('vec4', false)}>vec3</button>
        <button role="radio" aria-checked={panel.options.vec4} class:on={panel.options.vec4} onclick={() => panel.setOption('vec4', true)}>vec4</button>
      </div>
    </div>

    <div class="checks">
      {#each CHECKS as check (check.key)}
        <Check label={config.t(check.label)} checked={panel.options[check.key]} onchange={(value) => panel.setOption(check.key, value)} />
      {/each}
    </div>
  </div>

  {#if points.count === 0}
    <p class="empty">{config.t('empty')}</p>
  {:else}
    <div class="code num">
      {#each lines as line, index (index)}
        <div class="line">{line}</div>
      {/each}
    </div>
  {/if}

  <footer>
    <Confirm label={config.t('clear')} confirmLabel={config.t('clear_confirm')} disabled={points.count === 0} onconfirm={clearAll} />
    <button class="btn solid" disabled={points.count === 0} onclick={() => copy(text, config.t('copied_all', points.count))}>
      {config.t('copy_all')}
    </button>
  </footer>
</section>

<style>
  .export {
    display: flex;
    flex: 1;
    flex-direction: column;
    gap: calc(14 * var(--px));
    min-height: 0;
    padding: calc(16 * var(--px)) calc(20 * var(--px)) calc(20 * var(--px));
  }

  .options {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: space-between;
    gap: calc(12 * var(--px));
  }

  .group {
    display: flex;
    align-items: center;
    gap: calc(10 * var(--px));
  }

  .caption {
    font-size: var(--text-xs);
    font-weight: 700;
    color: var(--ash);
  }

  .segmented {
    display: flex;
    padding: calc(3 * var(--px));
    border-radius: var(--radius-block);
    background: var(--smoke);
  }

  .segmented button {
    height: calc(30 * var(--px));
    padding: 0 calc(14 * var(--px));
    border: 0;
    border-radius: var(--radius-field);
    background: transparent;
    font-size: var(--text-sm);
    font-weight: 700;
    color: var(--graphite);
  }

  .segmented button.on {
    background: var(--paper);
    color: var(--black);
  }

  .checks {
    display: grid;
    flex: 1 0 100%;
    grid-template-columns: repeat(3, auto);
    justify-content: start;
    gap: calc(10 * var(--px)) calc(24 * var(--px));
    padding: calc(10 * var(--px)) calc(2 * var(--px)) 0;
    border-top: calc(1 * var(--px)) solid var(--smoke);
  }

  .code {
    flex: 1;
    min-height: 0;
    margin: 0;
    padding: calc(12 * var(--px)) calc(16 * var(--px));
    overflow-y: auto;
    border: calc(1 * var(--px)) solid var(--rule);
    border-radius: var(--radius-block);
    background: rgba(255, 255, 255, 0.03);
    font-size: var(--text-sm);
    line-height: 1.55;
    color: var(--graphite);
    user-select: text;
  }

  .line {
    padding: calc(4 * var(--px)) 0 calc(4 * var(--px)) calc(18 * var(--px));
    text-indent: calc(-18 * var(--px));
    overflow-wrap: anywhere;
  }

  .line + .line {
    border-top: calc(1 * var(--px)) solid var(--smoke);
  }

  .empty {
    display: flex;
    flex: 1;
    align-items: center;
    justify-content: center;
    margin: 0;
    font-size: var(--text-sm);
    color: var(--ash);
  }

  footer {
    display: flex;
    justify-content: space-between;
    gap: calc(8 * var(--px));
  }

  footer :global(.btn:disabled) {
    opacity: 0.35;
  }
</style>
