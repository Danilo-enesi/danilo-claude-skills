import { atom, read, update } from 'claude-code'
import type { EngineInterface } from 'claude-code'

import type { HookInstall } from '../types'

export const LOCAL_SETTINGS = '.claude/settings.local.json'

// Where the session started: Claude Code reads the project's settings there, while $.session.cwd() follows every `cd`.
const startCwd = atom({ plugin: 'repo-deck', key: 'startCwd' } as const, '', { shape: 'startCwd-1' })

// Kept from the first session.start only: a reload re-runs it after the cwd may have moved.
export async function rememberStart($: EngineInterface, cwd: string) {
  await update($, startCwd, cur => cur || cwd.replace(/\\/g, '/'))
}

// Adds the hook under its event/matcher; `added` false when that command is already there.
export function addHook(settings: Record<string, any>, hook: HookInstall): { settings: Record<string, any>; added: boolean } {
  const hooks = { ...(settings.hooks ?? {}) }
  const groups: any[] = [...(hooks[hook.event] ?? [])]
  const has = groups.some(g => (g.hooks ?? []).some((h: any) => h.command === hook.command))
  if (has) return { settings, added: false }
  const at = groups.findIndex(g => (g.matcher ?? '') === (hook.matcher ?? ''))
  const entry = { type: 'command', command: hook.command, ...(hook.timeout ? { timeout: hook.timeout } : {}) }
  if (at >= 0) groups[at] = { ...groups[at], hooks: [...(groups[at].hooks ?? []), entry] }
  else groups.push({ ...(hook.matcher ? { matcher: hook.matcher } : {}), hooks: [entry] })
  hooks[hook.event] = groups
  return { settings: { ...settings, hooks }, added: true }
}

// A path and every folder above it, nearest first: `C:/a/b` -> `C:/a/b`, `C:/a`, `C:`.
export function ancestors(path: string): string[] {
  const parts = path.replace(/\\/g, '/').replace(/\/+$/, '').split('/')
  return parts.map((_, i) => parts.slice(0, parts.length - i).join('/')).filter(Boolean)
}

// The session's start folder; without it, the nearest folder above the cwd holding `.git`.
export async function projectRoot($: EngineInterface): Promise<string> {
  const start = await read($, startCwd)
  if (start) return start
  const cwd = await $.session.cwd()
  for (const dir of ancestors(cwd)) {
    if (await $.fs.exists(`${dir}/.git`)) return dir
  }
  return cwd.replace(/\\/g, '/')
}

// Installs the hook for this project only (local scope, not committed): .claude/settings.local.json of the project root.
export async function installLocal($: EngineInterface, hook: HookInstall): Promise<string> {
  const file = `${await projectRoot($)}/${LOCAL_SETTINGS}`
  let current: Record<string, any> = {}
  if (await $.fs.exists(file)) {
    try {
      current = JSON.parse(await $.fs.read(file))
    } catch {
      // never overwrite a settings file we cannot parse: the person's other settings would be lost
      return `${file} non è JSON valido: non l'ho toccato`
    }
  }
  const { settings, added } = addHook(current, hook)
  if (!added) return `Hook già presente in ${file}`
  await $.fs.write(file, `${JSON.stringify(settings, null, 2)}\n`)
  return `Hook installato in ${file}: attivo da /hooks o dalla prossima sessione`
}
