#!/bin/bash

####################################################
# cad_olt_sql.sh - Script olt cadastro por rede    #
#                                                  #
# Script GPL - Desenvolvido por Jamil W.           #
# Favor manter os direitos e adicionar alterações  #
# xx/xx/2023                                       #
# usage: ./cad_olt_sql.sh                          #
#                                                  #
####################################################


###INICIO DO SCRIPT

DATA=`date +%d-%m-%Y`
HORA=`date +%Hh%Mmin`

#LISTA DE IPS DOS CMTS CONSULTADOS

olts="/dados/monitor_olt/scripts/olt.list";
log="/dados/monitor_olt/scripts/coleta_$DATA.log";
com="public2";
comunidade="public";
snmpwalk="snmpwalk -Osqv -v2c -c";
snmpget="snmpget -Ovq -v2c -c";
walk="snmpwalk -On -v2c -c";
nmap="nmap -sP";


# Acesso SQL

SQL_H="192.168.10.20";
SQL_U="usuario";
SQL_P="senha";
SQL_DB="db_olt";
TB_OLT_CAD="tb_olt_cad";
TB_OLT_PLACA="tb_olt_placas";
TB_OLT_IF="tb_olt_uplink";

##LISTA DE OIDS


oltNome="1.3.6.1.2.1.1.5.0";
oltVendor="1.3.6.1.2.1.1.1.0";
boardModel="1.3.6.1.4.1.2011.2.6.7.1.1.2.1.7.0";
boardStatus="1.3.6.1.4.1.2011.6.3.3.2.1.8.0";
boardModelZ="1.3.6.1.4.1.3902.1082.10.1.2.4.1.42.1.1";
boardStatusZ="1.3.6.1.4.1.3902.1082.10.1.2.4.1.5.1.1";
boardPower="1.3.6.1.4.1.2011.2.6.7.1.1.2.1.11.0";
upTempo="1.3.6.1.2.1.1.3.0";
EtherOid="1.3.6.1.2.1.2.2.1.2";
EtherTx="1.3.6.1.4.1.2011.5.14.6.4.1.4";
EtherRx="1.3.6.1.4.1.2011.5.14.6.4.1.5";
EtherNome="1.3.6.1.2.1.2.2.1.2";

XgeiTx="1.3.6.1.4.1.3902.1082.30.40.2.4.1.3";
XgeiRx="1.3.6.1.4.1.3902.1082.30.40.2.4.1.2";

##Log Falha OLT

failLog="/dados/monitor_olt/scripts/log/fail_log_$DATA_$HORA.log";

#Redes por cidades

cidade1="10.0.0.0/24";
cidade2="192.168.20.0/24";

#Lista de Hosts

#oltIps=`cat $olts | awk '-F;' '{print $1}' | grep -v '#'`;


oltIps=`$nmap $cidade1 $cidade2 | grep report | awk '{print $NF}' | sed 's/(//g' | sed 's/)//g'`;
oltIpsQnt=`$nmap $cidade1 $cidade2 | grep report | awk '{print $NF}' | sed 's/(//g' | sed 's/)//g' | wc -l`;


echo -ne "Sys Start [$DATA $HORA] - Serão processadas $oltIpsQnt host's no Cluster PR\n\n\n";

for olt in ${oltIps[@]}; do


nomeOlt=`$snmpget $com $olt $oltNome 2> /dev/null | sed 's/"//g'`;

