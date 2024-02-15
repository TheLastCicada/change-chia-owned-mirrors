#!/bin/bash

newUrl='https://the-ip-or-url-of-your-new-mirror-address.com/' #New mirror address
badURL='127.0.0.1'  #Old mirror address you want to replace
amount='100'  #Amount in mojos of new mirror coin
fee='0'

subscriptions_array=( $(nice -n 19 chia data get_subscriptions | jq -r .store_ids[]) )

for sub in "${subscriptions_array[@]}"
do
    echo "Subscription ID: ${sub}"
    coin_id=''
    coin_id=$(nice -n 19 chia data get_mirrors --id ${sub} | jq -r --arg badURL "${badURL}" '.mirrors[] | select(.ours == true and any(.urls[]; contains($badURL))) | .coin_id')
    if [ ! -z "$coin_id" ]
    then
        echo "Deleting and recreating mirror for coin_id: ${coin_id}"
        confirmedCount=$(nice -n 19 chia wallet get_transactions --no-paginate | grep "Status: Confirmed" | wc -l)
        totalCount=$(nice -n 19 chia wallet get_transactions --no-paginate | grep "Status:" | wc -l)
        while [ $confirmedCount != $totalCount ]
        do
            echo "Waiting for transaction to be confirmed..."
            confirmedCount=$(nice -n 19 chia wallet get_transactions --no-paginate | grep "Status: Confirmed" | wc -l)
            totalCount=$(nice -n 19 chia wallet get_transactions --no-paginate | grep "Status:" | wc -l)
            sleep 5
        done
        echo "Deleting mirror for ${coin_id}"
        nice -n 19 chia data delete_mirror -m ${fee} -c ${coin_id}
        confirmedCount=0
        totalCount=1
        while [ $confirmedCount != $totalCount ]
        do
            echo "Waiting for transaction to be confirmed..."
            confirmedCount=$(nice -n 19 chia wallet get_transactions --no-paginate | grep "Status: Confirmed" | wc -l)
            totalCount=$(nice -n 19 chia wallet get_transactions --no-paginate | grep "Status:" | wc -l)
            sleep 5
        done
        echo "Adding mirror for store-id ${sub}"
        nice -n 19 chia data add_mirror  -m ${fee} --id ${sub} --amount ${amount} --url ${newUrl}
        confirmedCount=0
        totalCount=1
        while [ $confirmedCount != $totalCount ]
        do
            echo "Waiting for transaction to be confirmed..."
            confirmedCount=$(nice -n 19 chia wallet get_transactions --no-paginate | grep "Status: Confirmed" | wc -l)
            totalCount=$(nice -n 19 chia wallet get_transactions --no-paginate | grep "Status:" | wc -l)
            sleep 5
        done
    else
        echo "No bad mirrors here"
    fi
done
