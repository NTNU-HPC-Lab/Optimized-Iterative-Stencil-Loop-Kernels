import json
import math
import pprint as p
import subprocess

#domain_dims = [32, 64, 128, 256, 512, 1024, 2048, 4096]
# NOTE: The 2_gpus output is a copy of 4_gpus. The real output is being generated.
#prefix = 'results/yme/'
prefix = ''
#folders = ["1_gpu/1_gpu.txt"]#, "2_gpus/2_gpus.txt", "4_gpus/4_gpus.txt"]
folders = ["1_gpu.txt"]#, "2_gpus/2_gpus.txt", "4_gpus/4_gpus.txt"]

db = {}

for folder in folders:
    gpus = folder.split('.')[0]
    db[gpus] = {}
    ngpus = folder.split('_')[0]
    with open(prefix + folder, "r") as file:
        lines = file.readlines()
        for i in range(0, len(lines), 5):
            version = lines[i].split(' ')[0]
            db[gpus][version] = {}

        #for i in range(0, 6, 5): # DEBUG
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

            #res = subprocess.run(
            #        ['./generate_results.sh',
            #         version,
            #         ngpus,
            #         domain_dim,
            #         blockdims['BLOCK_X'],
            #         blockdims['BLOCK_Y']],
            #         #'32',
            #         #'32'],
            #        stdout=subprocess.PIPE).stdout.decode('utf-8')
            #results = list(filter(None, res.split('\n')))
            #blockdims["results"] = [float(result) for result in results]#[res.strip() for res in results]
            db[gpus][version][domain_dim] = blockdims

pretty_db = p.pformat(db)
print(pretty_db)
#with open('results.txt', 'w') as out_file:
#     out_file.write(pretty_db)
#
with open('results.json', 'w') as fp:
    json.dump(db, fp)
