#!/bin/bash

############################################################
# node_search.sh - Script coleta docsis via SNMP           #
#						                                               #
# Script GPL - Desenvolvido por Jamil W.                   #
# Favor manter os direitos e adicionar alterações          #
# 04/11/2019                                               #
# usage: ./node_search.sh <NODE>                           #
#                                                          #
############################################################


NODE=$1
COM="COMUNITY";
OID_ALIAS="1.3.6.1.2.1.31.1.1.1.18";
OID_IF="1.3.6.1.2.1.31.1.1.1.1";
OID_SNR="1.3.6.1.2.1.10.127.1.1.4.1.5";
OID_FEC="1.3.6.1.2.1.10.127.1.1.4.1.2";
OID_FECC="1.3.6.1.2.1.10.127.1.1.4.1.3";
OID_FECN="1.3.6.1.2.1.10.127.1.1.4.1.4";
OID_FU="1.3.6.1.2.1.10.127.1.1.2.1.2";
OID_CMTS_NOME="sysName.0";

SQL_H="127.0.0.1";
SQL_U="user";
SQL_P="user";
SQL_DB="DATABASE";
TB_CMTS="TABLE";
TB_PORT="TABLE2";
HORA_CON_I=`date +"%T"`;
s=`date +"%s"`;
TMP_CON="/dados/log/busca.$s.log";

tmp_int="/dados/log/busca.int.$s.log";
tmp_int2="/dados/log/busca.int2.$s.log";
tmp_snr="/dados/log/busca.snr.$s.log";
tmp_snr2="/dados/log/busca.snr2.$s.log";
tmp_fec="/dados/log/busca.fec.$s.log";
tmp_fec2="/dados/log/busca.fec2.$s.log";
tmp_fecc="/dados/log/busca.fecc.$s.log";
tmp_fecc2="/dados/log/busca.fecc2.$s.log";
tmp_fecnc="/dados/log/busca.fecnc.$s.log";
tmp_fecnc2="/dados/log/busca.fecnc2.$s.log";
tmp_freq="/dados/log/busca.freq.$s.log";
tmp_freq2="/dados/log/busca.freq2.$s.log";

tmp_ok="/dados/log/exibe.conok.$s.log";


valida_consulta(){
if [ "$NODE" = "" ]; then
    echo Necessário entrar com argumento para pesquisa!
    exit
else
    echo "OK, só um momento..." > $TMP_CON
fi

}

