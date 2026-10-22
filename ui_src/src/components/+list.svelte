<script lang="ts">
  import { untrack } from 'svelte'
  import { select } from '../lib/api'
  import { fixed } from '../lib/format'
  import { config } from '../stores/config.svelte'
  import { points } from '../stores/points.svelte'
  import Keycap from './+keycap.svelte'

  let scroller = $state<HTMLOListElement>()

  const digits = $derived(config.precision)
  const hint = $derived(config.t('empty_hint', '\u0000').split('\u0000'))

  function rowOf(node: HTMLOListElement, index: number): Element | null {
    return index > 0 ? (node.children[index - 1] ?? null) : null
  }

  function settle(node: HTMLOListElement) {
    scroller = node

    const row = untrack(() => rowOf(node, points.selected))

    if (row) row.scrollIntoView({ block: 'nearest' })
    else node.scrollTop = node.scrollHeight

    return () => {
      scroller = undefined
    }
  }

  $effect(() => {
    const index = points.selected
    if (!scroller) return

    rowOf(scroller, index)?.scrollIntoView({ block: 'nearest' })
  })
</script>

{#if points.count === 0}
  <div class="empty">
    <strong>{config.t('empty')}</strong>
    <p>{hint[0]}<Keycap label={config.keys.add} />{hint[1] ?? ''}</p>
  </div>
{:else}
  <ol class="list" {@attach settle}>
    {#each points.list as point, i (point)}
      <li>
        <button class="row" class:selected={points.selected === i + 1} onclick={() => select(i + 1)}>
          <span class="index num">{i + 1}</span>
          <span class="main">
            <span class="title">
              <span class="name" class:unnamed={point.label === ''}>{point.label || config.t('unnamed')}</span>
              {#if point.model}<span class="tag">prop</span>{/if}
              {#if point.blip || point.area}<span class="tag">blip</span>{/if}
            </span>
            <span class="coords num">{fixed(point.x, digits)}&ensp;{fixed(point.y, digits)}&ensp;{fixed(point.z, digits)}</span>
          </span>
          <span class="side">
            <span class="radius num">{fixed(point.r, digits)} m</span>
            <span class="heading num">{fixed(point.h, 0)}°</span>
          </span>
        </button>
      </li>
    {/each}
  </ol>
{/if}

<style>
  .list {
    flex: 1 1 0;
    min-height: calc(170 * var(--px));
    margin: 0;
    padding: calc(8 * var(--px)) calc(10 * var(--px));
    overflow-y: auto;
    list-style: none;
  }

  .row {
    display: grid;
    grid-template-columns: calc(30 * var(--px)) minmax(0, 1fr) auto;
    align-items: center;
    gap: calc(12 * var(--px));
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

  .index {
    font-size: var(--text-lg);
    font-weight: 700;
    text-align: right;
  }

  .main,
  .side {
    display: flex;
    flex-direction: column;
    min-width: 0;
  }

  .side {
    align-items: flex-end;
  }

  .title {
    display: flex;
    align-items: center;
    gap: calc(6 * var(--px));
    min-width: 0;
  }

  .tag {
    flex: none;
    padding: 0 calc(5 * var(--px));
    border: calc(1 * var(--px)) solid var(--ash);
    border-radius: calc(4 * var(--px));
    font-size: calc(11 * var(--px));
    font-weight: 700;
    line-height: calc(16 * var(--px));
    color: var(--graphite);
  }

  .selected .tag {
    border-color: var(--ink-graphite);
    color: var(--ink-graphite);
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
    color: var(--ash);
  }

  .coords,
  .heading {
    font-size: var(--text-xs);
    color: var(--graphite);
    white-space: nowrap;
  }

  .radius {
    font-size: var(--text-sm);
    font-weight: 700;
    white-space: nowrap;
  }

  .selected .name.unnamed,
  .selected .coords,
  .selected .heading {
    color: var(--ink-graphite);
  }

  .empty {
    display: flex;
    flex: 1;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: calc(6 * var(--px));
    padding: calc(24 * var(--px));
    text-align: center;
  }

  .empty strong {
    font-size: var(--text-lg);
  }

  .empty p {
    display: inline-flex;
    flex-wrap: wrap;
    align-items: center;
    justify-content: center;
    gap: calc(6 * var(--px));
    margin: 0;
    font-size: var(--text-sm);
    color: var(--graphite);
  }
</style>
