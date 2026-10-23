export type Clicks = number

declare module 'claude-code' {
  interface PluginState {
    '__NAME__': { clicks: Shaped<Clicks> }
  }
}
