<h1 dir="rtl">معجم يسمو للمصطلحات التقنية الحديثة</h1>

Check it at: https://noureddin.github.io/ysmu/

Or see the summarized entries (without their explainations) at: https://github.com/noureddin/ysmu/raw/main/ysmu.tsv

The **experimental** entries are at: https://noureddin.github.io/ysmu/experimental/

Resources, guidelines, and general notes are available at: https://noureddin.github.io/ysmu/notes/

## Contact

Open [an issue](https://github.com/noureddin/ysmu/issues), or talk to us on Aosus Localization's Matrix room: [#localization:aosus.org](https://matrix.to/#/#localization:aosus.org).

## License

[Creative Commons Zero](https://creativecommons.org/choose/zero/) (equivalent to Public Domain).

## Structure

This repo consists of four logical sections:

- Data:

    - `w/`: contains all the (stable) words: each entry is a single English word with its translation(s) and explanation and contextual details.
        - The filename is the English term in small case (with spaces, if any, replaced with underscores).
        - The first paragraph in each file is the summary that tells how to translate this word without explanation. This is what gets into `ysmu.tsv` and hence into other dictionaries.
        - The rest of the file is paragraphs explaining the choice of the Arabic term, and its usage in different contexts etc.
        - The file may end in a "see also" section, linking to other English terms that are related in some way to this English term.
        - Files use a home-grown restricted lightweight markup language described in `MARK.md`.

    - `x/`: like `w/` but contains only experimental entries, including changes to “stable” entries.

    - `.h/`: hidden entries, that still haven't reached the “staging area” called `x/` yet.

    - `notes/src`: resources, guidelines, and general notes that might be of interest to those interested in this project. It uses a superset of the lightweight markup language used in entries.

- Processing:

    - `p/`: contains the processing script that converts the lightweight marked up files in `w/` into a single good-looking HTML file, and another one for `x/`, and generates `ysmu.tsv`.

    - `Makefile`: calls the appropriate script in `p/` and does all the necessary processing when something changes.

- Output:

    - `ysmu.tsv`: an English-Arabic dictionary as summarized from the stable entries in `w/`.

    - `index.html`: a human-friendly rendering of the entries in `w/`.

    - `experimental/`: contains a single file: `index.html`, which is like the root's `index.html` but for the experimental entries only.

    - `notes/index.html`: a human-friendly rendering of `notes/src`.

- Static:

    - `style.css`: the CSS style shared by the HTML files.

    - `MARK.md`: an informal description of the lightweight markup language used in this project.

    - `README.md`.

    - `LICENSE`.
