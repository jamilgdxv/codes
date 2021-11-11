#!/bin/bash

################################################################
# Interface utilization CMTS tootls for bash                   #
#                                                              #
# LOG into CMTS with expect                                    #
# Collect data                                                 #
# Display information                                          #
#                                                              #
# required "utilization.sh"                                    #
#                                                              #
# ./if_utilization.sh                                          #
# 01/04/2020                                                   #
################################################################





# OID SISTEMA

OID_NOME="1.3.6.1.2.1.1.5.0";
OID_BOOT="1.3.6.1.2.1.69.1.1.3.0";
OID_TYPE="1.3.6.1.2.1.2.2.1.3";
OID_MAC="1.3.6.1.2.1.2.2.1.6.2";
OID_TX="1.3.6.1.2.1.10.127.1.2.2.1.3.2";
OID_RX="1.3.6.1.2.1.10.127.1.1.1.1.6.3";
OID_SNR="1.3.6.1.2.1.10.127.1.1.4.1.5.3";


# COMUNIDADES SNMP

COM="<comunity SNMP>";

#VARIAVEIS DO SISTEMA
HORA=`date +'%T'`;
TIME=`date +'%s'`;
DIA=`date +'%d%m%Y'`;
DIAF=`date +'%d-%m-%Y'`;

# DIRETORIO PARA DADOS DE LOG ARQUIVADOS

histdir="/dados/utilization_hist/BKP-$DIA-$TIME/";

logexec="/dados/utilization_exec/LOG-EXEC-$DIA-$TIME.txt";

#DADOS PARA INTERACAO DO EXPECT

USER="<usuario ssh/expect>";
PASS="<your pass to acess>";

CMTS=("<ip host>" "<ip host>" "<ip host>" "<ip host>" );



# DADOS DO EMAIL

dest1="nomedodestinatario@gmail.com";
dest2="copiadodestinatarior@claro.com.br";



#MSG DO SISTEMA

echo "+-------------------------------------------+";
echo "| Iniciando consultas por favor aguarde     |" >> $logexec ;
echo "| Sistema iniciado as $HORA              |" >> $logexec ;
echo "| Sistema iniciado as $HORA              |";
echo "+-------------------------------------------+";
echo "Dados logados em $logexec";
echo "";


# Inicio da função de consulta


consulta(){

for c in ${CMTS[@]};do


CMTS_NOME=`snmpget -v2c -c $COM $c $OID_NOME 2> /dev/null | awk -F ":" '{print $4}' | sed 's/.ctb.virtua.com.br//g' | sed 's/ //g'`;
echo "+ Realizando consulta para o CMTS ${c} $CMTS_NOME";
logdir="/dados/utilization_dir/$CMTS_NOME.log";


ACESSO=`utilization.sh ${c} $USER $PASS > $logdir `;

DADOS=`cat "$logdir" | grep -v $CMTS_NOME | egrep "ucam|dcam|Channel|<--" `;


CONTA_U=`cat "$logdir" | grep "ucam" | wc -l`;
CONTA_D=`cat "$logdir" | grep "dcam" | wc -l`;

echo "$DADOS";
echo "++ Foram localizados $CONTA_U upstream e $CONTA_D downstream com utilização > 75% no $CMTS_NOME";
echo "";

done
}

#Funcao para envio de email

envia_email(){

ENVIA=`echo Rotina de consulta para portas com alta utilizacao em CMTS ARRIS realizada em $DIAF. | mail -A "$logexec" -s "[ROTINA] CMTS If Utilization verify - Arris CMTS $DIAF" "$dest1, $dest2"`;

}

# Função de consulta do script

consulta >> $logexec


# Função para envio de email

envia_email


exit