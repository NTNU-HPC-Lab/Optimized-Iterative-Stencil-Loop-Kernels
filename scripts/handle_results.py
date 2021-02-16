import json
import math
import pprint as p

import subprocess

files = ["1_gpu.txt", "2_gpus.txt", "4_gpus.txt"]

db = {}

for path in files:
    gpus = path.split('.')[0]
    db[gpus] = {}
    ngpus = path.split('_')[0]
    with open("results/" + path, "r") as f:
        lines = f.readlines()
        for i in range(0, len(lines), 5):
            version = lines[i].split(' ')[0]
            db[gpus][version] = {}

        #for i in range(0, 5, 5): # DEBUG
        for i in range(0, len(lines), 5):
            version = lines[i].split(' ')[0]
            tmp_db = {}
            params = lines[i+1:i+5] # Get the four lines preceeding each version

            # Extract block dims for domain dim
            t = [v.strip() for v in params[1].split(',')]
            ttmp = [v.split('=') for v in t]

            variables = {}
            for cfg in ttmp:
                variable = cfg[0].strip()
                value = cfg[1].strip()
                variables[variable] = value

            domain_dim = variables['DIM']
            blockdims = {block: variables[block] for block in variables.keys() & {'BLOCK_X', 'BLOCK_Y'}}

            res = subprocess.run(
                    ['./generate_results.sh',
                     version,
                     ngpus,
                     domain_dim,
                     #blockdims['BLOCK_X'],
                     #blockdims['BLOCK_Y']],
                     #blockdims['BLOCK_Z']],
                     '32',
                     '8',
                     '4'],
                    stdout=subprocess.PIPE).stdout.decode('utf-8')
            results = list(filter(None, res.split('\n')))
            blockdims["results"] = [float(result) for result in results]#[res.strip() for res in results]
            db[gpus][version][domain_dim] = blockdims

pretty_db = p.pformat(db)
print(pretty_db)

with open('results.json', 'w') as fp:
#with open('results_optimized.json', 'w') as fp:
    json.dump(db, fp)
