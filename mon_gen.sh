#!/bin/bash

####################################################
# mon.sh - Script monitoramento ICMP generico      #
#						                                       #
# Script GPL - Desenvolvido por Jamil W.           #
# Favor manter os direitos e adicionar alterações  #
# 13/11/2019                                       #
# usage: ./mon.sh                                  #
#                                                  #
####################################################


IP=('<IP HERE>');


log="/dados/log_mon_ip.txt";

teste(){

for i in ${IP[@]};
do

    TESTE=`ping -c 600 ${i}`;
    echo "$TESTE"
    echo ""
    echo "---------------------------------------------------"
    echo Execução de testes OK para o destino ${i}
    if [ "$TESTE" = "no response" ]; then
    echo Falha ao executar testes para o destino ${i}
    fi
done

}


while true; do

teste >> $log

done
