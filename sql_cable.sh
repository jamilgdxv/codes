#!/bin/bash 

##############################################################
# sql_cable.sh - Script coleta docsis via SNMP + SQL insert  #
#                                                            #
# Script GPL - Desenvolvido por Jamil W.                     #
# Favor manter os direitos e adicionar alterações            #
# 04/11/2019                                                 #
# usage: ./sql_cable.sh                                      #
#                                                            #
##############################################################
# Variaveis SNMP
COM="<comunity snmp>";
OID_ALIAS="1.3.6.1.2.1.31.1.1.1.18";
OID_IF="1.3.6.1.2.1.31.1.1.1.1";
OID_SNR="1.3.6.1.2.1.10.127.1.1.4.1.5";
OID_FECC="1.3.6.1.2.1.10.127.1.1.4.1.3";
OID_FECN="1.3.6.1.2.1.10.127.1.1.4.1.4";
OID_FU="1.3.6.1.2.1.10.127.1.1.2.1.2";
OID_CMTS_NOME="1.3.6.1.2.1.1.5.0";
OID_STATUS_MAC="1.3.6.1.2.1.10.127.1.3.3.1.2";

DIA=`date +'%Y-%m-%d %H:%m:%S'`;

# Variaveis SQL

SQL_H="127.0.0.1";
SQL_U="<user sql>";
SQL_P="<sql pass>";
SQL_DB="db_consulta";
TB_CMTS="cables";

#Variaveis do sistema
CMTS=('<ip do host>' '<ip do host>' '<ip do host>' '<ip do host>' '<ip do host>' '<ip do host>' '<ip do host>' '<ip do host>' '<ip do host>' '<ip do host>' '<ip do host>' '<ip do host>' '<ip do host>');
count='0';

loop(){

for c in "${CMTS[@]}"; do
cmtsnome=`snmpget -v2c -c $COM $c $OID_CMTS_NOME 2> /dev/null `;
DADOSM="/opt/base/${cmtsnome}_mac.txt";
DADOSI="/opt/base/${cmtsnome}_index.txt";

(( count++ ))
countd=(`snmpwalk -v2c -c $COM $c $OID_STATUS_MAC 2> /dev/null | tail -n 1 | awk  '{ print $1 }' | sed -e 's/DOCS-IF-MIB::docsIfCmtsCmStatusMacAddress.//g'`) ;
while [ $count != $countd ]; do
(( count++ ))
mac=(`snmpget -v2c -c $COM $c $OID_STATUS_MAC.$count 2> /dev/null | awk '{print $4}'`) ;
index=(`snmpwalk -v2c -c $COM $c $OID_STATUS_MAC 2> /dev/null | grep ${mac} | awk '{print $1}' | sed -e 's/DOCS-IF-MIB::docsIfCmtsCmStatusMacAddress.//g'`) ;
echo $c ${mac} ${index}
done
done
}


lista(){

for c in "${CMTS[@]}"; do

cmtsnome=`snmpget -v2c -c $COM $c $OID_CMTS_NOME 2> /dev/null | awk '{print $4}' | sed -e 's/.ctb.virtua.com.br//g'`;

DADOS="/opt/base/${cmtsnome}.txt";
DADOSM="/opt/base/${cmtsnome}_mac.txt";
DADOSI="/opt/base/${cmtsnome}_index.txt";

CONSULTA=(`snmpwalk -v2c -c $COM $c $OID_STATUS_MAC 2> /dev/null  > $DADOS`);

corteMAC=(`cat $DADOS | awk '{print $4}' > $DADOSM`);
corteIN=(`cat $DADOS | awk '{print $1}' | sed -e 's/DOCS-IF-MIB::docsIfCmtsCmStatusMacAddress.//g' > $DADOSI`);


exibei=(`cat $DADOSI `);
exibem=(`cat $DADOSM `);

TOTALI=${#exibei[@]};
TOTALM=${#exibem[@]};

#echo ${exibei[@]};
#echo ${exibem[@]};

done
}


limpa(){

    LIMPA=$(mysql -sN -h $SQL_H -u $SQL_U -p$SQL_P -e \
   "truncate table $TB_CMTS;" $SQL_DB)
    echo "Realizado truncate da table! $TB_CMTS";

}



insere(){


for i in "${CMTS[@]}"; do

cmtsnome=`snmpget -v2c -c $COM $i $OID_CMTS_NOME 2> /dev/null | awk '{print $4}' | sed -e 's/.ctb.virtua.com.br//g'`;

DADOS="/opt/base/${cmtsnome}.txt";
DADOSM="/opt/base/${cmtsnome}_mac.txt";
DADOSI="/opt/base/${cmtsnome}_index.txt";

exibei=(`cat $DADOSI `);
exibem=(`cat $DADOSM `);

TOTALI=${#exibei[@]};
TOTALM=${#exibem[@]};
    for j in `seq 0 $((TOTALI -1))`; do
    INSERE_D=$(mysql -sN -h $SQL_H -u $SQL_U -p$SQL_P -e \
   "INSERT into $TB_CMTS values ( '', '$cmtsnome', '${i}', '${exibem[$j]}', '${exibei[$j]}', '$DIA' )" $SQL_DB)

    done
    echo "";
done

}

lista
limpa
insere
