# Tags

Neuron supports Twitter like tags. Tags are added by prefixing them with `#`, and they can appear anywhere in the note text. For example:

```markdown
Gaslighting is enabled by the victim's #cognitive-distortion without which the
victimizer is rendered powerless to influence their victim.
```

In the above example, the note is tagged with `#cognitive-distortion` which also links to the tag page.

Tags can also be specified in the [[metadata]] block. The above tag can be specified alternatively as follows:

```markdown
---
tags:
  - cognitive-distortion 
```

## Hierarchical tags

Tags can be nested using a "tag/subtag" syntax, to allow a more fine-grained organization of your Zettelkasten, especially when using advanced queries as shown in [[link-query]].

For example, the following zettel is tagged "math/calculus/definition"

```markdown
---
tags:
  - math/calculus/definition
---

# Derivative
```

It will be included in the following tag queries:

- `math/**`
- `math/calculus/*`
- `math/calculus/definition`
- `**/definition`

See [[link-query]] to understand how to link zettels automatically based on tag patterns as above.

## Tag trees

Use `[[z:tags?filter=**]]` to render your entire tags set as a tree. Note that this only *renders* the tags; whereas `[[z:zettels?tag=...]]` of [[link-query]] exists to *link* to the zettels tagged with matching tags.
