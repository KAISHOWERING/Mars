import sys
import os
import re
import json

#0.0 当前路径 current_path
current_path = (os.getcwd())
#0.1 仿真路径 sim_path
sim_path = current_path + "/Simulation"
#0.2 RTL源文件路径 source_path
source_path = current_path + "/Source"
#0.3 TB文件路径 tb_path
tb_path = current_path + "/Source/tb"

print ("仿真准备\n")

#1 仿真时间 sim_time
print("输入仿真时间(ns)\n")
for line in sys.stdin:
    sim_time = line.rstrip() #LIB NAME
    print ("仿真时间：" + sim_time + "ns\n")
    break

################################################################
#               创建Simulation文件夹                            #
################################################################
os.makedirs(sim_path)

################################################################
#                  1. 生成仿真脚本文件：sim.sh                   #
################################################################
#初始化新文件
new_sim_sh = sim_path+'/sim.sh'
f2 = open(new_sim_sh,'w+')
# 读原始文件
f1 = open('/export/home/linyukai/Documents/Mars/LIBRARY/VCS_SCRIPTS/sim.sh','r')

# 替换 SIM_TIME
str1 = r'OLD_SIM_TIME'
str2 = sim_time
for ss in f1.readlines():
    tt=re.sub(str1,str2,ss)
    f2.write(tt)
f1.close()
f2.close()

# 替换 TB
file_name_list = os.listdir(tb_path)
file_name = str(file_name_list)
# 读取文件列表
rtl_source_files = ""
for file_name in file_name_list:
    tb_source_files = tb_path + "/" + file_name
# 开始替换
str1 = r'OLD_TB'
str2 = tb_source_files
f = open(new_sim_sh,'r')
alllines = f.readlines()
f.close()
f = open(new_sim_sh,'w+')
for eachline in alllines:
    a=re.sub(str1,str2,eachline)
    f.writelines(a)
f.close()

# 替换 RTL_SOURCE_FILES
file_name_list = os.listdir(source_path)
file_name = str(file_name_list)
# 读取文件列表
rtl_source_files = ""
for file_name in file_name_list:
    if (file_name != "tb"):
        file_name = source_path+"/" + file_name
        rtl_source_files = file_name + " \\" + "\n"+ rtl_source_files 
# 开始替换
str1 = r'OLD_RTL_SOURCES'
str2 = rtl_source_files
f = open(new_sim_sh,'r')
alllines = f.readlines()
f.close()
f = open(new_sim_sh,'w+')
for eachline in alllines:
    a=re.sub(str1,str2,eachline)
    f.writelines(a)
f.close()

