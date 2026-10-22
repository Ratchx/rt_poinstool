<script lang="ts">
  import { onDestroy } from 'svelte'

  const ARM_MS = 3000

  let {
    label,
    confirmLabel,
    onconfirm,
    disabled = false,
    small = false,
  }: { label: string; confirmLabel: string; onconfirm: () => void; disabled?: boolean; small?: boolean } = $props()

  let armed = $state(false)
  let timer = 0

  function disarm() {
    clearTimeout(timer)
    armed = false
  }

  function press() {
    if (!armed) {
      armed = true
      timer = window.setTimeout(disarm, ARM_MS)
      return
    }

    disarm()
    onconfirm()
  }

  onDestroy(() => clearTimeout(timer))
</script>

<button class="btn" class:solid={armed} class:small {disabled} onclick={press} onblur={disarm}>
  {armed ? confirmLabel : label}
</button>
