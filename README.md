# Log syntax highlighting and filtering in Atom [![Build Status](https://travis-ci.org/mrodalgaard/language-log.svg)](https://travis-ci.org/mrodalgaard/language-log)

Adds syntax colors for common log formats in [Atom](https://atom.io/) - improving visual grepping.

Also adds a filtering bottom bar to separate out the statements you are not interested in (can be removed through package config).

![language-log](https://raw.githubusercontent.com/mrodalgaard/language-log/master/screenshots/preview.png)

An Atom grammar that helps you quickly extract the important parts of various log files.

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

There are a whole bunch of standard and non-standard log formats out there. This is an attempt to reach the most common I bump into on a weekly basis.

## Tasks

 * [x] Log filtering
 * [x] Show warning on logs above 10,000 lines
 * [ ] Hide filtered lines option
 * [ ] Timestamp search and filtering
 * [ ] Log tail
 * [ ] Dynamically updating
 * [ ] Vertically fold timestamp

## Notes

Log files above 10,000 lines does not get grammar applied according to Atom.

A great companion to this package is [tail](https://github.com/eliasak/tail) for live viewing logs. See [here](https://github.com/mrodalgaard/language-log/issues/1#issue-92097844) for a good way to integrate.

> Contributions, bug reports and feature requests are very welcome.

> &nbsp; &nbsp; _- Martin_
