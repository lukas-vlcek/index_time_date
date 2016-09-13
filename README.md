# Low resolution dates in Elasticsearch

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
- [Accuracy of aggregations](#accuracy-of-aggregations)

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
	
It is possible to get "unexpected" order of documents. Like the following example. It is interesting that (re-)running the `setup.sh` script can (i.e. reindexing the data) influence order in which the documents are returned. 
	
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

As a workaround one can introduce secondary field to store needed fraction number and use this field as a secondary sort value.

### More details about ES implementation:

Efficient sorting on field data has gone through some evolution in ES. Important improvement was addition of [Doc Values](https://www.elastic.co/guide/en/elasticsearch/guide/current/docvalues-intro.html), the underlying data structure used by Elasticsearch when sorting on a field.

Note that in ES `1.7` one has to [enable the doc values explicitely in mapping for date type](https://www.elastic.co/guide/en/elasticsearch/reference/1.7/mapping-core-types.html#date) by settings [fielddata](https://www.elastic.co/guide/en/elasticsearch/reference/1.7/fielddata-formats.html) (it was not by default enabled for [number field data](https://www.elastic.co/guide/en/elasticsearch/reference/1.7/fielddata-formats.html#_numeric_field_data_types)).

Starting with ES `2.x` (not sure which version specifically) it is enabled by [default for dates](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/date.html#date-params).

_Just for completeness: Older blog post [introducing Doc Values](https://www.elastic.co/blog/disk-based-field-data-a-k-a-doc-values) for ES `1.x`, some info can be dated - especially about mapping and enabling?_

--
#### II.)
More over, we can see that when `_source` field is disabled and individual fields are `stored` (see [`template.sh`](template.sh)) then when we ask Elasticsearch for date field values we get only milliseconds resolution formated according to first custom format from mapping (`date2` and `date3`) or by default format (`date1`).

This means that if we want to **get original date-time value** back from Elasticsearch we either have to:

- index value as non analyzed string into \[another\] field (this is what we use field `date` for)
- or we must **disable `store`** for particular field and **enable `_source`** (which requires more disk space) at the same time, however, any custom **date-time format in mapping is ignored** in the case and the value is returned as is

Note: disabling `_source` might not be possible for some future ES versions, see <https://github.com/elastic/elasticsearch/pull/10915> and <https://github.com/elastic/elasticsearch/pull/11171> which reverted this change back.

The `_source` field seems to be a bit "confusing and controversial" topic in Elasticsearch. For example, the official documentation [reads](https://www.elastic.co/guide/en/elasticsearch/guide/2.x/root-object.html#source-field) that: 

> The whole document is already stored as the `_source` field. It is almost always better to just extract the fields that you need by using the `_source` parameter.

but Simon W. says [here](https://github.com/elastic/elasticsearch/issues/20068#issuecomment-244399363):

> I am personally convinced we should never access `_source` in an aggregation. I think the majority of the users do NOT understand what that means ie. decompressing the ENTIRE document to access a single field.

I \*think\* that if Doc Values are available for the field being sorted on or aggregating on then the `_source` is not accessed. The comment from Simon W. above was made in connection to accessing `_source` within aggregation (for example from scripts or by other means).

--
	
## Range filter

[Range query](https://www.elastic.co/guide/en/elasticsearch/reference/2.4/query-dsl-range-query.html) is used to test ability of ES to filter data based on finer-grained date values.

	range_filter.sh
	
The [`range_filter.sh`](range_filter.sh) script runs two queries, one using filter `gte` (greater-than-or-equal) and second using `lte` (lower-than-or-equal). Basically, we take date values from the [`array.sh`](array.sh) one at a time and use each value to test if we can split set of indexed documents into two sets: those documents that are greater (or equal) and those that are lower (or equal) than given value.

In our particular case ES always selects all indexed documents (or none if `gte` and `lte` are changed to `gt` and `le` respectively). Which is not correct.

### Conclusion

Filtering does not support finer grained resolution than milliseconds.

## Accuracy of aggregations

TBD.

General assumption is that aggregations are impacted as well, although it will be interesting to see if script based aggregations can provide some kind of workaround.