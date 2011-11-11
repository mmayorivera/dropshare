#! /bin/bash
# set -eu

expect () {

  if [[ "$1" != "$2" ]]; then
    echo "FAILURE: $3"
    echo "Expected $1 and got $2."
  else
    echo "."
  fi
}

HOST="http://localhost:3700"

RESULT=`curl --silent "${HOST}/files/new"  -X POST \
  -H "Content-Type: application/json" \
  -d '[{
        "size": 35,
        "lastModifiedDate": "2011-11-08T00:15:06.000Z",
        "fileName": "foobar.txt",
        "type": "text/plain; charset=utf-8"
      }]'`

# echo $RESULT

ID=`echo ${RESULT} | json-cherry-pick 0` || exit

RESPONSE=`curl --silent "${HOST}/files"  -X POST \
  --form ${ID}=@foobar.txt`
EXPECTED="[{\"result\":\"success\",\"data\":\"File ${ID} stored successfully.\"}]"
expect "$EXPECTED" "$RESPONSE" "File not uploaded successfully."


RESPONSE=`curl --silent "${HOST}/files/${ID}/test.txt" -X GET`
EXPECTED="¬˚∆˙ß∂ƒ¬˚∆˙∑øˆ´¨©ƒ˙¬∂ß∆˙ƒ¬∫√ç≈µ˙©ß˚∂∆ƒ©˙What the dickens is going on here?"
expect "$EXPECTED" "$RESPONSE" "File downloaded not equal to file stored."

#test multiple file upload
RESULT=`curl --silent "${HOST}/files/new"  -X POST \
  -H "Content-Type: application/json" \
  -d'[{"size":4460,"lastModifiedDate":"2011-10-29T20:22:56.000Z","fileSize":4460,"name":"temp.txt","type":"text/plain","fileName":"test.txt"},
      {"size":749717,"lastModifiedDate":"2011-11-08T00:59:14.000Z","fileSize":749717,"name":"IMG_0366.JPG","type":"image/jpeg","fileName":"IMG_0366.JPG"},
      {"size":50615,"lastModifiedDate":"2011-11-10T23:00:31.000Z","fileSize":50615,"name":"gopher.jpg","type":"image/jpeg","webkitRelativePath":"","fileName":"gopher.jpg"}
     ]'`

ID0=`echo ${RESULT} | json-cherry-pick 0` || exit
ID1=`echo ${RESULT} | json-cherry-pick 1` || exit
ID2=`echo ${RESULT} | json-cherry-pick 2` || exit

RESPONSE=`curl --silent "${HOST}/files"  -X POST \
  --form ${ID0}=@temp.txt ${ID1}=@IMG_0366.JPG ${ID2}=@gopher.jpg`
EXPECTED="HURP DURP"
expect "$EXPECTED" "$RESULT" "HURP DURP"


# Test with a bogus id
RESPONSE=`curl --silent "${HOST}/files"  -X POST \
  --form SVEN=@foobar.txt`
EXPECTED="[{\"result\":\"error\",\"data\":\"No metadata for id 'SVEN'.\"}]"
ERROR_MESSAGE="Posting a file without an ID should return an error message."
expect "$EXPECTED" "$RESPONSE" "$ERROR_MESSAGE"


RESPONSE=`curl --silent "${HOST}/files/SVEN/test.txt" -X GET`
EXPECTED="{\"result\":\"error\",\"data\":\"No files uploaded for SVEN.\"}"
expect "$EXPECTED" "$RESPONSE" "Attempting to download a non-existent file should return an error."



RESPONSE=`curl --silent "${HOST}/files/ABC" -X DELETE`
EXPECTED="{\"result\":\"error\",\"data\":\"No files uploaded for ABC.\"}"
expect "$EXPECTED" "$RESPONSE" "Deleting a nonexistent file should return an error."

RESPONSE=`curl --silent "${HOST}/files/${ID}" -X DELETE`
EXPECTED="{\"result\":\"success\",\"data\":\"Successfully deleted ${ID}.\"}"
expect "$EXPECTED" "$RESPONSE" "Deleting an existing file should delete it."

#test that getting the deleted file now returns an error
RESONSE=`curl --silent "${HOST}/files/${ID}/foobar.bin" -X GET`
EXPECTED="{\"result\":\"error\",\"data\":\"No files uploaded for ${ID}.\"}"
expect "$EXPECTED" "$RESONSE" "Getting a deleted file should return an error, but not crash the server."

