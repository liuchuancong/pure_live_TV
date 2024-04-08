import os
path="d:/flutter/pure_live/assets/iptv/category"  
jsonpath="d:/flutter/pure_live/assets/iptv/categories.json"      
import json
data = []
#获取该目录下所有文件，存入列表中
n=0
for n,name in enumerate(os.listdir(path)):
    
    #设置旧文件名（就是路径+文件名）
    oldname= name   # os.sep添加系统分隔符
    
    #设置新文件名
    newname='category'+str(n+1)

    data.append({
         'id': str(n+1),
         'path': oldname,
         'name': newname
      })
    # os.rename(oldname,newname)   #用os模块中的rename方法对文件改名
    print(oldname,'======>',newname)
    
    n+=1
print(data,'======>',data)
with open(jsonpath, "w") as json_file:
  json_data = json.dumps(data, indent=4)
  json_file.write(json_data)