Inline formatting (in a single line, not across lines):
- `{{just some ltr text}}`: forces some part of the text to be LTR.
- `**strong emphasis**`: use sparingly.
- `<<::term>>`: link a term (shows as LTR)
- `<<altname::term>>`: like the above but with alternative title, and thus doesn't force LTR; use `{{` and `}}`.
- `<<https://link>>`: an external link (shows as LTR)
- `<<altname||https://link>>`: like the above but with alternative title, and thus doesn't force LTR; use `{{` and `}}`.
- No fancy Unicode transformations are done whatsoever; bring your own fancy quotes, ellipses, dashes, and so.

Line formatting:
- Newline at the end means a line break (ie hard line breaks). (Use a text editor that supports soft wrapping.)

Block formatting:
- Blank lines delimit paragraphs.
- `>>>>` on a line by its own, preceding a paragraph, makes it a blockquote.
- `::::` on a line by its own, makes every line till the end of paragraph a see-also linked term. It should be used at the end.
