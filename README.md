Elasticsearch documentation states that [`date` datetype](https://www.elastic.co/guide/en/elasticsearch/reference/current/date.html) resolution is up to milliseconds:

> Internally, dates are converted to UTC (if the time-zone is specified) and stored as a long number representing milliseconds-since-the-epoch.

There is some debate about how what it would take to implement finer resolution:

- Elasticsearch: [Date type has not enough precision for the logging use case](https://github.com/elastic/elasticsearch/issues/10005)
- Kibana: [Nanosecond times](https://github.com/elastic/kibana/issues/2498)

--

I created simple shell scripts to test how Elasticsearch handles the following use cases.

Run the test:

	$ do.sh
	
- assuming Elasticsearch runs on `http://localhost:9200`
- tested with Elasticsearch `1.7.2`, `2.3.5`, `2.4.0`