import { afterAll, beforeAll, describe, expect, test } from '@vidot/vitest'
import { _Example } from './src/main.ts'

describe('editable Godot project', () => {
  const expectedValue = 7
  const previousRoots: Node[] = []

  beforeAll((context) => {
    expect(context.root).toBe(null)
  })

  test('runs inside the project', async (context) => {
    if (!expect(context.root !== null).toBe(true) || context.root === null)
      return

    previousRoots.append(context.root)
    const importedScene = new _Example()
    context.root.add_child(importedScene)
    expect(importedScene.increment(1)).toBe(1)

    const scriptPath = ProjectSettings.globalize_path('res://scripts/main.gd')
    const scene = context.instantiate<_Example>(scriptPath)
    if (!expect(scene !== null).toBe(true) || scene === null)
      return

    context.root.add_child(scene)

    expect(scene.increment(2)).toBe(2)

    scene.set_later(expectedValue)
    expect(await context.waitUntil(() => scene.value === expectedValue, 500)).toBe(true)
    expect(scene.value).toBe(expectedValue)
  })

  test('releases the previous test root', (context) => {
    expect(previousRoots.size()).toBe(1)
    expect(is_instance_valid(previousRoots[0])).toBe(false)
    expect(context.root !== null).toBe(true)
  })

  afterAll((context) => {
    expect(context.root).toBe(null)
  })
})
