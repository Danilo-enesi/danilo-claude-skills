import { atom, read, update } from 'claude-code'
import type { Register } from 'claude-code'

import { deck } from './deck'

const PANE = '__NAME__'
const clicks = atom({ plugin: '__NAME__', key: 'clicks' } as const, 0, { shape: 'clicks-1' })

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await $.command.register({ name: '__NAME__', description: '__TITLE__' })
    return next(e)
  })

  on('command.run', { command: '__NAME__' }, async $ => {
    const opened = await $.ui.open({ id: PANE, title: '__TITLE__', focus: true }).catch(err => ({ isPlaced: false as const, reason: String(err) }))
    return { text: opened.isPlaced ? '__TITLE__ aperto.' : `Pane non aperto: ${'reason' in opened ? opened.reason : ''}` }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const el = $.ui.resolve(e)
    if (e.surface !== 'terminal') return <el.Text>Solo terminale.</el.Text>
    const { Box, Button } = el
    const { Header, Card, Meter, Kv } = deck(el as never)
    const count = await read($, clicks)

    return (
      <Box flexDirection="column" gap={1}>
        <Header title="__TITLE__" legend={[['demo', 'orange']]} />
        <Card title="DEMO" sub="template" right={`${count} press`} color="orange">
          <Kv pairs={[['clicks', count], ['max', 10]]} />
          <Meter value={count} max={10} color="orange" />
        </Card>
        <Button key="inc" hotkey="p" onPress={() => void update($, clicks, n => n + 1)}>Premi</Button>
      </Box>
    )
  })
}
