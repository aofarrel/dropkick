version 1.0

# !!! THIS ONLY WORKS WHEN RUNNING ON GOOGLE CLOUD (INCLUDING TERRA) !!!
# !!! IF YOU RUN THIS WORKFLOW LOCALLY, IT WILL JUST HANG / TIME OUT !!!

workflow Test_Upload_Curl {
	input {
		# ommit gs:// and trailing slashes, ex "gs://my_cool_bucket/" should be "my_cool_bucket"
		String destination_bucket
	}

	call touch_curl {
		input:
			destination_bucket = destination_bucket
	}

	# If you run this, the workflow will fail (intentionally)
	#call verify_no_overwrite_curl {
	#	input:
	#		destination_bucket = destination_bucket,
	#		run_after_touch = touch_curl.prevent_race_condition
	#}
}

task touch_curl {
	# This requires the account has storage.objects.create, but doesn't require storage.objects.list
	input {
		String destination_bucket
	}
	
	command <<<
		set -eu pipefail
		set +x
		touch foo.txt
		# this needs to be http, not https
		TOKEN=$(curl -s -H "Metadata-Flavor: Google" \
			http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token \
			| sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
		echo "Now uploading..."
		curl -f -X POST \
			-H "Authorization: Bearer $TOKEN" \
			-H "Content-Type: application/octet-stream" \
			--data-binary @foo.txt \
			"https://storage.googleapis.com/upload/storage/v1/b/~{destination_bucket}/o?uploadType=media&name=foo.txt&ifGenerationMatch=0"
	>>>

	runtime {
		cpu: 2
		disks: "local-disk " + 10 + " HDD"
		docker: "ashedpotatoes/dropkick:0.0.2"
		memory: "4 GB"
		preemptible: 2
	}

	output {
		Boolean prevent_race_condition = true
	}
}

task verify_no_overwrite_curl {
	# This requires the account has storage.objects.create, but doesn't require storage.objects.list
	# If foo.txt already exists, this task is expected to fail
	input {
		String destination_bucket
		Boolean run_after_touch #!UnusedDeclaration
	}
	
	command <<<
		set -eu pipefail
		set +x
		echo "some text here to make this not a zero byte file" > foo.txt
		TOKEN=$(curl -s -H "Metadata-Flavor: Google" \
			http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token \
			| sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
		echo "Now uploading..."
		curl -f -X POST \
			-H "Authorization: Bearer $TOKEN" \
			-H "Content-Type: application/octet-stream" \
			--data-binary @foo.txt \
			"https://storage.googleapis.com/upload/storage/v1/b/~{destination_bucket}/o?uploadType=media&name=foo.txt&ifGenerationMatch=0"
	>>>

	runtime {
		cpu: 2
		disks: "local-disk " + 10 + " HDD"
		docker: "ashedpotatoes/dropkick:0.0.2"
		memory: "4 GB"
		preemptible: 2
	}
}