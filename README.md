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
	
### Sorting

	$ sorting.sh
	
### Range filter

_Note: this is in WIP_

	$ range_filter.sh