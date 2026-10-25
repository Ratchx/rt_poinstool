<script lang="ts">
  import { quintOut } from 'svelte/easing'
  import { fly } from 'svelte/transition'
  import { config } from '../stores/config.svelte'
  import { panel } from '../stores/panel.svelte'
  import { points } from '../stores/points.svelte'
  import { polys } from '../stores/polys.svelte'
  import { toast } from '../stores/toast.svelte'
  import Keycap from './+keycap.svelte'
</script>

{#if !panel.open}
  <div class="dock">
    {#if polys.placing}
      <aside class="hud place" transition:fly={{ x: 24, duration: 220, easing: quintOut }}>
        <div class="line">
          <strong>{config.t('place_title')}</strong>
        </div>
        <span class="target">
          {polys.target > 0 ? config.t('place_poly', polys.nameOf(polys.target)) : config.t('place_point')}
        </span>
        <div class="keys grid">
          <span><Keycap label={config.t('mouse_left')} />{config.t('place_click')}</span>
          <span><Keycap label={config.t('mouse_right')} />{config.t('place_look')}</span>
          <span><Keycap label={config.keys.undo} />{config.t('place_undo')}</span>
          <span><Keycap label={config.keys.place} /><Keycap label="ESC" />{config.t('place_exit')}</span>
        </div>
      </aside>
    {:else if points.visible}
      <aside class="hud" transition:fly={{ x: 24, duration: 220, easing: quintOut }}>
        <div class="line">
          <strong>{config.t('title')}</strong>
          <span class="num">{config.t('points', points.count)}</span>
        </div>
        <div class="keys">
          <span><Keycap label={config.keys.add} />{config.t('add')}</span>
          <span><Keycap label={config.keys.menu} />{config.t('list')}</span>
          <span><Keycap label={config.keys.place} />{config.t('place')}</span>
        </div>
      </aside>
    {/if}

    {#if toast.message}
      {#key toast.id}
        <div class="toast" in:fly={{ y: -10, duration: 220, easing: quintOut }}>
          <strong>{toast.message}</strong>
          {#if toast.detail}<span class="num">{toast.detail}</span>{/if}
        </div>
      {/key}
    {/if}
  </div>
{/if}

<style>
  .dock {
    position: fixed;
    top: calc(32 * var(--px));
    right: calc(32 * var(--px));

    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: calc(8 * var(--px));
  }

  .hud {
    display: flex;
    flex-direction: column;
    gap: calc(10 * var(--px));
    padding: calc(14 * var(--px)) calc(16 * var(--px));
    border: calc(1 * var(--px)) solid var(--rule);
    border-radius: var(--radius-block);
    background: var(--ink);
  }

  .line {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: calc(24 * var(--px));
    font-size: var(--text-md);
  }

  .line span {
    font-size: var(--text-sm);
    color: var(--graphite);
  }

  .keys {
    display: flex;
    gap: calc(16 * var(--px));
    font-size: var(--text-sm);
    color: var(--graphite);
  }

  .keys span {
    display: inline-flex;
    align-items: center;
    gap: calc(7 * var(--px));
  }

  .place {
    border-color: var(--paper);
  }

  .target {
    padding: calc(4 * var(--px)) calc(10 * var(--px));
    border-radius: var(--radius-field);
    background: var(--paper);
    color: var(--black);
    font-size: var(--text-sm);
    font-weight: 700;
  }

  .keys.grid {
    display: grid;
    grid-template-columns: auto auto;
    gap: calc(8 * var(--px)) calc(16 * var(--px));
  }

  .toast {
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: calc(2 * var(--px));
    padding: calc(10 * var(--px)) calc(14 * var(--px));
    border-radius: var(--radius-block);
    background: var(--paper);
    color: var(--black);
    font-size: var(--text-sm);
  }

  .toast span {
    font-size: var(--text-xs);
    color: var(--ink-graphite);
  }
</style>
