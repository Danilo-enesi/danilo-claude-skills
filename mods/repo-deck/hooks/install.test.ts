import { test, expect } from 'claude-code/testing'

import { addHook, ancestors } from './install'

const hook = { event: 'PreToolUse', matcher: 'Edit|Write', command: 'bash "/r/hooks/x.sh"' }

test('addHook creates the event and keeps other settings', async () => {
  const { settings, added } = addHook({ permissions: { allow: ['Bash(ls)'] } }, hook)
  expect(added).toBe(true)
  expect(settings.permissions.allow[0]).toBe('Bash(ls)')
  expect(settings.hooks.PreToolUse[0].matcher).toBe('Edit|Write')
  expect(settings.hooks.PreToolUse[0].hooks[0].command).toBe(hook.command)
})

test('addHook joins an existing matcher and never duplicates', async () => {
  const start = { hooks: { PreToolUse: [{ matcher: 'Edit|Write', hooks: [{ type: 'command', command: 'other' }] }] } }
  const once = addHook(start, hook)
  expect(once.settings.hooks.PreToolUse.length).toBe(1)
  expect(once.settings.hooks.PreToolUse[0].hooks.length).toBe(2)
  expect(addHook(once.settings, hook).added).toBe(false)
})

test('ancestors walks up to the drive', async () => {
  expect(ancestors('C:\\a\\b')).toEqual(['C:/a/b', 'C:/a', 'C:'])
  expect(ancestors('/home/x/')).toEqual(['/home/x', '/home'])
})
