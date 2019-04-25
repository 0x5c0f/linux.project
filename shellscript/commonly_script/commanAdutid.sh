# /etc/profile.d/commanAdutid.sh - set i18n stuff
# mkdir /var/log/commandAudit -p
# echo "0 0 * * * root touch /var/log/commandAudit/audit_\`date '+\%y-\%m-\%d'\`.log && chmod 622 /var/log/commandAudit/audit_\`date '+\%y-\%m-\%d'\`.log && chattr +a /var/log/commandAudit/audit_\`date '+\%y-\%m-\%d'\`.log" >> /etc/crontab
#

TMOUT=600
HISTSIZE=1000
HISTFILESIZE=1500
HISTTIMEFORMAT="%Y%m%d-%H%M%S: "

COMMANDAUDIT_FILE=/var/log/commandAudit/audit_`date '+%y-%m-%d'`.log
PROMPT_COMMAND='{ date "+%y-%m-%d %T ### [$(whoami)] ### $(who am i |awk "{print \$1\" \"\$2\" \"\$5}") ### $(pwd) ### $(history 1 | { read x cmd; echo "$cmd"; })"; } >> $COMMANDAUDIT_FILE'