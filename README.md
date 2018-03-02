# Log syntax highlighting and filtering in Atom [![Build Status](https://travis-ci.org/mrodalgaard/language-log.svg)](https://travis-ci.org/mrodalgaard/language-log)

Adds syntax colors for common log formats in [Atom](https://atom.io/) - improving visual grepping.

Also adds a filtering bottom bar to separate out the statements you are not interested in (can be removed through package config).

![language-log](https://raw.githubusercontent.com/mrodalgaard/language-log/master/screenshots/preview.png)

An Atom grammar that helps you quickly extract the important parts of various log files.

The filtering bottom bar contains the following elements:

* Text filter input which filters based on regex expression (prepend an exclamation mark (`!`) to perform a reverse filter).
* Tail button (`⇩`) which enables tailing of log changes (move to the bottom of the file).
* Case sensitive/insensitive search button (`Aa`).
* Level filter buttons which filters based on log level.

NOTE: *soft wrap* is disabled by default and can be enabled via the package settings page.

There are a whole bunch of standard and non-standard log formats out there. Create an [issue](https://github.com/mrodalgaard/language-log/issues/new) (or even better a PR) if you are missing a format.

## Notes

When asking for a certain log type support, please provide an example log file showing the general format and the different log levels.

Files above 10,000 lines does not get grammar applied according to Atom.

> Contributions, bug reports and feature requests are very welcome.

> &nbsp; &nbsp; _- Martin_
