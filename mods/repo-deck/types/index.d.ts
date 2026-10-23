export type Kind = 'plugin' | 'command' | 'skill' | 'hook' | 'agent'
export type Entry = { kind: Kind; name: string; owner: string; description: string; meta?: string; invoke?: string }
export type Catalog = { root: string; entries: Entry[]; scannedMs: number }

declare module 'claude-code' {
  interface PluginState {
    'repo-deck': {
      catalog: Shaped<Catalog>
      selected: Shaped<string>
      collapsed: Shaped<Kind[]>
      error: Shaped<string>
    }
  }
}
