#!/bin/bash

####################
# Config has moved to bashbot.conf
# shellcheck source=./commands.sh
[ -r "${BASHBOT_ETC:-.}/mycommands.conf" ] && source "${BASHBOT_ETC:-.}/mycommands.conf"  "$1"

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
				delete_message "${CHAT[ID]}" "${MESSAGE[ID]}"
			fi
		fi

		# remove keyboard if you use keyboards
		[ -n "${REMOVEKEYBOARD}" ] && remove_keyboard "${CHAT[ID]}" &
		[[ -n "${REMOVEKEYBOARD_PRIVATE}" &&  "${CHAT[ID]}" == "${USER[ID]}" ]] && remove_keyboard "${CHAT[ID]}" &

		# uncomment to fix first letter upper case because of smartphone auto correction
		#[[ "${MESSAGE}" =~  ^/[[:upper:]] ]] && MESSAGE="${MESSAGE:0:1}$(tr '[:upper:]' '[:lower:]' <<<"${MESSAGE:1:1}")${MESSAGE:2}"
		case "${MESSAGE}" in
			'/start'*)
				result="$(start_instance)"
				send_normal_message "${CHAT[ID]}" "${result}"
				;;
			'/delete'*)
				result="$(delete_instance)"
				send_normal_message "${CHAT[ID]}" "${result}"
				;;
			*)
				result="$(inference "${MESSAGE}")"
				escaped_result="$(escape_message "${result}")"
				send_markdown_message "${CHAT[ID]}" "${escaped_result}"
				;;
		esac
		}

		mycallbacks() {
		#######################
		# callbacks from buttons attached to messages will be processed here
		case "${iBUTTON[USER_ID]}+${iBUTTON[CHAT_ID]}" in
				*)	# all other callbacks are processed here
			local callback_answer
			: # your processing here ...
			:
			# Telegram needs an ack each callback query, default empty
			answer_callback_query "${iBUTTON[ID]}" "${callback_answer}"
			;;
		esac
		}
		myinlines() {
		#######################
		# this fuinction is called only if you has set INLINE=1 !!
		# shellcheck disable=SC2128
		iQUERY="${iQUERY,,}"
		
		case "${iQUERY}" in
			##################
			# example inline command, replace it by your own
			"image "*) # search images with yahoo
				local search="${iQUERY#* }"
				answer_inline_multi "${iQUERY[ID]}" "$(my_image_search "${search}")"
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
		# Output stream
		output="/tmp/${CHAT[ID]}-start_instance.response"

		# Deploy
		url="https://api.deepinfra.com/v1/deploy"
		data="{ \"provider\": \"${PROVIDER}\", \"model_name\": \"${MODEL_NAME}\", \"version\": \"${VERSION}\" }"
		send_action "${CHAT[ID]}" "typing"
		deepinfra_post "${url}" "${data}" > "${output}"
		jq -r < "${output}"
	}

	delete_instance(){
		# Output stream
		output="/tmp/${CHAT[ID]}-delete_instance.response"

		# Get deploy ID
		url="https://api.deepinfra.com/deploy/list?status=running"
		deploy_id="$(deepinfra_get "${url}" | jq -r '.[0].deploy_id')"

		# Delete the deployment
		url="https://api.deepinfra.com/deploy/${deploy_id}"
		send_action "${CHAT[ID]}" "typing"
		deepinfra_delete "${url}" > "${output}"
		jq -r < "${output}"
	}

	inference(){
		# Output stream
		output="/tmp/${CHAT[ID]}-inference.response"

		# Chat
		input="${1}"
		url="https://api.deepinfra.com/v1/inference/${MODEL_NAME}"
		data="{ \"input\": \"${input}\", \"stream\": false }"
		send_action "${CHAT[ID]}" "typing"
		deepinfra_post "${url}" "${data}" > "${output}"

		send_action "${CHAT[ID]}" "typing"
		jq -r '.results[0].generated_text' < "${output}"
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