consulta(){

QUERY=$(mysql -sN -h $SQL_H -u $SQL_U -p$SQL_P -e \
    "SELECT index_p from tb_ports_c where node = '$NODE'" lista_bot)

if [ "$QUERY" = "" ]; then
    echo NODE: $NODE, não localizado em nossa base de dados, favor validar a digitação!
    exit
else

CMTS=$(mysql -sN -h $SQL_H -u $SQL_U -p$SQL_P -e \
    "SELECT distinct cmts_ip from tb_ports_c where node = '$NODE'" lista_bot)
    CMTS_NOME=`snmpget -v2c -c $COM $CMTS $OID_CMTS_NOME 2> /dev/null | awk -F ":" '{print $4}' | sed 's/.ctb.virtua.com.br//g'`;
    echo "NODE:*$NODE,* localizado no CMTS *$CMTS_NOME*";
    echo "Inicio da consulta *$HORA_CON_I hs*";
fi

for index in ${QUERY[@]}; do
    NODE_S=`snmpget -v2c -c $COM $CMTS $OID_ALIAS.${index} 2> /dev/null | awk -F "." '{print $2}' | awk '{print $4}'`
    if [ "$NODE_S" != "" ]; then
    CON_ID_NODE=`snmpget -c $COM -v 1 -Osqv $CMTS $OID_ALIAS.${index} 2> /dev/null &`;
    CON_IF_NODE=`snmpget -c $COM -v 1 -Osqv $CMTS $OID_IF.${index} 2> /dev/null &`;
    CON_SNR_NODE=`snmpget -c $COM -v 1 -Osqv $CMTS $OID_SNR.${index} 2> /dev/null &`;
    CON_FU_NODE=`snmpget -c $COM -v 1 -Osqv $CMTS $OID_FU.${index} 2> /dev/null &`;
    con_fec_1=`snmpget -c $COM -v 1 -Osqv $CMTS $OID_FEC.${index} 2> /dev/null | sed 's/codewords//g' &`;
    con_fecc_1=`snmpget -c $COM -v 1 -Osqv $CMTS $OID_FECC.${index} 2> /dev/null | sed 's/codewords//g' &`;
    con_fecn_1=`snmpget -c $COM -v 1 -Osqv $CMTS $OID_FECN.${index} 2> /dev/null | sed 's/codewords//g' &`;

sleep 3

    con_fec_2=`snmpget -c $COM -v 1 -Osqv $CMTS $OID_FEC.${index} 2> /dev/null | sed 's/codewords//g' &`;
    con_fecc_2=`snmpget -c $COM -v 1 -Osqv $CMTS $OID_FECC.${index} 2> /dev/null | sed 's/codewords//g' &`;
    con_fecn_2=`snmpget -c $COM -v 1 -Osqv $CMTS $OID_FECN.${index} 2> /dev/null | sed 's/codewords//g' &`;
    r_con_fecc=`echo "($con_fecc_2 - $con_fecc_1)/(($con_fecn_2 - $con_fecn_1)+($con_fecc_2 - $con_fecc_1)+($con_fec_2 - $con_fec_1))*100 " | bc -l 2> /dev/null`;
    r_con_fecn=`echo "($con_fecn_2 - $con_fecn_1)/(($con_fecn_2 - $con_fecn_1)+($con_fecc_2 - $con_fecc_1)+($con_fec_2 - $con_fec_1))*100 " | bc -l 2> /dev/null`;
#    echo $NODE localizado com o id ${index} em $CMTS
    echo $CON_IF_NODE >> $tmp_int
    echo $CON_SNR_NODE >> $tmp_snr
    echo $CON_FU_NODE >> $tmp_freq
    echo $r_con_fecc >> $tmp_fecc
    echo  $r_con_fecn >> $tmp_fecnc
    continue
    else
    echo Não foi possivel consultar $NODE
    fi
done
}

exibe_dados(){

cat $tmp_int | sed -e '1d' | sed -e '2d' | sed -e '3d' | sed -e '4d' | awk -F "/" '{print $3}' > $tmp_int2
cat $tmp_snr | sed 's/TenthdB//g' | sed -e '1d' | sed -e '2d' | sed -e '3d' | sed -e '4d' > $tmp_snr2
cat $tmp_fecc | sed -e '1d' | sed -e '2d' | sed -e '3d' | sed -e '4d' | cut -c 1-4 | sed 's/[0-9]\{0\}/&0/' > $tmp_fecc2
cat $tmp_fecnc | sed -e '1d' | sed -e '2d' | sed -e '3d' | sed -e '4d' |  cut -c 1-4 | sed 's/[0-9]\{0\}/&0/' > $tmp_fecnc2
cat $tmp_freq | sed 's/hertz//g' | sed -e '1d' | sed -e '2d' | sed -e '3d' | sed -e '4d' | sed 's/[0-9]\{2\}/&./' | sed -e 's/00000//g' > $tmp_freq2
echo "*UP SNR FQ    FC% FN% *" >> $tmp_ok
CONCAT_DADOS=`paste $tmp_int2 $tmp_snr2 $tmp_freq2 $tmp_fecc2 $tmp_fecnc2 | sed -e 's/\ \+/\t/g'  >> $tmp_ok`;


cat $tmp_ok

}


valida_consulta
consulta
HORA_CON_F=`date +"%T"`;

exibe_dados
echo "Consulta concluida! *$HORA_CON_F*"
