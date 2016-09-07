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

# How to run the test

We assume empty cluster running on `http://localhost:9200` (tested with Elasticsearch `1.7.2`, `2.3.5`, `2.4.0`):

	export PROJECT_HOME=index_time_date
	git clone https://github.com/lukas-vlcek/index_time_date.git ${PROJECT_HOME}
	cd ${PROJECT_HOME}
	setup.sh
	
## What is going on behind the scene

When the [`setup.sh`](setup.sh) script is run, it removes all data from testing index, add index template, and index seed data into testing index in ES cluster.

Number of indexed documents and their content is determined by [`array.sh`](array.sh) script. For each array value in this script a new document is created and indexed.

````
# E.g. value "2014-01-17T15:57:22.123456Z" yields document:
{
  "date":  "2014-01-17T15:57:22.123456Z",
  "date1": "2014-01-17T15:57:22.123456Z",
  "date2": "2014-01-17T15:57:22.123456Z",
  "date3": "2014-01-17T15:57:22.123456Z"  
}
````

One of the last commands the [`setup.sh`](setup.sh) script does is getting  field stats like:

	curl -X GET 'localhost:9200/1/_field_stats?pretty&fields=date1,date2,date3'
	
This gives us understanding about resolution of date values indexed by Elasticsearch. We can see that all date fields (`date1`, `date2` and `date3`) contain the same `"min_value"` and `"max_value"`.

````
      "fields" : {
        "date3" : {
          "max_doc" : 3,
          "doc_count" : 3,
          "density" : 100,
          "sum_doc_freq" : 12,
          "sum_total_term_freq" : -1,
          "min_value" : 1389974242123,
          "min_value_as_string" : "2014-01-17T15:57:22.1230+0000",
          "max_value" : 1389974242123,
          "max_value_as_string" : "2014-01-17T15:57:22.1230+0000"
        },
        "date2" : {
          "max_doc" : 3,
          "doc_count" : 3,
          "density" : 100,
          "sum_doc_freq" : 12,
          "sum_total_term_freq" : -1,
          "min_value" : 1389974242123,
          "min_value_as_string" : "2014-01-17T15:57:22.123000+0000",
          "max_value" : 1389974242123,
          "max_value_as_string" : "2014-01-17T15:57:22.123000+0000"
        },
        "date1" : {
          "max_doc" : 3,
          "doc_count" : 3,
          "density" : 100,
          "sum_doc_freq" : 12,
          "sum_total_term_freq" : -1,
          "min_value" : 1389974242123,
          "min_value_as_string" : "2014-01-17T15:57:22.123Z",
          "max_value" : 1389974242123,
          "max_value_as_string" : "2014-01-17T15:57:22.123Z"
        }
      }
````

## Date detection

We define some field types in advance in [`template.sh`](template.sh), except for field `"date1"`. To see what type has been detected for this field run:

	curl -X GET 'localhost:9200/1/_mapping?pretty'
	
In our case it has been correctly detected as a date despite the fact first value in [`array.sh`](array.sh) represents finer-than-milliseconds resolution:

````
"date1" : {
  "type" : "date",
  "store" : true,
  "format" : "strict_date_optional_time||epoch_millis"
}
````

### Conclusions

#### I.)
We can make conclusion that Elasticsearch can **recognise date-time value and parse it out-of-the-box** as long as it sticks to ISO format described here: <http://www.joda.org/joda-time/apidocs/org/joda/time/format/ISODateTimeFormat.html#dateOptionalTimeParser-->.

Note the `fraction` part can consists of very **high number of digits** (`digit+` = literally unlimited?).
	
--	
#### II.)
However, when indexing the date-time value the Elasticsearch keeps only the **milliseconds resolution** internally. (We have seen this already in field stats output above and will again verify using sorting below.)

--
	
## Sorting

To find if Elasticsearch can correctly sort by finer grained values run:

	sorting.sh
	
It is possible to get "unexpected" order of documents. Like the following example. It is interesting that (re-)running the `setup.sh` script can influence order in which the documents are returned. 
	
````
  "hits" : {
    "total" : 3,
    "max_score" : null,
    "hits" : [ {
      "_index" : "1",
      "_type" : "test",
      "_id" : "AVcAFT10MQGFxLlcPi4C",
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
      "_id" : "AVcAFT02MQGFxLlcPi4A",
      "_score" : null,
      "fields" : {
        "date" : [ "2014-01-17T15:57:22.12345Z" ],
        "date3" : [ "2014-01-17T15:57:22.1230+0000" ],
        "date2" : [ "2014-01-17T15:57:22.123000+0000" ],
        "date1" : [ "2014-01-17T15:57:22.123Z" ]
      },
      "sort" : [ 1389974242123 ]
    }, {
      "_index" : "1",
      "_type" : "test",
      "_id" : "AVcAFT1eMQGFxLlcPi4B",
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

### Conclusions

#### I.)
We can make conclusion that when sorting then all **document falling into the same millisecond can be returned in random order** (more specifically, the order seem to be determined by internal ES factors at indexing time).

--
#### II.)
More over, we can see that when `_source` field is disabled and individual fields are `stored` (see [`template.sh`](template.sh)) then when we ask Elasticsearch for date field values we get only milliseconds resolution formated according to first custom format from mapping (`date2` and `date3`) or by default format (`date1`).

This means that if we want to **get original date-time value** we either have to:

- store it as a string into another field (this is what we use field `date` for)
- or we must enable `_source` (which requires more disk space)

--
	
## Range filter

_Note: this is in WIP_

	range_filter.sh