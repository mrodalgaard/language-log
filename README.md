# Log file syntax highlighting in Atom

Adds syntax highlighting colors for common log formats in Atom. Improving visual grepping.

## Use Case

I often get random logs sent to me for analyzing system behavior. These include crash reports, stack traces, system logs and ad-hoc loggings from different IDEs using dissimilar logging formats. Every time I look for the same keywords (error, exception, exit), check previous line's logging level (info, warning, error) and compare time stamps.

This Atom grammar helps you quickly extract the log information that is important.

## Supported formats

 * [x] Android LogCat
 * [x] Nabto Log
 * [x] iOS Log / Stack trace
 * [x] Firefox crash log (use json raw dump)
 * [x] IDEA log
 * [x] Apache
 * [x] Syslog
 * [x] Common crash logs
 * [x] Common system logs from e.g. ~/Library/Logs/

There are a whole bunch of standard and non-standard log formats out there. This is an attempt to reach the most common I run in to on a weekly basis.

## Notes

A great companion to this package is [tail](https://github.com/eliasak/tail) for live viewing logs. See [here](https://github.com/mrodalgaard/language-log/issues/1#issue-92097844) for a good way to integrate.

<br>

> Contributions, bug reports and feature requests are very welcome.

> &nbsp; &nbsp; _- Martin_
