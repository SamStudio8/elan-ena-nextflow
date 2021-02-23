#!/usr/bin/env python
import sys
from bs4 import BeautifulSoup as bs

# usage: webin_to_majora.py <webin_manifest> <webin_output_xml> <published_name>
published_name = sys.argv[3]

assembly_name = None
for line in open(sys.argv[1]):
    k,v = line.strip().split(None, 1)
    if k == "ASSEMBLYNAME":
        assembly_name = v

if not assembly_name or not published_name:
    sys.exit(1)

fh = open(sys.argv[2])
soup = bs("".join(fh.readlines()), 'xml')

try:
    erz = soup.findAll('ANALYSIS')[0]["accession"]
except:
    sys.exit(2)

print('published_name', 'assemblyname', 'ena_assembly_id')
print(published_name, assembly_name, erz)
