#!/usr/bin/env bash
log() {
	now=$(date +%Y-%m-%d:%H:%M:%S)
	echo "$now[$1]$2"
}

die() {
	log "ERROR""$1"
	exit 1
}

#搜索关键字、正则表达式
search_keywords="(logger)"
#全局排除路径
exclude_path="\.(svn|git|cloudbuild|idea|gitignore)|.*.min.js|elementUI.js"
#搜索结果导出文件名
result="search.txt"

#默认搜索文件	
DEFAULT_SEARCH_PATTERN=".*"
#默认不包含文件
DEFAULT_EXCLUDE_PATTERN="\b\B"
#默认搜索所有文件
DEFAULT_SEARCHFILE_PATTERN=".*"
#默认搜索
files=${DEFAULT_SEARCH_PATTERN}
#默认不包含
exclude_keywords=${DEFAULT_EXCLUDE_PATTERN}
#默认不包含
exclude_file=${DEFAULT_EXCLUDE_PATTERN}
#全局扫描路径
search_file=${DEFAULT_SEARCHFILE_PATTERN}
#全局排除路径
exclude_path_final=${exclude_path}
#搜索当前目录下的.*.，脚本当前路径
current_dir="$PWD"
#结果输出文件夹名称
output_dir="result"
#结果保存路径
result="${output_dir}/${result}"
[ -e "${result}" ] && rm -f ${result}
mkdir -p ${output_dir}
#开始扫描时间
a=$(date +%H%M%S)
echo -e "startTime:\t$a"
#最大线程数据
max_thread=10

#获取file数组，.*转为$PWD
if [[ "$search_file"x = "$DEFAULT_SEARCHFILE_PATTERN"x ]];then search_file="$PWD";fi
search_file=${search_file/(/''}
search_file=${search_file/).*/''}
search_file=${search_file//.\*/\*}
file_arr=(${search_file//|/ })

#参数接收以|间隔的路径 /a|/b
#if [[ x"${1}" != x ]];then file_arr=${1//|/ };fi
echo ${file_arr[@]}

#执行搜索
for sub_path in ${file_arr[@]}; do
	echo "搜索: "${sub_path}
	find ${sub_path} -type f -regextype 'posix-egrep' \( -iregex "${files}" \) -print |
		egrep -vsi "/result/" |
		egrep -vsi "^(/proc/|/sys/)" |
		egrep -vsi "${exclude_path_final}" |
		egrep -vsi "${exclude_file}" |
		xargs egrep -HsiIn "${search_keywords}" |
		egrep -vsi "${exclude_keywords}" >>${result}
	folds=$(find ${sub_path} -type f -regextype 'posix-egrep' \( -iregex "${files%%\$}\.gz$" -o -iregex "${files%%\$}\.zip$" \) -print |
		egrep -vsi ".*(\.tar\.).*" |
		egrep -vsi ".*(${exclude_path}).*" |
		egrep -vsi "${exclude_file}")
	for fold in ${folds}; do
		if [ -f"${fold}" ];then
			zcat ${fold} | egrep -si "${search_keywords}" | egrep -vsi "${exclude_keywords}" | sed "sM^M${fold}:Mg" >>${result};fi
	done
done

b=$(date +%H%M%S)
echo -e "endTime:\t$b"
#去除代码里可能存在的windows换行符
perl -pi -e 's/\r(?!\n)//g' ${result}
echo "Done"
