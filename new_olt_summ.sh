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
    snmpwalk="snmpwalk -v2c -c paranoia";
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

#list=`cat $listOlt | grep -v '#' | awk '-F;' '{print $1}'`;

list=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
"select oltIp from $sqlTable" $sqlBase)



for olt in ${list[@]}; do

#oltIp=`cat $listOlt | grep -w $olt | awk '-F;' '{print $1}'`;
#oltNome=`cat $listOlt | grep -w $olt | awk '-F;' '{print $3}'`;
#oltModel=`cat $listOlt | grep -w $olt | awk '-F;' '{print $2}'`;
oltNome=`$snmpget $com $olt $oltName 2> /dev/null | sed 's/"//g'`;
oltModel=`$snmpget $com $olt $oltVendor | sed 's/Integrated Access Software//g' | sed 's/ZXA10//g' | sed 's/,//g' | sed 's/"//g' | sed 's/Software Version: V1.2.3//g' | sed 's/C600//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' `;

if [[ -z $oltNome ]] && [[ -z $oltModel ]]; then

oltStatus="OFFLINE";

oltinfostatus=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
"update $sqlTable set oltStatus = '$oltStatus' where oltIp = '$olt'" $sqlBase)

else

oltStatus="ONLINE";

oltinfostatus=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
"update $sqlTable set oltStatus = '$oltStatus' where oltIp = '$olt'" $sqlBase)



    if [ $oltModel = 'Huawei' ]; then
    #oltSoma=`$snmpwalk $oltIp $huaweiONUon 2> /dev/null | grep -v 'No Such Instance currently exists at this OID' |awk '{print $NF}' |  grep -v 2147483647 | wc -l`;
    #	    if [ -z $oltSoma ]; then
    #	    oltSoma="SEM COLETA";
    #	    fi
    dia1=`date +'%d-%m-%Y %H:%M:%S'`;
    echo -ne "$oltNome - $olt - $oltModel em $dia1 \n\n";
    #placas_olt=`snmpwalk -v2c -c public0 -Onq $olt 1.3.6.1.2.1.2.2.1.2 | grep 'UNI' | sed 's/.1.3.6.1.2.1.2.2.1.2.//g' | sed 's/Huawei-MA5800-V100R020-//g' | awk '{print $2,$3}'`;
    oltID=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e\
    "select id_olt from $sqlTable where oltIp = '$olt'" $sqlBase)
    placas_id=`snmpwalk -v2c -c public0 -Onq $olt 1.3.6.1.2.1.2.2.1.2 | grep 'UNI' | sed 's/.1.3.6.1.2.1.2.2.1.2.//g' | sed 's/Huawei-MA5800-V100R020-//g' | awk '{print $1}'`;
	for placa in ${placas_id[@]}; do
	placa_nome=`snmpwalk -v2c -c public0 -Onq $olt 1.3.6.1.2.1.2.2.1.2.$placa | grep 'UNI' | sed 's/.1.3.6.1.2.1.2.2.1.2.//g' | sed 's/Huawei-MA5800-V100R020-//g' | awk '{print $2,$3}' | sed 's/"//g'`;
	placa_soma=`snmpwalk -v2c -c public0 $olt 1.3.6.1.4.1.2011.6.128.1.1.2.51.1.5.$placa 2> /dev/null | grep -v 'No Such Instance currently exists at this OID' | grep -v 2147483647 | wc -l`;
	placa_reg=`snmpwalk -v2c -c public0 $olt iso.3.6.1.4.1.2011.6.128.1.1.2.43.1.9.$placa 2> /dev/null | grep -v 'No Such Instance currently exists at this OID' | wc -l`;
	percentual=`echo "scale=2; $placa_soma * 100 / $placa_reg" 2> /dev/null | bc -l`;
		if [ ! "$percentual" ]; then
		percentual="0";
		fi
		percent=`printf "%.0f" $percentual 2> /dev/null`;
		if [ "$percent" -gt "100" ]; then
		percent="100";
		fi

	#placaSfpName=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.11.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
	#	if [ -z $placaSfpName ]; then
	#		placaSfpName="SEM SFP";
	#	fi
	#placaSfpPn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.13.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
	#	if [ -z $placaSfpPn ]; then
	#		placaSfpPn="SEM SFP";
	#	fi
	#placaSfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.2011.6.128.1.1.2.22.1.20.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
	#	if [ -z $placaSfpSn ]; then
	#		placaSfpSn="SEM SFP";
	#	fi
	placa_desc=`snmpwalk -v2c -c public0 -Onq $olt iso.3.6.1.4.1.2011.6.128.1.1.2.21.1.6.$placa | grep -v 'xgei' | sed 's/.1.3.6.1.2.1.2.2.1.2.//g' | sed 's/ZTE-C600-V1.2.3-//g' | sed 's/"//g' | awk '{print $2}'`;
	    if [ -z $placa_desc ]; then
	    placa_desc="NO DESC";
	    fi
	diaP=`date +'%d-%m-%Y %H:%M:%S'`;
	alarmeStats=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
	"select oltPortStats from $sqlTableP where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase)
	if [ $alarmeStats == "ALARMADO" ]; then
	:
	elif [ $alarmeStats != "ALARMARDO" ]; then
	echo -ne "id:$placa if:$placa_nome [$placa_desc] soma: $placa_soma \n";
	insere_sql=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
	"update $sqlTableP set oltDescPort = '$placa_desc', oltNomePort = '$placa_nome', oltPorSoma = '$placa_soma', oltRegPor = '$placa_reg', oltPercPor = '$percent', oltPortUpdate = '$diaP' where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase)
	fi
	done &
    echo -ne "\n\n";
    dia2=`date +'%d-%m-%Y %H:%M:%S'`;
    echo -ne "Concludo: $oltNome - $olt - $oltModel em $dia2 \n\n";


    elif [ $oltModel = 'ZTE' ]; then
    #oltSoma=`$snmpwalk $oltIp $zteONUon 2> /dev/null | wc -l`;
    #	    if [ -z $oltSoma ]; then
    #	    oltSoma="SEM COLETA";
    #	    fi
    dia1=`date +'%d-%m-%Y %H:%M:%S'`;
    echo -ne "$oltNome - $olt - $oltModel em $dia1 \n\n" ;
    oltID=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
    "select id_olt from $sqlTable where oltIp = '$olt'" $sqlBase)
    placas_id=`snmpwalk -v2c -c public0 -Onq $olt 1.3.6.1.2.1.2.2.1.2 | grep -v 'xgei' | egrep -v '285280770|285280771|285280772|285281026|285281027|285281028' | sed 's/.1.3.6.1.2.1.2.2.1.2.//g' | sed 's/ZTE-C600-V1.2.3-//g' | sed 's/"//g' | awk '{print $1}'`;
	for placa in ${placas_id[@]}; do
	placa_desc=`snmpwalk -v2c -c public0 -Onq $olt 1.3.6.1.2.1.2.2.1.2.$placa | grep -v 'xgei' | sed 's/.1.3.6.1.2.1.2.2.1.2.//g' | sed 's/ZTE-C600-V1.2.3-//g' | sed 's/"//g' | awk '{print $2}'`;
	placa_nome=`cat /dados/gpon/zteBoard.txt | grep -w $placa | awk '-F;' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
	    if [ -z $placa_desc ]; then
	    placa_desc="NO DESC";
	    elif [ "$placa_desc" = "$placa_nome" ]; then
	    placa_desc="NO DESC";
	    fi
	placa_soma=`snmpwalk -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.500.10.2.3.8.1.3.$placa 2> /dev/null | grep -v 'No Such Instance currently exists at this OID' | grep -v 1 | wc -l`;
	placa_reg=`snmpwalk -v2c -c public0 -Onq $olt 1.3.6.1.4.1.3902.1082.500.10.2.3.8.1.5.$placa 2> /dev/null | grep -v 'No Such Instance currently exists at this OID' | wc -l`;
	percentual=`echo "scale=2; $placa_soma * 100 / $placa_reg" 2> /dev/null | bc -l`;
		if [ ! "$percentual" ]; then
		percentual="0";
		fi
		percent=`printf "%.0f" $percentual 2> /dev/null`;
		if [ "$percent" -gt "100" ]; then
		percent="100";
		fi
	#placaSfpName=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.12.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
	#	if [ -z "$placaSfpName" ]; then
	#		placaSfpName="SEM SFP";
	#	fi
	#placaSfpPn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.11.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
	#	if [ -z "$placaSfpPn" ]; then
	#		placaSfpPn="SEM SFP";
	#	fi
	#placaSfpSn=`snmpget -v2c -c public0 -Osqv $olt 1.3.6.1.4.1.3902.1082.30.40.2.4.1.13.$placa | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
	#	if [ -z "$placaSfpSn" ]; then
	#		placaSfpSn="SEM SFP";
	#	fi
	diaP=`date +'%d-%m-%Y %H:%M:%S'`;
	alarmeStats=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
	"select oltPortStats from $sqlTableP where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase)
	if [ $alarmeStats == "ALARMADO" ]; then
	:
	elif [ $alarmeStats != "ALARMARDO" ]; then
	echo -ne "id:$placa if:$placa_nome soma: $placa_soma \n";
	insere_sql=$(mysql --defaults-extra-file=/dados/gpon/acesso.cnf -N -e \
	"update $sqlTableP set oltDescPort = '$placa_desc', oltNomePort = '$placa_nome', oltPorSoma = '$placa_soma', oltRegPor = '$placa_reg', oltPercPor = '$percent', oltPortUpdate = '$diaP' where id_olt = '$oltID' and oltIdPort = '$placa'" $sqlBase);
	fi
	done &
    #insere_sql=$(mysql -sN -h $sqlHost -u $sqlUser -p$sqlPass -e \
    #"update $sqlTable set oltSoma = '$oltSoma' where ip = '$oltIp'" $sqlBase)
    echo -ne "\n\n";
    dia2=`date +'%d-%m-%Y %H:%M:%S'`;
    echo -ne "Concludo: $oltNome - $olt - $oltModel em $dia2 \n\n";


    fi

fi

done

dia=`date +'%d-%m-%Y %H:%M:%S'`;

echo -ne "\n\n\n SYS ENDED at $dia \n\n";
