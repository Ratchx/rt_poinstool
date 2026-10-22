<script lang="ts">
  let {
    label,
    checked,
    ariaLabel,
    onchange,
  }: { label: string; checked: boolean; ariaLabel?: string; onchange: (value: boolean, event: MouseEvent) => void } = $props()
</script>

<button class="check" class:on={checked} role="checkbox" aria-checked={checked} aria-label={ariaLabel} onclick={(event) => onchange(!checked, event)}>
  <span class="box"></span>{label}
</button>

<style>
  .check {
    display: inline-flex;
    align-items: center;
    gap: calc(8 * var(--px));
    padding: 0;
    border: 0;
    background: transparent;
    font-size: var(--text-sm);
    color: var(--graphite);
    white-space: nowrap;
  }

  .check.on {
    color: var(--paper);
  }

  .box {
    position: relative;
    flex: none;
    width: calc(16 * var(--px));
    height: calc(16 * var(--px));
    border: calc(1.5 * var(--px)) solid var(--ash);
    border-radius: calc(4 * var(--px));
  }

  .check:hover .box {
    border-color: var(--graphite);
  }

  .check.on .box {
    border-color: var(--paper);
    background: var(--paper);
  }

  .check.on .box::after {
    content: '';
    position: absolute;
    left: calc(4.5 * var(--px));
    top: calc(1 * var(--px));
    width: calc(4 * var(--px));
    height: calc(8 * var(--px));
    border: solid var(--black);
    border-width: 0 calc(2 * var(--px)) calc(2 * var(--px)) 0;
    transform: rotate(45deg);
  }
</style>
