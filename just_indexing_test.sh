#!/bin/bash

ES=http://localhost:9200

function delete_index() {
  curl -X DELETE "${ES}/test" 
}

function refresh() {
  curl -X POST "${ES}/_refresh"
}

function index_document() {
  echo "Testing $1"
  curl -X POST "${ES}/test/1" -d "{
    \"date\": \"$1\"
  }" 
}

function mapping() {
  curl -X GET "${ES}/test/_mapping?pretty"
}

for i in 2014-01-17T15:57:22.123456Z  2014-01-17T15:57:22Z 
do
  delete_index
  index_document $i
  mapping
  refresh
done
