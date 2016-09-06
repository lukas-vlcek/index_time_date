set -o xtrace

source ./array.sh

for i in "${!arr[@]}"; do

  curl -X POST "localhost:9200/1/_search?pretty" -d "{
    \"fields\": [ \"date\" ],
    \"filter\": {
      \"range\": {
        \"date1\": {
          \"gte\": \"${arr[$i]}\"
        }
      }
    }
  }"

  curl -X POST "localhost:9200/1/_search?pretty" -d "{
    \"fields\": [ \"date\" ],
    \"filter\": {
      \"range\": {
        \"date1\": {
          \"lte\": \"${arr[$i]}\"
        }
      }
    }
  }"

done
