""" Example handler file. """

import runpod
import subprocess
import os
import requests
import json

# start llama server here
llama = subprocess.Popen(["./llama",
                          "-m", "model.gguf",
                          '-a', os.environ.get("MODEL_FILE", 'Model'),
                          '-c', os.environ.get("ctx_size", '2048'),
                          '--mlock',
                          '--embedding',
                          # '--threads', os.environ.get("threads", '0'),
                          '-ngl', os.environ.get("n_gpu_layers", '1000')
                          ], stdout=subprocess.PIPE, text=True)

while True:
    line = llama.stdout.readline()
    if not line:
        break
    if "HTTP server listening" in line:
        print("LLAMA Server startup complete")
        break


def handler(job):
    """ Handler function that will be used to process jobs. """
    job_input = job['input']
    response = requests.request("POST", "http://127.0.0.1:8080/completion",
                                data=json.dumps(job_input)).json()

    return response


runpod.serverless.start({"handler": handler})
