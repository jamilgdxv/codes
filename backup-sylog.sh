#!/bin/bash -x
#--------------------------------------------------------------------
#       backup-syslog.sh                                            |
#       jamilgdxv@gmail.com.br                                      |
#       sander@sanderval.com.br                                     |
#       ULTIMA ALTERACAO 29/05/2015                                 |
#       ultima alteracao 06/06/2015                                 |
#       ultima alteracao 09/06/2015                                 |
# versao 0.1 - Inicial                                              |
# versao 0.2 - Atualização de versão com iserção de sistema de LOGS |
# versao 0.2.1 - Correcao no sistema de LOG acrescimo e debug       |
# versao 0.2.2 - Correcao na geracao dos logs                       |
#--------------------------------------------------------------------

# VARIAVEIS DE SISTEMA
DIR_ORIG="/opt/syslogdir/";
DIR_DEST="/srv/backup/";
DIR_FTP="/srv/ftp";
BKP_NAME="syslogbkp.tar.gz";
DATA=`date +%d%m%Y`;
DATAINICIO=`date +%d/%m/%Y`;
HORA=`date +%H:%M`;
LOG=/srv/backup/log/backup-$DATA.log;
LOGTMP=/srv/backup/log/backup-$DATA.tmp;

#VARIAVEIS PARA ENVIO DE EMAIL

#SMTP_SERVER="<IP AQUI>"
#HOSTNAME=$(hostname)

# INICIO DO SCRIPT, PARANDO O SERVICO DO SYSLOG
echo "" >> $LOG;
echo "+------ SCRIPT DE BACKUP 0.2.1 --------" > $LOG;
echo "|" >> $LOG
echo "| PROCESSO INICIALIZADO EM $DATAINICIO AS $HORA - [ OK ]" >> $LOG;
echo "|" >> $LOG;
echo `/etc/init.d/syslog-ng stop` >> $LOGTMP;
echo "| PARANDO SERVICO DE LOG - [ OK ]" >> $LOG;

# COPIA E COMPACTACAO DO ARQUIVO
echo "" >> $LOGTMP;
tar -zcvf ${DIR_DEST}${DATA}${BKP_NAME} ${DIR_ORIG} >> $LOGTMP 2> /dev/null;
echo "| COMPACTACAO DOS DADOS - [ OK ]" >> $LOG;

# INICIO DA EXCLUSAO DO DIRETORIO ANTIGO
#cd $DIR_ORIG;
echo "" >> $LOGTMP;
rm -vRrf ${DIR_ORIG}*.log* >> $LOGTMP;
echo "| EXCLUSAO DOS ARQUIVOS DE $DIR_ORIG - [ OK ]" >> $LOG;

# REINICIANDO O SERVICO APOS O PROCESSO
echo "" >> $LOGTMP;
echo `/etc/init.d/syslog-ng start` >> $LOGTMP;
echo "| SERVICO DE LOG INICIALIZADO - [ OK ]" >> $LOG;
#cd $DIR_DEST;
cp -v ${DIR_DEST}${DATA}${BKP_NAME} ${DIR_FTP} >> $LOGTMP;
echo "| COPIA DOS DADOS DISPONIVEIS PARA FTP - [ OK ]" >> $LOG;
DATAFINAL=`date +%d/%M/%Y`;
HORAFINAL=`date +%H:%M`;
echo "|" >> $LOG;
echo "| PROCESSO FINALIZADO EM $DATAFINAL AS $HORAFINAL - [ OK ]" >> $LOG;
echo "|" >> $LOG;
echo "+-----------------------------------------" >> $LOG;

# CRIA RELATORIO DE COMANDOS (ANEXA E REMOVE)
echo "" >> $LOG;
echo "------- RELATORIO DE COMANDOS -------" >> $LOG;
echo "" >> $LOG;
cat $LOGTMP >> $LOG;
echo "" >> $LOG;
echo "------- FIM RELATORIO ---------" >> $LOG;
echo "" >> $LOG;

#ENVIA EMAIL

#telnet $SMTP_SERVER 25 << EOF
#     helo virtua.com.br
#     mail from: teste@teste.com.br
#     rcpt to: nonoon@nono.com.br
#     Subject: ROTINA SERVIDOR SYSLOG - BACKUP $DATA
#     data
#     O servidor SYSLOG executou a rotina de BACKUP com sucesso em $(date +%d/%m/%Y) !
#     $LOGTMP
#.
#noop
#quit
#EOF
#
rm $LOGTMP;

exit;
