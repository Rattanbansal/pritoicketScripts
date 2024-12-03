#!/bin/bash

# Define your order IDs here as a space-separated list
order_ids="172820976581117 172820996205895 172821441499620 172822031128058 172822124972416 172822735180826 172823302279321 172823656874092 172824115513040 172824184520418 172824312351593 172824488207040 172824512107044 172824860406013 172825109142998 172828866005011 172828867872954 172830141404760 172830191916681 172831431125666 172831482549700 172831727234676 172832147729599 172832543372401 172832885643217 172833242591956 172833427607690 172833744693024 172837016958237 172837870060189 172837910728965 172838077804530 172838091508668 172838305974501 172838810426468 172839976654346 172840297246571 172840623095353 172840868973368 172841055673996 172841181916369 172841873050673 172846194963097 172846762228201 172846920559114 172846990629599 172847247324592 172847999825358 172849075548935 172849939710372 172850511817844 172850556672249 172854309999305 172855129924069 172856483181692 172858895098755 172859053450852 172859074150301 172863633180828 172863995686461 172864300579799 172865117282538 172865596978510 172865682936345 172866002432707 172867581202709 172867808545626 172867863765406 172870901796902 172872659524862 172873887443141 172874418094373 172874686675481 172875050585759 172876553372922 172876554101024 172880677762534 172880754309380 172881067293453 172881107059057 172881116263296 172882056244799 172882405943423 172882757881778 172882782675613 172883193419137 172883221790299 172883249781375 172883899033229 172884184320734 172884378182079 172884709321891 172884715083366 172884724311864 172884815153503 172886311370081 172889179613239 172889350481046 172889593460817 172891418226968 172891520050626 172892299643382 172892653822980 172892908586510 172893379647973 172893483916226 172897264568668 172898002704755 172898210868569 172898439023326 172898754421197 172898852073443 172899988200519 172900044148478 172900049948319 172900512913727 172900733550224"

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

    echo "$order_id" >> matchdata1.txt
    
    echo "$response" >> response1.json
    sleep 4
done

# jq -r '.response.data.order | "\(.order_reference): \(.order_status)"' response.json
