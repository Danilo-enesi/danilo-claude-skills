import { test, expect } from 'claude-code/testing'

import { cut, fill } from './deck'

test('fill clamps the meter', async () => {
  expect(fill(66, 100)).toBe(7)
  expect(fill(5, 0)).toBe(0)
  expect(fill(200, 100, 4)).toBe(4)
})

test('cut keeps one row', async () => {
  expect(cut('a  b\nc', 10)).toBe('a b c')
  expect(cut('abcdef', 4)).toBe('abc…')
})
