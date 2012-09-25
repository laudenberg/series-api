series-api
==========

## About
This is a public API wrapper for thetvdb.com, which re-routes and re-organizes the thetvdb.com to a more sane structure.

## Output

All output comes in JSON.

## JSONP

When you pass a "callback"-Parameter you get the output wrapped with a callback-function.

```
http://series.c3w.de/series/83462/5/1?callback=func
```

## Usage

The follwing endpoints are available:

```
http://series.c3w.de/series/search/$SERIES_NAME ( [Example](http://series.c3w.de/series/search/Castle) )
http://series.c3w.de/series/$SERIES_ID ( [Example](http://series.c3w.de/series/83462) )
http://series.c3w.de/series/$SERIES_ID/$SEASON ( [Example](http://series.c3w.de/series/83462/5) )
http://series.c3w.de/series/$SERIES_ID/$SEASON/$EPSIODE ( [Example](http://series.c3w.de/series/83462/5/1) )

http://series.c3w.de/series/$SERIES_ID/$SEASON?since=1336341599
Only shows Episodes aired after 1336341599 (06.05.2012).
```