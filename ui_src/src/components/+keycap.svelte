<script lang="ts">
  let { label, inverted = false }: { label: string; inverted?: boolean } = $props()
</script>

{#if label}
  <kbd class:inverted>{label}</kbd>
{/if}

<style>
  kbd {
    display: inline-flex;
    align-items: center;
    justify-content: center;
    min-width: calc(24 * var(--px));
    height: calc(24 * var(--px));
    padding: 0 calc(6 * var(--px));
    border: calc(1 * var(--px)) solid var(--paper);
    border-bottom-width: calc(3 * var(--px));
    border-radius: var(--radius-key);
    font-family: var(--font);
    font-size: var(--text-xs);
    font-weight: 700;
    line-height: 1;
    color: var(--paper);
  }

  kbd.inverted {
    border-color: var(--black);
    color: var(--black);
  }
</style>
