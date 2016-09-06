curl 'localhost:9200/_search?pretty' -d '{
  "fields": [ "date","date1","date2","date3" ],
  "sort": {
     "date3": "desc"
  }
}'
