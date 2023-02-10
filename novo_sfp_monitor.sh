#!/bin/bash

#####################################################################
#                                                                   #
# Todos os direitos autorais são GPL                                #
# Favor manter os direitos e adicionar as alterações abaixo.        #
# Time de desenvolvimento Claro Cluster PR                          #
# Versão original e devidas correções                               #
# Jamil Elirio Walber - jamil.walber@claro.com.br                   #
# 08/05/2022                                                        #
# Look at: version.data                                             #
#                                                                   #
#                                                                   #
#                                                                   #
#####################################################################
##########################
# Variaveis do SQL #######
##########################

sqlBase="db_olt";
sqlTable="tb_olt_cad";
sqlTableP="tb_olt_ports";


com="public0";


#########################
# Variaveis do sistema ##
#########################

    snmpwalk="snmpwalk -v2c -c public1";
    snmpget="snmpget -Ovq -v2c -c";


########################
# SNMP LISTA           #
########################


huaweiONUon="1.3.6.1.4.1.2011.6.128.1.1.2.51.1.4";
zteONUon="1.3.6.1.4.1.3902.1082.500.10.2.3.8.1.4";
oltName="1.3.6.1.2.1.1.5.0";
oltVendor="1.3.6.1.2.1.1.1.0";



SFPVendorName="1.3.6.1.4.1.2011.6.128.1.1.2.22.1.11";
SFPVendorPN="1.3.6.1.4.1.2011.6.128.1.1.2.22.1.13";
SFPVendorSN="1.3.6.1.4.1.2011.6.128.1.1.2.22.1.20";


#########################
# Inicio do SYS #########
#########################

dia=`date +'%d-%m-%Y %H:%M:%S'`;

echo -ne "SYS STARTED at $dia \n\n\n";


list=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
"select oltIp from $sqlTable" $sqlBase)


for olt in ${list[@]}; do

