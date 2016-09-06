Elasticsearch documentation states that [`date` datetype](https://www.elastic.co/guide/en/elasticsearch/reference/current/date.html) resolution is up to milliseconds:

> Internally, dates are converted to UTC (if the time-zone is specified) and stored as a long number representing milliseconds-since-the-epoch.

There is some debate about what it would take to implement finer resolution:

- Elasticsearch: [Date type has not enough precision for the logging use case](https://github.com/elastic/elasticsearch/issues/10005)
- Kibana: [Nanosecond times](https://github.com/elastic/kibana/issues/2498)

--

I created simple shell scripts to test how Elasticsearch handles the following use cases:

- [Autodetect finer date-time values as dates](#date-detection)
- [How precisely ES can sort finer values](#sorting)
- [How precisely ES can execute range filters on the data](#range-filter)

### How to run the test

We assume empty cluster running on `http://localhost:9200` (tested with Elasticsearch `1.7.2`, `2.3.5`, `2.4.0`). First, prepare index template and data in the cluster:

	$ setup.sh

We have indexed couple of documents into the cluster. The documents look like the following example:

````
{
  "date":  "2014-01-17T15:57:22.123456Z",
  "date1": "2014-01-17T15:57:22.123456Z",
  "date2": "2014-01-17T15:57:22.123456Z",
  "date3": "2014-01-17T15:57:22.123456Z"  
}
````
Source values are defined by [`array.sh`](array.sh) script. For each value from this script a new document is created and indexed.


### Date detection

We define some field types in advance in [`template.sh`](template.sh), except the field `"date1"`. To see what type has been detected for this field run:

	$ curl -X GET 'localhost:9200/1/_mapping?pretty'
	
In our case it has been correctly detected as a date despite the fact first value in [`array.sh`](array.sh) represents finer-than-milliseconds resolution:

````
"date1" : {
  "type" : "date",
  "store" : true,
  "format" : "strict_date_optional_time||epoch_millis"
}
````
We can make conclusion that Elasticsearch recognises date-time values out-of-the-box as long it sticks to ISO format described here: <http://www.joda.org/joda-time/apidocs/org/joda/time/format/ISODateTimeFormat.html#dateOptionalTimeParser-->.

This grammar allows the `fraction` to consists of high number of digits (`digit+` = literally unlimited ?).
	
However, when indexing the date-time value the Elasticsearch keeps only the milliseconds resolution. See below.
	
### Sorting

To find out how Elasticsearch can sort by finer grained values run:

	$ sorting.sh
	
It is possible to get "unexpected" order of documents. Like the following example. It is interesting that (re-)running the `setup.sh` script can influence the order in which the documents are returned. 
	
````
"hits" : {
    "total" : 3,
    "max_score" : null,
    "hits" : [ {
      "_index" : "1",
      "_type" : "test",
      "_id" : "AVcAAexfMQGFxLlcPi3y",
      "_score" : null,
      "fields" : {
        "date" : [ "2014-02-17T15:57:22.12345Z" ],
        "date3" : [ "2014-02-17T15:57:22.1230+0000" ],
        "date2" : [ "2014-02-17T15:57:22.123000+0000" ],
        "date1" : [ "2014-02-17T15:57:22.123Z" ]
      },
      "sort" : [ 1392652642123 ]
    }, {
      "_index" : "1",
      "_type" : "test",
      "_id" : "AVcAAeydMQGFxLlcPi30",
      "_score" : null,
      "fields" : {
        "date" : [ "2014-01-17T15:57:22.123456789Z" ],
        "date3" : [ "2014-01-17T15:57:22.1230+0000" ],
        "date2" : [ "2014-01-17T15:57:22.123000+0000" ],
        "date1" : [ "2014-01-17T15:57:22.123Z" ]
      },
      "sort" : [ 1389974242123 ]
    }, {
      "_index" : "1",
      "_type" : "test",
      "_id" : "AVcAAeyDMQGFxLlcPi3z",
      "_score" : null,
      "fields" : {
        "date" : [ "2014-01-17T15:57:22.123456Z" ],
        "date3" : [ "2014-01-17T15:57:22.1230+0000" ],
        "date2" : [ "2014-01-17T15:57:22.123000+0000" ],
        "date1" : [ "2014-01-17T15:57:22.123Z" ]
      },
      "sort" : [ 1389974242123 ]
    } ]
  }
````
	
### Range filter

_Note: this is in WIP_

	$ range_filter.sh