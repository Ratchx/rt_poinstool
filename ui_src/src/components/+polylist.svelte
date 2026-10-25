<script lang="ts">
  import { fixed } from '../lib/format'
  import { createPoly, togglePoly } from '../lib/polyApi'
  import { config } from '../stores/config.svelte'
  import { polys } from '../stores/polys.svelte'
</script>

{#if polys.count === 0}
  <div class="empty">
    <strong>{config.t('poly_empty')}</strong>
    <p>{config.t('poly_empty_hint')}</p>
    <button class="btn solid" onclick={createPoly}>{config.t('poly_new')}</button>
  </div>
{:else}
  <ol class="list">
    {#each polys.list as poly, i (poly)}
      <li>
        <button class="row" class:selected={polys.selected === i + 1} onclick={() => togglePoly(i + 1)}>
          <span class="swatch" style:background="rgb({poly.color[0]}, {poly.color[1]}, {poly.color[2]})"></span>
          <span class="main">
            <span class="name" class:unnamed={poly.label === ''}>{poly.label || config.t('poly_name', i + 1)}</span>
            <span class="meta num">{config.t('vertices', poly.points.length)}</span>
          </span>
          <span class="side num">{fixed(poly.thickness, config.precision)} m</span>
        </button>
      </li>
    {/each}
  </ol>

  <div class="foot">
    <button class="btn small" disabled={polys.count >= config.poly.limit} onclick={createPoly}>{config.t('poly_new')}</button>
  </div>
{/if}

<style>
  .list {
    flex: 1 1 0;
    min-height: calc(140 * var(--px));
    margin: 0;
    padding: calc(8 * var(--px)) calc(10 * var(--px));
    overflow-y: auto;
    list-style: none;
  }

  .row {
    display: grid;
    grid-template-columns: calc(14 * var(--px)) minmax(0, 1fr) auto;
    align-items: center;
    gap: calc(14 * var(--px));
    width: 100%;
    padding: calc(10 * var(--px)) calc(12 * var(--px));
    border: 0;
    border-radius: var(--radius-block);
    background: transparent;
    text-align: left;
  }

  .row:hover {
    background: var(--smoke);
  }

  .row.selected {
    background: var(--paper);
    color: var(--black);
  }

  .swatch {
    width: calc(14 * var(--px));
    height: calc(14 * var(--px));
    border: calc(1 * var(--px)) solid var(--rule);
    border-radius: calc(4 * var(--px));
  }

  .main {
    display: flex;
    flex-direction: column;
    min-width: 0;
  }

  .name {
    overflow: hidden;
    font-size: var(--text-md);
    font-weight: 700;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .name.unnamed {
    font-weight: 400;
    color: var(--graphite);
  }

  .meta {
    font-size: var(--text-xs);
    color: var(--graphite);
  }

  .side {
    font-size: var(--text-sm);
    font-weight: 700;
    white-space: nowrap;
  }

  .selected .name.unnamed,
  .selected .meta {
    color: var(--ink-graphite);
  }

  .foot {
    display: flex;
    flex: none;
    justify-content: flex-end;
    padding: calc(8 * var(--px)) calc(14 * var(--px));
    border-top: calc(1 * var(--px)) solid var(--rule);
  }

  .foot .btn:disabled {
    opacity: 0.35;
  }

  .empty {
    display: flex;
    flex: 1;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: calc(10 * var(--px));
    padding: calc(24 * var(--px));
    text-align: center;
  }

  .empty strong {
    font-size: var(--text-lg);
  }

  .empty p {
    max-width: calc(300 * var(--px));
    margin: 0;
    font-size: var(--text-sm);
    color: var(--graphite);
  }
</style>
