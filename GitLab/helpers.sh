__get_parameter_list() {
	if [[ -n "$1" && "$1" != "-" ]]; then
		echo $1
	elif [ ! -t 0 ]; then
		while read in; do
			echo $in
		done
	else
		echo "Please provide either the parameter value or the stdin." >&2
	fi
}

get_group_subgroups() {
	for g in $(__get_parameter_list $1); do
		glab api $g/descendant_groups --paginate | jq -r '.[] | "groups/\(.id)"'
	done
}

get_group_and_subgroups() {
	for g in $(__get_parameter_list $1); do
		echo $g
		glab api $g/descendant_groups --paginate | jq -r '.[] | "groups/\(.id)"'
	done
}

get_group_projects() {
	for g in $(__get_parameter_list $1); do
		glab api "$g/projects?archived=false" --paginate | jq -r '.[] | "projects/\(.id)"'
	done
}

get_merge_requests() {
	for p in $(__get_parameter_list $1); do
		glab api $p/merge_requests$2 | jq '.[] | .iid' 
	done
}
