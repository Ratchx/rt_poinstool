<script lang="ts">
  import { untrack } from 'svelte'

  let {
    label,
    value,
    placeholder,
    maxlength,
    oncommit,
  }: {
    label: string
    value: string
    placeholder: string
    maxlength: number
    oncommit: (model: string) => Promise<boolean>
  } = $props()

  const ALLOWED = /[^A-Za-z0-9_-]/g

  let draft = $state(untrack(() => value))
  let invalid = $state(false)
  let busy = $state(false)

  function oninput(event: Event & { currentTarget: HTMLInputElement }) {
    const clean = event.currentTarget.value.replace(ALLOWED, '')
    if (clean !== event.currentTarget.value) event.currentTarget.value = clean

    draft = clean
    invalid = false
  }

  async function commit() {
    if (busy || draft === value) return

    busy = true
    invalid = !(await oncommit(draft))
    busy = false
  }

  function onkeydown(event: KeyboardEvent) {
    if (event.key !== 'Enter') return

    commit()
  }
</script>

<label class="field" class:invalid class:busy>
  <span class="label">{label}</span>
  <input type="text" spellcheck="false" autocomplete="off" {maxlength} {placeholder} value={draft} {oninput} {onkeydown} onblur={commit} />
</label>

<style>
  .field {
    display: flex;
    align-items: center;
    gap: calc(8 * var(--px));
    height: calc(36 * var(--px));
    padding: 0 calc(10 * var(--px));
    border: calc(1 * var(--px)) solid transparent;
    border-radius: var(--radius-field);
    background: var(--smoke);
    transition: border-color 120ms var(--ease-out);
  }

  .field:hover {
    border-color: var(--rule);
  }

  .field:focus-within {
    border-color: var(--paper);
  }

  .field.invalid {
    border-color: var(--graphite);
    border-style: dashed;
  }

  .field.invalid input {
    text-decoration: line-through;
    color: var(--graphite);
  }

  .field.busy input {
    color: var(--ash);
  }

  .label {
    flex: none;
    font-size: var(--text-xs);
    font-weight: 700;
    color: var(--ash);
  }

  input {
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

  input::placeholder {
    color: var(--ash);
  }
</style>
