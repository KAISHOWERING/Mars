from curses.panel import top_panel
import sys
import os
import re
import json

#0.0 当前路径 current_path
current_path = (os.getcwd())
#0.1 布局布线路径 syn_path
pr_path = current_path + "/Layout"
#0.2 导入参数
with open(current_path + "/Config/mars_var.json","r") as f:
    mars_var = json.load(f)

lib_name = mars_var["mv_lib_name"]
top_name = mars_var["mv_top_name"]

with open(current_path + "/Config/mars_pin.json","r") as f:
    mars_pin = json.load(f)

metal_text = {
    "metal1":'MnTXT1',
    "metal2":'MnTXT2',
    "metal3":'MnTXT3',
    "metal4":'MnTXT4',
    "metal5":'MnTXT5',
    "metal6":'MnTXT6',
    "metal7":'MnTXT7'}


print ("布局布线准备\n")

#1. 电源名 power_name
print ("输入power name\n")
for line in sys.stdin:
    power_name = line.rstrip() 
    print ("power name：" + power_name + "\n")
    break

#2. 地名 ground_name
print ("输入ground name\n")
for line in sys.stdin:
    ground_name = line.rstrip() 
    print ("ground name：" + ground_name + "\n")
    break

#3. 利用率 core_utilization
print ("输入核面积占比(0~1)\n")
for line in sys.stdin:
    core_utilization = line.rstrip() 
    print ("核面积占比：" + core_utilization + "\n")
    break


################################################################
#               创建Layout文件夹                             #
################################################################
os.makedirs(pr_path+"/netlist")
os.makedirs(pr_path+"/gds")
os.makedirs(pr_path+"/rpt")
################################################################
#                  1. 生成准备文件：build.tcl                   #
################################################################
# 初始化新文件
new_build_tcl = pr_path+'/build/build.tcl'
f2 = open(new_build_tcl,'w+')
# 读原始文件
f1 = open('/export/home/linyukai/Documents/Mars/LIBRARY/'+ lib_name + '/ICC/build/build_pt1.tcl','r')

# 替换 TOP_NAME
str1 = r'OLD_TOP_NAME'
str2 = top_name
for ss in f1.readlines():
    tt=re.sub(str1,str2,ss)
    f2.write(tt)
f1.close()
f2.close()

#替换 CURRENT_PATH
str1 = r'OLD_CURRENT_PATH'
str2 = current_path
f = open(new_build_tcl,'r')
alllines = f.readlines()
f.close()
f = open(new_build_tcl,'w+')
for eachline in alllines:
    a=re.sub(str1,str2,eachline)
    f.writelines(a)
f.close()

#替换 OLD_VDD
str1 = r'OLD_VDD'
str2 = power_name
f = open(new_build_tcl,'r')
alllines = f.readlines()
f.close()
f = open(new_build_tcl,'w+')
for eachline in alllines:
    a=re.sub(str1,str2,eachline)
    f.writelines(a)
f.close()

#替换 OLD_VSS
str1 = r'OLD_VSS'
str2 = ground_name
f = open(new_build_tcl,'r')
alllines = f.readlines()
f.close()
f = open(new_build_tcl,'w+')
for eachline in alllines:
    a=re.sub(str1,str2,eachline)
    f.writelines(a)
f.close()

#替换 OLD_CORE_UTILIZATION
str1 = r'OLD_CORE_UTILIZATION'
str2 = core_utilization
f = open(new_build_tcl,'r')
alllines = f.readlines()
f.close()
f = open(new_build_tcl,'w+')
for eachline in alllines:
    a=re.sub(str1,str2,eachline)
    f.writelines(a)
f.close()

#打GDS标签
f = open(new_build_tcl,'a')
for key,value in mars_pin.items():
    f.write("set temp_ports [get_ports "+key+"]\nforeach_in_collection p $temp_ports {\n    set xy_location [get_location $p]\n    set x_location  [lindex $xy_location 0]\n    set y_location  [lindex $xy_location 1]\n    set name [collection_to_list $p]\n    set name_1 [string range $name 7 end-2]\n    create_text -height 0.00 -layer $"+metal_text[value]+" -origin [list [expr $x_location] [expr $y_location]] -orient W $name_1\n}\n")
f.close()

#加上part 2
f2 = open(new_build_tcl,'a')
# 读原始文件
f1 = open('/export/home/linyukai/Documents/Mars/LIBRARY/'+ lib_name + '/ICC/build/build_pt2.tcl','r')
# 不做处理，直接复制
for ss in f1.readlines():
    f2.write(ss)
f1.close()
f2.close()