oltNome=`$snmpget $com $olt $oltName 2> /dev/null | sed 's/"//g'`;
oltModel=`$snmpget $com $olt $oltVendor | sed 's/Integrated Access Software//g' | sed 's/ZXA10//g' | sed 's/,//g' | sed 's/"//g' | sed 's/Software Version: V1.2.3//g' | sed 's/C600//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' `;



	if [ $oltModel = 'Huawei' ]; then
		dia1=`date +'%d-%m-%Y %H:%M:%S'`;
		echo -ne "$oltNome - $olt - $oltModel em $dia1 \n\n";
		oltID=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
		"select id_olt from $sqlTable where oltIp = '$olt'" $sqlBase);
		placas_id=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
		"select oltIdPort from tb_olt_ports where oltSfpSn NOT LIKE '%SEM SFP%' and id_olt = '$oltID'" $sqlBase)
			for placa in ${placas_id[@]}; do
			sfpSnBD=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
			"select oltSfpSn from $sqlTableP where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase)
			stat_alarme=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
			"select oltPortStats from $sqlTableP where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase)
			if [ $stat_alarme == "NULL" ];then
			sfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.20.$placa 2> /dev/null | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
				if [ -z $sfpSn ] || [ "$sfpSn" == *"Timeout"* ]; then
					sleep 2
					sfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.20.$placa  2> /dev/null | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
						if [ -z $sfpSn ] || [ "$sfpSn" == *"Timeout"* ]; then
						sleep 2
						sfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.20.$placa  2> /dev/null | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
							if [ -z $sfpSn ] || [ "$sfpSn" == *"Timeout"* ]; then
							sfpSn="SEM SFP";
							fi
						fi
				elif [ ! -z $sfpSn ]; then
				:
				fi
			placa_nome=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
			"select oltNomePort from $sqlTableP where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase)
			placa_IF=`echo $placa_nome | sed 's/_/ /g'`;
					if [ "$sfpSnBD" == "$sfpSn" ]; then
					Status="IGUAIS";
					elif [ "$sfpSnBD" != "$sfpSn" ]; then
					Status="DIFERENTES";
					sql_msg=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
					"select oltMsgStats from $sqlTableP where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase)
						if [ "$sql_msg" == "ENVIADA" ]; then
						notificacao="NADA FEITO";
						elif [ "$sql_msg" == "NULL" ]; then
						echo -ne "ENVIAR MSG VIA TELEGRAMA";
						notificacao="ENVIADO MSG";
						portStats="ALARMADO";
						msgStats="ENVIADA";
						diaN=`date +'%d-%m-%Y %H:%M:%S'`;
						insere_alarme=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e  \
						"update $sqlTableP set oltPortStats = '$portStats', oltMsgStats = '$msgStats', oltPortUpdate = '$diaN' where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase);
						echo -ne "DADOS ATUALIZADOS NO SQL $oltNome $placa_IF $portStats $msgStats\n";
						envia_MSG=`./stats_NOK.sh $oltNome $olt "$oltModel - FALHA SFP MONITOR" "SFP: $sfpSnBD $placa_IF - REMOVIDA" "$diaN"`;
						fi
					echo -ne "$placa_IF SFP na base: $sfpSnBD SFP na porta: $sfpSn  SFP Status: [ $Status ] MSG Stat: [ $notificacao ]\n";
					fi
			#echo -ne "$placa_IF SFP na base: $sfpSnBD SFP na porta: $sfpSn  SFP Status: [ $Status ]\n";
			elif [ "$stat_alarme" == "ALARMADO" ]; then
			sfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.20.$placa 2> /dev/null | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
				if [ -z $sfpSn ] || [ "$sfpSn" == *"Timeout"* ]; then
				sleep 2
				sfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.20.$placa  2> /dev/null | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
					if [ -z $sfpSn ] || [ "$sfpSn" == *"Timeout"* ]; then
					sleep 2
					sfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.20.$placa  2> /dev/null | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
						if [ -z $sfpSn ] || [ "$sfpSn" == *"Timeout"* ]; then
						sfpSn="SEM SFP";
						fi
					fi
				elif [ ! -z $sfpSn ]; then
					if [ "$sfpSnBD" == "$sfpSn" ]; then
					portStats="NULL";
					msgStats="NULL";
					diaN=`date +'%d-%m-%Y %H:%M:%S'`;
					alarme_hr=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
					"select oltPortUpdate from $sqlTableP where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase);
					insere_alarme=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e  \
					"update $sqlTableP set oltPortStats = NULL, oltMsgStats = NULL, oltPortUpdate = '$diaN' where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase);
					envia_MSG=`./stats_OK.sh $oltNome $olt "$oltModel - NORMALIZADA" "SFP: $sfpSn $placa_IF - INSERIDA" "$alarme_hr" "$diaN"`;
					echo -ne "DADOS ATUALIZADOS NO SQL $oltNome $placa_IF $portStats $msgStats\n";
					fi
				fi
				
			fi
			done &
		echo -ne "\n";
		dia2=`date +'%d-%m-%Y %H:%M:%S'`;
	echo -ne "\n";
	echo -ne "Concluido: $oltNome - $olt - $oltModel em $dia2 \n\n";



	elif [ $oltModel = 'ZTE' ]; then
		dia1=`date +'%d-%m-%Y %H:%M:%S'`;
		echo -ne "$oltNome - $olt - $oltModel em $dia1 \n\n";
		oltID=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
		"select id_olt from $sqlTable where oltIp = '$olt'" $sqlBase);
		placas_id=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
		"select oltIdPort from tb_olt_ports where oltSfpSn NOT LIKE '%SEM SFP%' and id_olt = '$oltID'" $sqlBase)
			for placa in ${placas_id[@]}; do
			sfpSnBD=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
			"select oltSfpSn from $sqlTableP where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase)
			stat_alarme=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
			"select oltPortStats from $sqlTableP where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase)
			if [ $stat_alarme == "NULL" ];then
			sfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.13.$placa 2> /dev/null | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
				if [ -z $sfpSn ] || [ "$sfpSn" == *"Timeout"* ]; then
					sleep 2
					sfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.13.$placa 2> /dev/null | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
						if [ -z $sfpSn ] || [ "$sfpSn" == *"Timeout"* ]; then
						sleep 2
						sfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.13.$placa 2> /dev/null | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
							if [ -z $sfpSn ] || [ "$sfpSn" == *"Timeout"* ]; then
							sfpSn="SEM SFP";
							fi
						fi
				elif [ ! -z $sfpSn ]; then
				:
				fi
			placa_nome=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
			"select oltNomePort from $sqlTableP where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase)
			placa_IF=`echo $placa_nome | sed 's/_/ /g'`;
					if [ "$sfpSnBD" == "$sfpSn" ]; then
					Status="IGUAIS";
					elif [ "$sfpSnBD" != "$sfpSn" ]; then
					Status="DIFERENTES";
					sql_msg=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
					"select oltMsgStats from $sqlTableP where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase)
						if [ "$sql_msg" == "ENVIADA" ]; then
						notificacao="NADA FEITO";
						elif [ "$sql_msg" == "NULL" ]; then
						echo -ne "ENVIAR MSG VIA TELEGRAMA";
						notificacao="ENVIADO MSG";
						portStats="ALARMADO";
						msgStats="ENVIADA";
						diaN=`date +'%d-%m-%Y %H:%M:%S'`;
						insere_alarme=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e  \
						"update $sqlTableP set oltPortStats = '$portStats', oltMsgStats = '$msgStats', oltPortUpdate = '$diaN' where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase);
						echo -ne "DADOS ATUALIZADOS NO SQL $oltNome $placa_IF $portStats $msgStats\n";
						envia_MSG=`./stats_NOK.sh $oltNome $olt "$oltModel - FALHA SFP MONITOR" "SFP: $sfpSnBD $placa_IF - REMOVIDA" "$diaN"`;
						fi
					echo -ne "$placa_IF SFP na base: $sfpSnBD SFP na porta: $sfpSn  SFP Status: [ $Status ] MSG Stat: [ $notificacao ]\n";
					fi
			#echo -ne "$placa_IF SFP na base: $sfpSnBD SFP na porta: $sfpSn  SFP Status: [ $Status ]\n";
			elif [ "$stat_alarme" == "ALARMADO" ]; then
			sfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.13.$placa 2> /dev/null | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
				if [ -z $sfpSn ] || [ "$sfpSn" == *"Timeout"* ]; then
				sleep 2
				sfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.13.$placa 2> /dev/null | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
					if [ -z $sfpSn ] || [ "$sfpSn" == *"Timeout"* ]; then
					sleep 2
					sfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.13.$placa 2> /dev/null | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
						if [ -z $sfpSn ] || [ "$sfpSn" == *"Timeout"* ]; then
						sfpSn="SEM SFP";
						fi
					fi
				elif [ ! -z $sfpSn ]; then
					if [ "$sfpSnBD" == "$sfpSn" ]; then
					portStats="NULL";
					msgStats="NULL";
					diaN=`date +'%d-%m-%Y %H:%M:%S'`;
					alarme_hr=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
					"select oltPortUpdate from $sqlTableP where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase);
					insere_alarme=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e  \
					"update $sqlTableP set oltPortStats = NULL, oltMsgStats = NULL, oltPortUpdate = '$diaN' where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase);
					envia_MSG=`./stats_OK.sh $oltNome $olt "$oltModel - NORMALIZADA" "SFP: $sfpSn $placa_IF - INSERIDA" "$alarme_hr" "$diaN"`;
					echo -ne "DADOS ATUALIZADOS NO SQL $oltNome $placa_IF $portStats $msgStats\n";
					fi
				fi
				
			fi
			done &
		echo -ne "\n";
		dia2=`date +'%d-%m-%Y %H:%M:%S'`;
	echo -ne "\n";
	echo -ne "Concluido: $oltNome - $olt - $oltModel em $dia2 \n\n";



	fi
echo -ne "\n\n";
done

dia=`date +'%d-%m-%Y %H:%M:%S'`;

echo -ne "\n\n\n SYS ENDED at $dia \n\n";

