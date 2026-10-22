<script lang="ts">
  import Hud from './components/+hud.svelte'
  import Panel from './components/+panel.svelte'
  import { close } from './lib/api'
  import { config } from './stores/config.svelte'
  import { panel } from './stores/panel.svelte'

  $effect(() => {
    document.documentElement.style.setProperty('--ui-scale', String(config.scale))
  })

  const typing = (target: EventTarget | null) => target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement

  function onkeyup(event: KeyboardEvent) {
    if (!panel.open || event.key !== 'Escape') return

    close()
  }

  function onkeydown(event: KeyboardEvent) {
    if (!panel.open || event.repeat || typing(event.target)) return
    if (event.key.toUpperCase() !== config.keys.menu.toUpperCase()) return

    event.preventDefault()
    close()
  }
</script>

<svelte:window {onkeyup} {onkeydown} oncontextmenu={(event) => event.preventDefault()} />

<Hud />

{#if panel.open}
  <Panel />
{/if}