nomeOltCheck=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
"select oltNome from $TB_OLT_CAD where oltNome = '$nomeOlt'" $SQL_DB)


    if [[ $nomeOlt == $nomeOltCheck ]]; then
    echo -ne "[DUPLICADA][$olt] Ja inserida no BD\n\n" >> $failLog;
    elif [ -z $nomeOlt ]; then
    echo -ne "[Sem coleta][$olt] HOST Off [OTHER]\n\n" >> $failLog;
    elif [[ $nomeOlt == *"RTD"* ]]; then
    echo -ne "[$nomeOlt][$olt] HOST type [RTD] \n\n" >> $failLog;
    elif [[ $nomeOlt == *"CMT"* ]]; then
    echo -ne "[$nomeOlt][$olt] HOST type [CMT] \n\n" >> $failLog;
    else
    vendor=`$snmpget $com $olt $oltVendor | sed 's/Integrated Access Software//g' | sed 's/ZXA10//g' | sed 's/,//g' | sed 's/"//g' | sed 's/Software Version: V1.2.3//g' | sed 's/C600//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' `;
	if [ $vendor == "Huawei" ]; then
		boards=`$walk $com $olt $boardModel | sed 's/.1.3.6.1.4.1.2011.2.6.7.1.1.2.1.7.0.//g' | awk '{print $1}'`;
		tempo=`$snmpget $com $olt $upTempo | awk '-F:' '{print $1,"Dias", $2"H", $3"Min"}'`;
		ether=`$walk $com $olt $EtherOid | egrep '0/8/0|0/9/0' | sed 's/.1.3.6.1.2.1.2.2.1.2.//g' | awk '{print $1}'`;
		#echo -ne "OLT: $nomeOlt [$olt] [$vendor]\n";
		#echo -ne "SysTime: $tempo \n";
		#echo -ne "[Slot]\t[Type]\t[Status]\t[Watts] \n";
		echo "$nomeOlt:$olt:$vendor:$tempo";
		cableSql=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
		"insert into $TB_OLT_CAD (oltNome,oltVendor,oltIp,oltUptime) values ('$nomeOlt','$vendor','$olt','$tempo')" $SQL_DB)
			for slot in ${boards[@]}; do
				oltID=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
				"select id_olt from $TB_OLT_CAD where oltIp = '$olt'" $SQL_DB)
				modelo=`$snmpget $com $olt $boardModel.$slot | sed 's/"//g'`;
				status=`$snmpget $com $olt $boardStatus.$slot | sed 's/"//g'`;
					if [ $status -eq 1 ]; then
					stats="uninstall";
					elif [ $status -eq 2 ]; then
					stats="normal";
					elif [ $status -eq 3 ]; then
					stats="fault";
					elif [ $status -eq 4 ]; then
					stats="forbidden";
					elif [ $status -eq 5 ]; then
					stats="discovery";
					elif [ $status -eq 6 ]; then
					stats="config";
					elif [ $status -eq 7 ]; then
					stats="offline";
					elif [ $status -eq 8 ]; then
					stats="abnormal";
					fi
					#if [[ $modelo == *"PILA"* ]]; then
					#power=`$snmpget $com $olt $boardPower.$slot`;
					#echo -e "$slot \t $modelo \t $stats [$power]";
					#echo "$slot:$modelo:$stats";
					#oltID=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
					#"select id_olt from $TB_OLT_CAD where oltIp = '$olt'" $SQL_DB)
					placaSQL=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
					"insert into $TB_OLT_PLACA (id_olt,slotPlaca,slotModel,slotStatus) values ('$oltID','$slot','$modelo','$stats')" $SQL_DB)
					#else
					#echo -e "$slot \t $modelo \t $stats";
					#echo "$slot:$modelo:$stats";
					#fi
			done
		#echo -ne "[IF]\t[Tx]\t\t[Rx]\n";
			for eth in ${ether[@]}; do
			nome_eth=`$snmpwalk $com $olt $EtherNome.$eth | sed 's/Huawei-MA5800-V100R020-ETHERNET//g' | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
			eth_TX=`$snmpget $com $olt $EtherTx.$eth`;
			eth_RX=`$snmpget $com $olt $EtherRx.$eth`;
			TX=`echo "$eth_TX * 0.000001" | bc | awk '{printf "%.3f\n", $0}'`;
			RX=`echo "$eth_RX * 0.000001" | bc | awk '{printf "%.3f\n", $0}'`;
			#echo -ne "$nome_eth \t $TX \t $RX \n";
			echo "$nome_eth:$TX:$RX";
			IfSQL=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
			"insert into $TB_OLT_IF (id_olt,slotIF,slotIfTx,slotIfRx) values ('$oltID','$nome_eth','$TX','$RX')" $SQL_DB)
			#oltID=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
			#"select id_olt from $TB_OLT_CAD where oltIp = '$olt'" $SQL_DB)
			#placaSQL=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
			#"insert into $TB_OLT_PLACA (id_olt,slotPlaca,slotModel,slotStatus) values ('$oltID','$vendor','$olt','$tempo')" $SQL_DB)
			done
		#cableSql=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
		#"insert into $TB_OLT_CAD (oltNome,oltVendor,oltIp,oltUptime) values ('$nomeOlt','$vendor','$olt','$tempo')" $SQL_DB)
		echo -ne "\n\n";
	elif [ $vendor == "ZTE" ]; then
		boards=`$walk $com $olt $boardModelZ | sed 's/.1.3.6.1.4.1.3902.1082.10.1.2.4.1.42.1.1.//g' | egrep 'HFTH|SFUQ'| awk '{print $1}'`;
		tempo=`$snmpget $com $olt $upTempo | awk '-F:' '{print $1,"Dias", $2"H", $3"Min"}'`;
		ether=`$walk $com $olt $EtherOid | egrep '1/10/1|1/11/1' | sed 's/.1.3.6.1.2.1.2.2.1.2.//g' | awk '{print $1}'`;
		#echo -ne "OLT: $nomeOlt [$olt] [$vendor]\n";
		#echo -ne "SysTime: $tempo \n";
		#echo -ne "[Slot]\t[Type]\t[Status]\n";
		echo "$nomeOlt:$olt:$vendor:$tempo";
		cableSql=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
		"insert into $TB_OLT_CAD (oltNome,oltVendor,oltIp,oltUptime) values ('$nomeOlt','$vendor','$olt','$tempo')" $SQL_DB)
			for slot in ${boards[@]}; do
				oltID=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
				"select id_olt from $TB_OLT_CAD where oltIp = '$olt'" $SQL_DB)
				modelo=`$snmpget $com $olt $boardModelZ.$slot | sed 's/"//g'`;
				status=`$snmpget $com $olt $boardStatusZ.$slot`;
					if [ $status -eq 1 ]; then
					stats="inService";
					elif [ $status -eq 2 ]; then
					stats="notInService";
					elif [ $status -eq 3 ]; then
					stats="hwOnline";
					elif [ $status -eq 4 ]; then
					stats="hwOffline";
					elif [ $status -eq 5 ]; then
					stats="configuring";
					elif [ $status -eq 6 ]; then
					stats="configFailed";
					elif [ $status -eq 7 ]; then
					stats="typeMismatch";
					elif [ $status -eq 8 ]; then
					stats="deactived";
					elif [ $status -eq 9 ]; then
					stats="faulty";
					elif [ $status -eq 10 ]; then
					stats="invalid";
					elif [ $status -eq 11 ]; then
					stats="noPower";
					elif [ $status -eq 12 ]; then
					stats="unauthorized";
					elif [ $status -eq 13 ]; then
					stats="adminDown";
					elif [ $status -eq 34 ]; then
					stats="powerSaving";
					fi
					#echo -e "$slot \t $modelo \t $stats ";
					echo "$slot:$modelo:$stats";
					placaSQL=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
					"insert into $TB_OLT_PLACA (id_olt,slotPlaca,slotModel,slotStatus) values ('$oltID','$slot','$modelo','$stats')" $SQL_DB)
			done
		#echo -ne "[IF]\t[Tx]\t[Rx]\n";
			for eth in ${ether[@]}; do
			nome_eth=`snmpwalk -v2c -c $com -Osqv $olt $EtherNome.$eth | sed 's/ZTE-C600-V1.2.3-xgei-//g' | sed 's/ZTE-C600-V1.1.2_BC-xgei-//g' | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
			eth_TX=`$snmpget $com $olt $XgeiTx.$eth`;
			eth_RX=`$snmpget $com $olt $XgeiRx.$eth`;
			TX=`echo "$eth_TX * 0.001" | bc | awk '{printf "%.3f\n", $0}'`;
			RX=`echo "$eth_RX * 0.001" | bc`;
			#echo -ne "$nome_eth \t $TX \t $RX \n";
			echo "$nome_eth:$TX:$RX";
			IfSQL=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
			"insert into $TB_OLT_IF (id_olt,slotIF,slotIfTx,slotIfRx) values ('$oltID','$nome_eth','$TX','$RX')" $SQL_DB)
			done
#		cableSql=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
#		"insert into $TB_OLT_CAD (oltNome,oltVendor,oltIp,oltUptime) values ('$nomeOlt','$vendor','$olt','$tempo')" $SQL_DB)
		echo -ne "\n\n";
	fi
    fi
done
