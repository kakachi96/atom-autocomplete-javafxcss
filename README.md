# JavaFX-CSS Autocomplete package
[![OS X Build Status](https://travis-ci.org/kgeorgiy/atom-autocomplete-javafxcss.svg?branch=master)](https://travis-ci.org/atom/autocomplete-css) [![Windows Build Status](https://ci.appveyor.com/api/projects/status/4uv3rfmxa1kgedmd/branch/master?svg=true)](https://ci.appveyor.com/project/Atom/autocomplete-css/branch/master)

JavaFX-specific CSS property name and value autocompletions in Atom. Uses the
[autocomplete-plus](https://github.com/atom-community/autocomplete-plus) package.

This is powered by the list of CSS property and values 
from the [JavaFX CSS Reference Guide](https://docs.oracle.com/javase/8/javafx/api/javafx/scene/doc-files/cssref.html).

You can update the prebuilt list of property names and values by running the `update.coffee` file at the root of the repository and then checking in the changed `properties.json` file.
