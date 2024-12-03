#!/bin/bash

# Define your order IDs here as a space-separated list
order_ids="173230509815395 173230559992025 173230622878111 173230647870433 173230670808250 173230751765085 173230779337804 173230794586745 173230812502444 173230844094705 173230997978827 173231053435882 173231079383869 173231152857856 173231268563623 173231360605153 173231401058228 173231462054758 173231519240494 173231735585113 173231864644578 173231901262738 173232068593280 173232194775106 173232240730878 173234980755027 173234982689805 173235071068488 173235121746597 173235244571640 173235310104798 173235347035827 173235372477468 173235472400239 173235534621545 173235649981593 173235661979976 173235818981578 173235895717375 173236050243364 173236083711499 173236220664869 173236278216305 173236342585135 173236406145154 173236492294302 173236501459867"

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

# jq -r '.response.data.order | "\(.order_reference): \(.order_status)"' response.json response1.json response2.json response3.json > test.json
