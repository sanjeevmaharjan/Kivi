#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
RESULTS_DIR="$SCRIPT_DIR/results"
echo "Results DIR: $RESULTS_DIR"

# mac support gdate; for linux, may need to change to date
DATE_EXEC="date"
KIVI_RUNNER="$SCRIPT_DIR/../kivi_runner.py"

declare -A ARG1_LABELS=(
    [0]="only violation"
    [1]="only non-violation"
    [2]="both"
)
declare -A ARG2_LABELS=(
    [0]="only with small scale algorithm"
    [1]="only for original scale"
    [2]="both"
)

describe() {  # $1 = label-array name, $2 = arg name
    local -n L=$1
    local parts=() v
    for v in 0 1 2; do parts+=("$v: ${L[$v]}"); done
    printf '%s %s' "$2" "$(IFS=', '; echo "${parts[*]}")"
}

usage() {
    cat <<EOF
Usage: $0 <arg1: 0|1|2> <arg2: 0|1|2>
$(describe ARG1_LABELS arg1)
$(describe ARG2_LABELS arg2)
EOF
}

[ "$#" -eq 2 ] || { usage >&2; exit 1; }

case "$1" in 0|1|2) ;; *) echo "Error: first argument must be 0, 1, or 2 (got '$1')" >&2; exit 1 ;; esac
case "$2" in 0|1|2) ;; *) echo "Error: second argument must be 0, 1, or 2 (got '$2')" >&2; exit 1 ;; esac

echo
echo "Selected:"
for i in 1 2; do
    declare -n L="ARG${i}_LABELS"
    printf '  arg%s = %s (%s)\n' "$i" "${!i}" "${L[${!i}]}"
done

# The is case scale is chosen with a log-based scale. range: 3-100.
# round it to the nearest 5-based or 2-squared number if possible.
# 0.5 3.1622776601683795
# 0.6 3.981071705534973
# 0.7 5.011872336272725
# 0.8 6.309573444801936
# 0.9 7.943282347242818
# 1.0 10.000000000000005
# 1.1 12.589254117941682
# 1.2 15.848931924611149
# 1.3 19.95262314968882
# 1.4 25.11886431509582
# 1.5 31.622776601683825
# 1.6 39.81071705534978
# 1.7 50.11872336272727
# 1.8 63.09573444801939
# 1.9 79.43282347242825
# 2.0 100.0000000000001

case_scale=(3 4 5 6 8 10 13 16 20 25 32 40 50 64 80 100)
case_id=(d1 s4 s9 s6 s3 h2 s1 h1)
count=3
# case_scale=(10)
# case_id=(s4 s1 s9)

if [ ! -d "$RESULTS_DIR" ]; then
    mkdir $RESULTS_DIR
fi
cur_per_file_all_violation="$RESULTS_DIR/perf_all_violation"
cur_per_file_all_non_violation="$RESULTS_DIR/perf_all_non_violation"

if [ $1 != 1 ] && [ $2 != 1 ]
then
	:> $cur_per_file_all_violation
fi

if [ $1 -gt 0 ] && [ $2 != 1 ]
then
	:> $cur_per_file_all_non_violation
fi

