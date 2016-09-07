set -o xtrace

curl -X DELETE localhost:9200/1
curl -X PUT localhost:9200/_template/template -d@template.json
curl -X GET 'localhost:9200/_template/template?pretty'

source ./array.sh

for i in "${!arr[@]}"; do
  curl -X POST "localhost:9200/1/test" -d "{
    \"date\":  \"${arr[$i]}\",
    \"date1\": \"${arr[$i]}\",
    \"date2\": \"${arr[$i]}\",
    \"date3\": \"${arr[$i]}\"
  }"
  curl -X GET 'localhost:9200/1/_mapping?pretty'
done

curl -X GET 'localhost:9200/1/_field_stats?pretty&fields=date1,date2,date3'
curl -X POST 'localhost:9200/1/_refresh'
curl -X GET 'localhost:9200/1/_field_stats?pretty&fields=date1,date2,date3'

curl -X GET 'localhost:9200/1/_count?pretty'
