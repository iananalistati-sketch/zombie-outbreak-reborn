#!/usr/bin/env python3
"""Decode the two pinned multi-root models for offline review/extraction.

Rojo accepts one root per RBXM. Add only a temporary Folder and reparent the
existing roots to it; retain every original property/source chunk unchanged.
Never run any downloaded Lua. Originals remain byte-exact in third_party.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import struct
import subprocess
import tempfile
from inspect_studio_binary import decode_lz4, parse, read_string, u32

ROOT=Path(__file__).resolve().parents[1]
FOLDER=ROOT/'third_party/roblox-weapon-kit/official-prefabs'

def refs(raw,count):
    result=[];current=0
    for i in range(count):
        value=sum(raw[i+k*count]<<(24-8*k) for k in range(4))
        current+=(value>>1)^-(value&1);result.append(current)
    return result

def encoded_refs(values):
    previous=0;encoded=[]
    for value in values:
        delta=value-previous;previous=value
        encoded.append(((delta<<1)^(delta>>31))&0xffffffff)
    return bytes((value>>(24-8*k))&255 for k in range(4) for value in encoded)

def string(value):
    data=value.encode();return struct.pack('<I',len(data))+data

def wrap(source,target):
    original_classes,original_names,original_sources=parse(source)
    data=source.read_bytes();header=bytearray(data[:32]);chunks=[];offset=32;classes=[];all_refs=[]
    while offset<len(data):
        kind,compressed,size,reserved=struct.unpack_from('<4sIII',data,offset)
        assert reserved==0
        body=data[offset+16:offset+16+(compressed or size)];offset+=16+(compressed or size)
        if compressed:body=decode_lz4(body,size)
        if kind==b'INST':
            class_id=u32(body,0);_,index=read_string(body,4);count=u32(body,index+1)
            classes.append(class_id);all_refs+=refs(body[index+5:index+5+count*4],count)
        chunks.append([kind,body])
    class_id=max(classes)+1;root_ref=max(all_refs)+1
    struct.pack_into('<I',header,16,u32(data,16)+1)
    struct.pack_into('<I',header,20,u32(data,20)+1)
    found=False
    for item in chunks:
        if item[0]!=b'PRNT':continue
        assert not found;found=True
        body=item[1];assert body[0]==0
        count=u32(body,1);children=refs(body[5:5+count*4],count);parents=refs(body[5+count*4:5+count*8],count)
        assert sum(parent==-1 for parent in parents)==3,'Unexpected original prefab roots'
        parents=[root_ref if parent==-1 else parent for parent in parents]
        item[1]=b'\x00'+struct.pack('<I',count+1)+encoded_refs(children+[root_ref])+encoded_refs(parents+[-1])
    assert found
    index=next(i for i,(kind,_) in enumerate(chunks) if kind==b'PROP')
    chunks.insert(index,[b'INST',struct.pack('<I',class_id)+string('Folder')+b'\x00'+struct.pack('<I',1)+encoded_refs([root_ref])])
    index=next(i for i,(kind,_) in enumerate(chunks) if kind==b'PRNT')
    chunks.insert(index,[b'PROP',struct.pack('<I',class_id)+string('Name')+b'\x01'+string('ReviewedPrefab')])
    target.write_bytes(bytes(header)+b''.join(struct.pack('<4sIII',kind,0,len(body),0)+body for kind,body in chunks))
    converted,names,sources=parse(target)
    assert sources==original_sources and sorted(names)==sorted(original_names+['ReviewedPrefab'])
    assert sum(count for _,count in converted.values())==sum(count for _,count in original_classes.values())+1

def build(rojo,output):
    records=json.loads((FOLDER/'SOURCE.json').read_text())
    with tempfile.TemporaryDirectory(prefix='k17-official-review-') as temporary:
        temporary=Path(temporary)
        tree={'$className':'DataModel','ServerStorage':{'$className':'ServerStorage'}}
        for weapon,record in records.items():
            source=FOLDER/record['file']
            assert hashlib.sha256(source.read_bytes()).hexdigest()==record['sha256'],'Official source identity changed'
            target=temporary/(weapon+'.rbxm');wrap(source,target)
            tree['ServerStorage'][weapon]={'$path':str(target)}
        project=temporary/'review.project.json'
        project.write_text(json.dumps({'name':'Offline official weapon review','tree':tree}))
        subprocess.run([rojo,'build',str(project),'--output',str(output.resolve())],cwd=ROOT,check=True)
    print('PASS offline prefab review: pinned originals, three roots each, identical source bodies; no Lua executed')

if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rojo',default=shutil.which('rojo'))
    parser.add_argument('--output',type=Path,required=True)
    args=parser.parse_args()
    if not args.rojo:parser.error('Provide --rojo PATH')
    build(args.rojo,args.output)
