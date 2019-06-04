#!/bin/bash

#Wersja 0.1

urlencode() {
  local data
  if [[ $# != 1 ]]; then
    echo "Usage: $0 string-to-urlencode"
    return 1
  fi
  data="$(curl -s -o /dev/null -w %{url_effective} --get --data-urlencode "$1" "")"
  if [[ $? != 3 ]]; then
    echo "Unexpected error" 1>&2
    return 2
  fi
  echo "${data##/?}"
  return 0
}

#Dane do logowania

read -p 'Username: ' uservar
read -sp 'Password: ' passvar

ENuservar=${uservar/@/%40}

ENpassvar=$(urlencode "$passvar")

#Logowanie i zapisanie cookiesa

LOGIN=$(echo "curl --silent --cookie-jar cookies.txt -d 'LoginForm%5Bemail%5D=${ENuservar}&LoginForm%5Bpassword%5D=${ENpassvar}&LoginForm%5BrememberMe%5D=0&login-button=' https://hive.frontend.fleetbird.eu/customer/login")

eval $LOGIN

echo "\n\nLogged in, cookie saved.\n\nPreparing tokens:"

#Generowanie CSFR i tokenów

TOKENLINE=$(curl --silent -b cookies.txt https://hive.frontend.fleetbird.eu/customer/add-voucher | grep -w 'csrf-token')

TOKEN=${TOKENLINE:37:88}

echo "TOKEN: $TOKEN"

ENCODEDTOKEN=$(urlencode "$TOKEN")

echo "ENCODEDTOKEN: $ENCODEDTOKEN"

SESID=$(grep PHPSESSID cookies.txt | cut -f 7)

echo "SESID: $SESID"

CSRF=$(grep csrf cookies.txt | cut -f 7)

echo "CSRF: $CSRF"

#Pobieranie kodów

echo "\n\nDownloading codes..."

content=$(wget http://raw.githubusercontent.com/jbkpdk/hivecodes/master/codes.txt -q -O -)

codescount=$(echo "$content" | wc -l)

echo "Downloaded ${codescount//[!0-9]/} codes.\n\nRedeeming codes now."

#Sprawdzanie

for i in $content; do
  #echo $i

  VOUCHER=$i

  echo "Trying code: ${VOUCHER}"

  MIN=$(curl --silent -b cookies.txt https://hive.frontend.fleetbird.eu/customer/vouchers | grep -w 'free minutes left')
  echo "Minutes before: ${MIN//[!0-9]/}"

  #Generowanie cURL i wykonanie

  #echo "curl 'https://hive.frontend.fleetbird.eu/customer/add-voucher' -H 'authority: hive.frontend.fleetbird.eu' -H 'pragma: no-cache' -H 'cache-control: no-cache' -H 'origin: https://hive.frontend.fleetbird.eu' -H 'upgrade-insecure-requests: 1' -H 'dnt: 1' -H 'content-type: application/x-www-form-urlencoded' -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3806.1 Safari/537.36' -H 'sec-fetch-mode: navigate' -H 'sec-fetch-user: ?1' -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'sec-fetch-site: same-origin' -H 'referer: https://hive.frontend.fleetbird.eu/customer/add-voucher' -H 'accept-encoding: gzip, deflate, br' -H 'accept-language: pl-PL,pl;q=0.9,en-US;q=0.8,en;q=0.7,it;q=0.6' -H 'cookie: PHPSESSID=${SESID}; _csrf-frontend=${CSRF}' --data '_csrf-frontend=${ENCODEDTOKEN}&PromotionCode%5Bcode%5D=sqqsq' --compressed"

  CMD=$(echo "curl --silent 'https://hive.frontend.fleetbird.eu/customer/add-voucher' -H 'authority: hive.frontend.fleetbird.eu' -H 'pragma: no-cache' -H 'cache-control: no-cache' -H 'origin: https://hive.frontend.fleetbird.eu' -H 'upgrade-insecure-requests: 1' -H 'dnt: 1' -H 'content-type: application/x-www-form-urlencoded' -H 'user-agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_14_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3806.1 Safari/537.36' -H 'sec-fetch-mode: navigate' -H 'sec-fetch-user: ?1' -H 'accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3' -H 'sec-fetch-site: same-origin' -H 'referer: https://hive.frontend.fleetbird.eu/customer/add-voucher' -H 'accept-encoding: gzip, deflate, br' -H 'accept-language: pl-PL,pl;q=0.9,en-US;q=0.8,en;q=0.7,it;q=0.6' -H 'cookie: PHPSESSID=${SESID}; _csrf-frontend=${CSRF}' --data '_csrf-frontend=${ENCODEDTOKEN}&PromotionCode%5Bcode%5D=sqqsq' --compressed")

  OUTPUT=$(eval $CMD)

  #echo "$OUTPUT"

  #Sprawdzenie wyniku

  if echo "$OUTPUT" | grep -o 'not valid'; then

    echo "Voucher not valid: ${VOUCHER}."
  else

    echo "Code aplied or attempt failed."
  fi

  MIN=$(curl --silent -b cookies.txt https://hive.frontend.fleetbird.eu/customer/vouchers | grep -w 'free minutes left')
  echo "Minutes after: ${MIN//[!0-9]/}"

done
