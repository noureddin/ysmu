Inline formatting (in a single line, not across lines):
- `{{just some ltr text}}`: forces some part of the text to be LTR.
- `**strong emphasis**`: use sparingly.
- ```` ``LTR code`` ````: an inline code span, always LTR.
- `<<::term>>`: link to a term (may be in a different stage) (shows as LTR)
- `<<altname::term>>`: like the above but with an alternative title, and thus doesn't force LTR; use `{{` and `}}`.
- `<<https://link>>`: an external link (shows as LTR)
- `<<altname||https://link>>`: like the above but with alternative title, and thus doesn't force LTR; use `{{` and `}}`.
- `~~strokeout~~`: to strike out or delete some text, for instance to show bad examples of usage.
- No fancy Unicode transformations are done whatsoever; bring your own fancy quotes, ellipses, dashes, and so on.

Line formatting:
- Newlines are rendered as line breaks (ie hard line breaks). (Use a text editor that supports soft wrapping.)

Block formatting:
- Blank lines delimit paragraphs.
- `""""` on a line by its own, preceding a paragraph, makes it a blockquote.
- `::::` on a line by its own, makes every line till the end of paragraph a see-also linked term. It should be used at the end.
- `----` in a paragraph by its own makes a `<hr>` (thematic break); use sparingly.
- `@@@@` in a paragraph by its own makes a negative paragraph space; can be used between paragraph and following tight lists
  (ie, lists whose all items are lines, never a block element like a paragraph).

Big blockquotes:
- Start it by `>>>>` in a paragraph by its own, and end it by `<<<<` in a paragraph on its own.

Lists (other than "see-also" term lists):
- Start an ordered list with `##((` in a paragraph by its own, and end it by `))##` in a paragraph by its own. (Think number = "#".)
- Start an unordered list with `++((` in a paragraph by its own, and end it by `))++` in a paragraph by its own. (Think "+" is like a bullet.)
- `[[type]]` can precede a list opening mark in a line by its own, to mark this list with a CSS `list-style-type`;
  eg `[[arabic-indic]]\n##((` or `[['* ']]\n++((`.
- Each item can be defined in two ways:
  - Start a line with `--` then a space, to make a `<li>` without inner `<p>`.
  - Put `****` in its own paragraph, to enclose in a `<li>` everything till the next item mark or list closing mark.

---

That's for entries (under `w/`, `c/`, and `x/`); notes (`notes/src`) has the same syntax plus these additions:
- `!!!!` followed by a list of "`https://link` long mandatory title" lines to make a list of external links.
- Starting a paragraph with `== title` makes that a `h2`, and preceding that with `[[id]]` on a separate line in the same
  paragraph gives it an id and makes it a link.

Other notes:
- Files' names in `w/`, `c/`, and `x/` must not contain spaces; use underscores instead.

General info:
- All inline formatting (including those that must start a line) are two repeating punctuation characters, no exceptions.
- All paragraph formatting (those that must stand in a paragraph by their own, and those that must be the first (entire)
  line of their paragraph) are four punctuation characters, mostly repeating.
