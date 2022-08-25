from asyncore import write
import sys
import os
import re
import json

#0.0 当前路径 current_path
current_path = (os.getcwd())
#0.1 综合路径 syn_path
syn_path = current_path + "/Synthesis"
#0.2 RTL源文件路径 source_path
source_path = current_path + "/Source"
#0.3 初始化标记
#0.3.1 是否组合逻辑 is_comb（0/1 N/Y）
is_comb = 0 
#0.3.2

# print (syn_path)
print ("综合准备\n")

#1. 设计名 design_name
print ("输入顶层设计名\n")
for line in sys.stdin:
    design_name = line.rstrip() #LIB NAME
    print ("顶层设计名：" + design_name + "\n")
    break

#2. 选库 lib_name
print ("输入数字键选择库，按回车结束\n1:SIMC40LL\n")
for line in sys.stdin:
    if '1' == line.rstrip():
        lib_name = "SIMC40LL" #LIB NAME
        print ("选择工艺库：SIMC40LL\n")
        break
    else:
        print ("输入错误，请重试\n")

#3. 选库 clk_name
print ("输入时钟名，按回车键结束（若无时钟直接回车结束）\n")
for line in sys.stdin:
    if(line.rstrip()!=""):
        clk_name = line.rstrip() #LIB NAME
        print ("时钟名:"+clk_name+"\n")
        break
    else:
        is_comb = 1
        print ("无时钟\n")
        break

#4. 设置时钟周期 clk_period
if(is_comb == 1):
    print("无需设置周期\n")
else:
    print ("输入时钟周期（单位ns），按回车键结束\n")
    for line in sys.stdin:
        if (line.rstrip().isdigit()):
            clk_period = line.rstrip() #LIB NAME
            print ("时钟周期为" + clk_period + "ns\n")
            break

################################################################
#               创建Synthesis文件夹                             #
################################################################
os.makedirs(syn_path)
os.makedirs(current_path+"/Config")
os.makedirs(syn_path+"/DC")
os.makedirs(syn_path+"/DC/setup")
os.makedirs(syn_path+"/DC/Temp")
os.makedirs(syn_path+"/DC/dc_scripts")
os.makedirs(syn_path+"/SDC")
os.makedirs(syn_path+"/SAIF")
os.makedirs(syn_path+"/DONT_USE")
################################################################
#           1. 生成准备文件：common_setup.tcl                   #
################################################################
# 初始化新文件
new_common_setup_tcl = syn_path+'/DC/setup/common_setup.tcl'
f2 = open(new_common_setup_tcl,'w+')
# 读原始文件
f1 = open('/export/home/linyukai/Documents/Mars/LIBRARY/'+ lib_name + '/DC/setup/common_setup.tcl','r')

# 替换 DESIGN_NAME
str1 = r'OLD_DESIGN_NAME'
str2 = design_name
for ss in f1.readlines():
    tt=re.sub(str1,str2,ss)
    f2.write(tt)
f1.close()
f2.close()

#替换 CURRENT_PATH
str1 = r'OLD_CURRENT_PATH'
str2 = current_path
f = open(new_common_setup_tcl,'r')
alllines = f.readlines()
f.close()
f = open(new_common_setup_tcl,'w+')
for eachline in alllines:
    a=re.sub(str1,str2,eachline)
    f.writelines(a)
f.close()

################################################################
#              2. 生成准备文件：dc_setup.tcl                    #
################################################################
# 初始化新文件
new_dc_setup_tcl = syn_path+'/DC/setup/dc_setup.tcl'
f2 = open(new_dc_setup_tcl,'w+')
# 读原始文件
f1 = open('/export/home/linyukai/Documents/Mars/LIBRARY/'+ lib_name + '/DC/setup/dc_setup.tcl','r')

# 替换 CURRENT_PATH
str1 = r'OLD_CURRENT_PATH'
str2 = current_path
for ss in f1.readlines():
    tt=re.sub(str1,str2,ss)
    f2.write(tt)
f1.close()
f2.close()

# 替换 RTL_SOURCE_FILES
file_name_list = os.listdir(source_path)
file_name = str(file_name_list)
# 读取文件列表
rtl_source_files = ""
for file_name in file_name_list:
    file_name = "${DESIGN_REF_DATA_PATH}/" + file_name
    rtl_source_files = file_name + " \\" + "\n"+ rtl_source_files  
# 开始替换
str1 = r'OLD_RTL_SOURCE_FILES'
str2 = rtl_source_files
f = open(new_dc_setup_tcl,'r')
alllines = f.readlines()
f.close()
f = open(new_dc_setup_tcl,'w+')
for eachline in alllines:
    a=re.sub(str1,str2,eachline)
    f.writelines(a)
f.close()

