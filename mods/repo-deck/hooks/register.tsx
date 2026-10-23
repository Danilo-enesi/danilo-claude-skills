import { atom, read, update } from 'claude-code'
import type { Register, EngineInterface } from 'claude-code'

import type { Catalog, Entry, Kind } from '../types'
import { cut, deck, tone } from './deck'
import type { Tone } from './deck'
import { installLocal } from './install'
import { scan } from './scan'

const PANE = 'repo-deck'
const catalog = atom({ plugin: 'repo-deck', key: 'catalog' } as const, { root: '', entries: [], scannedMs: 0 } as Catalog, { shape: 'catalog-2' })
const selected = atom({ plugin: 'repo-deck', key: 'selected' } as const, '', { shape: 'selected-1' })
const collapsed = atom({ plugin: 'repo-deck', key: 'collapsed' } as const, [] as Kind[], { shape: 'collapsed-1' })
const error = atom({ plugin: 'repo-deck', key: 'error' } as const, '', { shape: 'error-1' })

const SECTIONS: { kind: Kind; title: string; color: Tone }[] = [
  { kind: 'plugin', title: 'PLUGINS', color: 'orange' },
  { kind: 'command', title: 'COMMANDS', color: 'violet' },
  { kind: 'skill', title: 'SKILLS', color: 'green' },
  { kind: 'hook', title: 'HOOKS', color: 'lavender' },
  { kind: 'agent', title: 'AGENTS', color: 'cyan' },
]

const keyOf = (x: Entry) => `${x.kind}:${x.owner}:${x.name}`

async function load($: EngineInterface) {
  try {
    const found = await scan($)
    await update($, catalog, () => found)
    await update($, error, () => '')
  } catch (err) {
    await update($, error, () => `Scansione fallita: ${String(err)}`)
  }
}

// A plugin installs through the built-in /plugin command; anything else goes in the prompt.
async function use($: EngineInterface, x: Entry) {
  if (x.kind !== 'plugin') return void (await $.prompt.fill({ text: x.invoke ?? '' }))
  await $.command.run({ command: 'plugin', args: x.invoke ?? '' }).catch(err => $.ui.toast(`Installazione non avviata: ${String(err)}`))
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: 'repo-deck', description: 'Pane: plugin, comandi, skill, hook e agenti del repo danilo-claude-skills' })
    void load($)
    return next(e)
  })

  on('command.run', { command: 'repo-deck' }, async $ => {
    await load($)
    const opened = await $.ui.open({ id: PANE, title: 'Repo deck', focus: true }).catch(err => ({ isPlaced: false as const, reason: String(err) }))
    return { text: opened.isPlaced ? 'Repo deck aperto.' : `Pane non aperto: ${'reason' in opened ? opened.reason : ''}` }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const el = $.ui.resolve(e)
    if (e.surface !== 'terminal') return <el.Text>Repo deck è pensato per il terminale.</el.Text>
    const { Box, Text, Button } = el
    const { Header, Card, Kv } = deck(el as never)
    const cat = await read($, catalog)
    const sel = await read($, selected)
    const shut = await read($, collapsed)
    const problem = await read($, error)
    const cols = Math.max(30, (e.props?.bodyColumns ?? 60) - 4)
    const count = (k: Kind) => cat.entries.filter(x => x.kind === k).length
    const pick = (x: Entry) => () => void update($, selected, cur => (cur === keyOf(x) ? '' : keyOf(x)))
    const toggle = (k: Kind) => () => void update($, collapsed, list => (list.includes(k) ? list.filter(x => x !== k) : [...list, k]))
    const current = cat.entries.find(x => keyOf(x) === sel)
    const colorOf = (k: Kind) => SECTIONS.find(s => s.kind === k)?.color ?? 'text'

    return (
      <Box flexDirection="column">
        <Header title={`REPO DECK · ${cat.root === '.' ? 'cwd' : cat.root}`} legend={SECTIONS.map(s => [s.kind, s.color] as [string, Tone])} />
        {problem ? <Text color="red">{problem}</Text> : null}

        {SECTIONS.map(s => {
          const rows = cat.entries.filter(x => x.kind === s.kind)
          if (rows.length === 0) return null
          const isShut = shut.includes(s.kind)
          return (
            <Card
              title={s.title}
              right={`${rows.length}`}
              color={s.color}
              isOpen={!isShut}
              onToggle={toggle(s.kind)}
            >
              {rows.map(x => {
                  const isSel = keyOf(x) === sel
                  const head = s.kind === 'skill' || s.kind === 'plugin' ? x.name : `${x.owner}:${x.name}`
                  const tail = cut(x.meta ? `${x.meta} · ${x.description}` : x.description, cols - head.length - 4)
                  return (
                    <Button key={keyOf(x)} plain onPress={pick(x)}>
                      <Text color={isSel ? tone[s.color] : tone.text}>{isSel ? '◆ ' : '◇ '}{head}</Text>
                      <Text color={tone.muted}> {tail}</Text>
                    </Button>
                  )
                })}
            </Card>
          )
        })}

        {current ? (
          <Card title={current.name} right={current.meta} color={colorOf(current.kind) as Tone}>
            <Box marginTop={1}>
              <Text wrap="wrap" color={tone.text}>{current.description || 'Nessuna descrizione.'}</Text>
            </Box>
            <Box flexDirection="row" gap={1} marginTop={1}>
              {current.invoke ? (
                <Button key="use" variant="primary" hotkey="u" onPress={() => void use($, current)}>
                  {current.kind === 'plugin' ? 'INSTALLA' : 'USA NELLA CHAT'}
                </Button>
              ) : current.install ? (
                <Button key="install-local" variant="primary" hotkey="l" onPress={() => void installLocal($, current.install!).then(msg => $.ui.toast(msg), err => $.ui.toast(String(err)))}>
                  INSTALLA
                </Button>
              ) : null}
            </Box>
          </Card>
        ) : null}

        <Box borderStyle="round" borderColor={tone.orange} borderDimColor paddingX={1} flexDirection="row" justifyContent="space-between">
          <Text>
            <Kv pairs={SECTIONS.filter(s => count(s.kind) > 0).map(s => [s.kind, count(s.kind)] as [string, number])} />
            <Text color={tone.faint}> · {cat.scannedMs}ms</Text>
          </Text>
        </Box>
      </Box>
    )
  })
}
