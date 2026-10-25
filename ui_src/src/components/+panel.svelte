<script lang="ts">
  import { quintOut } from 'svelte/easing'
  import { fade, fly } from 'svelte/transition'
  import { close, setVisible } from '../lib/api'
  import { setTab } from '../lib/polyApi'
  import { fixed } from '../lib/format'
  import { config } from '../stores/config.svelte'
  import { panel } from '../stores/panel.svelte'
  import { points } from '../stores/points.svelte'
  import { toast } from '../stores/toast.svelte'
  import Editor from './+editor.svelte'
  import Export from './+export.svelte'
  import Keycap from './+keycap.svelte'
  import List from './+list.svelte'
  import PolyEditor from './+polyeditor.svelte'
  import PolyList from './+polylist.svelte'
  import { polys } from '../stores/polys.svelte'
</script>

<section class="panel" transition:fly={{ x: 48, duration: 260, easing: quintOut }}>
  <header class="head">
    <div class="title">
      <h1>{config.t('title')}</h1>
      <p class="meta">
        {#if toast.message}
          {#key toast.id}
            <span class="status" in:fade={{ duration: 160 }}>{toast.message}</span>
          {/key}
        {:else}
          <span class="num">{config.t('points', points.count)}</span>
          <span class="num">{config.t('default_radius', fixed(config.radius.default, config.precision))}</span>
        {/if}
      </p>
    </div>

    <div class="tools">
      <button class="btn quiet" aria-pressed={!points.visible} onclick={() => setVisible(!points.visible)}>
        {points.visible ? config.t('hide') : config.t('show')}
      </button>
      <button class="btn" onclick={close}>
        {config.t('close')}
        <Keycap label="ESC" />
      </button>
    </div>
  </header>

  <nav class="tabs">
    <button class:on={panel.tab === 'list'} onclick={() => setTab('list')}>
      {config.t('list')}
      <span class="num">{points.count}</span>
    </button>
    <button class:on={panel.tab === 'poly'} onclick={() => setTab('poly')}>
      {config.t('poly')}
      <span class="num">{polys.count}</span>
    </button>
    <button class:on={panel.tab === 'export'} onclick={() => setTab('export')}>
      {config.t('export')}
    </button>
  </nav>

  {#if panel.tab === 'list'}
    <List />
    <Editor />
  {:else if panel.tab === 'poly'}
    <PolyList />
    <PolyEditor />
  {:else}
    <Export />
  {/if}
</section>

<style>
  .panel {
    position: fixed;
    top: calc(32 * var(--px));
    right: calc(32 * var(--px));
    bottom: calc(32 * var(--px));

    display: flex;
    flex-direction: column;
    width: calc(460 * var(--px));
    overflow: hidden;
    border: calc(1 * var(--px)) solid var(--rule);
    border-radius: var(--radius-panel);
    background: var(--ink);
  }

  .head {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    gap: calc(12 * var(--px));
    padding: calc(20 * var(--px)) calc(20 * var(--px)) calc(14 * var(--px));
  }

  .title {
    min-width: 0;
  }

  h1 {
    margin: 0;
    font-size: var(--text-xl);
    font-weight: 700;
    line-height: 1.2;
  }

  .meta {
    display: flex;
    flex-wrap: wrap;
    gap: calc(14 * var(--px));
    min-height: calc(24 * var(--px));
    margin: calc(6 * var(--px)) 0 0;
    font-size: var(--text-sm);
    color: var(--graphite);
  }

  .status {
    padding: 0 calc(10 * var(--px));
    border-radius: calc(12 * var(--px));
    background: var(--paper);
    color: var(--black);
    font-weight: 700;
    line-height: calc(24 * var(--px));
  }

  .tools {
    display: flex;
    flex: none;
    gap: calc(6 * var(--px));
  }

  .tools .btn :global(kbd) {
    height: calc(20 * var(--px));
    min-width: 0;
    font-size: calc(10 * var(--px));
  }

  .tools .btn:active :global(kbd) {
    border-color: var(--black);
    color: var(--black);
  }

  .tabs {
    display: flex;
    gap: calc(22 * var(--px));
    padding: 0 calc(22 * var(--px));
    border-bottom: calc(1 * var(--px)) solid var(--rule);
  }

  .tabs button {
    position: relative;
    display: inline-flex;
    align-items: center;
    gap: calc(8 * var(--px));
    height: calc(42 * var(--px));
    padding: 0;
    border: 0;
    background: transparent;
    font-size: var(--text-md);
    font-weight: 700;
    color: var(--ash);
  }

  .tabs button:hover {
    color: var(--graphite);
  }

  .tabs button.on {
    color: var(--paper);
  }

  .tabs button.on::after {
    content: '';
    position: absolute;
    right: 0;
    bottom: calc(-1 * var(--px));
    left: 0;
    height: calc(2 * var(--px));
    background: var(--paper);
  }

  .tabs span {
    font-size: var(--text-xs);
    font-weight: 400;
  }
</style>
