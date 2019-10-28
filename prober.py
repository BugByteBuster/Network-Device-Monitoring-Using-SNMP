#!/usr/bin/python3

from easysnmp import Session
import sys
import time
b=[]
x=[]
Nr=[]
dr=[]
a=[]
tf=0
oids=['1.3.6.1.2.1.1.3.0']
oids=oids+sys.argv[4:len(sys.argv)]
samplingfrequency = float(sys.argv[2])
Nosamples = int(sys.argv[3])
ses = sys.argv[1].split(":")
session = Session(hostname=ses[0], remote_port=ses[1], community=ses[2], version=2, timeout=1,retries=1)

for i in range(0,Nosamples+1):
    t=time.time()
    a=session.get(oids)
    b=[]
    t2=[]
    dr=[]

    for f in range(0,len(oids)):
        if a[f].value=='NOSUCHINSTANCE':
           del(a[f])
                     
    for j in range(1,len(a)):
        b.append(int(a[j].value))

        t2.append(t)
        if (i>0 and len(x)>0):
           if b[j-1]-x[j-1]<0:
              e=a[j].snmp_type
              if e=='COUNTER':
                 b[j-1]=b[j-1]+2**32
              elif e=='COUNTER64':
                   b[j-1]=b[j-1]+2**64
           else:
             #print(Nr)
              Nr=b[j-1]-x[j-1]
              td=round((t2[j-1]-y[j-1]),1)
              dr.append(int(Nr/td))
             #print(dr)

           if len(dr)==len(a)-1:
            den=str(dr)[1:-1]
            den = den.replace(",", "|")
            print(int(t),"|",den)
    tf=time.time()
    time.sleep((1/samplingfrequency)-(tf-t))
    x=b
    y=t2
    z=dr