for case in "${case_id[@]}"
do
	mkdir "$RESULTS_DIR/${case}"
	cur_per_file="$RESULTS_DIR/$case/$case"
	cur_per_cn_file="$RESULTS_DIR/$case/${case}_cn"

	cur_log_base_file="$RESULTS_DIR/${case}/output_$case"
	if [ $1 != 1 ]
	then
		:> $cur_per_file
		:> $cur_log_base_file
		:> ${cur_log_base_file}_o
	fi

	if [ $1 -gt 0 ]
	then
		:> $cur_per_cn_file
		:> ${cur_log_base_file}_cn
		:> ${cur_log_base_file}_cn_o
	fi

	echo "========================="
	echo "Working on case $case"
	for i in "${case_scale[@]}"
	do
		echo "-------------------------"
		echo "Working on (case $case, scale $i)..."
		elapsed_all=0
		elapsed_all_vio=0
		elapsed_all_vio_o=0
		elapsed_all_non_vio=0
		elapsed_all_non_vio_o=0

		for j in $(seq $count)
		do
			echo "Times $j..."
			if [ $1 != 1 ] && [ $2 != 1 ]
			then
				echo "Working on violation cases"
				echo "python3 $KIVI_RUNNER -c $case -s $i >> $cur_log_base_file"
				start_time="$($DATE_EXEC -u +%s.%N)"
				python3 "$KIVI_RUNNER" -c $case -s $i >> $cur_log_base_file
				end_time="$($DATE_EXEC -u +%s.%N)"
				elapsed="$(bc <<<"$end_time-$start_time")"
				elapsed_all_vio="$(bc <<<"$elapsed+$elapsed_all_vio")"
				echo "Runtime #$j $elapsed"
			fi

			if [ $1 -gt 0 ] && [ $2 != 1 ]
			then
				echo "Working on non-violation cases"
				echo "python3 $KIVI_RUNNER -c $case -s $i -cn >> ${cur_log_base_file}_cn"
				start_time="$($DATE_EXEC -u +%s.%N)"
				python3 "$KIVI_RUNNER" -c $case -s $i -cn >> ${cur_log_base_file}_cn
				end_time="$($DATE_EXEC -u +%s.%N)"
				elapsed="$(bc <<<"$end_time-$start_time")"
				elapsed_all_non_vio="$(bc <<<"$elapsed+$elapsed_all_non_vio")"
				echo "Runtime non-violation #$j $elapsed"
			fi

			if [ $1 != 1 ] && [ $2 -gt 0 ]
			then
				echo "first bench mark the actual result for the cases.."
				echo "python3 $KIVI_RUNNER -c $case -s $i -o >> ${cur_log_base_file}_o"
				start_time="$($DATE_EXEC -u +%s.%N)"
				python3 "$KIVI_RUNNER" -c $case -s $i -o >> ${cur_log_base_file}_o
				end_time="$($DATE_EXEC -u +%s.%N)"
				elapsed="$(bc <<<"$end_time-$start_time")"
				elapsed_all_vio_o="$(bc <<<"$elapsed+$elapsed_all_vio_o")"
				echo "Runtime #$j $elapsed"
			fi

			if [ $1 -gt 0 ] && [ $2 -gt 0 ]
			then
				echo "python3 $KIVI_RUNNER -c $case -s $i -o -cn -to 1000 >> ${cur_log_base_file}_cn_o"
				start_time="$($DATE_EXEC -u +%s.%N)"
				python3 "$KIVI_RUNNER" -c $case -s $i -o -cn -to 1000 >> ${cur_log_base_file}_cn_o
				end_time="$($DATE_EXEC -u +%s.%N)"
				elapsed="$(bc <<<"$end_time-$start_time")"
				elapsed_all_non_vio_o="$(bc <<<"$elapsed+$elapsed_all_non_vio_o")"
				echo "Runtime #$j $elapsed"
			fi

			# echo "../src/model_generator.py $case $i"

			# python3 ../src/model_generator.py $path $case $i
			# ../libs/Spin/Src/spin -a ../temp/main.pml
			# gcc -o pan pan.c -DVECTORSZ=450000

			# ./pan -m10000000 >> "results/pan_exec_$case._$i._$1"
			# ./pan -r main.pml.trail >> "results/pan_error_trail_$case._$i._$1"

			# end_time="$(date -u +%s)"
			# elapsed2="$(bc <<<"$end_time-$start_time")"
			# echo "Total of $elapsed1 seconds elapsed for process"
			# echo "$i $elapsed1 $elapsed2" >> "results/exec_time_$case._$1 "
		done
		if [ $1 != 1 ] && [ $2 != 1 ]
		then
			elapsed_avg=$(echo "scale=5; $elapsed_all_vio / $count" | bc)
			echo "Avg runtime $elapsed_avg"
			echo "$case $i $elapsed_avg" >> $cur_per_file_all_violation
		fi

		if [ $1 -gt 0 ] && [ $2 != 1 ]
		then
			elapsed_non_violation_avg=$(echo "scale=5; $elapsed_all_non_vio / $count" | bc)
			echo "Avg runtime $elapsed_non_violation_avg"
			#echo "$i $elapsed_avg $elapsed_non_violation_avg" >> $cur_per_cn_file
			echo "$case $i $elapsed_non_violation_avg" >> $cur_per_file_all_non_violation
		fi

		if [ $1 != 1 ] && [ $2 -gt 0 ]
		then
			elapsed_violation_avg=$(echo "scale=5; $elapsed_all_vio_o / $count" | bc)
			echo "Avg runtime $elapsed_violation_avg"
			echo "$i $elapsed_violation_avg" >> $cur_per_file
		fi

		if [ $1 -gt 0 ] && [ $2 -gt 0 ]
		then
			elapsed_non_violation_avg=$(echo "scale=5; $elapsed_all_non_vio_o / $count" | bc)
			echo "Avg runtime $elapsed_non_violation_avg"
			echo "$i $elapsed_non_violation_avg" >> $cur_per_cn_file
		fi
	done
done

# cd eval
# gnuplot eval/plot.plt
