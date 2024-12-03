#!/bin/bash

# Define your order IDs here as a space-separated list
order_ids="172596632669487 172598314089930 172598542522773 172598875222911 172598955949679 172600306563935 172600308838298 172600537190849 172604655584832 172604671356617 172607297291491 172607479506707 172607701180859 172608401060137 172609591807411 172612961914237 172616513157435 172617555103920 172617912711372 172621235180299 172621718280948 172622239623575 172624234777012 172625250859067 172625285649966 172625548131301 172625760371499 172625806266892 172630577953360 172631310096205 172632043830425 172632356945990 172634644877409 172638990971238 172639181970152 172639375643254 172639652374108 172640289461238 172640967940109 172641428878882 172642088233378 172646801400630 172647995643490 172649599863959 172650114145275 172650135121412 172650266061752 172651170313742 172651235282595 172651256832206 172651792249206 172651948573960 172652025723124 172655408031460 172655563124634 172655814071470 172656401298888 172656511332530 172656551005944 172656614617230 172657894513315 172658765875832 172658963297094 172659204625318 172659267787780 172659619391765 172659900434221 172659956595914 172660191407286 172660207361816 172660468229597 172660484835254 172664792670009 172665197289092 172665452794272 172665556463422 172667406553680 172668045908280 172668671529506 172668749726067 172669083021448 172672998218772 172673326350348 172674363607435 172674374084046 172674441023387 172674443740749 172675351746105 172675737794369 172676143863151 172676156510318"

# Write the header to the CSV file
# echo "order_id,currency,price_total" > "$output_file"

id_token_here="AMf-vBxfT0bM6pH_dI_9eF4DF2l44E4SrMOum_2i-XLfQPdWTHJIcnWQRLikLMwQsxtWuayzec95IS5VZBFEupO8ducZQARmt8IgG7RlVu7JugfT6C4SXZfYgxTvAVSU21y3PxXM8L5HlboqpiRtO2GIEnQnQ9tuDU5imvJimlXu2p1rGnSH2oJTFiQ0OlwWa5Rf_YabdKa4alxTc_pVnXVqYC0iW9PynuAFheDlnkxbBd47POVn0VYvVfTPg9x-1ifL7HcQa_3HB05oXpy1YBsheFPPkdkHeqVOetp6UhgGzFn3lOvxnrjuF78yXkCEcxykA0h8HavN4ePMoM-nzP4NMloPJtZV9foy4BOPD-LkO9HKIOEIcEjA_o8b7Vt1kLn_aKu_yX50DYZmNuiaXNWtnHXHlW5mSiiYkAHiFsEBylBGXTsJ0VCtcaBa5491YDflPwLWATfj"

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

    echo "http://localhost82.com/prioticket-refund/public/refundOrderFullQuantity/$order_id?refresh_token=$id_token_here&skip_third_party=0"
    
    response=$(curl -s "http://localhost82.com/prioticket-refund/public/refundOrderFullQuantity/$order_id?refresh_token=$id_token_here&skip_third_party=0")
    
    echo "$order_id" >> matchdata.txt
    echo "$response" >> response.json
    sleep 4
done

# jq -r '.response.data.order | "\(.order_reference): \(.order_status)"' response.json

# jq -r '.response.data.order | "\(.order_reference): \(.order_status)"' response.json response1.json response2.json response3.json
