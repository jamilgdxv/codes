#!/bin/bash
######################################################
# Sistema para coleta de cables  BOUND               #
#                                                    #
# 05/12/19 - Versão inicial 0.1.0                    #
# Desenvolvido por Jamil W.                          #
#                                                    #
# Usage: ./docsis_wrong_bound.sh                     #
# apt-get install sshpass                            #
######################################################
# OIDS SISTEMA

OID_NOME="sysName.0";
OID_BOOT=".1.3.6.1.2.1.69.1.1.3.0";
COMU="nononono";
COMUM="nononono";

HORA=`date +'%T'`;
TIME=`date +'%s'`;
pass="YOURPASS";


# VARIAVEIS LOG

lista="/dados/lista.$TIME.txt";

# LISTA CMTS

CMTS=("YOUR IP CMTS");

# Msg inicio sistema

echo Coleta de cables iniciada as $HORA;

# Função do sistema
coleta_cable(){

for c in ${CMTS[@]}; do

LOGA=`sshpass -p $pass ssh ${c} -l <LOGIN> 2> /dev/null << EOF
show cable modem | include "Operational 3.0" | exclude 16x* | 8x*
quit
EOF`

    CMTS_NOME=`snmpget -v2c -c $COM $c $OID_NOME 2> /dev/null | awk -F ":" '{print $4}' | sed 's/.ctb.virtua.com.br//g'`;

    CORTE=(`echo "$LOGA" 2> /dev/null | grep -v "CMT" | sed -e 1,21d | awk '{print $8}'`);

    CORTE2=(`echo "$LOGA" 2> /dev/null | grep -v "CMT" | sed -e 1,21d | awk '{print $9}'`);

    DADOS=`echo "$LOGA" 2> /dev/null | grep -v "CMT" | sed -e 1,21d | awk '{print $8}' | grep -v "by" | awk 'NF>0'`;

    IP=`echo "$LOGA" 2> /dev/null | grep -v "CMT" | sed -e 1,21d | awk '{print $9}' | grep -v "technically" | awk 'NF>0' >> $lista `

    IPS=(`cat $lista`);

CONTA=${#CORTE[@]};

if [ $CONTA -gt 10 ]; then

    # Condição caso a contagem seja maior a 10
    echo A lista do $CMTS_NOME contem mais que 10 equipamentos! Foram localizados $CONTA;
    MONTA=`seq 0 $((CONTA -1))`
    echo "$DADOS"
    else
    # Condição caso a contagem seja inferior a 10
    echo A lista do $CMTS_NOME contem menos que 10 equipamentos! Foram localizados $CONTA;
    echo "$DADOS"
    echo -------------------------------------------------;
    echo "";
    MONTA=`seq 0 $((CONTA -1))`
    fi
done


}

reseta(){

for i in ${IPS[@]}; do
    RESETA=`snmpset -c $COMU -v 1 $i $OID_BOOT i 1 2> /dev/null `;
    RESETA=`snmpset -c $COMUM -v 1 $i $OID_BOOT i 1 2> /dev/null `;
    echo Cable $i Resetado via SNMP.
    sleep 1

done
}



coleta_cable

CONTAL=${#IPS[@]};
cat $lista
echo Um total de $CONTAL cables com falha de Bounding de UP ou DOWN!;
echo Iniciando a tratativa dos ofensores...
echo "";

reseta

FIM=`date +'%T'`;
echo "";
echo Finalizada coleta de cables as $FIM
Você tem mensagem de correio em /var/mail/root
