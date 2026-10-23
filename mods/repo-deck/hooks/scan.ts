import type { EngineInterface } from 'claude-code'

import type { Catalog, Entry } from '../types'

// shortcut: fallback path of this PC, used only when the session is not opened inside the repo
const FALLBACK_ROOT = 'C:/Users/danilo/Dev/danilo-claude-skills'
const MARKET = '.claude-plugin/marketplace.json'

// Frontmatter `key:` value, also the folded `key: >` form.
export function frontmatter(text: string, key: string): string {
  const head = text.match(/^---\r?\n([\s\S]*?)\r?\n---/)?.[1] ?? ''
  const lines = head.split(/\r?\n/)
  const at = lines.findIndex(line => line.startsWith(`${key}:`))
  if (at < 0) return ''
  let value = lines[at].slice(key.length + 1).trim()
  if (/^[>|]-?$/.test(value) || value === '') {
    const rest: string[] = []
    for (const line of lines.slice(at + 1)) {
      if (!/^\s+/.test(line)) break
      rest.push(line.trim())
    }
    value = rest.join(' ')
  }
  return value.replace(/^["']|["']$/g, '')
}

// Path of the script a hook command runs, relative to its plugin (`hooks/x.sh`).
export function hookScript(command: string): string | undefined {
  return command.match(/(?:CLAUDE_PLUGIN_ROOT\}?[\\/]+)?(hooks[\\/][^"'\s\\]+)/)?.[1]
}

// First comment line of a script, after the shebang: the hook's own description.
export function firstComment(text: string): string {
  for (const line of text.split(/\r?\n/).slice(0, 15)) {
    const m = line.match(/^\s*(?:#(?!!)|\/\/|""")\s*(.+?)\s*(?:""")?$/)
    if (m && m[1]) return m[1]
  }
  return ''
}

async function list($: EngineInterface, path: string) {
  return (await $.fs.exists(path)) ? $.fs.list(path) : []
}

// Standalone skills, commands, agents and hooks: those of the root plugin, which is the repo itself.
// `absDir` replaces ${CLAUDE_PLUGIN_ROOT} so a hook can be installed outside the plugin.
async function scanDir($: EngineInterface, dir: string, absDir: string, owner: string): Promise<Entry[]> {
  const out: Entry[] = []
  {
    for (const e of await list($, `${dir}/skills`)) {
      const file = `${dir}/skills/${e.name}/SKILL.md`
      if (e.kind !== 'dir' || !(await $.fs.exists(file))) continue
      const text = await $.fs.read(file)
      const name = frontmatter(text, 'name') || e.name
      out.push({ kind: 'skill', name, owner, description: frontmatter(text, 'description'), invoke: `/${owner}:${name} ` })
    }
  }
  for (const kind of ['command', 'agent'] as const) {
    for (const e of await list($, `${dir}/${kind}s`)) {
      if (!e.name.endsWith('.md')) continue
      const text = await $.fs.read(`${dir}/${kind}s/${e.name}`)
      const name = e.name.replace(/\.md$/, '')
      const invoke = kind === 'command' ? `/${owner}:${name} ` : `Usa l'agente ${owner}:${name} per `
      out.push({ kind, name, owner, description: frontmatter(text, 'description'), invoke })
    }
  }
  const hooksFile = `${dir}/hooks/hooks.json`
  if (await $.fs.exists(hooksFile)) {
    const hooks: Record<string, any[]> = JSON.parse(await $.fs.read(hooksFile)).hooks ?? {}
    for (const [event, groups] of Object.entries(hooks)) {
      for (const group of groups) {
        for (const hook of group.hooks ?? []) {
          const script = hookScript(String(hook.command ?? ''))
          const path = script ? `${dir}/${script.replace(/\\/g, '/')}` : ''
          const own = path && (await $.fs.exists(path)) ? firstComment(await $.fs.read(path)) : ''
          out.push({
            kind: 'hook',
            name: script ? script.replace(/^hooks[\\/]/, '') : event,
            owner,
            meta: event,
            description: own || String(hook.command ?? ''),
            install: {
              event,
              ...(group.matcher ? { matcher: String(group.matcher) } : {}),
              command: String(hook.command ?? '').replace(/\$\{CLAUDE_PLUGIN_ROOT\}|\$CLAUDE_PLUGIN_ROOT/g, absDir),
            },
          })
        }
      }
    }
  }
  return out
}

export async function scan($: EngineInterface): Promise<Catalog> {
  const started = Date.now()
  const root = (await $.fs.exists(MARKET)) ? '.' : FALLBACK_ROOT
  const market = JSON.parse(await $.fs.read(`${root}/${MARKET}`))
  const abs = ((await $.fs.stat(root, { resolve: true })).realPath ?? root).replace(/\\/g, '/')
  const entries: Entry[] = []
  for (const p of market.plugins ?? []) {
    const rel = String(p.source).replace(/^\.\/?/, '').replace(/\/$/, '')
    const dir = rel ? `${root}/${rel}` : root
    const meta = JSON.parse(await $.fs.read(`${dir}/.claude-plugin/plugin.json`))
    const own = rel === '' ? await scanDir($, dir, abs, p.name) : []
    if (rel !== '') {
      entries.push({
        kind: 'plugin',
        name: p.name,
        owner: p.name,
        description: p.description ?? meta.description ?? '',
        meta: `v${meta.version ?? '?'}`,
        // args of the built-in /plugin command, run as is by the INSTALLA button
        invoke: `install ${p.name}@${market.name}`,
      })
    }
    entries.push(...own)
  }
  return { root, entries, scannedMs: Date.now() - started }
}
