#!/bin/bash
#===============================================================================
#    System Required: Ubuntu12+/Debian7+/CentOS7+
#    Description: Install and manager the Don't Starve Together Dedicated Server
#    Author: Ariwori
#    Blog: https://blog.wqlin.com
#===============================================================================
script_ver="2.4.2"
dst_conf_dirname="DoNotStarveTogether"
dst_conf_basedir="${HOME}/Klei"
dst_base_dir="${dst_conf_basedir}/${dst_conf_dirname}"
dst_server_dir="${HOME}/DSTServer"
dst_bin_cmd="./dontstarve_dedicated_server_nullrenderer"
data_dir="${HOME}/.dstscript"
dst_token_file="${data_dir}/clustertoken.txt"
server_conf_file="${data_dir}/server.conf"
dst_cluster_file="${data_dir}/clusterdata.txt"
log_arr_str="${data_dir}/logarr.txt"
ays_log_file="${data_dir}/ays_log_file.txt"
feedback_link="https://blog.wqlin.com/dstscript.html"
my_api_link="https://api.wqlin.com/dst"
update_link="${my_api_link}/dstscript"
log_save_dir="${dst_conf_basedir}/LogBackup"
mod_cfg_dir="${data_dir}/modconfigure"
# 屏幕输出
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Yellow_font_prefix="\033[33m"
Font_color_suffix="\033[0m"
Info="${Green_font_prefix}[信息]${Font_color_suffix}"
Error="${Red_font_prefix}[错误]${Font_color_suffix}"
Tip="${Yellow_font_prefix}[提示]${Font_color_suffix}"
info(){
    echo -e "${Info}" "$1"
}
tip(){
    echo -e "${Tip}" "$1"
}
error(){
    echo -e "${Error}" "$1"
}
# Main menu
Menu(){
    while (true)
    do
        echo -e "\e[33m============欢迎使用饥荒联机版独立服务器脚本[Linux-Steam](${script_ver})============\e[0m"
        echo -e "\e[33m作者：Ariwori    下载更新及Bug反馈：${feedback_link}\e[0m"
        echo -e "\e[33m本脚本一切权利归作者所有。未经许可禁止使用本脚本进行任何的商业活动！\e[0m"
        echo -e "\e[31m游戏服务端安装目录：${dst_server_dir} (Version: $(cat "${dst_server_dir}/version.txt"))\e[33m【${dst_need_update_str}】\e[0m"
        echo -e "\e[35m公告：$(grep -v script_ver "${data_dir}/announce.txt")\e[0m"
        echo -e "\e[92m[ 1]启动服务器           [ 2]关闭服务器           [ 3]重启服务器\e[0m"
        echo -e "\e[92m[ 4]修改房间设置         [ 5]添加或移除MOD        [ 6]设置管理员和黑名单\e[0m"
        echo -e "\e[92m[ 7]游戏服务端控制台     [ 8]自动更新及异常维护   [ 9]退出本脚本\e[0m"
        echo -e "\e[92m[10]删除存档             [11]更新游戏服务端       [12]更新MOD\e[0m"
        echo -e "\e[92m[13]当前玩家记录\e[0m"
        Simple_server_status
        echo -e "\e[33m================================================================================\e[0m"
        echo -e "\e[92m[如需中断任何操作请直接按Ctrl+C]请输入命令代号：\e[0m\c"
        read -r cmd
        case "${cmd}" in
            1)
            Start_server
            ;;
            2)
            Close_server
            Exit_auto_update
            ;;
            3)
            Reboot_server
            ;;
            4)
            Change_cluster
            ;;
            5)
            MOD_manager
            ;;
            6)
            List_manager
            ;;
            7)
            Server_console
            ;;
            8)
            Auto_update
            ;;
            9)
            exit
            ;;
            10)
            Cluster_manager
            ;;
            11)
            Force_update
            ;;
            12)
            Update_MOD
            ;;
            13)
            Show_players
            ;;
            *)
            error "输入有误！！！"
            ;;
        esac
    done
}
Change_cluster(){
    Get_current_cluster
    if [ -d "$dst_base_dir/${cluster}" ]
    then
        Set_cluster
    else
        error "当前存档【${cluster}】已被删除或已损坏！"
    fi
}
Server_console(){
    Get_single_shard
    if tmux has-session -t DST_"${shard}" > /dev/null 2>&1
    then
        info "即将跳转${shard}世界后台。。。退出请按Ctrl + B松开再按D，否则服务器将停止运行！！！"
        sleep 3
        tmux attach-session -t DST_"${shard}"
    else
        tip "${shard}世界未开启或已异常退出！！！"
    fi
}
Get_shard_array(){
    Get_current_cluster
    [ "$cluster" != "无" ] && [ -d "$dst_base_dir/${cluster}" ] && shardarray=$(ls -l "$dst_base_dir/${cluster}" | grep ^d | awk '{print $9}')
}
Get_single_shard(){
    Get_current_cluster
    Get_shard_array
    for shard in ${shardarray}
    do
        shardm=$shard
        if [ -f "${dst_base_dir}/${cluster}/${shardm}/server.ini" ]
        then
            if [ $(grep 'is_master = true' -c "${dst_base_dir}/${cluster}/${shardm}/server.ini") -gt 0 ] 
            then
                shardm=$shard
                break
            fi
        else
            error "存档【${cluster}】世界【${shardm}】配置文件server.ini缺失，存档损坏！"
            exit
        fi
    done
    [ -z "$shardm" ] && shard=$shardm
}
Get_current_cluster(){
    cluster="无"
    [ -f "${server_conf_file}" ] && cluster=$(grep "^cluster" "${server_conf_file}" | cut -d "=" -f2)
}
Get_server_status(){
    [ -f "${server_conf_file}" ] && serveropen=$(grep "serveropen" "${server_conf_file}" | cut -d "=" -f2)
}
MOD_manager(){
    Get_current_cluster
    if [ -d "${dst_base_dir}/${cluster}" ]
    then
        if [ $( ls -l "${dst_base_dir}/${cluster}" | grep -c ^d) -gt 0 ]
        then
            Default_mod
            echo -e "\e[92m【存档：${cluster}】 你要 1.添加mod  2.删除mod  3.修改MOD配置\n                    4.重置MOD配置  5.安装MOD合集\n：\e[0m\c"
            read mc
            case "${mc}" in
                1)
                Listallmod
                Addmod;;
                2)
                Listusedmod
                Delmod;;
                3)               
                Mod_Cfg;;
                4)
                Clear_mod_cfg
                ;;
                5)
                Install_mod_collection
                ;;
                *)
                return;;
            esac
            Removelastcomma
        else
            error "当前存档【${cluster}】已被删除或已损坏！"
        fi
    else
        error "当前存档【${cluster}】已被删除或已损坏！"
    fi
}
Install_mod_collection(){
    [ -f "$data_dir/modcollectionlist.txt" ] && rm -rf "$data_dir/modcollectionlist.txt"
    touch "$data_dir/modcollectionlist.txt"
    echo -e "\e[92m[输入结束请输入数字 0]请输入你的MOD合集ID:\e[0m\c"
    while (true)
    do
        read clid
        if [ "$clid" -eq 0 ]
        then
            info "合集添加完毕！即将安装 ..."
            break
        else
            echo "ServerModCollectionSetup(\"$clid\")" >> "$data_dir/modcollectionlist.txt"
            info "该MOD合集($clid)已添加到待安装列表。"
        fi
    done
    if [ -s "$data_dir/modcollectionlist.txt" ]
    then
        info "正在安装新添加的MOD(合集)，请稍候 。。。"
        if [ ! -d "${dst_base_dir}/downloadmod/Master" ]
        then
            mkdir -p "${dst_base_dir}/downloadmod/Master"
        fi
        if tmux has-session -t DST_MODUPDATE > /dev/null 2>&1
        then
            tmux kill-session -t DST_MODUPDATE
        fi
        cp "$data_dir/modcollectionlist.txt" "${dst_server_dir}/mods/dedicated_server_mods_setup.lua"
        cd "${dst_server_dir}/bin" || exit 1
        tmux new-session -s DST_MODUPDATE -d "${dst_bin_cmd}" -persistent_storage_root "${dst_conf_basedir}" -cluster downloadmod -shard Master
        sleep 3
        while (true)
        do
            if tmux has-session -t DST_MODUPDATE > /dev/null 2>&1
            then
                if [[ $(grep "Your Server Will Not Start" -c "${dst_base_dir}/downloadmod/Master/server_log.txt") -gt 0 ]]
                then              
                    info "安装进程已执行完毕，请到添加MOD中查看是否安装成功！"
                    tmux kill-session -t DST_MODUPDATE
                    break         
                fi
            fi
        done
    else
        tip "没有新的MOD合集需要安装！"
    fi
}
Clear_mod_cfg(){
    [ -d "$mod_cfg_dir" ] && rm -rf $mod_cfg_dir
    info "所有MOD配置均已重置！" 
}
Mod_Cfg(){
    while (true)
    do
        clear
        Get_current_cluster
        echo -e "\e[92m【存档：${cluster}】已启用的MOD配置修改===============\e[0m"
        Listusedmod
        info "请从以上列表选择你要配置的MOD${Red_font_prefix}[编号]${Font_color_suffix},完毕请输数字 0 ！"
        read modid
        if [[ "${modid}" -eq 0 ]]
        then
            info "MOD配置完毕！"
            break
        else
            Truemodid #moddir
            Show_mod_cfg
            Write_mod_cfg
        fi
    done
}
# 传入moddir
Show_mod_cfg(){
    if [ -f "${mod_cfg_dir}/${moddir}.cfg" ]
    then
        Get_installed_mod_version
        n_ver=$result
        Get_data_from_file "${mod_cfg_dir}/${moddir}.cfg" mod-version
        c_ver=$result
        if [[ "$n_ver" != "$c_ver" ]]
        then
            update_mod_cfg
        fi
    else
        update_mod_cfg
    fi
    Get_data_from_file "${mod_cfg_dir}/${moddir}.cfg" "mod-configureable"
    c_able=$result
    c_line=$(grep "^" -n "${mod_cfg_dir}/${moddir}.cfg"| tail -n 1 | cut -d : -f1)
    if [[ "$c_able" == "true" && "$c_line" -gt 3 ]]
    then
        Get_data_from_file "${mod_cfg_dir}/${moddir}.cfg" "mod-version"
        c_ver=$result
        Get_data_from_file "${mod_cfg_dir}/${moddir}.cfg" "mod-name"
        c_name=$(echo $result | sed 's/#/ /g')
        while (true)
        do
            clear
            echo -e "\e[92m【修改MOD：$c_name配置】[$c_ver]\e[0m"
            index=1
            cat "${mod_cfg_dir}/${moddir}.cfg" | grep -v "mod-configureable" | grep -v "mod-version" | grep -v "mod-name" | while read line
            do
                ss=(${line})
                if [ "${ss[2]}" == "table" ]
                then
                    value=${ss[1]}
                else               
                    for ((i=5;i<${#ss[*]};i=$i+3))
                    do
                        if [ "${ss[$i]}" == "${ss[1]}" ]
                        then
                            value=${ss[$i+1]}
                        fi
                    done
                fi              
                if [[ "$value" == "不明项勿修改" ]]
                then
                    value=${ss[1]}
                fi
                value=$(echo "$value" | sed 's/#/ /g')
                label=$(echo "${ss[3]}" | sed 's/#/ /g')
                hover=$(echo "${ss[4]}" | sed 's/#/ /g')
                if [[ "$label" == "" || "$label" == "nolabel" ]]
                then
                    label=$(echo "${ss[0]}" | sed 's/#/ /g')
                    hover="${Red_font_prefix}该项作用不明，请勿轻易修改否则可能出错。详情请查看modinfo.lua文件。${Font_color_suffix}"
                fi
                if [ "${index}" -lt 10 ]
                then
                    echo -e "\e[33m[ ${index}] $label：${Red_font_prefix}${value}${Font_color_suffix}\n     简介==>$hover\e[0m"
                else
                    echo -e "\e[33m[${index}] $label：${Red_font_prefix}${value}${Font_color_suffix}\n     简介==>$hover\e[0m"
                fi
                index=$(($index + 1))
            done
            echo -e "\e[92m===============================================\e[0m"
            unset cmd
            while (true)
            do
                if [[ "${cmd}" == "" ]]
                then
                    echo -e "\e[92m请选择你要更改的选项(修改完毕输入数字 0 确认修改并退出)：\e[0m\c"
                    read cmd
                else
                    break
                fi
            done
            case "${cmd}" in
                0)
                info "更改已保存！"
                break
                ;;
                *)
                cmd=$(($cmd + 3))
                changelist=($(sed -n "${cmd}p" "${mod_cfg_dir}/${moddir}.cfg"))
                label=$(echo "${changelist[3]}" | sed 's/#/ /g')
                if [[ "$label" == "" || "$label" == "nolabel" ]]
                then
                    label=$(echo "${changelist[0]}" | sed 's/#/ /g')
                fi
                if [ "${changelist[2]}" = "table" ]
                then
                    tips "${Red_font_prefix}此项为表数据，请直接修改modinfo.lua文件${Font_color_suffix}"
                else
                    echo -e "\e[92m请选择$label： \e[0m"
                    index=1
                    for ((i=5;i<${#changelist[*]};i=$i+3))
                    do
                        description=$(echo "${changelist[$[$i + 1]]}" | sed 's/#/ /g')
                        hover=$(echo "${changelist[$[$i + 2]]}" | sed 's/#/ /g')
                        printf "%-30s" "${index}.$description"
                        echo -e "\e[92m简介==>$hover\e[0m"
                        index=$((${index} + 1))
                    done
                    echo -e "\e[92m: \e[0m\c"
                    read changelistindex
                    listnum=$[${changelistindex} - 1]*3
                    changelist[1]=${changelist[$[$listnum + 5]]}
                fi
                changestr="${changelist[@]}"
                sed -i "${cmd}c ${changestr}" "${mod_cfg_dir}/${moddir}.cfg"
                ;;
            esac
        done
    fi
}
Write_mod_cfg(){
    Delmodfromshard > /dev/null 2>&1
    rm "${data_dir}/modconfwrite.lua" > /dev/null 2>&1
    touch "${data_dir}/modconfwrite.lua"
    c_line=$(grep "^" -n "${mod_cfg_dir}/${moddir}.cfg"| tail -n 1 | cut -d : -f1)
    if [[ $c_line -le 3 ]]
    then
        echo "  [\"$moddir\"]={ [\"enabled\"]=true }," >> "${data_dir}/modconfwrite.lua"
    else
        echo "  [\"$moddir\"]={" >> "${data_dir}/modconfwrite.lua"
        echo "    configuration_options={" >> "${data_dir}/modconfwrite.lua"
        # cindex=4
        cat "${mod_cfg_dir}/${moddir}.cfg"| grep -v "mod-configureable" | grep -v "mod-version" | grep -v "mod-name" | while read lc
        do
            lcstr=($lc)
            cfgname=$(echo "${lcstr[0]}" | sed 's/#/ /g')
            if [[ "${lcstr[2]}" != "table" ]]
            then
                if [[ "${lcstr[2]}" == "number" ]]
                then
                    echo -e "      [\"$cfgname\"]=${lcstr[1]}," >> "${data_dir}/modconfwrite.lua"
                elif [[ "${lcstr[2]}" == "string" ]]
                then
                    echo -e "      [\"$cfgname\"]=\"${lcstr[1]}\"," >> "${data_dir}/modconfwrite.lua"
                elif [[ "${lcstr[2]}" == "boolean" ]]
                then
                    echo -e "      [\"$cfgname\"]=${lcstr[1]}," >> "${data_dir}/modconfwrite.lua"
                fi
            fi
        done
        echo "    }," >> "${data_dir}/modconfwrite.lua"
        echo "    [\"enabled\"]=true" >> "${data_dir}/modconfwrite.lua"
        echo "  }," >> "${data_dir}/modconfwrite.lua"
    fi
    Addmodtoshard > /dev/null 2>&1
}
Get_data_from_file(){
    if [ -f "$1" ]
    then       
        result=$(grep "^$2" "$1" |head -n 1 | cut -d " " -f3)
    fi
}
Get_installed_mod_version(){
    echo "fuc=\"getver\"" > "${data_dir}/modinfo.lua"
    cat "${dst_server_dir}/mods/${moddir}/modinfo.lua" >> "${data_dir}/modinfo.lua"
    cd "${data_dir}"
    result=$(lua modconf.lua)
}

update_mod_cfg(){
    if [[ -f "${dst_server_dir}/mods/${moddir}/modinfo.lua" ]]
    then
        cat > "${data_dir}/modinfo.lua" <<-EOF
fuc = "createmodcfg"
modid = "${moddir}"
EOF
        cat "${dst_server_dir}/mods/${moddir}/modinfo.lua" >> "${data_dir}/modinfo.lua"
        cd "${data_dir}"
        lua modconf.lua >/dev/null 2>&1
        cd "${HOME}"
    else
        tip "请先安装并启用MOD！"
        break
    fi
}

# old
MOD_conf(){
    if [[ "${fuc}" == "createmodcfg" ]]
    then
        if [[ -f "${dst_server_dir}/mods/${moddir}/modinfo.lua" ]]
        then
            cat "${dst_server_dir}/mods/${moddir}/modinfo.lua" >> "${data_dir}/modinfo.lua"
        else
            needdownloadid=$(echo "${moddir}" | cut -d "-" -f2)
            echo "ServerModSetup(\"$needdownloadid\")" > "${dst_server_dir}/mods/dedicated_server_mods_setup.lua"      
            Download_MOD
        fi
        if [ ! -f "${mod_cfg_dir}/${moddir}.cfg" ]
        then
            update_mod_cfg
        fi
    else
        cat > "${data_dir}/modinfo.lua" <<-EOF
fuc = "${fuc}"
modid = "${moddir}"
used = "${used}"
EOF
        if [[ -f "${dst_server_dir}/mods/${moddir}/modinfo.lua" ]]
        then
            cat "${dst_server_dir}/mods/${moddir}/modinfo.lua" >> "${data_dir}/modinfo.lua"
        else
            echo "name = \"UNKNOWN\"" >> "${data_dir}/modinfo.lua"
        fi
        cd ${data_dir}
        lua modconf.lua >/dev/null 2>&1
        cd ${HOME}
    fi
}
Listallmod(){
    if [ ! -f "${data_dir}/mods_setup.lua" ]
    then
        touch "${data_dir}/mods_setup.lua"
    fi
    rm -f "${data_dir}/modconflist.lua"
    touch "${data_dir}/modconflist.lua"
    Get_single_shard
    for moddir in $(ls -F "${dst_server_dir}/mods" | grep "/$" | cut -d '/' -f1)
    do
        if [ $(grep "${moddir}" -c "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua") -gt 0 ]
        then
            used="true"
        else
            used="false"
        fi
        if [[ "${moddir}" != "" ]]
        then
            fuc="list"
            MOD_conf
        fi
    done
    if [ ! -s  "${data_dir}/modconflist.lua" ]
    then
        tip "没有安装任何MOD，请先安装MOD！！！" && break
    else
        grep -n "^" "${data_dir}/modconflist.lua"
    fi
}
Listusedmod(){
    rm -f "${data_dir}/modconflist.lua"
    touch "${data_dir}/modconflist.lua"
    Get_single_shard
    for moddir in $(grep "^  \[" "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua" | cut -d '"' -f2)
    do
        used="false"
        if [[ "${moddir}" != "" ]]
        then
            fuc="list"
            used="true"
            MOD_conf
        fi
    done  
    if [ ! -s  "${data_dir}/modconflist.lua" ]
    then
        tip "没有启用任何MOD，请先启用MOD！！！" && break
    else
        grep -n "^" "${data_dir}/modconflist.lua"
    fi
}
Addmod(){
    info "请从以上列表选择你要启用的MOD${Red_font_prefix}[编号]${Font_color_suffix}，不存在的直接输入MODID"
    tip "大小超过10M的MOD如果无法在服务器添加下载，请手动上传到服务器再启用！！！"
    info "添加完毕要退出请输入数字 0 ！"
    while (true)
    do
        read modid
        if [[ "${modid}" == "0" ]]
        then
            info "添加完毕 ！"
            break
        else
            Addmodfunc
        fi
    done
    info "默认参数配置已写入配置文件，可手动修改，也可通过脚本修改："
    info "${dst_base_dir}/${cluster}/***/modoverrides.lua"
    sleep 3
    clear
}
Addmodtoshard(){
    Get_shard_array
    for shard in ${shardarray}
    do
        if [ -f "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua" ]
        then
            if [ $(grep "${moddir}" -c "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua") -gt 0 ]
            then
                info "${shard}世界该Mod(${moddir})已添加"
            else
                sed -i '1d' "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua"
                cat "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua" > "${data_dir}/modconftemp.txt"
                echo "return {" > "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua"
                cat "${data_dir}/modconfwrite.lua" >> "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua"
                cat "${data_dir}/modconftemp.txt" >> "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua"
                if [[ "${newmodinstalled}" == "false" ]]
                then
                    tips "${shard}世界Mod(${moddir})已添加到配置，但MOD安装/更新失败！请从本地上传MOD后再重启!"
                else
                    info "${shard}世界Mod(${moddir})添加完成"
                fi
            fi
        else
            tip "${shard} MOD配置文件未由脚本初始化，无法操作！如你已自行配置请忽略本提示！"
        fi
    done
}
Truemodid(){
    if [ "${modid}" -lt 10000 ]
    then
        moddir=$(sed -n ${modid}p "${data_dir}/modconflist.lua" | cut -d ':' -f3)
    else
        moddir="workshop-${modid}"
    fi
}
Addmodfunc(){
    Truemodid
    fuc="createmodcfg"
    MOD_conf
    Write_mod_cfg
    Addmodtoshard
    Removelastcomma
}
Delmodfromshard(){
    Get_shard_array
    for shard in ${shardarray}
    do
        if [ -f "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua" ]
        then
            if [[ $(grep "${moddir}" -c "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua") -gt 0 ]]
            then
                grep -n "^  \[" "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua" > "${data_dir}/modidlist.txt"
                lastmodlinenum=$(cat "${data_dir}/modidlist.txt" | tail -n 1 | cut -d ":" -f1)
                up=$(grep "${moddir}" "${data_dir}/modidlist.txt" | cut -d ":" -f1)
                if [ "${lastmodlinenum}" -eq "${up}" ]
                then
                    down=$(grep "^" -n "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua" | tail -n 1 | cut -d ":" -f1)
                else
                    down=$(grep -A 1 "${moddir}" "${data_dir}/modidlist.txt" | tail -1 |cut -d ":" -f1)
                fi
                upnum=${up}
                downnum=$((${down} - 1))
                sed -i "${upnum},${downnum}d" "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua"
                info "${shard}世界该Mod(${moddir})已停用！"
            else
                info "${shard}世界该Mod(${moddir})未启用！"
            fi
        else
            tip "${shard} MOD配置文件未由脚本初始化，无法操作！如你已自行配置请忽略本提示！"
        fi
    done
}
# 保证最后一个MOD配置结尾不含逗号
Removelastcomma(){
    for shard in ${shardarray}
    do
        if [ -f "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua" ]
        then
            checklinenum=$(grep "^" -n "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua" | tail -n 2 | head -n 1 | cut -d ":" -f1)
            sed -i "${checklinenum}s/,//g" "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua"
        fi
    done
}
Delmod(){
    info "请从以上列表选择你要停用的MOD${Red_font_prefix}[编号]${Font_color_suffix},完毕请输数字 0 ！"
    while (true)
    do
        read modid
        if [[ "${modid}" -eq 0 ]]
        then
            info "MOD删除完毕！"
            break
        else
            Truemodid
            Delmodfromshard
        fi
    done
}
List_manager(){
    echo -e "\e[92m你要设置：1.管理员  2.黑名单  3.白名单 ? \e[0m\c"
    read list
    case "${list}" in
        1)
        listfile="alist.txt"
        listname="管理员"
        ;;
        2)
        listfile="blist.txt"
        listname="黑名单"
        ;;
        3)
        listfile="wlist.txt"
        listname="白名单"
        ;;
        *)
        error "输入有误，请输入数字[1-3]"
        ;;
    esac
    echo -e "\e[92m你要：1.添加${listname}" 2.移除${listname}" ? \e[0m\c"
    read addordel
    case "${addordel}" in
        1)
        Addlist
        ;;
        2)
        Dellist
        ;;
    esac
}
Addlist(){
    echo -e "\e[92m请输入你要添加的KLEIID（KU_XXXXXXX）：(添加完毕请输入数字 0 )\e[0m"
    while (true)
    do
        read kleiid
        if [[ "${kleiid}" -eq 0 ]]
        then
            info "添加完毕！"
            break
        else
            if [[ $(grep "${kleiid}" -c "${data_dir}/${listfile}") -gt 0 ]]
            then
                info "名单${kleiid}已经存在！"
            else
                echo "${kleiid}" >> "${data_dir}/${listfile}"
                info "名单${kleiid}已添加！"
            fi
        fi
    done
}
Dellist(){
    while (true)
    do
        echo "=========================================================================="
        grep -n "^" "${data_dir}/${listfile}"
        echo -e "\e[92m请输入你要移除的KLEIID${Red_font_prefix}[编号]${Font_color_suffix}，删除完毕请输入数字 0 \e[0m"
        read kleiid
        if [[ "${kleiid}" -eq 0 ]]
        then
            info "移除完毕！"
            break
        else
            sed -i "${kleid}d" "${data_dir}/${listfile}"
            info "名单已移除！"
        fi
    done
}
Cluster_manager(){
    cluster_str="删除"
    Choose_exit_cluster
    if [ ! -z $cluster ]
    then
        mycluster=$cluster
        Get_current_cluster
        if [[ $mycluster != $cluster ]]
        then
            rm -rf "${dst_base_dir}/${cluster}" && info "存档【${cluster}】已删除！"
        else
            error "存档【$cluster】正在运行，请关闭后再删除！！"
        fi
    fi
}
Auto_update(){
    Get_single_shard
    if tmux has-session -t DST_"${shard}" > /dev/null 2>&1
    then       
        if tmux has-session -t Auto_update > /dev/null 2>&1
        then
            info "自动更新进程已在运行，即将跳转。。。退出请按Ctrl + B松开再按D！"
            tmux attach-session -t Auto_update
            sleep 1
        else
            tmux new-session -s Auto_update -d "bash $HOME/dstserver.sh au"
            info "自动更新已开启！即将跳转。。。退出请按Ctrl + B松开再按D!"
            sleep 1
            tmux attach-session -t Auto_update
        fi
    else
        tip "${shard}世界未开启或已异常退出！无法启用自动更新！"
    fi
}
Show_players(){
    Get_single_shard
    if tmux has-session -t DST_"${shard}" > /dev/null 2>&1
    then
        if tmux has-session -t Show_players > /dev/null 2>&1
        then
            info "即将跳转。。。退出请按Ctrl + B松开再按D！"
            tmux attach-session -t Show_players
            sleep 1
        else
            tmux new-session -s Show_players -d "bash $HOME/dstserver.sh sp"
            tmux split-window -t Show_players
            tmux send-keys -t Show_players:0 "bash $HOME/dstserver.sh sa" C-m
            info "进程已开启。。。请再次执行命令进入!"
        fi
    else
        tip "${shard}世界未开启或已异常退出！无法启用玩家日志后台！"
    fi
}
Update_DST_Check(){
    # data from klei forums
    info "正在检查游戏服务端是否有更新 。。。 请稍后 。。。"
    currentbuild=$(cat "${dst_server_dir}/version.txt")
    availablebuild=$(curl -s "${my_api_link}/" | sed 's/[ \t]*$//g' | tr -cd [0-9])
    if [[ "${currentbuild}" != "${availablebuild}" && "${availablebuild}" != "" ]]
    then
        dst_need_update=true
        dst_need_update_str="需要更新"
    else
        dst_need_update=false
        dst_need_update_str="无需更新"
    fi
}
Force_update(){
    echo -e "\e[92m是否强制更新游戏服务端：1.是  2.否 ? \e[0m\c"
    read force
    case $force in
        1)
        Get_server_status
        cur_serveropen=${serveropen}
        Reboot_announce
        Close_server
        Install_Game
        Update_DST_Check
        if [[ "${cur_serveropen}" == "true" ]]
        then
            Run_server
        fi
        ;;
        *)
        Update_DST
        ;;
    esac
}
Update_DST(){
    Get_server_status
    cur_serveropen=${serveropen}
    Update_DST_Check
    if [[ "${dst_need_update}" == "true" ]]
    then
        info "更新可用(${currentbuild}===>${availablebuild})！即将执行更新..."
        Reboot_announce
        Close_server
        Install_Game
        Update_DST_Check
    else
        tip "无可用更新！当前版本（${availablebuild}）"
    fi
    if [[ "${cur_serveropen}" == "true" && "${dst_need_update}" == "true" ]]
    then
        Run_server
    fi
}
###################################################################
Reboot_server(){
    info "服务器重启中。。。请稍候。。。"
    Reboot_announce
    Close_server
    Run_server
}
exchangestatus(){
    if [ ! -f "${server_conf_file}" ]
    then
        touch "${server_conf_file}"
    fi
    if [ $(grep "serveropen" -c "${server_conf_file}") -eq 0 ]
    then
        echo "serveropen=$1" >> "${server_conf_file}"
    else
        str=$(grep "serveropen" "${server_conf_file}")
        sed -i "s/${str}/serveropen=$1/g" "${server_conf_file}"
    fi
}
Run_server(){
    Get_current_cluster
    if [ -d "$dst_base_dir/${cluster}" ]
    then
        Get_shard_array
        exchangestatus true
        Default_mod
        Set_list
        Update_DST_MOD_Check
        Del_need_update_mod_folder
        Start_shard
        info "服务器开启中。。。请稍候。。。"
        sleep 5
        Start_check
    else
        error "存档【${cluster}】已被删除或损坏！服务器无法开启！"
    fi
}
Reboot_announce(){
    Get_shard_array
    for shard in ${shardarray}
    do
        if tmux has-session -t DST_"${shard}" > /dev/null 2>&1
        then
            tmux send-keys -t DST_"${shard}" "c_announce(\"${shard}世界服务器因改动或更新需要重启，预计耗时三分钟，给你带来的不便还请谅解！\")" C-m
        fi
        sleep 5
    done
}
Start_server(){
    info "本操作将会关闭已开启的服务器 ..."
    Close_server
    Exit_auto_update
    echo -e "\e[92m是否新建存档: [y|n] (默认: y): \e[0m\c"
    read yn
    [[ -z "${yn}" ]] && yn="y"
    unset new_cluster
    if [[ "${yn}" == [Yy] ]]
    then
        echo -e "\e[92m请输入新建存档名称：（不要包含中文、符号和空格）\e[0m"
        read cluster
        if [ -d "${dst_base_dir}/${cluster}" ]
        then
            tip "${cluster}存档已存在！是否删除已有存档：1.是  2.否？ "
            read ifdel
            if [[ "$ifdel" -eq 1 ]]
            then
                rm -rf "${dst_base_dir}/${cluster}"
            else
                rm -rf "${dst_base_dir}/${cluster}/cluster.ini"
            fi
        fi
        mkdir -p "${dst_base_dir}/${cluster}"
        Set_cluster
        Set_token
        new_cluster="true"
    else
        cluster_str="开启"
        Choose_exit_cluster
        [ -z $cluster ] && exit 0
    fi
    echo "cluster=${cluster}" > "${server_conf_file}"
    echo "shardarray=${shardarray}" >> "${server_conf_file}"
    if [[ "${new_cluster}" == "true" ]]
    then
        Addshard
    fi
    Import_cluster
    Run_server
}
Addshard(){
    while (true)
    do
        echo -e "\e[92m请选择要添加的世界：1.地面世界  2.洞穴世界  3.添加完成选我\n          快捷设置：4.熔炉MOD选我  5.挂机MOD房选我\n\e[0m\c"
        read shardop
        case "${shardop}" in
            1)
            Addforest;;
            2)
            Addcaves;;
            3)
            break;;
            4)
            Forgeworld
            break;;
            5)
            AOGworld
            break;;
            *)
            error "输入有误，请输入[1-5]！！！";;
        esac
    done
}
Shardconfig(){
    tip "只能有一个主世界！！！熔炉MOD房和挂机MOD房只能选主世界！！！"
    info "已创建${shardtype}[$sharddir]，这是一个：1. 主世界   2. 附从世界？ "
    read ismaster
    if [ "${ismaster}" -eq 1 ]
    then
        shardmaster="true"
		shardid=1
    else
        shardmaster="false"
		# 非主世界采用随机数，防止冲突
		shardid=$RANDOM
    fi
    cat > "${dst_base_dir}/${cluster}/$sharddir/server.ini"<<-EOF
[NETWORK]
server_port = $((10997 + $idnum))


[SHARD]
is_master = $shardmaster
name = ${shardname}${idnum}
id = $shardid


[ACCOUNT]
encode_user_path = true


[STEAM]
master_server_port = $((27016 + $idnum))
authentication_port = $((8766 + $idnum))
EOF
}
Getidnum(){
    idnum=$(($(ls -l "${dst_base_dir}/${cluster}" | grep ^d | awk '{print $9}' | grep -c ^) + 1))
}
Createsharddir(){
    sharddir="${shardname}${idnum}"
    mkdir -p "${dst_base_dir}/${cluster}/$sharddir"
}
Addcaves(){
    shardtype="洞穴世界"
    shardname="Caves"
    Getidnum
    Createsharddir
    Shardconfig
    Set_world
}
Addforest(){
    shardtype="地面世界"
    shardname="Forest"
    Getidnum
    Createsharddir
    Shardconfig
    Set_world
}
Forgeworld(){
    shardtype="熔炉MOD房"
    shardname="Forge"
    Wmodid="1531169447"
    Wconfigfile="lavaarena.lua"
    Getidnum
    Createsharddir
    Shardconfig
    Set_world
}
AOGworld(){
    shardtype="挂机MOD房"
    shardname="AOG"
    Wmodid="1210706609"
    Wconfigfile="aog.lua"
    Getidnum
    Createsharddir
    Shardconfig
    Set_world
}
# 导入存档
Import_cluster(){
    Default_mod
    if [ ! -f "${dst_base_dir}/${cluster}/cluster_token.txt" ]
    then
        Set_token
    fi
}
Choose_exit_cluster(){
    echo -e "\e[92m已有存档[退出输入数字 0]：\e[0m"
    ls -l "${dst_base_dir}" | awk '/^d/ {print $NF}' | grep -v downloadmod > "/tmp/dirlist.txt"
    index=1
    for dirlist in $(cat "/tmp/dirlist.txt")
    do
        if [ $(ls -l "${dst_base_dir}/${dirlist}" | grep -c ^d) -gt 0 ]
        then
            if [ -f "${dst_base_dir}/${dirlist}/cluster.ini" ]
            then
                cluster_name_str=$(cat "${dst_base_dir}/${dirlist}/cluster.ini" | grep '^cluster_name =' | cut -d " " -f3)
            fi
            if [[ "$cluster_name_str" == "" ]]
            then
                cluster_name_str="不完整或已损坏的存档"
            fi
        else
            cluster_name_str="不完整或已损坏的存档"
        fi
        echo "${index}. ${dirlist}：${cluster_name_str}"
        let index++
    done
    echo -e "\e[92m请输入你要${cluster_str}的存档${Red_font_prefix}[编号]${Font_color_suffix}：\e[0m\c"
    read listnum
    unset cluster
    if [ $listnum -ne 0 ]
    then
        cluster=$(cat "/tmp/dirlist.txt" | head -n "${listnum}" | tail -n 1)
    fi
}
Close_server(){
    tip "正在关闭已开启的服务器（有的话） ..."
    unset nodone
    for shard in ${shardarray}
    do
        if tmux has-session -t DST_"${shard}" > /dev/null 2>&1
        then
            tmux send-keys -t DST_"${shard}" "c_shutdown(true)" C-m
            exchangestatus false
            nodone="true"
        else
            info "${shard}世界服务器未开启！"
        fi
    done
    if [[ "$nodone" == "true" ]]
    then
        for shard in ${shardarray}
        do
            while (true)
            do
                if ! tmux has-session -t DST_"${shard}" > /dev/null 2>&1
                then
                    info "${shard}世界服务器已关闭！"
                    break
                fi
            done
        done
        for shard in ${shardarray}
        do
            tmux kill-session -t DST_"${shard}" > /dev/null 2>&1
        done
    fi
    Exit_show_players
}
Exit_auto_update(){
    if tmux has-session -t Auto_update > /dev/null 2>&1
    then
        tmux kill-session -t Auto_update > /dev/null 2>&1
    fi
    info "自动更新进程已停止运行 ..."
}
Exit_show_players(){
    if tmux has-session -t Show_players > /dev/null 2>&1
    then
        tmux kill-session -t Show_players > /dev/null 2>&1
    fi
    info "玩家记录后台进程已停止运行 ..."
}
Set_cluster(){
    if [ -f "${dst_base_dir}/${cluster}/cluster.ini" ]
    then
        rm -rf "${dst_base_dir}/${cluster}/cluster.ini"
    fi
    while (true)
    do
        clear
        echo -e "\e[92m=============【存档槽：${cluster}】===============\e[0m"
        index=1
        cat "${dst_cluster_file}" | grep -v "script_ver" | while read line
        do
            ss=(${line})
            if [ "${ss[4]}" != "readonly" ]
            then
                if [ "${ss[4]}" == "choose" ]
                then
                    for ((i=5;i<${#ss[*]};i++))
                    do
                        if [ "${ss[$i]}" == "${ss[1]}" ]
                        then
                            value=${ss[$i+1]}
                        fi
                    done
                else
                    # 处理替代空格的#号
                    value=$(echo "${ss[1]}" | sed 's/#/ /g')
                fi
                if [ "${index}" -lt 10 ]
                then
                    echo -e "\e[33m[ ${index}] ${ss[2]}：${value}\e[0m"
                else
                    echo -e "\e[33m[${index}] ${ss[2]}：${value}\e[0m"
                fi
            fi
            index=$((${index} + 1))
        done
        echo -e "\e[92m===============================================\e[0m"
        echo -e "\e[31m要开熔炉MOD房的要先在这里修改游戏模式为熔炉！！！\e[0m"
        echo -e "\e[92m===============================================\e[0m"
        unset cmd
        while (true)
        do
            if [[ "${cmd}" == "" ]]
            then
                echo -e "\e[92m请选择你要更改的选项(修改完毕输入数字 0 确认修改并退出)：\e[0m\c"
                read cmd
            else
                break
            fi
        done
        case "${cmd}" in
            0)
            info "更改已保存！"
               break
               ;;
            *)
            changelist=($(sed -n ${cmd}p "${dst_cluster_file}"))
            if [ "${changelist[4]}" = "choose" ]
            then
                echo -e "\e[92m请选择${changelist[2]}：\e[0m\c"
                index=1
                for ((i=5;i<${#changelist[*]};i=$i+2))
                do
                    echo -e "\e[92m${index}.${changelist[$[$i + 1]]}  \e[0m\c"
                    index=$((${index} + 1))
                done
                echo -e "\e[92m: \e[0m\c"
                read changelistindex
                listnum=$(($((${changelistindex} - 1)) * 2))
                changelist[1]=${changelist[$[$listnum + 5]]}
            else
                echo -e "\e[92m请输入${changelist[2]}：\e[0m\c"
                read changestr
                # 处理空格
                changestr=$(echo "${changestr}" | sed 's/ /#/g')
                changelist[1]=${changestr}
            fi
            changestr=${changelist[@]}
            sed -i "${cmd}c ${changestr}" ${dst_cluster_file}
            ;;
        esac
    done
    type=([STEAM] [GAMEPLAY] [NETWORK] [MISC] [SHARD])
    for (( i=0; i<${#type[*]}; i++ ))
    do
        echo "${type[i]}" >> "${dst_base_dir}/${cluster}/cluster.ini"
        cat "${dst_cluster_file}" | grep -v "script_ver" | while read lc
        do
            lcstr=($lc)
            if [ "${lcstr[3]}" == "${type[i]}" ]
            then
                if [ "${lcstr[1]}" == "无" ]
                then
                    lcstr[1]=""
                fi
                # 还原空格
                value_str=$(echo "${lcstr[1]}" | sed 's/#/ /g')
                echo "${lcstr[0]} = ${value_str}" >> "${dst_base_dir}/${cluster}/cluster.ini"
            fi
        done
        echo "" >> "${dst_base_dir}/${cluster}/cluster.ini"
    done
}

Set_token(){
    if [ -f "${dst_token_file}" ]
    then
        default_token=$(cat "${dst_token_file}")
    else
        default_token="pds-g^KU_6yNrwFkC^9WDPAGhDM9eN6y2v8UUjEL3oDLdvIkt2AuDQB2mgaGE="
    fi
    info "当前预设的服务器令牌：\n ${default_token}"
    echo -e "\e[92m是否更改？ 1.是  2.否 : \e[0m\c"
    read ch
    if [ $ch -eq 1 ]
    then
        tip "请输入或粘贴你的令牌到此处："
        read mytoken
        mytoken=$(echo "${mytoken}" | sed 's/ //g')
        echo "${mytoken}" > "${dst_token_file}"
        info "已更改服务器默认令牌！"
    else
        echo "${default_token}" > ${dst_token_file}
    fi
    cat "${dst_token_file}" > "${dst_base_dir}/${cluster}/cluster_token.txt"
}
Set_list(){
    if [ ! -f "${data_dir}/alist.txt" ]
    then
        touch "${data_dir}/alist.txt"
    fi
    if [ ! -f "${data_dir}/blist.txt" ]
    then
        touch "${data_dir}/blist.txt"
    fi
    if [ ! -f "${data_dir}/wlist.txt" ]
    then
        touch "${data_dir}/wlist.txt"
    fi
    cat "${data_dir}/alist.txt" > "${dst_base_dir}/${cluster}/adminlist.txt"
    cat "${data_dir}/blist.txt" > "${dst_base_dir}/${cluster}/blocklist.txt"
    cat "${data_dir}/wlist.txt" > "${dst_base_dir}/${cluster}/whitelist.txt"
}
Set_world(){
    if [[ "${shardtype}" == "熔炉MOD房" || "${shardtype}" == "挂机MOD房" ]]
    then
        cat "${data_dir}/${Wconfigfile}" > "${dst_base_dir}/${cluster}/${sharddir}/leveldataoverride.lua"
        info "${shardtype}世界配置已写入！"
        info "正在检查${shardtype}MOD是否已下载安装 。。。"
        if [ -f "${dst_server_dir}/mods/workshop-${Wmodid}/modinfo.lua" ]
        then
            info "${shardtype}MOD已安装 。。。"
        else
            tip "${shardtype}MOD未安装 。。。即将下载 。。。"
            echo "ServerModSetup(\"${Wmodid}\")" > "${dst_server_dir}/mods/dedicated_server_mods_setup.lua"
            Download_MOD
        fi
        if [ -f "${dst_server_dir}/mods/workshop-${Wmodid}/modinfo.lua" ]
        then
            Default_mod
            modid=${Wmodid}
            Get_shard_array
            Addmodfunc
            info "${shardtype}MOD已启用 。。。"
        else
            tip "${shardtype}MOD启用失败，请自行检查原因或反馈 。。。"
        fi
    else
        info "是否修改${shardtype}[${sharddir}]配置？：1.是 2.否（默认为上次配置）"
        read wc
        configure_file="${data_dir}/${shardname}leveldata.txt"
        data_file="${dst_base_dir}/${cluster}/${sharddir}/leveldataoverride.lua"
        if [ "${wc}" -ne 2 ]
        then
            Set_world_config
        fi
        Write_in ${shardname}
    fi
}
Set_world_config(){
    while (true)
    do
        clear
        index=1
        linenum=1
        list=(environment source food animal monster)
        liststr=(
        ================================世界环境================================
        ==================================资源==================================
        ==================================食物==================================
        ==================================动物==================================
        ==================================怪物==================================
        )
        for ((j=0;j<${#list[*]};j++))
        do
            echo -e "\n\e[92m${liststr[$j]}\e[0m"
            cat "${configure_file}" | grep -v "script_ver" | while read line
            do
                ss=(${line})
                if [ "${#ss[@]}" -gt 4 ]
                then
                    if [ "${index}" -gt 3 ]
                    then
                        printf "\n"
                        index=1
                    fi
                    for ((i=4;i<${#ss[*]};i++))
                    do
                        if [ "${ss[$i]}" == "${ss[1]}" ]
                        then
                            value=${ss[$i+1]}
                        fi
                    done
                    if [ "${list[$j]}" == "${ss[2]}" ]
                    then
                        if [ "${linenum}" -lt 10 ]
                        then
                            printf "%-21s\t" "[ ${linenum}]${ss[3]}: ${value}"
                        else
                            printf "%-21s\t" "[${linenum}]${ss[3]}: ${value}"
                        fi
                        index=$((${index} + 1))
                    fi
                fi
                linenum=$((${linenum} + 1))
            done
        done
        printf "\n"
        unset cmd
        while (true)
        do
            if [[ "${cmd}" == "" ]]
            then
                echo -e "\e[92m请选择你要更改的选项(修改完毕输入数字 0 确认修改并退出)： \e[0m\c"
                read cmd
            else
                break
            fi
        done
        case "${cmd}" in
            0)
            info "更改已保存！"
            break
            ;;
            *)
            changelist=($(sed -n "${cmd}p" "${configure_file}"))
               echo -e "\e[92m请选择${changelist[3]}： \e[0m\c"
               index=1
               for ((i=4;i<${#changelist[*]};i=$i+2))
               do
                   echo -e "\e[92m${index}.${changelist[$[$i + 1]]}   \e[0m\c"
                   index=$[${index} + 1]
               done
               echo -e "\e[92m: \e[0m\c"
               read changelistindex
               listnum=$[${changelistindex} - 1]*2
               changelist[1]=${changelist[$[$listnum + 4]]}
               changestr="${changelist[@]}"
               sed -i ${cmd}c "${changestr}" "${configure_file}";;
        esac
    done
}
Write_in(){
    data_num=$[$(grep -n "^" "${configure_file}" | tail -n 1 | cut -d : -f1) - 1]
    cat "${data_dir}/${1}start.lua" > "${data_file}"
    index=1
    cat "${configure_file}" | grep -v "script_ver" | while read line
    do
        ss=(${line})
        if [ "${index}" -lt "${data_num}" ]
        then
            char=","
        else
            char=""
        fi
        index=$[${index} + 1]
        if [[ "${ss[1]}" == "highlyrandom" ]]
        then
            str="${ss[0]}=\"highly random\"${char}"
        else
            str="[\"${ss[0]}\"]=\"${ss[1]}\"${char}"
        fi
        echo "    ${str}" >> "${data_file}"
    done
    cat "${data_dir}/${1}end.lua" >> "${data_file}"
}
Default_mod(){
    Get_shard_array
    for shard in ${shardarray}
    do
        if [ ! -f "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua" ]
        then
            echo 'return {
}' > "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua"
        fi
    done
}
Setup_mod(){
    if [ -f "${data_dir}/mods_setup.lua" ]
    then
        rm -rf "${data_dir}/mods_setup.lua"
    fi
    touch "${data_dir}/mods_setup.lua"
    Get_single_shard
    dir=$(cat "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua" | grep "workshop" | cut -f2 -d '"' | cut -d "-" -f2)
    for moddir in ${dir}
    do
        if [[ $(grep "${moddir}" -c "${data_dir}/mods_setup.lua") = 0 ]]
        then
            echo "ServerModSetup(\"${moddir}\")" >> "${data_dir}/mods_setup.lua"
        fi
    done
    cp "${data_dir}/mods_setup.lua" "${dst_server_dir}/mods/dedicated_server_mods_setup.lua"
    info "添加启用的MODID到MOD更新配置文件！"
}
Start_shard(){
    if [[ "$MOD_update" == "true" ]]
    then
        Setup_mod
    fi
    cd "${dst_server_dir}/bin"
    for shard in ${shardarray}
    do
        Save_log
        unset TMUX
        tmux new-session -s DST_"${shard}" -d "${dst_bin_cmd}" -persistent_storage_root "${dst_conf_basedir}" -cluster "${cluster}" -shard "${shard}"
    done
}
Save_log(){
    cur_day=$(date "+%F")
    if [ ! -d "$log_save_dir/$cur_day" ]
    then
        mkdir -p "$log_save_dir/$cur_day"
    fi
    info "【${shard}】旧的日志已备份到【$log_save_dir】。"
    cur_time=$(date "+%T")
    echo "$(date)" >> "$log_save_dir/$cur_day/server_chat_log_backup_${cluster}_${shard}_${cur_time}.txt"
    cp "$dst_base_dir/$cluster/$shard/server_chat_log.txt" "$log_save_dir/$cur_day/server_chat_log_backup_${cluster}_${shard}_${cur_time}.txt" >/dev/null 2>&1
    echo "$(date)" >> "$log_save_dir/$cur_day/server_log_backup_${cluster}_${shard}_${cur_time}.txt"
    cp  "$dst_base_dir/$cluster/$shard/server_log.txt" "$log_save_dir/$cur_day/server_log_backup_${cluster}_${shard}_${cur_time}.txt" >/dev/null 2>&1
}
Pid_kill(){
    kill $(ps -ef | grep -v grep | grep $1 | awk '{print $2}')
}
Start_check(){
    Get_shard_array
    rm "${ays_log_file}" >/dev/null 2>&1
    touch "${ays_log_file}"
    shardnum=0
    for shard in $shardarray
    do
        unset TMUX
        tmux new-session -s DST_"${shard}"_log -d "bash $HOME/dstserver.sh ay $shard"
        shardnum=$[$shardnum + 1]
    done
    ANALYSIS_SHARD=0
    any_log_index=1
    unset any_old_line
    while (true)
    do
        if [ "$ANALYSIS_SHARD" -lt $shardnum ]
        then
            anyline=$(sed -n ${any_log_index}p ${ays_log_file})
            if [[ "$anyline" != "" && "$anyline" != "$any_old_line" ]]
            then
                any_log_index=$(($any_log_index + 1))
                any_old_line=$anyline
                if [ $(echo "$anyline" | grep -c ANALYSISLOGDONE) -gt 0 ]
                then
                    ANALYSIS_SHARD=$(($ANALYSIS_SHARD + 1))
                else
                    info "$anyline"
                fi
            fi
        else
            break
        fi
    done
    # 清空需要更新的mod列表
    rm "${data_dir}/needupdatemodlist.txt" > /dev/null 2>&1
}
printf_and_save_log(){
    printf "%-7s：%s\n" "$1" "$2" | tee -a $3
}
Analysis_log(){
    log_file="${dst_base_dir}/${cluster}/$1/server_log.txt"
    grep -v "script_ver" ${log_arr_str} > "${data_dir}/log_arr_str_$1.txt"
    if [ -f "$log_file" ]
    then
        RES="nodone"
        retrytime=0
        while [ $RES == "nodone" ]
        do
            while read line
            do
                echo $line
                line_0=$(echo $line | cut -d '@' -f1)
                line_1=$(echo $line | cut -d '@' -f2)
                line_2=$(echo $line | cut -d '@' -f3)
                echo "$line_0 $line_1 $line_2"
                if [ $(grep "$line_1" -c $log_file) -gt 0 ]
                then
                    case "$line_0" in
                        1)
                        printf_and_save_log $1 $line_2 "$ays_log_file"
                        RES="done"
                        printf_and_save_log $1 "ANALYSISLOGDONE" "$ays_log_file"
                        break;;
                        2)
                        retrytime=$[$retrytime + 1]
                        if [ $retrytime -le 5 ]
                        then
                            printf_and_save_log $1 "连接失败！第$retrytime次连接重试！" "$ays_log_file"
                        else
                            printf_and_save_log "$1" "$line_2" "$ays_log_file"
                            num=$(grep "$line_2" -n "${data_dir}/log_arr_str_$1.txt" | cut -d ":" -f1)
                            sed -i "${num}d" "${data_dir}/log_arr_str_$1.txt"
                            RES="done"
                            printf_and_save_log $1 "ANALYSISLOGDONE" "$ays_log_file"
                        fi
                        break;;
                        *)
                        echo "$1:$line_2" >> "$ays_log_file"
                        num=$(grep "$line_2" -n "${data_dir}/log_arr_str_$1.txt" | cut -d ":" -f1)
                        sed -i "${num}d" "${data_dir}/log_arr_str_$1.txt"
                        break;;
                    esac
                fi
            done < "${data_dir}/log_arr_str_$1.txt"
        done
    fi
}
#############################################################################
First_run_check(){
    Open_swap
    Mkdstdir
    if [ ! -f "${dst_server_dir}/version.txt" ]
    then
        info "检测到你是首次运行脚本，需要进行必要的配置，所需时间由服务器带宽决定，大概一个小时 ..."
        Install_Dependency
        Install_Steamcmd
        info "安装游戏服务端 ..."
        Install_Game
        Fix_steamcmd
        if [ ! -f "${dst_server_dir}/version.txt" ]
        then
            error "安装失败，请重试！多次重试仍无效请反馈!" && exit 1
        fi
        info "首次运行配置完毕，你可以创建新的世界了。"
    fi
}
# open swap
Open_swap(){
    if [ ! -f "/swapfile" ]
    then
        info "创建虚拟内存 ..."
        sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
        sudo mkswap /swapfile
        sudo chmod 0600 /swapfile
        # 开机自启
        sudo chmod 0666 /etc/fstab
        echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
        sudo chmod 0644 /etc/fstab
    fi
    if [ $(free -m | grep -i swap | tr -cd [0-9]) == "000" ]
    then
        sudo swapon /swapfile    
        info "虚拟内存已开启！"
    fi
}
# 创建文件夹
Mkdstdir(){
    mkdir -p "${HOME}/steamcmd"
    mkdir -p "${dst_server_dir}"
    mkdir -p "${DST_conf_basedir}/${DST_conf_dirname}"
    mkdir -p "${data_dir}"
    mkdir -p "${mod_cfg_dir}"
}
# 检查当前系统信息
Check_sys(){
    if [[ -f "/etc/redhat-release" ]]
    then
        release="centos"
    elif cat /etc/issue | grep -q -E -i "debian"
    then
        release="debian"
    elif cat /etc/issue | grep -q -E -i "ubuntu"
    then
        release="ubuntu"
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"
    then
        release="centos"
    elif cat /proc/version | grep -q -E -i "debian"
    then
        release="debian"
    elif cat /proc/version | grep -q -E -i "ubuntu"
    then
        release="ubuntu"
    elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"
    then
        release="centos"
    fi
    if [[ "${release}" != "ubuntu" && "${release}" != "debian" && "${release}" != "centos" ]]
    then
        error "很遗憾！本脚本暂时只支持Debian7+和Ubuntu12+和CentOS7+的系统！" && exit 1
    fi
    bit=`uname -m`
}
# 安装依赖库和必要软件
Install_Dependency(){
    info "安装DST所需依赖库及软件 ..."
    if [[ "${release}" != "centos" ]]
    then
        if [[ "${bit}" = "x86_64" ]]
        then
            sudo dpkg --add-architecture i386
                sudo apt update
                sudo apt install -y lib32gcc1 libstdc++6 libstdc++6:i386 libcurl4-gnutls-dev:i386 tmux wget lua5.2 git openssl libssl-dev
        else
            sudo apt update
            sudo apt install -y libstdc++6 libcurl4-gnutls-dev tmux wget lua5.2 git openssl libssl-dev
        fi
    else
        if [[ "${bit}" = "x86_64" ]]
        then
            sudo yum install -y tmux glibc.i686 libstdc++ libstdc++.i686 libcurl.i686 wget lua5.2 git openssl openssl-devel
        else
            sudo yum install -y wget tmux libstdc++ libcurl lua5.2 git openssl openssl-devel
        fi
     fi
}
# Install steamcmd
Install_Steamcmd(){
    wget "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
    tar -xzvf steamcmd_linux.tar.gz -C "${HOME}/steamcmd"
    chmod +x "${HOME}/steamcmd/steamcmd.sh"
    rm steamcmd_linux.tar.gz
}
# Install DST Dedicated Server
Install_Game(){
    cd "${HOME}/steamcmd" || exit 1
    ./steamcmd.sh +login "anonymous" +force_install_dir "${dst_server_dir}" +app_update "343050" validate +quit
}
# 修复SteamCMD [S_API FAIL] SteamAPI_Init() failed;
Fix_steamcmd(){
    info "修复Steamcmd可能存在的依赖问题 ..."
    mkdir -p "${HOME}/.steam/sdk32"
    cp -v "${HOME}/steamcmd/linux32/steamclient.so" "${HOME}/.steam/sdk32/steamclient.so"
    # fix lib for centos
    if [[ "${release}" == "centos" ]] && [ ! -f "${dst_server_dir}/bin/lib32/libcurl-gnutls.so.4" ]
    then
        info "libcurl-gnutls.so.4 missing ... create a lib link."
        ln -s "/usr/lib/libcurl.so.4" "${dst_server_dir}/bin/lib32/libcurl-gnutls.so.4"
    fi
}
##########################################################################
# Show change log
Show_changelog(){
    echo -e "\e[33m============================脚本更新说明====================================\e[0m"
    wget "${update_link}/.dstscript/changelog.txt" -O "/tmp/changelog.txt" > /dev/null 2>&1
    datelog=$(cat "/tmp/changelog.txt" | head -n 1)
    cat "/tmp/changelog.txt" | grep -A 20 "更新日志 ${datelog}"
    echo -e "\e[33m============================================================================\e[0m"
    sleep 3
}
# 脚本更新
Update_script(){
    info "正在检查脚本是否有更新 。。。 请稍后 。。。"
    wget "${update_link}/.dstscript/filelist.txt" -O "/tmp/filelist.txt" > /dev/null 2>&1
    for file in $(cat "/tmp/filelist.txt" | cut -d ":" -f1)
    do
        new_ver=$(cat "/tmp/filelist.txt" | grep "${file}" | cut -d ":" -f2)
        if [[ "${file}" != "dstserver.sh" ]]
        then
            truefile=".dstscript/${file}"
        else
            truefile=${file}
        fi
        if [ -f "${HOME}/${truefile}" ]
        then
            cur_ver=$(cat "${HOME}/${truefile}" | grep "script_ver=" | head -n 1 | cut -d '"' -f2)
        else
            cur_ver="000"
        fi
        [[ -z "${new_ver}" ]] && new_ver=${cur_ver}
        if [[ "${new_ver}" != "${cur_ver}" ]]
        then
            info "${file} 发现新版本[ ${new_ver} ]，更新中..."
            wget "${update_link}/${truefile}" -O "${HOME}/${truefile}" > /dev/null 2>&1
            chmod +x "${HOME}/dstserver.sh"
            info "${file} 已更新为最新版本[ ${new_ver} ] !"
            if [[ "${file}" == "dstserver.sh" ]]
            then
                need_exit="true"
            fi
            if [[ "${file}" == "updatelib.txt" ]]
            then
                tip "本次更新需要更新依赖 。。。请稍候 。。。"
                Install_Dependency >/dev/null 2>&1
            fi
            need_update="true"
        fi
    done
    if [[ "${need_update}" == "true" ]]
    then
        Show_changelog
    fi
    if [[ "${need_exit}" == "true" ]]
    then
        tmux kill-session -t Auto_update > /dev/null 2>&1
        tip "因脚本已更新，自动更新进程已退出，如需要请重新开启！"
        exit 0
    fi
}
# MOD update check
Update_DST_MOD_Check(){
    info "检查启用的创意工坊MOD是否有更新 ..."
    MOD_update="false"
    rm "${data_dir}/needupdatemodlist.txt" > /dev/null 2>&1
    touch "${data_dir}/needupdatemodlist.txt"
    Get_single_shard
    for modid in $(grep '^  \["workshop-' "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua" | cut -d '"' -f2 | cut -d '-' -f2)
    do
        mod_new_ver=$(curl -s "${my_api_link}/?type=mod&modid=${modid}" | sed 's/[ \t]*$//g')
        if [ -f "${dst_server_dir}/mods/workshop-${modid}/modinfo.lua" ]
        then
            echo "fuc = \"getver\"" > "${data_dir}/modinfo.lua"
            cat "${dst_server_dir}/mods/workshop-${modid}/modinfo.lua" >> "${data_dir}/modinfo.lua"
            cd "${data_dir}"
            mod_cur_ver=$(lua modconf.lua)
            echo "fuc=\"getname\"" > "${data_dir}/modinfo.lua"
            cat "${dst_server_dir}/mods/workshop-${modid}/modinfo.lua" >> "${data_dir}/modinfo.lua"
            cd "${data_dir}"
            cur_mod_name=$(lua modconf.lua)
        else
            mod_cur_ver=000
            cur_mod_name="未知名称"
        fi
        if [[ "${mod_new_ver}" != "" && "${mod_cur_ver}" != "" && "${mod_new_ver}" != "nil" && "${mod_new_ver}" != "${mod_cur_ver}" ]]
        then
            info "MOD 有更新(${modid}[${cur_mod_name}][${mod_cur_ver}" ==> "${mod_new_ver}])，即将更新 ..."
            MOD_update="true"
            echo "${modid}" >> "${data_dir}/needupdatemodlist.txt"
        else
            info "MOD (${modid})[${cur_mod_name}][${mod_new_ver}] 无更新！"
        fi
    done
}
Status_keep(){
    Get_current_cluster
    Get_shard_array
    for shard in $shardarray
    do
        if ! tmux has-session -t DST_"${shard}" > /dev/null 2>&1
        then
            server_alive=false
            break
        else
            server_alive=true
        fi
    done
    if [[ $(grep "serveropen" "${server_conf_file}" | cut -d "=" -f2) == "true" &&  "${server_alive}" == "false" ]]
    then
        tip "服务器异常退出，即将重启 ..."
        Reboot_server
    fi
}
Simple_server_status(){
    cluster="无"
    unset server_on
    Get_current_cluster
    Get_shard_array
    for shard in ${shardarray}
    do
        if tmux has-session -t DST_"${shard}" > /dev/null 2>&1
        then
            server_on="${server_on}${shard}"
        fi
    done
    if tmux has-session -t Auto_update > /dev/null 2>&1
    then
        auto_on="开启"
    else
        auto_on="关闭"
    fi
    cluster_name="无"
    if [[ "${server_on}" == "" ]]
    then
        server_on="无"
    fi
    [ -f "${dst_base_dir}/${cluster}/cluster.ini" ] && cluster_name=$(cat "${dst_base_dir}/${cluster}/cluster.ini" | grep "^cluster_name" | cut -d "=" -f2)
    echo -e "\e[33m存档: ${cluster}   开启的世界：${server_on}   名称: ${cluster_name}\e[0m"
    echo -e "\e[33m自动更新维护：${auto_on}\e[0m"
}
# 清楚旧版本修改的hosts
Fix_Net_hosts(){
    sudo chmod 777 /etc/hosts
    cat > /etc/hosts<<-EOF
# Your system has configured 'manage_etc_hosts' as True.
# As a result, if you wish for changes to this file to persist
# then you will need to either
# a.) make changes to the master file in /etc/cloud/templates/hosts.redhat.tmpl
# b.) change or remove the value of 'manage_etc_hosts' in
#     /etc/cloud/cloud.cfg"or cloud-config from user-data
#
# The following lines are desirable for IPv4 capable hosts
127.0.0.1 $HOSTNAME $HOSTNAME
127.0.0.1 localhost.localdomain localhost
127.0.0.1 localhost4.localdomain4 localhost4

# The following lines are desirable for IPv6 capable hosts
::1 $HOSTNAME $HOSTNAME
::1 localhost.localdomain localhost
::1 localhost6.localdomain6 localhost6

EOF
    sudo chmod 644 /etc/hosts
}
Update_MOD(){
    Get_current_cluster
    if [ -f "${dst_base_dir}/${cluster}/${shard}/modoverrides.lua" ]
    then
        Setup_mod
        Update_DST_MOD_Check
        if [[ "${MOD_update}" == "true" ]]
        then
            Download_MOD
        fi
    else
        tip "当前存档【${cluster}】没有启用MOD或存档已损坏！"
    fi
}
Download_MOD(){
    info "正在安装/更新新添加的MOD(合集)，请稍候 。。。"
    if [ ! -d "${dst_base_dir}/downloadmod/Master" ]
    then
        mkdir -p "${dst_base_dir}/downloadmod/Master"
    fi
    if tmux has-session -t DST_MODUPDATE > /dev/null 2>&1
    then
        tmux kill-session -t DST_MODUPDATE
    fi
    Del_need_update_mod_folder
    cd "${dst_server_dir}/bin" || exit 1
    tmux new-session -s DST_MODUPDATE -d "${dst_bin_cmd}" -persistent_storage_root "${dst_conf_basedir}" -cluster downloadmod -shard Master
    sleep 3
    while (true)
    do
        if tmux has-session -t DST_MODUPDATE > /dev/null 2>&1
        then
            if [[ $(grep "Your Server Will Not Start" -c "${dst_base_dir}/downloadmod/Master/server_log.txt") -gt 0 ]]
            then
                Update_DST_MOD_Check > /dev/null 2>&1
                if [[ "${MOD_update}" == "true" ]]
                then
                    tip "因网络或不明原因MOD更新失败！请本地上传更新或重试！"
                    newmodinstalled="false"
                else
                    newmodinstalled="true"
                    info "新MOD安装/更新完毕！"              
                fi
                tmux kill-session -t DST_MODUPDATE
                rm "$data_dir/needupdatemodlist.txt" > /dev/null 2>&1
                break
            fi
        fi
    done
}
# 更新MOD在删除已存在的MOD文件夹后更新成功率更高
Del_need_update_mod_folder(){
    if [ -s "${data_dir}/needupdatemodlist.txt" ]
    then
        info "清除需要更新的MOD的旧版本以加大更新成功率 ..."
        while read line
        do
            if [ -d "${dst_server_dir}/mods/workshop-${line}" ]
            then
                rm -rf "${dst_server_dir}/mods/workshop-${line}"
            fi
        done < "${data_dir}/needupdatemodlist.txt"
        info "旧版本MOD清除完毕！"
    fi
}
Get_IP(){
	ip=$(wget -qO- -t1 -T2 ipinfo.io/ip)
	if [[ -z "${ip}" ]]; then
		ip=$(wget -qO- -t1 -T2 api.ip.sb/ip)
		if [[ -z "${ip}" ]]; then
			ip=$(wget -qO- -t1 -T2 members.3322.org/dyndns/getip)
		fi
	fi
}
Post_ipmd5(){
    Get_IP
    send_str=$(echo -n "${ip}" | openssl md5 | cut -d " " -f2)
    curl -s "${my_api_link}/?type=tongji&ipmd5string=${send_str}" > /dev/null 2>&1
    echo "$(date +%s)" > "${data_dir}/ipmd5.txt"
}
# 仅发送md5值做统计，尊重隐私，周期内只发送一次，保证流畅性
Send_md5_ip(){
    if [ ! -f "${data_dir}/ipmd5.txt" ]
    then
        Post_ipmd5
    else
        cur_time=$(date +%s)
        old_time=$(cat "${data_dir}/ipmd5.txt")
        cycle=$((${cur_time} - ${old_time}))
        # 周期为七天
        if [ $cycle -gt 604800 ]
        then
            Post_ipmd5
        fi
    fi
}
### 防止次级tmux目录出错
if [ ! -f "${data_dir}/Move_base_dir.txt" ]
then
    dst_conf_basedir="$HOME/.klei"
    dst_base_dir="${dst_conf_basedir}/${dst_conf_dirname}"
fi

# 移动根目录到隐藏目录
if [ -d "${HOME}/dstscript" ]
then
    mv "${HOME}/dstscript" "${HOME}/.dstscript"
fi
# 迁移存档根目录到显性目录
Move_base_dir(){
    if [ -d "$HOME/.klei" ]
    then
        if [ ! -f "${data_dir}/Move_base_dir.txt" ]
        then
            tip "为方便小白找到存档根目录，根目录迁移至[${dst_conf_basedir}]，不再为隐藏目录"
            info "是否现在转移现有存档，为保证数据安全这将关闭正在运行的服务器：1.是   2.否？"
            read ismove
            if [[ "$ismove" == "1" ]]
            then
                Get_shard_array
                Close_server
                info "正在转移已有存档。。。请勿中断。。。"
                mkdir -p "$HOME/Klei"      
                cp -r "$HOME/.klei/*" "$HOME/Klei/" > /dev/null 2>&1
                info "存档转移到[$HOME/Klei]。完毕！！！"
                touch "${data_dir}/Move_base_dir.txt"
                dst_conf_basedir="$HOME/Klei"
                dst_base_dir="${dst_conf_basedir}/${dst_conf_dirname}"
            else
                dst_conf_basedir="$HOME/.klei"
                dst_base_dir="${dst_conf_basedir}/${dst_conf_dirname}"
                tip "你选择了否，根目录未改变，下次运行脚本仍会提醒！！！"
            fi
            sleep 1
        fi
    else
        dst_conf_basedir="$HOME/Klei"
        dst_base_dir="${dst_conf_basedir}/${dst_conf_dirname}"
    fi
}
Move_base_dir
###
if [[ "$1" == "au" ]]; then
    while (true)
    do
        clear
        echo -e "\e[33m=====饥荒联机版独立服务器脚本自动更新及异常维护进程[Linux-Steam](${script_ver})=====\e[0m"
        info "$(date) [退出请按Ctrl + B松开再按D]"
        Update_DST
        Update_DST_MOD_Check
        if [[ "${MOD_update}" == "true" ]]
        then
            Reboot_server
        fi
        Status_keep
        info "每五分钟进行一次更新检测。。。"
        sleep 300
    done
fi
if [[ "$1" == "sp" ]]; then
    clear
    echo -e "\e[33m=====饥荒联机版独立服务器脚本当前玩家记录后台[Linux-Steam](${script_ver})=====\e[0m"
    Get_single_shard
    tail -f "${dst_base_dir}/${cluster}/${shard}/server_chat_log.txt" | cut -d " " -f2-100
fi
if [[ "$1" == "sa" ]]; then
    while (true)
    do
        clear
        echo -e "\e[33m=====饥荒联机版独立服务器脚本发送公告后台[Linux-Steam](${script_ver})=====\e[0m"
        Get_single_shard
        echo -e "\e[92m请输入你要发送的公告内容，按下回车键发送：\e[0m"
        read an
        tmux send-keys -t DST_"${shard}" "c_announce(\"$an\")" C-m
        info "公告已发送！"
        sleep 1
    done
fi
if [[ "$1" == "ay" ]]; then
    Get_current_cluster
    Analysis_log $2
    exit
fi

# Run from here
Check_sys
First_run_check
Fix_Net_hosts
Update_script
Update_DST_Check
Send_md5_ip
clear
Menu