################################################################
#           3. 生成准备文件：dc_setup_filenames.tcl             #
################################################################
# 初始化新文件
new_su_tcl = syn_path+'/DC/setup/dc_setup_filenames.tcl'
f2 = open(new_su_tcl,'w+')
# 读原始文件
f1 = open('/export/home/linyukai/Documents/Mars/LIBRARY/'+ lib_name + '/DC/setup/dc_setup_filenames.tcl','r')
# 不做处理，直接复制
for ss in f1.readlines():
    f2.write(ss)
f1.close()
f2.close()

################################################################
#          4. 生成脚本文件：dc.dft_autofix_config.tcl           #
################################################################
# 初始化新文件
new_cfg_tcl = syn_path+'/DC/dc_scripts/dc.dft_autofix_config.tcl'
f2 = open(new_cfg_tcl,'w+')
# 读原始文件
f1 = open('/export/home/linyukai/Documents/Mars/LIBRARY/'+ lib_name + '/DC/dc_scripts/dc.dft_autofix_config.tcl','r')
# 不做处理，直接复制
for ss in f1.readlines():
    f2.write(ss)
f1.close()
f2.close()

################################################################
#                  5. 生成脚本文件：fm.tcl                      #
################################################################
# 初始化新文件
new_fm_tcl = syn_path+'/DC/dc_scripts/fm.tcl'
f2 = open(new_fm_tcl,'w+')
# 读原始文件
f1 = open('/export/home/linyukai/Documents/Mars/LIBRARY/'+ lib_name + '/DC/dc_scripts/fm.tcl','r')

# 替换 CURRENT_PATH
str1 = r'OLD_CURRENT_PATH'
str2 = current_path
for ss in f1.readlines():
    tt=re.sub(str1,str2,ss)
    f2.write(tt)
f1.close()
f2.close()

################################################################
#                  6. 生成脚本文件：dc.tcl                      #
################################################################
# 初始化新文件
new_fm_tcl = syn_path+'/DC/dc_scripts/dc.tcl'
f2 = open(new_fm_tcl,'w+')
# 读原始文件
f1 = open('/export/home/linyukai/Documents/Mars/LIBRARY/'+ lib_name + '/DC/dc_scripts/dc.tcl','r')

# 替换 CURRENT_PATH
str1 = r'OLD_CURRENT_PATH'
str2 = current_path
for ss in f1.readlines():
    tt=re.sub(str1,str2,ss)
    f2.write(tt)
f1.close()
f2.close()

################################################################
#           7. 生成时钟约束文件：DESIGN_NAME.sdc                 #
################################################################
# 初始化新文件

new_sdc = syn_path+'/SDC/'+design_name+'.sdc'
f2 = open(new_sdc,'w+')
# print (is_comb)
if (is_comb == 0):
    # 读原始文件
    f1 = open('/export/home/linyukai/Documents/Mars/LIBRARY/'+ lib_name + '/SDC/systolic_pe_array.sdc','r')

    # 替换 CLK_NAME
    str1 = r'OLD_CLK_NAME'
    str2 = clk_name
    for ss in f1.readlines():
        tt=re.sub(str1,str2,ss)
        f2.write(tt)
    f1.close()
    f2.close()
    half_clk_period = str(int(clk_period,10)/2)
    #替换 PERIOD
    str1 = r'OLD_PERIOD'
    str2 = clk_period
    f = open(new_sdc,'r')
    alllines = f.readlines()
    f.close()
    f = open(new_sdc,'w+')
    for eachline in alllines:
        a=re.sub(str1,str2,eachline)
        f.writelines(a)
    f.close()
    #替换 HALF_PERIOD
    str1 = r'OLD_HALF_PERIOD'
    str2 = half_clk_period
    f = open(new_sdc,'r')
    alllines = f.readlines()
    f.close()
    f = open(new_sdc,'w+')
    for eachline in alllines:
        a=re.sub(str1,str2,eachline)
        f.writelines(a)
    f.close()
else:
    f2.close()

################################################################
#                8. 生成配置：mars_var.json                     #
################################################################
mars_var = {
    'mv_current_path' : current_path ,
    'mv_top_name' : design_name ,
    'mv_lib_name' : lib_name
}
with open (current_path+"/Config/mars_var.json","w") as f:
    json.dump(mars_var, f, indent=4, sort_keys=True, ensure_ascii=False)  # 写为多行

################################################################
#           9. 生成pin_cons_src：pin_cons_src.txt                 #
################################################################
# 初始化新文件
new_pin_cons_src = current_path+'/Config/pin_cons_src.txt'
f1 = open(new_pin_cons_src,'w+')
f1.write("left_side:\ntop_side:\nright_side:\nbottom_side:")
f1.close()
