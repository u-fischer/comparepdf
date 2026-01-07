# comparepdf

Compare the PDF output of legacy LaTeX with tagged PDF. 

## Requirements

A working ImageMagick that can compare PDFs. 
That means `magick compare test1.pdf test2.pdf diff.png` should work.

A current TeX system.

## Use

`texlua comparepdf.lua <options> file`

This will compare a legacy compilation of `file` (with jobname `file-legacy.pdf`) with the original compilation (with jobname `file-new.pdf`).
If one of the compilation fails, an error is reported and the script stops. If the compilations succeed it compares the PDFs page by page creates for every page N with a difference a file `file-diff-N.png`.
If one of the PDF has more pages the surplus is silently ignored.


* The file should start with `\DocumentMetadata`. In the legacy compilation this will be redefined to do nothing.
  Some other commands like `\DebugBlocksOn` are redefined too. Other commands that do not exist in legacy LaTeX should be wrapped in a `\IfDocumentMetadataT`. 

* extension `.tex is assumed, for other extensions use option `-eXXX`, e.g. `-elvt`

* The compilation uses lualatex-dev. `-p` switches to pdflatex-dev. It then also forces T1-encoding in the legacy compilation. 

* By default compilation runs twice on every version, this can be changed with the option `-rN`, e.g. `-r1` compiles once.

* Other options are described in the lua-file.

* The option `-v` opens the file in the default png viewer (with `start` on windows or `xdg-open`). This perhaps would need customising for other platforms.
  The option is nice for a single test but a bit disturbing if one runs a loop over multiple files. 

## Batchfiles

There are two example batch files. `comparepdf` calls a single test. `comparetestfiles` loops over all `.lvt` and `.pvt` files in the current folder.


