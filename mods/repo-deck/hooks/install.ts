import type { EngineInterface } from 'claude-code'

import type { HookInstall } from '../types'

export const LOCAL_SETTINGS = '.claude/settings.local.json'

// Adds the hook under its event/matcher; `added` false when that command is already there.
export function addHook(settings: Record<string, any>, hook: HookInstall): { settings: Record<string, any>; added: boolean } {
  const hooks = { ...(settings.hooks ?? {}) }
  const groups: any[] = [...(hooks[hook.event] ?? [])]
  const has = groups.some(g => (g.hooks ?? []).some((h: any) => h.command === hook.command))
  if (has) return { settings, added: false }
  const at = groups.findIndex(g => (g.matcher ?? '') === (hook.matcher ?? ''))
  const entry = { type: 'command', command: hook.command }
  if (at >= 0) groups[at] = { ...groups[at], hooks: [...(groups[at].hooks ?? []), entry] }
  else groups.push({ ...(hook.matcher ? { matcher: hook.matcher } : {}), hooks: [entry] })
  hooks[hook.event] = groups
  return { settings: { ...settings, hooks }, added: true }
}

// Installs the hook for this project only (local scope, not committed): .claude/settings.local.json of the cwd.
export async function installLocal($: EngineInterface, hook: HookInstall): Promise<string> {
  let current: Record<string, any> = {}
  if (await $.fs.exists(LOCAL_SETTINGS)) {
    try {
      current = JSON.parse(await $.fs.read(LOCAL_SETTINGS))
    } catch {
      // never overwrite a settings file we cannot parse: the person's other settings would be lost
      return `${LOCAL_SETTINGS} non è JSON valido: non l'ho toccato`
    }
  }
  const { settings, added } = addHook(current, hook)
  if (!added) return `Hook già presente in ${LOCAL_SETTINGS}`
  await $.fs.write(LOCAL_SETTINGS, `${JSON.stringify(settings, null, 2)}\n`)
  return `Hook installato in ${LOCAL_SETTINGS}: attivo da /hooks o dalla prossima sessione`
}
