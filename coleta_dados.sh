#!/bin/bash

#######################################################################
# coleta_dados - Cable docsis data collection                         #
#                                                                     #
# Script GPL - Desenvolvido por Jamil W.                              #
# Favor manter os direitos e adicionar alterações                     #
# xx/xx/2020                                                          #
# usage: ./coleta_dados.sh xxxx.xxxx.xxxx CITY1 <exemplo>             #
#                                                                     #
# 1. Upstream info (quantity and frequencies)                         #
# 2. Downstream info (quantity and frequencies)                       #
# 3. Up and down bounding                                             #
# 4. SNR, RX, TX infos                                                #
# 5. CPE IP, CABLE IP INFO, VENDOR, MODEL, VERSION                    #
#                                                                     #
#######################################################################

### DEfinições do sistema


b=$1;
base=$2;

#OID TESTES NOVOS

OIDFreqU="1.3.6.1.2.1.10.127.1.1.2.1.2";
OIDFreqD="1.3.6.1.2.1.10.127.1.1.1.1.2";
OIDUpstream="1.3.6.1.2.1.31.1.1.1.1";
OIDOfdmCanal="1.3.6.1.4.1.4491.2.1.28.1.9.1.1";
OIDOfdmRxMer="1.3.6.1.4.1.4491.2.1.20.1.24.1.1";
OIDOfdmFreq="1.3.6.1.4.1.4491.2.1.28.1.11.1.2";
OID_CPE="1.3.6.1.2.1.4.22.1.3";
OID_IP="1.3.6.1.4.1.20858.10.12.1.3.1.3";
OID_MAC="1.3.6.1.2.1.17.4.3.1.1";

# Biblioteca de OIDs

OID_NODE="1.3.6.1.2.1.31.1.1.1.18";
OID_CMTS_NOME="1.3.6.1.2.1.1.5.0";
OID_MAC_CABLE="1.3.6.1.2.1.4.22.1.2";
OID_ID_MAC="1.3.6.1.2.1.10.127.1.3.7.1.2";
OID_CON_MAC="1.3.6.1.2.1.10.127.1.3.3.1.3";
OID_UPTIME="1.3.6.1.2.1.1.3.0";
OID_MODELO="1.3.6.1.2.1.1.1.0";
#OID_MAC="1.3.6.1.2.1.2.2.1.6.2";
OID_TX="1.3.6.1.2.1.10.127.1.2.2.1.3.2";
OID_RX="1.3.6.1.2.1.10.127.1.1.1.1.6.3";
OID_SNR="1.3.6.1.2.1.10.127.1.1.4.1.5.3";
OID_SNR_U="1.3.6.1.2.1.10.127.1.1.4.1.5";
OID_CPE="1.3.6.1.2.1.4.20.1.1";
OID_DOWN_F="1.3.6.1.2.1.10.127.1.1.1.1.2";
OID_DOWN_S="1.3.6.1.2.1.10.127.1.1.1.1.6";
OID_UP_F="1.3.6.1.2.1.10.127.1.1.2.1.2";
OID_FEC="1.3.6.1.2.1.10.127.1.1.4.1";
OID_UP_INDEX="1.3.6.1.4.1.4491.2.1.20.1.4.1.2";
oid_up_phy="1.3.6.1.2.1.2.2.1.2";
OID_IP_OLD="1.3.6.1.2.1.10.127.1.3.3.1.3";
OID_VERSION='1.3.6.1.2.1.69.1.3.5.0';
CPE_ARRIS='1.3.6.1.4.1.4998.1.1.20.2.7.1.2';

# Variaveis do sistema

data=`date`;
comunidade="public";
cmts="cmts.list"; # LISTA DE CMTS COMPOSTA COM ipcmts;vendor;nomecmts
dfs="dfs.list"; # LISTA DE DFS COMPOSTA COM dfs;pacotenominal

# Tratativa dos dados para consulta


if [ "$base" == "CITY1" ]; then
cmtsIp=`cat $cmts | grep 'CMT' | grep 'CITY1' | grep -v '#' | awk -F';' '{print $1}'`;
ldapBase="dc=xxx_docsis";
ldapSrv="10.10.1.10";
elif [ "$base" == "CITY2" ]; then
cmtsIp=`cat $cmts | grep 'CMT' | grep -v 'CITY2' | grep -v '#' | awk -F';' '{print $1}'`;
ldapBase="dc=yyy_docsis";
ldapSrv="10.10.2.20";
elif [ "$base" == "" ]; then
:
fi


