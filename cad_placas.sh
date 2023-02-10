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

sqlHost="192.168.10.20";
sqlUser="usuario";
sqlPass="senha";
sqlBase="db_olt";
sqlTable="tb_olt_cad";
sqlTableP="tb_olt_ports";


com="public0";


#########################
# Variaveis do sistema ##
#########################

    listOlt="olt.list";
    snmpwalk="snmpwalk -v2c -c public0";
    snmpget="snmpget -Ovq -v2c -c";


########################
# SNMP LISTA           #
########################


    huaweiONUon="1.3.6.1.4.1.2011.6.128.1.1.2.51.1.4";
    zteONUon="1.3.6.1.4.1.3902.1082.500.10.2.3.8.1.4";
    oltNome="1.3.6.1.2.1.1.5.0";
    oltVendor="1.3.6.1.2.1.1.1.0";



SFPVendorName="1.3.6.1.4.1.2011.6.128.1.1.2.22.1.11";
SFPVendorPN="1.3.6.1.4.1.2011.6.128.1.1.2.22.1.13";
SFPVendorSN="1.3.6.1.4.1.2011.6.128.1.1.2.22.1.20";


#########################
# Inicio do SYS #########
#########################

dia=`date +'%d-%m-%Y %H:%M'`;

echo -ne "SYS STARTED at $dia \n\n\n";

#list=`cat $listOlt | grep -v '#' | awk '-F;' '{print $1}'`;

list=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
"select oltIp from $sqlTable" $sqlBase)



for olt in ${list[@]}; do


dia=`date +'%d-%m-%Y %H:%M'`;

