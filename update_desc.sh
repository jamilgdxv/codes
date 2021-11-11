#!/bin/bash 

################################################################
# update_desc.sh - Att desc with SQL docsis via SNMP           #
#						                                                   #
# Script GPL - Desenvolvido por Jamil W.                       #
# Favor manter os direitos e adicionar alterações              #
# 04/11/2019                                                   #
# usage: ./update_desc.sh <IP CMTS>                            #
#                                                              #
################################################################


CMTS=$1
COM="COMMUNITY";
OID_ALIAS="1.3.6.1.2.1.31.1.1.1.18";
OID_IF="1.3.6.1.2.1.31.1.1.1.1";
OID_SNR="1.3.6.1.2.1.10.127.1.1.4.1.5";
OID_FECC="1.3.6.1.2.1.10.127.1.1.4.1.3";
OID_FECN="1.3.6.1.2.1.10.127.1.1.4.1.4";
OID_FU="1.3.6.1.2.1.10.127.1.1.2.1.2";
OID_CMTS_NOME="sysName.0";

SQL_H="127.0.0.1";
SQL_U="user";
SQL_P="user";
SQL_DB="DATABASES";
TB_PORT="tb_ports_c";
HORA_CON_I=`date +"%T"`;
s=`date +"%s"`;
TMP_CON="/dados/log/con.node.$s.log";

CMTS_NOME=`snmpget -v2c -c $COM $CMTS $OID_CMTS_NOME 2> /dev/null | awk -F ":" '{print $4}' | sed 's/.ctb.virtua.com.br//g'`;


valida_consulta(){
if [ "$CMTS" = "" ]; then
    echo Necessário entrar com IP do CMTS para atualização da base!!
    exit
else
    echo OK,irei realizar a atualização da base.
fi

}



atualiza(){

#echo Limpando description de nodes na Database para o $CMTS_NOME 

#LIMPA_NOME_NODE=$(mysql -sN -h $SQL_H -u $SQL_U -p$SQL_P -e \
#    "DELETE node from tb_ports_c where cmts_ip = '$CMTS'" lista_bot)

echo OK.
echo Inicio da atualização das descriptions para o $CMTS_NOME as $HORA_CON_I

QUERY=$(mysql -sN -h $SQL_H -u $SQL_U -p$SQL_P -e \
    "SELECT index_p from tb_ports_c where cmts_ip = '$CMTS'" lista_bot)

QUERY_ID=$(mysql -sN -h $SQL_H -u $SQL_U -p$SQL_P -e \
    "SELECT port_id from tb_ports_c where cmts_ip = '$CMTS'" lista_bot)

for q in ${QUERY_ID[@]}; do
    QUERY_I=$(mysql -sN -h $SQL_H -u $SQL_U -p$SQL_P -e \
    "SELECT index_p from tb_ports_c where port_id = '${q}'" lista_bot)
    GET_NODE=`snmpget -c $COM -v 1 -Osqv $CMTS $OID_ALIAS.$QUERY_I 2> /dev/null | grep -v "CM-*" | grep -v "cable-mac*" | grep -v "Cliente*" | grep -v "SEM*" | grep -v "Virtua*" | grep -v "bun*" | grep -v "Bun*" | grep -v "FRONT-*" | grep -v "NONE*" | grep -v "LIVRE*" | grep -v "BSoD" `
    if [ "$GET_NODE" != "" ]; then
    QUERY=$(mysql -sN -h $SQL_H -u $SQL_U -p$SQL_P -e \
    "UPDATE tb_ports_c set node = '$GET_NODE' where port_id = '${q}'" lista_bot)
    echo Inserido $GET_NODE na index $QUERY_I sob o id_port na DB ${q}
    continue
    fi
done
}


valida_consulta
atualiza