lista_version(){


if [ -z "$b" ]; then

echo -e "SYS:: \e[1;31mSEM DADOS PARA CONSULTA FAVOR VERIFICAR A DIGITAÇÃO\e[0m";
exit

elif [ -z "$base" ]; then

echo -e "SYS:: \e[1;31mSEM DADOS PARA CONSULTA FAVOR VERIFICAR A DIGITAÇÃO\e[0m";
exit

else

echo -e "SYS:: Consulta iniciada\e[0m \e[1;32m$b OK \e[0m \e[1;34m$base OK\e[0m [$data]";
echo "";

fi

b=`echo $b | sed 's/://g'`;
b=`echo $b | sed 's/\.//g'`;
b=`echo ${b:0:2}:${b:2:2}:${b:4:2}:${b:6:2}:${b:8:2}:${b:10:2}`;


# Variaveis para tratativa do MAC

C_1=`echo ${b} | tr 'a-z' 'A-Z'| awk -F: '{print $1}'`;
C_2=`echo ${b} | tr 'a-z' 'A-Z'| awk -F: '{print $2}'`;
C_3=`echo ${b} | tr 'a-z' 'A-Z'| awk -F: '{print $3}'`;
C_4=`echo ${b} | tr 'a-z' 'A-Z'| awk -F: '{print $4}'`;
C_5=`echo ${b} | tr 'a-z' 'A-Z'| awk -F: '{print $5}'`;
C_6=`echo ${b} | tr 'a-z' 'A-Z'| awk -F: '{print $6}'`;

# Convertendo o MAC para decimal para montar a consulta

mac_1=`echo "ibase=16; $C_1" | bc`;
mac_2=`echo "ibase=16; $C_2" | bc`;
mac_3=`echo "ibase=16; $C_3" | bc`;
mac_4=`echo "ibase=16; $C_4" | bc`;
mac_5=`echo "ibase=16; $C_5" | bc`;
mac_6=`echo "ibase=16; $C_6" | bc`;


for c in ${cmtsIp[@]}; do

cmtsVendor=`cat $cmts | grep -w $c | awk -F';' '{print $2}'`;
cmtsNome=`cat $cmts | grep -w $c | awk -F';' '{print $3}'`;
cmtsCidade=`cat $cmts | grep -w $c | awk -F';' '{print $5}'`;


COM=`cat $cmts | grep -w $c | awk -F';' '{print $4}'`;

    if [ "$cmtsVendor" == "Casa BDM" ]; then
    cableID=`snmpget -v2c -c $COM -Osqv ${c} $OID_ID_MAC.$mac_1.$mac_2.$mac_3.$mac_4.$mac_5.$mac_6 2>/dev/null | sed 's/No Such Instance currently exists at this OID//g'`;
    else
    cableID=`snmpget -c $COM -v 1 -Osqv ${c} $OID_ID_MAC.$mac_1.$mac_2.$mac_3.$mac_4.$mac_5.$mac_6 2>/dev/null`;
    fi
    if [ -n "$cableID" ]; then

# CONSULTA NO CMTS VENDOR ARRIS E6000
if [ "$cmtsVendor" == "Arris E6000" ]; then
data=`date`;
echo -e "SYS:: Localizado \e[1;32m$cmtsNome $c \e[0m[$data]";
echo "";
    cableIP=`snmpget -v2c -c $COM -Osqv ${c} $OID_CON_MAC.$cableID 2>/dev/null`;
    indexUP=`snmpwalk -v2c -c $COM ${c} $OID_UP_INDEX.$cableID 2> /dev/null | sed -e 's/'$OID_UP_INDEX'//g' | sed -e 's/'.$cableID'//g' | sed -e 's/ = INTEGER: 2//g' | sed -e 's/SNMPv2-SMI::enterprises.4491.2.1.20.1.4.1.2.//g' | head -n 1`;
    node=`snmpget -v2c -c $COM  -Osqv ${c} $OID_NODE.$indexUP 2> /dev/null | sed -e 's/"//g'`;
    upstream=`snmpget -v2c -c $COM  -Osqv ${c} $OIDUpstream.$indexUP 2> /dev/null | sed -e 's/"//g'`;
	if [ -z "$upstream" ]; then
	data=`date`;
	echo -e "SYS:: \e[1;31m$b esteve ONLINE em $cmtsNome está OFFLINE agora!\e[0m";
	echo "";
	echo -e "SYS:: \e[1;32mConcluido OK\e[0m [$data]";
	break
	fi
    cableContrato=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'contrato' | sed 's/docsiscontrato: //g'`;
    cablePolicy=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'policy' | sed 's/docsispolicyname: //g'`;
    nominalV=`cat "$dfs" | grep -w "$cablePolicy" | awk -F';' '{print $2}'`;
    cableClientClass=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'clientclass' | sed 's/docsisclientclass: //g'`;
    cableModel=`snmpget -v2c -c public $cableIP $OID_MODELO 2> /dev/null | awk -F ':' '{print $NF}' | sed 's/>>//g' | sed -e 's/ //g'`;
    cableVer=`snmpget -v2c -c public $cableIP $OID_VERSION 2> /dev/null | awk -F ':' '{print $NF}' | sed 's/>>//g' | sed -e 's/ //g'`;
#    cableCpe=`snmpwalk -v2c -c public -Osqv $cableIP $OID_CPE 2> /dev/null | egrep -v '0.1$|^192.|^172.|^.1$|0.0.0.0' | grep -v "$cableIP"`;
#    cableCpe=`snmpwalk -v2c -c public -Osq $cableIP 1.3.6.1.2.1.4.35.1.4 2> /dev/null | sed 's/ipNetToPhysicalPhysAddress.//g' | awk -F'"' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' `;
    dadosCpe=`snmpwalk -v2c -c public -Osqv $c $CPE_ARRIS.$mac_1.$mac_2.$mac_3.$mac_4.$mac_5.$mac_6 2> /dev/null | egrep -v 'FE 80|28 04' | sed 's/"//g' | sed 's/ /./g'`;
#    dadosCpe=`cat dados.txt | sed 's/ /./g'`;
    if [ "${dadosCpe[*]}" > "1" ]; then
    for cpe in ${dadosCpe[@]}; do

    # Variaveis para tratativa do MAC

    C_1=`echo $cpe | awk '-F.' '{print $1}'`;
    C_2=`echo $cpe | awk '-F.' '{print $2}'`;
    C_3=`echo $cpe | awk '-F.' '{print $3}'`;
    C_4=`echo $cpe | awk '-F.' '{print $4}'`;

    # Convertendo o MAC para decimal para montar a consulta

    mac_1=`echo "ibase=16; $C_1" | bc`;
    mac_2=`echo "ibase=16; $C_2" | bc`;
    mac_3=`echo "ibase=16; $C_3" | bc`;
    mac_4=`echo "ibase=16; $C_4" | bc`;

    novoCpe=`echo $mac_1.$mac_2.$mac_3.$mac_4`;
    cpeip=(${cpeip[@]} `echo "$novoCpe"`);
#    echo "${cpe}";
    done
    fi
    cableTx=`snmpget -v2c -c public $cableIP $OID_TX 2> /dev/null | awk {'print $4'} `;
    cableRx=`snmpget -v2c -c public $cableIP $OID_RX 2> /dev/null | awk {'print $4'} `;
    cableSnr=`snmpget -v2c -c public $cableIP $OID_SNR 2> /dev/null | awk {'print $4'} `;
    cableFreqD=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | cut -d ' ' -f 1 | sed 's/000000//g' | grep -v -w '0'`;
    cableFreqU=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null `;
    cableSomaU=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null | wc -l`;
    cableSomaD=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | wc -l`;
    ofdmaActive=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null | grep -w '0' | sed 's/hertz//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
    ofdmActive=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | grep -w '0' | sed 's/hertz//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
        if [ "$ofdmActive" != "" ]; then
        ofdmCanal=`snmpwalk -v2c -c public $cableIP $OIDOfdmCanal 2> /dev/null | sed 's/SNMPv2-SMI::enterprises.4491.2.1.28.1.9.1.1.//g' | awk '{print $1}'`;
        ofdmRxMer=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmRxMer.$ofdmCanal 2> /dev/null | sed 's/No Such Instance currently exists at this OID//g'`;
        ofdmSlice=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmFreq.$ofdmCanal 2> /dev/null | wc -l`;
        fi
    if [ "$ofdmRxMer" == "" ]; then
    ofdmRxMer=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmRxMer 2> /dev/null | sed 's/No Such Instance currently exists at this OID//g' | tail -1`;
    fi
dia=`date +'%d-%m-%Y %H:%M'`;
data=`date`;
echo "+-------------------------------------------------------------+";
echo "| Mac: "$b" IP: $cableIP ";
echo "| Modelo: $cableModel Versão: $cableVer";
echo "| CMTS: $cmtsNome ($c) node: $node base: $base";
echo "| Ctto: $cableContrato ";
echo "| Perfil: $cablePolicy ";
echo "| Velocidade Nominal: $nominalV";
echo "| ClientClass: $cableClientClass" ;
if [ "${cpeip[*]}" > "1" ]; then
for cpe in ${cpeip[@]}; do
echo "| CPE: $cpe"; done
elif [ "${cpeip[*]}" == "1" ]; then
echo "| CPE: $cpeip "; fi
echo "| Up: $upstream ";
if [ "$ofdmaActive" == "0" ]; then
echo "| OFDMA: Ativo";
fi
echo "| TX:$cableTx RX:$cableRx SNR:$cableSnr ";
echo "| Bonding: $cableSomaD X $cableSomaU";
for down in ${cableFreqD[@]}; do
echo "| Down: ${down} Mhz"; done
if [ "$ofdmActive" == "0" ]; then
echo "| OFDM: Ativo";
echo "| Canal: $ofdmCanal ";
echo "| RxMer: $ofdmRxMer ";
echo "| OFDM 6MHz Slices: $ofdmSlice ";

fi
echo "|_____________________________________________________________+";
echo "";
echo -e "SYS:: \e[1;32mConcluido OK \e[0m [$data]";
echo "";
break

# CONSULTA NO CMTS VENDOR ARRIS C4
elif [ "$cmtsVendor" == "Arris C4" ]; then
data=`date`;
echo -e "SYS:: Localizado \e[1;32m$cmtsNome $c \e[0m[$data]";
echo "";
    cableIP=`snmpget -v2c -c $COM -Osqv ${c} $OID_CON_MAC.$cableID 2>/dev/null`;
    indexUP=`snmpwalk -v2c -c $COM ${c} $OID_UP_INDEX.$cableID 2> /dev/null | sed -e 's/'$OID_UP_INDEX'//g' | sed -e 's/'.$cableID'//g' | sed -e 's/ = INTEGER: 2//g' | sed -e 's/SNMPv2-SMI::enterprises.4491.2.1.20.1.4.1.2.//g' | head -n 1`;
    node=`snmpget -v2c -c $COM  -Osqv ${c} $OID_NODE.$indexUP 2> /dev/null | sed -e 's/"//g'`;
    upstream=`snmpget -v2c -c $COM  -Osqv ${c} $OIDUpstream.$indexUP 2> /dev/null | sed -e 's/"//g'`;
	if [ -z "$upstream" ]; then
	data=`date`;
	echo -e "SYS:: \e[1;31m$b esteve ONLINE em $cmtsNome está OFFLINE agora!\e[0m";
	echo "";
	echo -e "SYS:: \e[1;32mConcluido OK\e[0m [$data]";
	break
	fi
    cablePolicy=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'policy' | sed 's/docsispolicyname: //g'`;
    nominalV=`cat "$dfs" | grep -w "$cablePolicy" | awk -F';' '{print $2}'`;
    cableContrato=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'contrato' | sed 's/docsiscontrato: //g'`;
    cableClientClass=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'clientclass' | sed 's/docsisclientclass: //g'`;
    cableModel=`snmpget -v2c -c public $cableIP $OID_MODELO 2> /dev/null | awk -F ':' '{print $NF}' | sed 's/>>//g' | sed -e 's/ //g'`;
    cableVer=`snmpget -v2c -c public $cableIP $OID_VERSION 2> /dev/null | awk -F ':' '{print $NF}' | sed 's/>>//g' | sed -e 's/ //g'`;
    cableCpe=`snmpwalk -v2c -c public -Osqv $cableIP $OID_CPE 2> /dev/null | egrep -v '0.1$|^192.|^172.|^.1$|0.0.0.0' | grep -v "$cableIP"`;
    cableTx=`snmpget -v2c -c public $cableIP $OID_TX 2> /dev/null | awk {'print $4'} `;
    cableRx=`snmpget -v2c -c public $cableIP $OID_RX 2> /dev/null | awk {'print $4'} `;
    cableSnr=`snmpget -v2c -c public $cableIP $OID_SNR 2> /dev/null | awk {'print $4'} `;
    cableFreqD=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | cut -d ' ' -f 1 | sed 's/000000//g' | grep -v -w '0'`;
    cableFreqU=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null `;
    cableSomaU=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null | wc -l`;
    cableSomaD=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | wc -l`;
    ofdmaActive=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null | grep -w '0' | sed 's/hertz//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
    ofdmActive=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | grep -w '0' | sed 's/hertz//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
        if [ "$ofdmActive" != "" ]; then
        ofdmCanal=`snmpwalk -v2c -c public $cableIP $OIDOfdmCanal 2> /dev/null | sed 's/SNMPv2-SMI::enterprises.4491.2.1.28.1.9.1.1.//g' | awk '{print $1}'`;
        ofdmRxMer=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmRxMer.$ofdmCanal 2> /dev/null | sed 's/No Such Instance currently exists at this OID//g'`;
        ofdmSlice=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmFreq.$ofdmCanal 2> /dev/null | wc -l`;
        fi
    if [ "$ofdmRxMer" == "" ]; then
    ofdmRxMer=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmRxMer 2> /dev/null | sed 's/No Such Instance currently exists at this OID//g' | tail -1`;
#    ofdmRxMer="0";
    fi
dia=`date +'%d-%m-%Y %H:%M'`;
data=`date`;
echo "+-------------------------------------------------------------+";
echo "| Mac: "$b" IP: $cableIP ";
echo "| Modelo: $cableModel Versão: $cableVer";
echo "| CMTS: $cmtsNome ($c) node: $node base: $base";
echo "| Ctto: $cableContrato ";
echo "| Perfil: $cablePolicy ";
echo "| ClientClass: $cableClientClass" ;
if [ "${cableCpe[*]}" > "1" ]; then
for cpe in ${cableCpe[@]}; do
echo "| CPE: $cpe"; done
elif [ "${cableCpe[*]}" == "1" ]; then
echo "| CPE: $cableCpe "; fi
echo "| Up: $upstream ";
if [ "$ofdmaActive" == "0" ]; then
echo "| OFDMA: Ativo";
fi
echo "| TX:$cableTx RX:$cableRx SNR:$cableSnr ";
echo "| Bonding: $cableSomaD X $cableSomaU";
for down in ${cableFreqD[@]}; do
echo "| Down: "$down" Mhz"; done
if [ "$ofdmActive" == "0" ]; then
echo "| OFDM: Ativo";
echo "| Canal: $ofdmCanal ";
echo "| RxMer: $ofdmRxMer ";
echo "| OFDM 6MHz Slices: $ofdmSlice ";
fi
echo "|_____________________________________________________________+";
echo "";
echo -e "SYS:: \e[1;32mConcluido OK \e[0m [$data]";
echo "";
break



# CONSULTA NO CMTS VENDOR CISCO CBR
elif [ "$cmtsVendor" == "Cisco CBR8" ]; then
data=`date`;
echo -e "SYS:: Localizado \e[1;32m$cmtsNome $c \e[0m[$data]";
echo "";
    cableIP=`snmpget -v2c -c $COM -Osqv ${c} $OID_CON_MAC.$cableID 2>/dev/null`;
    indexUP=`snmpwalk -v2c -c $COM ${c} $OID_UP_INDEX.$cableID 2> /dev/null | sed -e 's/'$OID_UP_INDEX'//g' | sed -e 's/'.$cableID'//g' | sed -e 's/ = INTEGER: 2//g' | sed -e 's/SNMPv2-SMI::enterprises.4491.2.1.20.1.4.1.2.//g' | sed 's/ = INTEGER: 0//g' | head -n 1`;
    node=`snmpget -v2c -c $COM  -Osqv ${c} $OID_NODE.$indexUP 2> /dev/null | sed -e 's/"//g'`;
    upstream=`snmpget -v2c -c $COM  -Osqv ${c} $OIDUpstream.$indexUP 2> /dev/null | sed -e 's/"//g'`;
	if [ -z "$upstream" ]; then
	data=`date`;
	echo -e "SYS:: \e[1;31m$b esteve ONLINE em $cmtsNome está OFFLINE agora!\e[0m";
	echo "";
	echo -e "SYS:: \e[1;32mConcluido OK\e[0m [$data]";
	break
	fi
    cablePolicy=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'policy' | sed 's/docsispolicyname: //g'`;
    nominalV=`cat "$dfs" | grep -w "$cablePolicy" | awk -F';' '{print $2}'`;
    cableContrato=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'contrato' | sed 's/docsiscontrato: //g'`;
    cableClientClass=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'clientclass' | sed 's/docsisclientclass: //g'`;
    cableModel=`snmpget -v2c -c public $cableIP $OID_MODELO 2> /dev/null | awk -F ':' '{print $NF}' | sed 's/>>//g' | sed -e 's/ //g'`;
    cableVer=`snmpget -v2c -c public $cableIP $OID_VERSION 2> /dev/null | awk -F ':' '{print $NF}' | sed 's/>>//g' | sed -e 's/ //g'`;
    cableCpe=`snmpwalk -v2c -c public -Osqv $cableIP $OID_CPE 2> /dev/null | egrep -v '0.1$|^192.|^172.|^.1$|0.0.0.0' | grep -v "$cableIP"`;
    cableCpe1=``;
    cableTx=`snmpget -v2c -c public $cableIP $OID_TX 2> /dev/null | awk {'print $4'} `;
    cableRx=`snmpget -v2c -c public $cableIP $OID_RX 2> /dev/null | awk {'print $4'} `;
    cableSnr=`snmpget -v2c -c public $cableIP $OID_SNR 2> /dev/null | awk {'print $4'} `;
    cableFreqD=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | cut -d ' ' -f 1 | sed 's/000000//g' | grep -v -w '0'`;
    cableFreqU=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null `;
    cableSomaU=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null | wc -l`;
    cableSomaD=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | wc -l`;
    ofdmaActive=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null | grep -w '0' | sed 's/hertz//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
    ofdmActive=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | grep -w '0' | sed 's/hertz//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
        if [ "$ofdmActive" != "" ]; then
        ofdmCanal=`snmpwalk -v2c -c public $cableIP $OIDOfdmCanal 2> /dev/null | sed 's/SNMPv2-SMI::enterprises.4491.2.1.28.1.9.1.1.//g' | awk '{print $1}'`;
        ofdmRxMer=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmRxMer.$ofdmCanal 2> /dev/null | sed 's/No Such Instance currently exists at this OID//g'`;
        ofdmSlice=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmFreq.$ofdmCanal 2> /dev/null | wc -l`;
        fi
    if [ "$ofdmRxMer" == "" ]; then
    ofdmRxMer=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmRxMer 2> /dev/null | sed 's/No Such Instance currently exists at this OID//g' | tail -1`;
    fi
dia=`date +'%d-%m-%Y %H:%M'`;
data=`date`;
echo "+-------------------------------------------------------------+";
echo "| Mac: "$b" IP: $cableIP ";
echo "| Modelo: $cableModel Versão: $cableVer";
echo "| CMTS: $cmtsNome ($c) node: $node base: $base";
echo "| Ctto: $cableContrato ";
echo "| Perfil: $cablePolicy ";
echo "| Velocidade Nominal: $nominalV";
echo "| ClientClass: $cableClientClass" ;
if [ "${cableCpe[*]}" > "1" ]; then
for cpe in ${cableCpe[@]}; do
echo "| CPE: $cpe"; done
elif [ "${cableCpe[*]}" == "1" ]; then
echo "| CPE: $cableCpe "; fi
echo "| Up: $upstream ";
if [ "$ofdmaActive" == "0" ]; then
echo "| OFDMA: Ativo";
fi
echo "| TX:$cableTx RX:$cableRx SNR:$cableSnr ";
echo "| Bonding: $cableSomaD X $cableSomaU";
for down in ${cableFreqD[@]}; do
echo "| Down: "$down" Mhz"; done
if [ "$ofdmActive" == "0" ]; then
echo "| OFDM: Ativo";
echo "| Canal: $ofdmCanal ";
echo "| RxMer: $ofdmRxMer ";
echo "| OFDM 6MHz Slices: $ofdmSlice ";
fi
echo "|_____________________________________________________________+";
echo "";
echo -e "SYS:: \e[1;32mConcluido OK \e[0m [$data]";
echo "";
break


# CONSULTA NO CMTS VENDOR CISCO UBR
elif [ "$cmtsVendor" == "Cisco UBR10K" ]; then
data=`date`;
echo -e "SYS:: Localizado \e[1;32m$cmtsNome $c \e[0m[$data]";
echo "";
    cableIP=`snmpget -v2c -c $COM -Osqv ${c} $OID_CON_MAC.$cableID 2>/dev/null`;
    indexUP=`snmpwalk -v2c -c $COM ${c} $OID_UP_INDEX.$cableID 2> /dev/null | sed -e 's/'$OID_UP_INDEX'//g' | sed -e 's/'.$cableID'//g' | sed -e 's/ = INTEGER: 2//g' | sed -e 's/SNMPv2-SMI::enterprises.4491.2.1.20.1.4.1.2.//g' | head -n 1`;
    node=`snmpget -v2c -c $COM  -Osqv ${c} $OID_NODE.$indexUP 2> /dev/null | sed -e 's/"//g'`;
    upstream=`snmpget -v2c -c $COM  -Osqv ${c} $OIDUpstream.$indexUP 2> /dev/null | sed -e 's/"//g'`;
	if [ -z "$upstream" ]; then
	data=`date`;
	echo -e "SYS:: \e[1;31m$b esteve ONLINE em $cmtsNome está OFFLINE agora!\e[0m";
	echo "";
	echo -e "SYS:: \e[1;32mConcluido OK\e[0m [$data]";
	break
	fi
    cablePolicy=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'policy' | sed 's/docsispolicyname: //g'`;
    nominalV=`cat "$dfs" | grep -w "$cablePolicy" | awk -F';' '{print $2}'`;
    cableContrato=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'contrato' | sed 's/docsiscontrato: //g'`;
    cableClientClass=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'clientclass' | sed 's/docsisclientclass: //g'`;
    cableModel=`snmpget -v2c -c public $cableIP $OID_MODELO 2> /dev/null | awk -F ':' '{print $NF}' | sed 's/>>//g' | sed -e 's/ //g'`;
    cableVer=`snmpget -v2c -c public $cableIP $OID_VERSION 2> /dev/null | awk -F ':' '{print $NF}' | sed 's/>>//g' | sed -e 's/ //g'`;
    cableCpe=`snmpwalk -v2c -c public -Osqv $cableIP $OID_CPE 2> /dev/null | egrep -v '0.1$|^192.|^172.|^.1$|0.0.0.0' | grep -v "$cableIP"`;
    cableTx=`snmpget -v2c -c public $cableIP $OID_TX 2> /dev/null | awk {'print $4'} `;
    cableRx=`snmpget -v2c -c public $cableIP $OID_RX 2> /dev/null | awk {'print $4'} `;
    cableSnr=`snmpget -v2c -c public $cableIP $OID_SNR 2> /dev/null | awk {'print $4'} `;
    cableFreqD=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | cut -d ' ' -f 1 | sed 's/000000//g' | grep -v -w '0'`;
    cableFreqU=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null `;
    cableSomaU=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null | wc -l`;
    cableSomaD=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | wc -l`;
    ofdmaActive=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null | grep -w '0' | sed 's/hertz//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
    ofdmActive=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | grep -w '0' | sed 's/hertz//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
        if [ "$ofdmActive" != "" ]; then
        ofdmCanal=`snmpwalk -v2c -c public $cableIP $OIDOfdmCanal 2> /dev/null | sed 's/SNMPv2-SMI::enterprises.4491.2.1.28.1.9.1.1.//g' | awk '{print $1}'`;
        ofdmRxMer=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmRxMer.$ofdmCanal 2> /dev/null | sed 's/No Such Instance currently exists at this OID//g'`;
        ofdmSlice=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmFreq.$ofdmCanal 2> /dev/null | wc -l`;
        fi
    if [ "$ofdmRxMer" == "" ]; then
    ofdmRxMer=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmRxMer 2> /dev/null | sed 's/No Such Instance currently exists at this OID//g' | tail -1`;
#    ofdmRxMer="0";
    fi
dia=`date +'%d-%m-%Y %H:%M'`;
data=`date`;
echo "+-------------------------------------------------------------+";
echo "| Mac: "$b" IP: $cableIP ";
echo "| Modelo: $cableModel Versão: $cableVer";
echo "| CMTS: $cmtsNome ($c) node: $node base: $base";
echo "| Ctto: $cableContrato ";
echo "| Perfil: $cablePolicy ";
echo "| ClientClass: $cableClientClass" ;
if [ "${cableCpe[*]}" > "1" ]; then
for cpe in ${cableCpe[@]}; do
echo "| CPE: $cpe"; done
elif [ "${cableCpe[*]}" == "1" ]; then
echo "| CPE: $cableCpe "; fi
echo "| Up: $upstream ";
if [ "$ofdmaActive" == "0" ]; then
echo "| OFDMA: Ativo";
fi
echo "| TX:$cableTx RX:$cableRx SNR:$cableSnr ";
echo "| Bonding: $cableSomaD X $cableSomaU";
for down in ${cableFreqD[@]}; do
echo "| Down: "$down" Mhz"; done
if [ "$ofdmActive" == "0" ]; then
echo "| OFDM: Ativo";
echo "| Canal: $ofdmCanal ";
echo "| RxMer: $ofdmRxMer ";
echo "| OFDM 6MHz Slices: $ofdmSlice ";
fi
echo "|_____________________________________________________________+";
echo "";
echo -e "SYS:: \e[1;32mConcluido OK \e[0m [$data]";
echo "";
break


# CONSULTA NO CMTS VENDOR CASA
elif [ "$cmtsVendor" == "Casa C10G" ]; then
data=`date`;
echo -e "SYS:: Localizado \e[1;32m$cmtsNome $c \e[0m[$data]";
echo "";
    cableIP=`snmpget -v2c -c $COM -Osqv ${c} $OID_CON_MAC.$cableID 2>/dev/null`;
    indexUP=`snmpwalk -v2c -c $COM ${c} $OID_UP_INDEX.$cableID 2> /dev/null | sed -e 's/'$OID_UP_INDEX'//g' | sed -e 's/'.$cableID'//g' | sed -e 's/ = INTEGER: 2//g' | sed -e 's/SNMPv2-SMI::enterprises.4491.2.1.20.1.4.1.2.//g' | head -n 1`;
    node=`snmpget -v2c -c $COM  -Osqv ${c} $OID_NODE.$indexUP 2> /dev/null | sed -e 's/"//g'`;
    upstream=`snmpget -v2c -c $COM  -Osqv ${c} $OIDUpstream.$indexUP 2> /dev/null | sed -e 's/"//g'`;
	if [ -z "$upstream" ]; then
	data=`date`;
	echo -e "SYS:: \e[1;31m$b esteve ONLINE em $cmtsNome está OFFLINE agora!\e[0m";
	echo "";
	echo -e "SYS:: \e[1;32mConcluido OK\e[0m [$data]";
	break
	fi
    cablePolicy=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'policy' | sed 's/docsispolicyname: //g'`;
    nominalV=`cat "$dfs" | grep -w "$cablePolicy" | awk -F';' '{print $2}'`;
    cableContrato=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'contrato' | sed 's/docsiscontrato: //g'`;
    cableClientClass=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'clientclass' | sed 's/docsisclientclass: //g'`;
    cableModel=`snmpget -v2c -c public $cableIP $OID_MODELO 2> /dev/null | awk -F ':' '{print $NF}' | sed 's/>>//g' | sed -e 's/ //g'`;
    cableVer=`snmpget -v2c -c public $cableIP $OID_VERSION 2> /dev/null | awk -F ':' '{print $NF}' | sed 's/>>//g' | sed -e 's/ //g'`;
    cableCpe=`snmpwalk -v2c -c public -Osqv $cableIP $OID_CPE 2> /dev/null | egrep -v '0.1$|^192.|^172.|^.1$|0.0.0.0' | grep -v "$cableIP"`;
    cableTx=`snmpget -v2c -c public $cableIP $OID_TX 2> /dev/null | awk {'print $4'} `;
    cableRx=`snmpget -v2c -c public $cableIP $OID_RX 2> /dev/null | awk {'print $4'} `;
    cableSnr=`snmpget -v2c -c public $cableIP $OID_SNR 2> /dev/null | awk {'print $4'} `;
    cableFreqD=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | cut -d ' ' -f 1 | sed 's/000000//g' | grep -v -w '0'`;
    cableFreqU=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null `;
    cableSomaU=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null | wc -l`;
    cableSomaD=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | wc -l`;
    ofdmaActive=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null | grep -w '0' | sed 's/hertz//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
    ofdmActive=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | grep -w '0' | sed 's/hertz//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
        if [ "$ofdmActive" != "" ]; then
        ofdmCanal=`snmpwalk -v2c -c public $cableIP $OIDOfdmCanal 2> /dev/null | sed 's/SNMPv2-SMI::enterprises.4491.2.1.28.1.9.1.1.//g' | awk '{print $1}'`;
        ofdmRxMer=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmRxMer.$ofdmCanal 2> /dev/null | sed 's/No Such Instance currently exists at this OID//g'`;
        ofdmSlice=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmFreq.$ofdmCanal 2> /dev/null | wc -l`;
        fi
    if [ "$ofdmRxMer" == "" ]; then
    ofdmRxMer=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmRxMer 2> /dev/null | sed 's/No Such Instance currently exists at this OID//g' | tail -1`;
#    ofdmRxMer="0";
    fi
dia=`date +'%d-%m-%Y %H:%M'`;
data=`date`;
echo "+-------------------------------------------------------------+";
echo "| Mac: "$b" IP: $cableIP ";
echo "| Modelo: $cableModel Versão: $cableVer";
echo "| CMTS: $cmtsNome ($c) node: $node base: $base";
echo "| Ctto: $cableContrato ";
echo "| Perfil: $cablePolicy ";
echo "| ClientClass: $cableClientClass" ;
if [ "${cableCpe[*]}" > "1" ]; then
for cpe in ${cableCpe[@]}; do
echo "| CPE: $cpe"; done
elif [ "${cableCpe[*]}" == "1" ]; then
echo "| CPE: $cableCpe "; fi
echo "| Up: $upstream ";
if [ "$ofdmaActive" == "0" ]; then
echo "| OFDMA: Ativo";
fi
echo "| TX:$cableTx RX:$cableRx SNR:$cableSnr ";
echo "| Bonding: $cableSomaD X $cableSomaU";
for down in ${cableFreqD[@]}; do
echo "| Down: "$down" Mhz"; done
if [ "$ofdmActive" == "0" ]; then
echo "| OFDM: Ativo";
echo "| Canal: $ofdmCanal ";
echo "| RxMer: $ofdmRxMer ";
echo "| OFDM 6MHz Slices: $ofdmSlice ";
fi
echo "|_____________________________________________________________+";
echo "";
echo -e "SYS:: \e[1;32mConcluido OK \e[0m [$data]";
echo "";
break


# CONSULTA NO CMTS VENDOR CASA C100G
elif [ "$cmtsVendor" == "Casa C100G" ]; then
data=`date`;
echo -e "SYS:: Localizado \e[1;32m$cmtsNome $c \e[0m[$data]";
echo "";
    cableIP=`snmpget -v2c -c $COM -Osqv ${c} $OID_CON_MAC.$cableID 2>/dev/null`;
    indexUP=`snmpwalk -v2c -c $COM ${c} $OID_UP_INDEX.$cableID 2> /dev/null | sed -e 's/'$OID_UP_INDEX'//g' | sed -e 's/'.$cableID'//g' | sed -e 's/ = INTEGER: 2//g' | sed -e 's/SNMPv2-SMI::enterprises.4491.2.1.20.1.4.1.2.//g' | head -n 1`;
    node=`snmpget -v2c -c $COM  -Osqv ${c} $OID_NODE.$indexUP 2> /dev/null | sed -e 's/"//g'`;
    upstream=`snmpget -v2c -c $COM  -Osqv ${c} $OIDUpstream.$indexUP 2> /dev/null | sed -e 's/"//g'`;
	if [ -z "$upstream" ]; then
	data=`date`;
	echo -e "SYS:: \e[1;31m$b esteve ONLINE em $cmtsNome está OFFLINE agora!\e[0m";
	echo "";
	echo -e "SYS:: \e[1;32mConcluido OK\e[0m [$data]";
	break
	fi
    cablePolicy=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'policy' | sed 's/docsispolicyname: //g'`;
    nominalV=`cat "$dfs" | grep -w "$cablePolicy" | awk -F';' '{print $2}'`;
    cableContrato=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'contrato' | sed 's/docsiscontrato: //g'`;
    cableClientClass=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'clientclass' | sed 's/docsisclientclass: //g'`;
    cableModel=`snmpget -v2c -c public $cableIP $OID_MODELO 2> /dev/null | awk -F ':' '{print $NF}' | sed 's/>>//g' | sed -e 's/ //g'`;
    cableVer=`snmpget -v2c -c public $cableIP $OID_VERSION 2> /dev/null | awk -F ':' '{print $NF}' | sed 's/>>//g' | sed -e 's/ //g'`;
    cableCpe=`snmpwalk -v2c -c public -Osqv $cableIP $OID_CPE 2> /dev/null | egrep -v '0.1$|^192.|^172.|^.1$|0.0.0.0' | grep -v "$cableIP"`;
    cableTx=`snmpget -v2c -c public $cableIP $OID_TX 2> /dev/null | awk {'print $4'} `;
    cableRx=`snmpget -v2c -c public $cableIP $OID_RX 2> /dev/null | awk {'print $4'} `;
    cableSnr=`snmpget -v2c -c public $cableIP $OID_SNR 2> /dev/null | awk {'print $4'} `;
    cableFreqD=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | cut -d ' ' -f 1 | sed 's/000000//g' | grep -v -w '0'`;
    cableFreqU=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null `;
    cableSomaU=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null | wc -l`;
    cableSomaD=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | wc -l`;
    ofdmaActive=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null | grep -w '0' | sed 's/hertz//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
    ofdmActive=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | grep -w '0' | sed 's/hertz//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
        if [ "$ofdmActive" != "" ]; then
        ofdmCanal=`snmpwalk -v2c -c public $cableIP $OIDOfdmCanal 2> /dev/null | sed 's/SNMPv2-SMI::enterprises.4491.2.1.28.1.9.1.1.//g' | awk '{print $1}'`;
        ofdmRxMer=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmRxMer.$ofdmCanal 2> /dev/null | sed 's/No Such Instance currently exists at this OID//g'`;
        ofdmSlice=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmFreq.$ofdmCanal 2> /dev/null | wc -l`;
        fi
    if [ "$ofdmRxMer" == "" ]; then
    ofdmRxMer=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmRxMer 2> /dev/null | sed 's/No Such Instance currently exists at this OID//g' | tail -1`;
#    ofdmRxMer="0";
    fi
dia=`date +'%d-%m-%Y %H:%M'`;
data=`date`;
echo "+-------------------------------------------------------------+";
echo "| Mac: "$b" IP: $cableIP ";
echo "| Modelo: $cableModel Versão: $cableVer";
echo "| CMTS: $cmtsNome ($c) node: $node base: $base";
echo "| Ctto: $cableContrato ";
echo "| Perfil: $cablePolicy ";
echo "| ClientClass: $cableClientClass" ;
if [ "${cableCpe[*]}" > "1" ]; then
for cpe in ${cableCpe[@]}; do
echo "| CPE: $cpe"; done
elif [ "${cableCpe[*]}" == "1" ]; then
echo "| CPE: $cableCpe "; fi
echo "| Up: $upstream ";
if [ "$ofdmaActive" == "0" ]; then
echo "| OFDMA: Ativo";
fi
echo "| TX:$cableTx RX:$cableRx SNR:$cableSnr ";
echo "| Bonding: $cableSomaD X $cableSomaU";
for down in ${cableFreqD[@]}; do
echo "| Down: "$down" Mhz"; done
if [ "$ofdmActive" == "0" ]; then
echo "| OFDM: Ativo";
echo "| Canal: $ofdmCanal ";
echo "| RxMer: $ofdmRxMer ";
echo "| OFDM 6MHz Slices: $ofdmSlice ";
fi
echo "|_____________________________________________________________+";
echo "";
echo -e "SYS:: \e[1;32mConcluido OK \e[0m [$data]";
echo "";
break


# CONSULTA NO CMTS VENDOR CASA BDM
elif [ "$cmtsVendor" == "Casa BDM" ]; then
data=`date`;
echo -e "SYS:: Localizado \e[1;32m$cmtsNome $c \e[0m[$data]";
echo "";
    cableIP=`snmpget -v2c -c $COM -Osqv ${c} $OID_CON_MAC.$cableID 2>/dev/null`;
    indexUP=`snmpwalk -v2c -c $COM ${c} $OID_UP_INDEX.$cableID 2> /dev/null | sed -e 's/'$OID_UP_INDEX'//g' | sed -e 's/'.$cableID'//g' | sed -e 's/ = INTEGER: 2//g' | sed -e 's/SNMPv2-SMI::enterprises.4491.2.1.20.1.4.1.2.//g' | head -n 1`;
    node=`snmpget -v2c -c $COM  -Osqv ${c} $OID_NODE.$indexUP 2> /dev/null | sed -e 's/"//g'`;
    upstream=`snmpget -v2c -c $COM  -Osqv ${c} $OIDUpstream.$indexUP 2> /dev/null | sed -e 's/"//g'`;
	if [ -z "$upstream" ]; then
	data=`date`;
	echo -e "SYS:: \e[1;31m$b esteve ONLINE em $cmtsNome está OFFLINE agora!\e[0m";
	echo "";
	echo -e "SYS:: \e[1;32mConcluido OK\e[0m [$data]";
	break
	fi
    cablePolicy=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'policy' | sed 's/docsispolicyname: //g'`;
    nominalV=`cat "$dfs" | grep -w "$cablePolicy" | awk -F';' '{print $2}'`;
    cableContrato=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'contrato' | sed 's/docsiscontrato: //g'`;
    cableClientClass=`ldapsearch -b $ldapBase -h $ldapSrv -D "uid=datacenter,dc=virtua" -w "dc2003" "docsismodemmacaddress=1,6,$b" | grep 'clientclass' | sed 's/docsisclientclass: //g'`;
    cableVer=`snmpget -v2c -c public $cableIP $OID_VERSION 2> /dev/null | awk -F ':' '{print $NF}' | sed 's/>>//g' | sed -e 's/ //g'`;
    cableModel=`snmpget -v2c -c public $cableIP $OID_MODELO 2> /dev/null | awk -F ':' '{print $NF}' | sed 's/>>//g' | sed -e 's/ //g'`;
#    cableCpe=`snmpwalk -v2c -c public -Osqv $cableIP $OID_CPE 2> /dev/null | egrep -v '0.1$|^192.|^172.|^.1$|0.0.0.0' | grep -v "$cableIP"`;
    cableMacs=`snmpwalk -v2c -c public -Osqv -Ih $cableIP $OID_MAC 2> /dev/null | sed 's/ /:/g' | cut -c-18 | sed 's/"//g'`;
	for mac in ${cableMacs[@]}; do
	# Variaveis para tratativa do MAC
	C_1=`echo ${mac} | tr 'a-z' 'A-Z'| awk -F: '{print $1}'`;
	C_2=`echo ${mac} | tr 'a-z' 'A-Z'| awk -F: '{print $2}'`;
	C_3=`echo ${mac} | tr 'a-z' 'A-Z'| awk -F: '{print $3}'`;
	C_4=`echo ${mac} | tr 'a-z' 'A-Z'| awk -F: '{print $4}'`;
	C_5=`echo ${mac} | tr 'a-z' 'A-Z'| awk -F: '{print $5}'`;
	C_6=`echo ${mac} | tr 'a-z' 'A-Z'| awk -F: '{print $6}'`;

	# Convertendo o MAC para decimal para montar a consulta

	mac_1=`echo "ibase=16; $C_1" | bc`;
	mac_2=`echo "ibase=16; $C_2" | bc`;
	mac_3=`echo "ibase=16; $C_3" | bc`;
	mac_4=`echo "ibase=16; $C_4" | bc`;
	mac_5=`echo "ibase=16; $C_5" | bc`;
	mac_6=`echo "ibase=16; $C_6" | bc`;
	    if [ "$cmtsVendor" == "Casa BDM" ]; then
	    cableCpe=(${cableCpe[@]} `snmpget -v2c -c $COM -Osqv ${c} $OID_IP.$mac_1.$mac_2.$mac_3.$mac_4.$mac_5.$mac_6 2>/dev/null | sed 's/No Such Instance currently exists at this OID//g' | grep -v $cableIP`);
	    cableMac=(${cableMac[@]} `echo "$mac"`);
	    else
	    cableCpe=(${cableCpe[@]} `snmpget -c $COM -v 1 -Osqv ${c} $OID_IP.$mac_1.$mac_2.$mac_3.$mac_4.$mac_5.$mac_6 2>/dev/null | grep -v $cableIP`);
	    cableMac=(${cableMac[@]} `echo "$mac"`);
	    fi
	done

    cableTx=`snmpget -v2c -c public $cableIP $OID_TX 2> /dev/null | awk {'print $4'} `;
    cableRx=`snmpget -v2c -c public $cableIP $OID_RX 2> /dev/null | awk {'print $4'} `;
    cableSnr=`snmpget -v2c -c public $cableIP $OID_SNR 2> /dev/null | awk {'print $4'} `;
    cableFreqD=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | cut -d ' ' -f 1 | sed 's/000000//g' | grep -v -w '0'`;
    cableFreqU=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null `;
    cableSomaU=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null | wc -l`;
    cableSomaD=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | wc -l`;
    ofdmaActive=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqU 2> /dev/null | grep -w '0' | sed 's/hertz//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
    ofdmActive=`snmpwalk -v2c -c public -Osqv $cableIP $OIDFreqD 2> /dev/null | grep -w '0' | sed 's/hertz//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
        if [ "$ofdmActive" != "" ]; then
        ofdmCanal=`snmpwalk -v2c -c public $cableIP $OIDOfdmCanal 2> /dev/null | sed 's/SNMPv2-SMI::enterprises.4491.2.1.28.1.9.1.1.//g' | awk '{print $1}'`;
        ofdmRxMer=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmRxMer.$ofdmCanal 2> /dev/null | sed 's/No Such Instance currently exists at this OID//g'`;
        ofdmSlice=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmFreq.$ofdmCanal 2> /dev/null | wc -l`;
        fi
    if [ "$ofdmRxMer" == "" ]; then
    ofdmRxMer=`snmpwalk -v2c -c public -Osqv $cableIP $OIDOfdmRxMer 2> /dev/null | sed 's/No Such Instance currently exists at this OID//g' | tail -1`;
#    ofdmRxMer="0";
    fi
dia=`date +'%d-%m-%Y %H:%M'`;
data=`date`;
echo "+-------------------------------------------------------------+";
echo "| Mac: "$b" IP: $cableIP";
echo "| Modelo: $cableModel Versão: $cableVer";
echo "| CMTS: $cmtsNome ($c) node: $node base: $base";
echo "| Ctto: $cableContrato ";
echo "| Perfil: $cablePolicy ";
echo "| Velocidade Nominal: $nominalV";
echo "| ClientClass: $cableClientClass" ;
if [ "${#cableCpe[@]}" -gt 0 ]; then
for cpe in ${cableCpe[@]}; do
echo "| CPE: $cpe "; done
elif [ "${cableCpe[*]}" == "1" ]; then
echo "| CPE: "$cableCpe" "; fi
echo "| Up: $upstream ";
if [ "$ofdmaActive" == "0" ]; then
echo "| OFDMA: Ativo";
fi
echo "| TX:$cableTx RX:$cableRx SNR:$cableSnr ";
echo "| Bonding: $cableSomaD X $cableSomaU";
for down in ${cableFreqD[@]}; do
echo "| Down: "$down" Mhz"; done
if [ "$ofdmActive" == "0" ]; then
echo "| OFDM: Ativo";
echo "| Canal: $ofdmCanal ";
echo "| RxMer: $ofdmRxMer ";
echo "| OFDM 6MHz Slices: $ofdmSlice ";
fi
echo "|_____________________________________________________________+";
echo "";
echo -e "SYS:: \e[1;32mConcluido OK \e[0m [$data]";
echo "";
break

# CONSULTA NO CMTS VENDOR INEXISTENTE
else
msg=`echo "Não identificado metodologia de consulta para o vendor cadastrado $cmtsVendor do CMTS $cmtsNome $c " > $cmtsLog`;
exibe=`echo "[   NOK   ] ---------- CONCLUIDA CONSULTA SEM LOGS "`;

    fi
fi
done
}


# CHAMA FUNCAO

lista_version
