#!/bin/bash

# Define your order IDs here as a space-separated list
order_ids="173222532640848 173222592162730 173222598098580 173222611875216 173222700746819 173222866279523 173222993377879 173223239213614 173223488846417 173223809102952 173225536407349 173225538943082 173225765708745 173226004847797 173226264572992 173226339166133 173226341238029 173226344054251 173226381750740 173226383313489 173226555406406 173226693936966 173226697556408 173226904179104 173226910920892 173226949746253 173227016925849 173227254416050 173227342368841 173227380105373 173227541516201 173227600606202 173227630446285 173227711826036 173227733351546 173227938262672 173227988851535 173228037174187 173228048330279 173228077164936 173228092445710 173228203079602 173228548874775 173228571633750 173228627342564 173228672209792 173228714521140 173228788176002 173228796280785 173229042667375 173229061440255 173229090431787 173229098561390 173229109681541 173229336544592 173229521732385 173229541568937 173229594690828 173229731636985 173229886710068 173229945518330 173230018868444 173230110514481 173230113366885 173230136006389 173230190395934 173230291880669 173230337132097 173230349402014 173230365634085 173230435462557 173230466541498"

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

    echo "$order_id" >> matchdata3.txt
    
    echo "$response" >> response3.json
    sleep 3
done

# jq -r '.response.data.order | "\(.order_reference): \(.order_status)"' response.json
