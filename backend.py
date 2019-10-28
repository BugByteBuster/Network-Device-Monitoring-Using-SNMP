#!/usr/bin/python
import subprocess
import sys
import os
from subprocess import PIPE
cmd=[]
time=[]
oids =[]
for i in range(1, len(sys.argv)):
  cmd.append(sys.argv[i])

cmd=cmd[:0] + ['unbuffer /tmp/A2/prober'] + cmd[0:]
cmd = cmd[:3] + [-1] + cmd[3:]

cmd=" ".join(str(x) for x in cmd)

oid=sys.argv[3:len(sys.argv)]
for x in oid:
    oids.append(x)
#print oids[1]
a = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, bufsize=1)

for line in iter(a.stdout.readline, b''):
    s=line.replace("|"," ")
    s=s.split() #convrtng string to a list
    rate=s[1:]
    #print(rate)  
    for i in range(0,len(oids)):
        #print oids[i], int(s[0]), float(rate[i])

        os.system ("curl -i -XPOST 'http://localhost:8086/write?db=A3&u=ats&p=atslabb00&precision=s' --data-binary 'rate,oid=%s value=%f %d'"%(oids[i],float(rate[i]),int(s[0])))

         

