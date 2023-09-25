<h1 dir="rtl">معجم يسمو للمصطلحات التقنية الحديثة</h1>

Check it at: https://noureddin.github.io/ysmu/

The **experimental** entries are at: https://noureddin.github.io/ysmu/experimental/

Resources, guidelines, and general notes are available at: https://noureddin.github.io/ysmu/notes/

## Contact

Open [an issue](https://github.com/noureddin/ysmu/issues), or talk to us on Aosus Localization's Matrix room: [#localization:aosus.org](https://matrix.to/#/#localization:aosus.org).

## License

[Creative Commons Zero](https://creativecommons.org/choose/zero/) (equivalent to Public Domain).

## Structure

This repo consists of four sections:

- Data:

    - `w/`: contains all the (stable) words, one English word in each file, representing a single entry. Files use a home-grown restricted lightweight markup language, which is described in `MARK.md`.

    - `x/`: like `w/` but contains only experimental entries, including changes to “stable” entries.

    - `.h/`: hidden entries, that still haven't reached the “staging area” called `x/`.

    - `notes/src`: resources, guidelines, and general notes that might be of interest to those interested in this project.

- Processing:

    - `p/`: contains the processing script that converts the lightweight marked up files in `w/` into a single good-looking HTML file, and another one for `x/`, and generates `ysmu.tsv`.

    - `Makefile`: calls the appropriate script in `p/` and does all the necessary processing on change.

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
