""" Example handler file. """

import runpod
from peft import PeftModel
from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline, GPTQConfig
import os

from huggingface_hub.hf_api import HfFolder 
from huggingface_hub import HfApi
print (os.environ["HF_TOKEN"])
HfFolder.save_token(os.environ["HF_TOKEN"])

model_name=os.environ.get("BASE_MODEL");
model_rev=os.environ.get("BASE_MODEL_REV")
adapter_model=os.environ.get("ADAPTER_MODEL")
adapter_revision=os.environ.get("ADAPTER_MODEL_REV")
adapter_folder="filter-adapter"

api = HfApi()
files_info = api.list_files_info(adapter_model, adapter_folder, revision=adapter_revision)
for file_info in files_info:
  api.hf_hub_download(
      local_dir='./',
      filename=file_info.path,
      repo_id=adapter_model,
      revision=adapter_revision,
      repo_type="model",
  )
# list of files in the adapter folder
print(os.listdir('./'+adapter_folder))

tokenizer = AutoTokenizer.from_pretrained(model_name, use_fast=True)
tokenizer.pad_token = tokenizer.eos_token
tokenizer.padding_side = 'right'

quantization_config_loading = GPTQConfig(bits=8, use_exllama=False, tokenizer=tokenizer)
base_model = AutoModelForCausalLM.from_pretrained(
    model_name, 
    low_cpu_mem_usage=True, 
    revision=model_rev,
    quantization_config=quantization_config_loading,
    device_map="auto",
    attn_implementation="flash_attention_2",
)
model = PeftModel.from_pretrained(base_model, './'+adapter_folder)
pipe = pipeline(task='text-generation', model=model, tokenizer=tokenizer)

def handler(job):
    """ Handler function that will be used to process jobs. """
    job_input = job['input']

    prompt = job_input.pop("prompt", None)  # Remove the "prompt" field from the dictionary
    out = pipe(prompt, **job_input)  # Spread the rest of the values from the dictionary

    return out

runpod.serverless.start({"handler": handler})