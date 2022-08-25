from curses import meta
from distutils.filelist import findall
import os, time, sys, re
import json

current_path = (os.getcwd())
# with open(current_path+"/mars_var.json") as f:
#     mars_var = json.load(f)

####创建pin的字典######
mars_pin = {}

f_src = open (current_path+"/Config/pin_cons_src.txt" , "r+")
f_gen = open (current_path+"/Layout/build/pin_pad.tcl" , "w+")

print ("输入pin层(水平)\n")
for line in sys.stdin:
    metal_name_h = line.rstrip() #LIB NAME
    print ("pin层(水平):" + metal_name_h + "\n")
    break

print ("输入pin层(垂直)\n")
for line in sys.stdin:
    metal_name_v = line.rstrip() #LIB NAME
    print ("pin层(垂直):" + metal_name_v + "\n")
    break

def pin_analysis (line,side,cnt,metal_name_h,metal_name_v):
    if (int(side,10) % 2 == 1):
        metal_name = metal_name_h
        print (side,metal_name)
    else:
        metal_name = metal_name_v
        print (side,metal_name)
    if "[" in line:
        words = re.findall(r"[0-9a-zA-Z_]+", line)
        # print (words)
        io = words[0]
        msb = int(words[1],10)
        # print (msb)
        lsb = int(words[2],10)
        pin_name = words[3]
        for i in range(lsb,msb+1): 
            f_gen.write("set_pin_physical_constraints -pin_name {"+pin_name+"["+str(i)+"]} -layers {"+metal_name+"} -side "+side+" -order "+str(cnt)+ " -pin_spacing 0\n")
            mars_pin = {pin_name:metal_name}
            cnt += 1
        return cnt
    else:
        words = re.findall(r"[0-9a-zA-Z_]+", line)
        # print (words)
        io = words[0]
        pin_name = words[1]
        f_gen.write("set_pin_physical_constraints -pin_name {"+pin_name+"} -layers {"+metal_name+"} -side "+side+" -order "+str(cnt)+ " -pin_spacing 0\n")
        mars_pin = {pin_name:metal_name}
        cnt += 1
        return cnt

for line in f_src.readlines():
    line = line.strip("\n")
    if line == "left_side:":
        f_gen.write("###左侧端口###" + "\n")
        print ("###左侧端口###" + "\n")
        side = "1"
        cnt = 1
    elif line == "right_side:":
        f_gen.write("###右侧端口###" + "\n")
        print ("###右侧端口###" + "\n")
        side = "3"
        cnt = 1
    elif line == "top_side:":
        f_gen.write("###上侧端口###" + "\n")
        print ("###上侧端口###" + "\n")
        side = "2"
        cnt = 1
    elif line == "bottom_side:":
        f_gen.write("###下侧端口###" + "\n")
        print ("###下侧端口###" + "\n")
        side = "4"
        cnt = 1
    else:
        line = line.strip(";")
        cnt = pin_analysis(line,side,cnt,metal_name_h,metal_name_v)

f_gen.close()
f_src.close()

with open (current_path+"/Config/mars_pin.json","w") as f:
    json.dump(mars_pin, f, indent=4, sort_keys=True, ensure_ascii=False)  # 写为多行