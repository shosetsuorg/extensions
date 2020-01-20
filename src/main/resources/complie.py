# Simple tool to update hashes
import hashlib
import json


def md5(fname):
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()


with open("formatters.json") as json_file:
    data = json.load(json_file)

print(data)

keys = list(data.keys())
keys.remove('comments')

for k in keys:
    jsonFormatter = data[k]
    m = md5("./src/" + k + ".lua")
    print(k + ":\t"+m)
    jsonFormatter['md5'] = m
    data[k] = jsonFormatter

print(data)
with open('formatters.json', 'w') as f:
    json.dump(data, f, indent=2)
