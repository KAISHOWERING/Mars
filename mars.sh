if [ -d ./Source/tb ]
then 
    echo -e "检测到testbench，是否需要仿真？（y/n）\n"

    while read name
    do
        if [ "$name"x = "n"x ]
        then
            echo -e "暂不仿真\n"
            break
        elif [ "$name"x = "y"x ]
        then
            echo -e "开始生成仿真脚本\n"
            python3.7 /export/home/linyukai/Documents/Mars/mars_sim.py
            echo -e "开始仿真…………\n"
            # sudo chmod 755 ./Simulation/sim.sh
            chmod 755 ./Simulation/sim.sh
            cd ./Simulation
            ./sim.sh
            cd ..
            break
        elif [ "$name"x = ""x ]
        then
            echo -e "开始生成仿真脚本\n"
            python3.7 /export/home/linyukai/Documents/Mars/mars_sim.py
            echo -e "开始仿真…………\n"
            # sudo chmod 755 ./Simulation/sim.sh
            chmod 755 ./Simulation/sim.sh
            cd ./Simulation
            ./sim.sh
            cd ..
            break
        else
            echo -e "无效输入，请重试\n"
        fi
    done

fi

if [ -d ./Synthesis ]
then
    echo -e "脚本已存在，是否现在开始综合？（y/n）\n"
else
    python3.7 /export/home/linyukai/Documents/Mars/mars_dc.py
    echo -e "脚本已生成，是否现在开始综合？（y/n）\n"
fi

while read name
do
    if [ "$name"x = "n"x ]
    then
        echo -e "暂不综合\n"
        break
    elif [ "$name"x = "y"x ]
    then
        echo -e "开始综合\n"
        cd ./Synthesis/DC
        dc_shell -topographical_mode -f dc_scripts/dc.tcl | tee dc.log
        cd ..
        cd ..
        break
    elif [ "$name"x = ""x ]
    then
        echo -e "开始综合\n"
        cd ./Synthesis/DC
        dc_shell -topographical_mode -f ./dc_scripts/dc.tcl | tee dc.log
        cd ..
        cd ..
        break
    else
        echo -e "无效输入，请重试\n"
    fi
done

if [ -d ./Layout ]
then
    echo -e "脚本已存在，是否现在开始布局布线？（y/n）\n"
else
    python3.7 /export/home/linyukai/Documents/Mars/pin_gen.py
    python3.7 /export/home/linyukai/Documents/Mars/mars_icc.py
    echo -e "脚本已生成，是否现在开始布局布线？（y/n）\n"
fi

while read name
do
    if [ "$name"x = "n"x ]
    then
        echo -e "暂不布局布线\n"
        break
    elif [ "$name"x = "y"x ]
    then
        echo -e "开始布局布线\n"
        icc_shell -gui -f ./Layout/build/build.tcl | tee ./Layout/icc.log
        mv command.log Layout/
        mv icc_output.txt Layout/
        mv net.acts Layout/
        break
    elif [ "$name"x = ""x ]
    then
        echo -e "开始布局布线\n"
        icc_shell -gui -f ./Layout/build/build.tcl | tee ./Layout/icc.log
        mv command.log Layout/
        mv icc_output.txt Layout/
        mv net.acts Layout/
        break
    else
        echo -e "无效输入，请重试\n"
    fi
done


