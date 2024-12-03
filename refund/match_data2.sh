#!/bin/bash

# Define your order IDs here as a space-separated list
order_ids="173073626352568 173073647390304 173073845650543 173074135879880 173074267373757 173074274632500 173074742025263 173074902871559 173075032351917 173075088896882 173075190892377 173075349048672 173075584202671 173075734215583 173075785961428 173076238290229 173077061907915 173079181387200 173079479648521 173079872109549 173079943221670 173079991452375 173080087803988 173080978868020 173081193703064 173081203493423 173081209307451 173081290027279 173081292284936 173081393494400 173081913325631 173082096799879 173082691175788 173082897292055 173082913195986 173083053937237 173083190660434 173083459790375 173083560072726 173083585497677 173083590519942 173083687111600 173083999745598 173084003978455 173084030442081 173084321159822 173084420874584 173084610174692 173084698593965 173087206681914 173087937801917 173088416464653 173088489268823 173088902817830 173088941853923 173088957283864 173089103103030 173089504874815 173089709542853 173089909314396 173089938317583 173090088026292 173090594517107 173090767849405 173090803014302 173090987285569 173091320945337 173091481017684 173091635654870 173091711936217 173091791776010 173091932472461 173092445451902 173092525593372 173092556335722 173092569339780 173092596772305 173092599017700 173092604392411 173092619851627 173092623761899 173092777291312 173092796807856 173092801100513 173092802578271 173092894430839"

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

    echo "$order_id" >> matchdata2.txt
    
    echo "$response" >> response2.json
    sleep 5
done

# jq -r '.response.data.order | "\(.order_reference): \(.order_status)"' response.json
