import type { Elements, RenderChildren } from 'claude-code'

// Flightdeck look: dark pane, one accent per actor (border + title), mono grid, `·` separators.
export const tone = {
  orange: '#c06050',
  violet: '#a078f8',
  green: '#48b860',
  lavender: '#a8b0e8',
  cyan: '#60b0c0',
  text: '#e0e0e0',
  muted: '#888888',
  faint: '#606068',
} as const
export type Tone = keyof typeof tone

// Cells of a block meter that are filled, clamped to [0, cells].
export function fill(value: number, max: number, cells = 10): number {
  if (max <= 0) return 0
  return Math.max(0, Math.min(cells, Math.round((value / max) * cells)))
}

// Cut a text to one terminal row of `width` cells.
export function cut(text: string, width: number): string {
  const flat = text.replace(/\s+/g, ' ').trim()
  return flat.length <= width ? flat : `${flat.slice(0, Math.max(0, width - 1))}…`
}

export function deck(el: Elements['terminal']) {
  const { Box, Text, Button } = el

  // With `onTitle` the title is a Button
  const Header = ({ title, onTitle }: { title: string; onTitle?: () => void }) => (
    <Box flexDirection="column" alignItems="center" marginBottom={1}>
      <Box flexDirection="row" justifyContent="center">
        {onTitle ? (
          <Button key="header:title" plain onPress={onTitle}>
            <Text bold color={tone.text}>{title}</Text>
          </Button>
        ) : (
          <Text bold color={tone.text}>{title}</Text>
        )}
      </Box>
    </Box>
  )

  // With `onToggle` the caret and the title are one Button that collapses the card; `isOpen` picks ▾ / ▸
  const Card = (props: {
    title: string
    sub?: string
    right?: string
    color: Tone
    isOpen?: boolean
    onToggle?: () => void
    children?: RenderChildren
  }) => {
    const title = (
      <Text bold color={tone[props.color]}>
        {props.title}
        {props.sub ? <Text color={tone[props.color]}> · {props.sub}</Text> : null}
      </Text>
    )
    return (
      <Box flexDirection="column" borderStyle="round" borderColor={tone[props.color]} paddingX={1}>
        <Box flexDirection="row" justifyContent="space-between">
          {props.onToggle ? (
            <Button key={`card:${props.title}`} plain onPress={props.onToggle}>
              <Text color={tone[props.color]}>{props.isOpen === false ? '▸ ' : '▾ '}</Text>
              {title}
            </Button>
          ) : (
            title
          )}
          {props.right ? <Text color={tone.muted}>{props.right}</Text> : null}
        </Box>
        {props.isOpen === false ? null : props.children}
      </Box>
    )
  }

  const Meter = ({ value, max, cells = 10, color }: { value: number; max: number; cells?: number; color: Tone }) => {
    const full = fill(value, max, cells)
    return (
      <Text>
        <Text color={tone[color]}>{'▬'.repeat(full)}</Text>
        <Text color={tone.faint}>{'▭'.repeat(cells - full)}</Text>
      </Text>
    )
  }

  // label value · label value
  const Kv = ({ pairs }: { pairs: [string, string | number][] }) => (
    <Text>
      {pairs.map(([k, v], i) => (
        <Text>
          {i > 0 ? <Text color={tone.faint}> · </Text> : null}
          <Text color={tone.muted}>{k} </Text>
          <Text bold color={tone.text}>{String(v)}</Text>
        </Text>
      ))}
    </Text>
  )

  return { Header, Card, Meter, Kv }
}
