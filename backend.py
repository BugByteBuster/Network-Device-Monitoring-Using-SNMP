import subprocess
import sys
import os

def build_command():
    cmd = ['unbuffer', '/tmp/A2/prober'] + sys.argv[1:]
    cmd = cmd[:3] + [-1] + cmd[3:]
    return " ".join(str(x) for x in cmd)

def extract_oids():
    oid_args = sys.argv[3:]
    return [oid for oid in oid_args]

def execute_command(cmd):
    process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, bufsize=1)
    return process

def process_output(process, oids):
    for line in iter(process.stdout.readline, b''):
        s = line.replace("|", " ")
        s = s.split()
        rate = s[1:]
        for i, oid in enumerate(oids):
            os.system("curl -i -XPOST 'http://localhost:8086/write?db=A3&u=ats&p=atslabb00&precision=s' --data-binary 'rate,oid=%s value=%f %d'" % (oid, float(rate[i]), int(s[0])))

def main():
    cmd = build_command()
    oids = extract_oids()
    process = execute_command(cmd)
    process_output(process, oids)

if __name__ == '__main__':
    main()
