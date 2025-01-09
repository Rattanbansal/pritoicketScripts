#!/bin/bash

# Define your order IDs here as a space-separated list
order_ids="171876877935535 171931406072915 172007343838950 172083440109067 172031049958829 171999825600889 172290923397488 172307577460468 172664151319299 171811816006427 172903227211450 172888049270637 172940343141259 172981032051727 173053582031676 173087012562902 173087367904378 173087506786199 173087521426708 173087546382871 173087769958872 173087959295794 173087963840354 173088798795939 173088807734139 173088811636492 173089038381027 173278814094150 173284752996124 173284702747716 173371512368492 173379252503243 173379429293814 173380265762498 173458896282142 172489920302909 172489716229850 172471394795536 172436203778655 172431011475967 172430986917238 172430411244565 172410475944083 172655558385116 172653228673312 172653224322714 172652515174266 172609326453432 172967217002696 172877739590401 173257742507521 173164187578285 172402566407559 172402566870186 172777508017474 171644128919952 171643943249583 171643923619567 171654942422839 171654486362761 171653466820581 171653238961509 171652502837576 171651728360747 171695574896380 171704676324618 171702438874642 171711412109218 171927221744980 171739559091434 171770428062863 171819486691448 171952968457322 171722680963406 171636465698547 171701396390736"

# Write the header to the CSV file
# echo "order_id,currency,price_total" > "$output_file"

id_token_here="AMf-vByez8sfBsirS1pJdQMbAM9ZqdLcxKc_bIzJXKFXr5Fpv7pq4O8pR5BwTjzcnmf8bRu520bKvoNeQFIqV7hVgAeJEgD_hfz8YmpnB6jm3PjP3zjZYU86Sf9N4rE1eV8bXHkgd0w5WL52HixePbZlr0AG0zQO5tTw2-HKLxC2HeI7OJ3QRYKWf89rNObfcUrjin2EFiXPHP-0zduqF-jsRwdlcw-XbFCm-B6VMyqgpbLqXBinTK0HCVlqNqM4Me2YdJYDyJlt4bYNu7YjTnKoqaU8rV2NUj77lmPUqr1cEbouGTnnzHizzV_Z8Xi4IIfjKslJ5NgWyCZtvAjHJWz0rboQyXVEFSEpcb8p2eqGGms3jPESN0RAIyOePJw8gukraqq9vZs2OL3WQ7fm_q_zkFCoq4sOY8cPMxjPyQu01bQyo1XIuEOdtq6WWUN2ahANQ_tyMa5i"

vpn_connection_name_a="pfSense-UDP4-1194-rattan1-config"
vpn_connection_name_b="pfSense-UDP4-1194-rattan2-config"

check_vpn_connection() {
    if nmcli connection show --active | grep -q "$vpn_connection_name_b"; then
        echo "VPN ($vpn_connection_name_b) is active."
    elif nmcli connection show --active | grep -q "$vpn_connection_name_a"; then
        echo "VPN ($vpn_connection_name_a) is active. Disconnecting it."
        sudo nmcli connection down $vpn_connection_name_a
        echo "rattan22024" | sudo nmcli --ask connection up $vpn_connection_name_b
        if nmcli connection show --active | grep -q "$vpn_connection_name_b"; then
            echo "VPN ($vpn_connection_name_b) is now connected."
            return 0
        else
            echo "Failed to connect VPN ($vpn_connection_name_b). Exiting with Condition 2."
            exit 1
        fi
    else
        echo "VPN ($vpn_connection_name_b) is not active. Connecting to the VPN."
        echo "rattan22024" | sudo nmcli --ask connection up $vpn_connection_name_b
        echo "----------- Aboive Error Message-----------"
        if nmcli connection show --active | grep -q "$vpn_connection_name_b"; then
            echo "VPN ($vpn_connection_name_b) is now connected."
            return 0
        else
            echo "Failed to connect VPN ($vpn_connection_name_b). Exiting with condition 3."
            exit 1
        fi
    fi
}

# check_vpn_connection
# Loop through each order ID in the list
for order_id in $order_ids; do

    echo "http://localhost82.com/prioticket-refund/public/refundOrderFullQuantity/$order_id?refresh_token=$id_token_here&skip_third_party=1"
    
    response=$(curl -s "http://localhost82.com/prioticket-refund/public/refundOrderFullQuantity/$order_id?refresh_token=$id_token_here&skip_third_party=1")
    
    echo "$order_id" >> matchdata.txt
    echo "$response" >> response.json
    # sleep 2
done

# jq -r '.response.data.order | "\(.order_reference): \(.order_status)"' response.json

# jq -r '.response.data.order | "\(.order_reference): \(.order_status)"' response.json response1.json response2.json response3.json > test.json

# jq -r '.response.data.order | "\(.order_reference): \(.order_status)"' response.json