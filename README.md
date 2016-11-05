# Log syntax highlighting and filtering in Atom [![Build Status](https://travis-ci.org/mrodalgaard/language-log.svg)](https://travis-ci.org/mrodalgaard/language-log)

Adds syntax colors for common log formats in [Atom](https://atom.io/) - improving visual grepping.

Also adds a filtering bottom bar to separate out the statements you are not interested in (can be removed through package config).

![language-log](https://raw.githubusercontent.com/mrodalgaard/language-log/master/screenshots/preview.png)

An Atom grammar that helps you quickly extract the important parts of various log files.

The filtering bottom bar contains the following elements:

* Text filter input which filters based on line text (prepend an exclamation mark (`!`) to perform a reverse filter).
* Tail button (`⇩`) which enables tailing of log changes (move to the bottom of the file).
* Case sensitive/insensitive search button (`Aa`).
* Level filter buttons which filters based on log level.

NOTE: *soft wrap* is disabled by default and can be enabled via the package settings page.

## Supported formats

 * [x] Android LogCat
 * [x] Nabto Log
 * [x] iOS Log / Stack trace
 * [x] Firefox crash log (use json raw dump)
 * [x] IDEA log
 * [x] Apache
 * [x] Syslog
 * [x] Windows CBS logs
 * [x] Common crash logs
 * [x] Common system logs from e.g. ~/Library/Logs/

There are a whole bunch of standard and non-standard log formats out there. Create an [issue](https://github.com/mrodalgaard/language-log/issues/new) (or even better a PR) if you are missing a format.

## Tasks

 * [x] Log filtering
 * [x] Show warning on logs above 10,000 lines
 * [x] Log tail option
 * [x] Hide filtered lines
 * [x] Show number of lines (and filtered)
 * [ ] Timestamp search and filtering
 * [ ] Dynamically updating
 * [ ] Graph / visualization of entry types
 * [ ] Quick jump to errors

## Notes

Files above 10,000 lines does not get grammar applied according to Atom.

> Contributions, bug reports and feature requests are very welcome.

> &nbsp; &nbsp; _- Martin_