#oltIp=`cat $listOlt | grep -w $olt | awk '-F;' '{print $1}'`;
#oltNome=`cat $listOlt | grep -w $olt | awk '-F;' '{print $3}'`;
#oltModel=`cat $listOlt | grep -w $olt | awk '-F;' '{print $2}'`;
oltNome=`$snmpget $com $olt $oltNome 2> /dev/null | sed 's/"//g'`;
oltModel=`$snmpget $com $olt $oltVendor | sed 's/Integrated Access Software//g' | sed 's/ZXA10//g' | sed 's/,//g' | sed 's/"//g' | sed 's/Software Version: V1.2.3//g' | sed 's/C600//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' `;



    if [ $oltModel = 'Huawei' ]; then
    #oltSoma=`$snmpwalk $oltIp $huaweiONUon 2> /dev/null | grep -v 'No Such Instance currently exists at this OID' |awk '{print $NF}' |  grep -v 2147483647 | wc -l`;
    #	    if [ -z $oltSoma ]; then
    #	    oltSoma="SEM COLETA";
    #	    fi
    echo -ne "$oltNome - $oltIp - $oltModel \n\n";
    #placas_olt=`snmpwalk -v2c -c public0 -Onq $olt 1.3.6.1.2.1.2.2.1.2 | grep 'UNI' | sed 's/.1.3.6.1.2.1.2.2.1.2.//g' | sed 's/Huawei-MA5800-V100R020-//g' | awk '{print $2,$3}'`;
    oltID=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
    "select id_olt from $sqlTable where oltIp = '$olt'" $sqlBase)
    placas_id=`snmpwalk -v2c -c public0 -Onq $olt 1.3.6.1.2.1.2.2.1.2 | grep 'UNI' | sed 's/.1.3.6.1.2.1.2.2.1.2.//g' | sed 's/Huawei-MA5800-V100R020-//g' | awk '{print $1}'`;
	for placa in ${placas_id[@]}; do
	placa_nome=`snmpwalk -v2c -c public0 -Onq $olt 1.3.6.1.2.1.2.2.1.2.$placa | grep 'UNI' | sed 's/.1.3.6.1.2.1.2.2.1.2.//g' | sed 's/Huawei-MA5800-V100R020-//g' | awk '{print $2,$3}' | sed 's/"//g'`;
	placa_soma=`snmpwalk -v2c -c public0 $olt iso.3.6.1.4.1.2011.6.128.1.1.2.43.1.9.$placa 2> /dev/null | grep -v 'No Such Instance currently exists at this OID' | wc -l`;
	placaSfpName=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.11.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
		if [[ -z $placaSfpName ]]; then
		sleep 2
		placaSfpName=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.11.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
			if [[ -z $placaSfpName ]]; then
			sleep 2
			placaSfpName=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.11.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
				if [[ -z $placaSfpName ]]; then
				placaSfpName="SEM SFP";
				fi
			fi
		fi
	placaSfpPn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.13.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
		if [[ -z $placaSfpPn ]]; then
		sleep 2
		placaSfpPn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.13.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
			if [[ -z $placaSfpPn ]]; then
			sleep 2
			placaSfpPn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.13.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
				if [[ -z $placaSfpPn ]]; then
				placaSfpPn="SEM SFP";
				fi
			fi
		fi
	placaSfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.20.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
		if [[ -z $placaSfpSn ]]; then
		sleep 2
		placaSfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.20.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
			if [[ -z $placaSfpSn ]]; then
			sleep 2
			placaSfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.20.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
				if [[ -z $placaSfpSn ]]; then
				placaSfpSn="SEM SFP";
				fi
			fi
		fi
		if [[ -z $placaSfpName ]] && [[ -z $placaSfpPn ]] && [[ -z $placaSfpSn ]]; then
		placaSfpName="SEM SFP";
		placaSfpPn="SEM SFP";
		placaSfpSn="SEM SFP";
		fi
	placa_desc="NO DESC";
	echo -ne "id:$placa if:$placa_nome soma: $placa_soma \n";
	insere_sql=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
	"insert into $sqlTableP set oltIdPort = '$placa', oltDescPort = '$placa_desc', oltNomePort = '$placa_nome', oltSfpNam = '$placaSfpName' , oltSfpPn = '$placaSfpPn', oltSfpSn = '$placaSfpSn', oltPorSoma = '$placa_soma', id_olt = '$oltID'" $sqlBase)
	done &
    echo -ne "\n\n";

    elif [ $oltModel = 'ZTE' ]; then
    #oltSoma=`$snmpwalk $oltIp $zteONUon 2> /dev/null | wc -l`;
    #	    if [ -z $oltSoma ]; then
    #	    oltSoma="SEM COLETA";
    #	    fi
    echo -ne "$oltNome - $oltIp - $oltModel \n" ;
    oltID=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
    "select id_olt from $sqlTable where oltIp = '$olt'" $sqlBase)
    placas_id=`snmpwalk -v2c -c public0 -Onq $olt 1.3.6.1.2.1.2.2.1.2 | grep -v 'xgei' | egrep -v '285280770|285280771|285280772|285281026|285281027|285281028' | sed 's/.1.3.6.1.2.1.2.2.1.2.//g' | sed 's/ZTE-C600-V1.2.3-//g' | sed 's/"//g' | awk '{print $1}'`;
	for placa in ${placas_id[@]}; do
	placa_desc=`snmpwalk -v2c -c public0 -Onq $olt 1.3.6.1.2.1.2.2.1.2.$placa | grep -v 'xgei' | sed 's/.1.3.6.1.2.1.2.2.1.2.//g' | sed 's/ZTE-C600-V1.2.3-//g' | sed 's/"//g' | awk '{print $2}'`;
	placa_nome=`cat /dados/gpon/zteBoard.txt | grep -w $placa | awk '-F;' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
	placa_soma=`snmpwalk -v2c -c public0 -Onq $olt 1.3.6.1.4.1.3902.1082.500.10.2.3.8.1.5.$placa 2> /dev/null | grep -v 'No Such Instance currently exists at this OID' | wc -l`;
	placaSfpName=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.12.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
		if [[ -z $placaSfpName ]]; then
		sleep 2
		placaSfpName=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.12.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
			if [[ -z $placaSfpName ]]; then
			sleep 2
			placaSfpName=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.12.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
				if [[ -z $placaSfpName ]]; then
				placaSfpName="SEM SFP";
				fi
			fi
		fi
	placaSfpPn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.11.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
		if [[ -z $placaSfpPn ]]; then
		sleep 2
		placaSfpPn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.11.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
			if [[ -z $placaSfpPn ]]; then
			sleep 2
			placaSfpPn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.11.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
				if [[ -z $placaSfpPn ]]; then
				placaSfpPn="SEM SFP";
				fi
			fi
		fi
	placaSfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.13.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
		if [[ -z $placaSfpSn ]]; then
		sleep 2
		placaSfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.13.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
			if [[ -z $placaSfpSn ]]; then
			sleep 2
			placaSfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.13.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
				if [[ -z $placaSfpSn ]]; then
				placaSfpSn="SEM SFP";
				fi
			fi
		fi
		if [[ -z $placaSfpName ]] && [[ -z $placaSfpPn ]] && [[ -z $placaSfpSn ]]; then
		placaSfpName="SEM SFP";
		placaSfpPn="SEM SFP";
		placaSfpSn="SEM SFP";
		fi
	    if [ -z $placa_desc ]; then
	    placa_desc="NO DESC";
	    elif [ "$placa_desc" = "$placa_nome" ]; then
	    placa_desc="NO DESC";
	    fi
	echo -ne "id:$placa if:$placa_nome [$placa_desc] soma: $placa_soma \n";
	insere_sql=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
	"insert into $sqlTableP set oltIdPort = '$placa', oltDescPort = '$placa_desc', oltNomePort = '$placa_nome', oltSfpNam = '$placaSfpName' , oltSfpPn = '$placaSfpPn', oltSfpSn = '$placaSfpSn', oltPorSoma = '$placa_soma', id_olt = '$oltID'" $sqlBase)
	done &
    #insere_sql=$(mysql -sN -h $sqlHost -u $sqlUser -p$sqlPass -e \
    #"update $sqlTable set oltSoma = '$oltSoma' where ip = '$oltIp'" $sqlBase)
    echo -ne "\n\n";


    fi


done

dia=`date +'%d-%m-%Y %H:%M'`;

echo -ne "\n\n\n SYS ENDED at $dia \n\n";
