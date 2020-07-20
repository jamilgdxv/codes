#!/bin/bash


######################################################
# Sistema para monitoramento de ONTS on/off          #
#                                                    #
# 28/11/19 - Versão inicial 0.1.0                    #
# Desenvolvido por Jamil W.                          #
#                                                    #
# Usage: ./onts_sum.sh                               #
######################################################


# OIDS SISTEMA

OID_OLT_NOME="sysName.0";
COM="<COM>";
HORA=`date +'%T'`;

pass="putyourpass";

# VARIAVEIS SQL
SQL_H="127.0.0.1";
SQL_U="user";
SQL_P="user";
SQL_DB="<UR BASE>";
TB_OLT="tb_summ_ont";


# OLTS

OLT=("<IP OLT>" "<IP OLT>");

# Inicio das mensagens de sistema

echo +-----------------------------------------------------+
echo Realizando a limpeza do banco de dados para popular.....

LIMPA_DB=$(mysql -sN -h $SQL_H -u $SQL_U -p$SQL_P -e \
"truncate table $TB_OLT" $SQL_DB)


echo Iniciada consulta as $HORA

# Função do sistema

get_info(){

for o in ${OLT[@]}; do


LOGA=`sshpass -p $pass ssh ${o} -l <LOGIN> 2> /dev/null << EOF 
enable
scroll
display ont info summary 0 | include port
quit
EOF`


OLT_NOME=`snmpget -v2c -c $COM $o $OID_OLT_NOME 2> /dev/null | awk -F ":" '{print $4}' | sed 's/.ctb.virtua.com.br//g'`;

CORTE=`echo "$LOGA" 2> /dev/null | grep total | awk -F ":" '{print $3}' | sed -e 's/\r//g'`;
CORTE2=`echo "$LOGA" 2> /dev/null | awk -F ":" '{print $2}' | sed -e 's/,//g' | sed -e 's/online//' | sed -e 's/\r//g'`;


TOTAL=`echo ${CORTE2[@]} 2> /dev/null | sed 's/ /+/g' | bc -l `;
ONLINE=`echo ${CORTE[@]} 2> /dev/null | sed 's/ /+/g' | bc -l `;
OFFLINE=`echo $TOTAL - $ONLINE 2> /dev/null | bc -l `;

# Inclusão dos dados na table SQL

INSERE_O=$(mysql -sN -h $SQL_H -u $SQL_U -p$SQL_P -e \
"INSERT into $TB_OLT (olt_name, olt_ip, ont_total, ont_up, ont_down) values ('${OLT_NOME}', '${o}', '${TOTAL}', '${ONLINE}', '${OFFLINE}')" $SQL_DB)


echo OLT:$OLT_NOME Total:$TOTAL ON:$ONLINE OFF:$OFFLINE

done
}
# Chama função

get_info

# Imprimindo mensagens finais

FIM=`date +'%T'`;

echo Finalizada consulta as $FIM
echo +----------------------------------------------------+
