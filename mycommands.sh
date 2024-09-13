#!/bin/bash

####################
# Config has moved to bashbot.conf
if [[ -r "${BASHBOT_ETC:-.}/mycommands.conf" ]]; then
	# shellcheck source=/dev/null
	source "${BASHBOT_ETC:-.}/mycommands.conf"  "$1"
fi

##################
# lets's go
if [ "$1" = "startbot" ];then
	###################
	# this section is processed on startup

	# run once after startup when the first message is received
	my_startup(){
		:
	}
	touch .mystartup
else
	# call my_startup on first message after startup
	# things to do only once
	[ -f .mystartup ] && rm -f .mystartup && _exec_if_function my_startup

	#############################
	# your own bashbot commands
	# NOTE: command can have @botname attached, you must add * to case tests...
	mycommands() {

		##############
		# a service Message was received
		# add your own stuff here
		if [ -n "${SERVICE}" ]; then
			# example: delete every service message
			if [ "${SILENCER}" = "yes" ]; then
				# shellcheck disable=SC2153
				delete_message "${CHAT[ID]}" "${MESSAGE[ID]}"
			fi
		fi

		# remove keyboard if you use keyboards
		[[ -n "${REMOVEKEYBOARD}" ]] && remove_keyboard "${CHAT[ID]}" &
		[[ -n "${REMOVEKEYBOARD_PRIVATE}" &&  "${CHAT[ID]}" == "${USER[ID]}" ]] && remove_keyboard "${CHAT[ID]}" &

		# uncomment to fix first letter upper case because of smartphone auto correction
		#[[ "${MESSAGE}" =~  ^/[[:upper:]] ]] && MESSAGE="${MESSAGE:0:1}$(tr '[:upper:]' '[:lower:]' <<<"${MESSAGE:1:1}")${MESSAGE:2}"
		case "${MESSAGE}" in
			'/start'*)
				result="$(start_instance)"
				send_normal_message "${CHAT[ID]}" "${result}"
				;;
			'/raw'*)
				result="$(raw_output)"
				send_normal_message "${CHAT[ID]}" "${result}"
				;;
			'/delete'*)
				result="$(delete_instance)"
				send_normal_message "${CHAT[ID]}" "${result}"
				;;
			'/'*)
				send_normal_message "${CHAT[ID]}" "${MESSAGE} isn't a valid command."
				;;
			*)
				result="$(chat "${MESSAGE}")"
				escaped_result="$(escape_message "${result}")"
				send_markdown_message "${CHAT[ID]}" "${escaped_result}"
				;;
		esac
		}

	#####################
	# processing functions here
	deepinfra_get() {
		url="${1}"
		curl --request GET \
			--url "${url}" \
			--header "Authorization: bearer $DEEPINFRA_API_KEY"
	}

	deepinfra_post(){
		url="${1}"
		data="${2}"
		curl --request POST \
			--url "${url}" \
			--header "Authorization: bearer $DEEPINFRA_API_KEY" \
			--header 'Content-Type: application/json' \
			--data "${data}"
	}

	deepinfra_delete() {
		url="${1}"
		curl --request DELETE \
			--url "${url}" \
			--header "Authorization: bearer $DEEPINFRA_API_KEY"
	}

	escape_message() {
		message="${1}"
		# Escape |
		message="${message//|/\\|}"
		# Escape +
		message="${message//+/\\+}"
		# Escape =
		echo "${message//=/\\=}"
	}

	start_instance(){
		# Response file
		response="/tmp/${CHAT[ID]}-start_instance.response"

		# Deploy
		url="https://api.deepinfra.com/v1/deploy"
		data="{ \"provider\": \"${PROVIDER}\", \"model_name\": \"${MODEL_NAME}\" }"
		send_action "${CHAT[ID]}" "typing"
		deepinfra_post "${url}" "${data}" > "${response}"
		jq -r < "${response}"
	}

	delete_instance(){
		# Response file
		response="/tmp/${CHAT[ID]}-delete_instance.response"

		# Get deploy ID
		url="https://api.deepinfra.com/deploy/list?status=running"
		deploy_id="$(deepinfra_get "${url}" | jq -r '.[0].deploy_id')"

		# Delete the deployment
		url="https://api.deepinfra.com/deploy/${deploy_id}"
		send_action "${CHAT[ID]}" "typing"
		deepinfra_delete "${url}" > "${response}"
		jq -r < "${response}"
	}

	inference(){
		# Response file
		response="/tmp/${CHAT[ID]}-chat.response"

		# Chat
		input=$(echo "${1}" | tr '\n' ' ')
		url="https://api.deepinfra.com/v1/inference/${MODEL_NAME}"
		data="{ \"input\": \"${input}\", \"stream\": false }"
		send_action "${CHAT[ID]}" "typing"
		deepinfra_post "${url}" "${data}" > "${response}"

		send_action "${CHAT[ID]}" "typing"
		jq -r '.results[0].generated_text' < "${response}"
	}

	chat(){
		# Response file
		response="/tmp/${CHAT[ID]}-chat.response"

		# Chat
		input=$(echo "${1}" | tr '\n' ' ')
		url="https://api.deepinfra.com/v1/openai/chat/completions"
		data="{ \"model\": \"${MODEL_NAME}\", \"max_tokens\": \"${MAX_TOKENS}\", \"stream\": false, \"messages\": [ {\"role\": \"system\", \"content\": \"${SYSTEM_PROMPT}\"}, {\"role\": \"user\", \"content\": \"${input}\"} ] }"
		send_action "${CHAT[ID]}" "typing"
		deepinfra_post "${url}" "${data}" > "${response}"

		send_action "${CHAT[ID]}" "typing"
		jq -r '.choices[0].message.content' < "${response}"
	}

	raw_output(){
		# Previous response
		response="/tmp/${CHAT[ID]}-chat.response"

		# Processing
		send_action "${CHAT[ID]}" "typing"
		jq -r '' < "${response}"
	}

	###########################
	# example error processing
	# called when delete Message failed
	# func="$1" err="$2" chat="$3" user="$4" emsg="$5" remaining args
	bashbotError_delete_message() {
		log_debug "custom errorProcessing delete_message: ERR=$2 CHAT=$3 MSGID=$6 ERTXT=$5"
	}

	# called when error 403 is returned (and no func processing)
	# func="$1" err="$2" chat="$3" user="$4" emsg="$5" remaining args
	bashbotError_403() {
		log_debug "custom errorProcessing error 403: FUNC=$1 CHAT=$3 USER=${4:-no-user} MSGID=$6 ERTXT=$5"
	}
fi
