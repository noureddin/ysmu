<h1 dir="rtl">معجم يسمو للمصطلحات التقنية الحديثة</h1>

Check it at: https://noureddin.github.io/ysmu/

## License

Creative Commons Zero (equivalent to Public Domain).

## Contact

Open a GitHub issue, or talk to us on Aosus Localization's Matrix room: `#localization:aosus.org`.

## Structure

This repo's files consists of three sections:

- Data:

    - `w/`: contains all the (stable) words, one English word in each file, representing a single entry. Files use a home-grown Markdown-like lightweight markup language, which is described in `MARK.md`.

    - `x/`: like `w/` but contains only experimental entries, including changes to “stable” entries.

- Processing:

    - `p/`: contains the processing script that converts the lightweight marked up files in `w/` into a single good-looking HTML file, and another one for `x/`, and generates `ysmu.tsv`.

    - `Makefile`: calls the appropriate script in `p/` and does all the necessary processing.

- Output:

    - `ysmu.tsv`: an English-Arabic dictionary as summarized from the stable entries in `w/`.

    - `index.html`: a human-friendly rendering of the entries in `w/`.

    - `experimental/`: contains a single file: `index.html`, which is like the root's `index.html` but for the experimental entries only.

    - `.style.css`: the CSS style shared by both HTML files.

    - `MARK.md`: an informal description of the lightweight markup language used in `w/` and `x/`.
