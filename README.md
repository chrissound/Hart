# Hart

## What problem does this solve?
Allows you to embed and reference various features within a format agnostic document, some relation to https://en.wikipedia.org/wiki/Literate_programming.

A project would be structured as:

```
Section1.md / commit1
            / commit2
            / commit3
Section2.md / commit4
            / commit5
Section3.md / commit6
            / commit7
```

This also means that if you want to `amend` an old section / code, you do a git rebase, change the code and thats it (well you still need to rerun the compilation / rendering)! No need to modify anything else as the section files only store references relating to files / diffs.

Some possible similar projects of interest:
https://byorgey.wordpress.com/blogliterately/
http://www.andrevdm.com/posts/2018-02-05-hakyll-code-build-include-compiler.html



## Supported tags / features:
`{{ sectionHeader }}` returns the text `Secton x` where x is the section number.

`{{ gitDiff path/to/file.sh }}` returns  a `git diff` of file.

`{{ file path/to/file.sh }}` returns the entire content of file.

`{{ gitCommitOffset }}` returns a special section's commit 'range'.

`{{ fileSection path/to/file.hs main }}` returns a section from a file (thanks to https://github.com/owickstrom/pandoc-include-code)

`{{{{ shellOutput command goes here }}}}` which would execute `command goes here` (in your shell) and output whatever is returned.

`{{{ghci
:t head
}}}` will run the code within a GHCi session and output the results.


## Limitations
Not 100% tested - but the core functionality (secitons?) works!
- Modifying 'older' section requires doing a  git rebase on that project - which may present some difficulty if you are accepting changes (git commits) from others. However changes can be shared by using additional git branches.
- There may be issues if you use text tags like `{{example}}` - there isn't any way to escape these at the moment. (TODO!)

## Installation
Most probably you would need to install Haskell / GHC (the Haskell compiler) + stack. It should be possible to provide a binary / docker image for this - but I'll need to investigate and test this first. 

## How to use this? Instructions?
Create a `sections` directory in a git repository. Create a `x_Example.md` file with your relevent commits, where x is a 'section' number. You can then render a project by executing:
`stack exec app -- /path/to/project` - this will generate a `compiledArticle.md` file from all the sections.  

Also using <https://github.com/jgm/pandoc> will allow you to generate HTML from markdown with a simple command like:
`pandoc --from markdown_strict+backtick_code_blocks -s compiledArticle.md -o compiled.html`

### Example 'projects':

- https://github.com/chrissound/NextUpHarticle
  Output available at: https://github.com/chrissound/NextUpHarticle/blob/master/compiledArticle.md

- https://github.com/chrissound/GentleIntroductionToMonadTransformers

![Screenshot](demo.jpg)

## Need help?
As this is a new project, if you hit any issues or need help setting anything up - please don't hesitate to post a github issue!  :)

