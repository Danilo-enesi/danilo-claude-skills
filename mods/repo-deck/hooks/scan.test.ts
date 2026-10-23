import { test, expect } from 'claude-code/testing'

import { firstComment, frontmatter, hookScript } from './scan'

test('frontmatter reads inline and folded values', async () => {
  expect(frontmatter('---\nname: a\ndescription: "Fa X"\n---\nbody', 'description')).toBe('Fa X')
  expect(frontmatter('---\r\ndescription: >\r\n  uno\r\n  due\r\nname: b\r\n---', 'description')).toBe('uno due')
  expect(frontmatter('no frontmatter', 'name')).toBe('')
})

test('hookScript finds the script under the plugin root', async () => {
  expect(hookScript('bash "${CLAUDE_PLUGIN_ROOT}/hooks/block-lang-edits.sh"')).toBe('hooks/block-lang-edits.sh')
  expect(hookScript('python -I "${CLAUDE_PLUGIN_ROOT}\\hooks\\guard.py"')).toBe('hooks\\guard.py')
  expect(hookScript('echo hi')).toBe(undefined)
})

test('firstComment skips the shebang', async () => {
  expect(firstComment('#!/usr/bin/env bash\n# Blocca X\nset -e')).toBe('Blocca X')
  expect(firstComment('"""Guard del progetto."""\nimport os')).toBe('Guard del progetto.')
  expect(firstComment('echo')).toBe('')
})
