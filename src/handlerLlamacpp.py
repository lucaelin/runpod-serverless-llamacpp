import runpod
import subprocess
import os
import requests
import json
from llama_cpp import Llama, LlamaGrammar


llm = Llama(model_path="./model.gguf", n_gpu_layers=1000, n_ctx=1024*4)


def handler(job):
    """ Handler function that will be used to process jobs. """
    job_input = job['input']
    if job_input.get("grammar"):
        job_input["grammar"] = LlamaGrammar.from_string(job_input.get("grammar"))
    output = llm(
      **job_input,
    ) # Generate a completion, can also call create_completion

    return output


runpod.serverless.start({"handler": handler})