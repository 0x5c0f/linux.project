#!/bin/bash
#
#


firewall-cmd --permanent --add-rich-rule 'rule family=“ipv4” source address=“192.168.0.4/24” port port protocal=“tcp” port=“3306” accept'

firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="172.16.110.43" port protocol="tcp" port="22" accept"

firewall-cmd --permanent --add-rich-rule="rule family="ipv4" source address="127.0.0.1" port protocol="tcp" port="5432" accept"




  <!-- 伪装 ,伪装了的才可以进行跨机器转发 -->
  <masquerade/> 
  <forward-port port="9090" protocol="tcp" to-port="22"/>
  
  <forward-port port="1111" protocol="tcp" to-port="52698" to-addr="172.16.80.38"/>