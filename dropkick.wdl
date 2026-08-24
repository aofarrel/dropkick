version 1.0

# !!! THIS ONLY WORKS WHEN RUNNING ON GOOGLE CLOUD (INCLUDING TERRA) !!!
# !!! IF YOU RUN THIS WORKFLOW LOCALLY, IT WILL JUST HANG / TIME OUT !!!

workflow Dropkick_Curl {
	input {
		String destination_bucket    # ommit gs:// and trailing slashes, ex "gs://my_cool_bucket/" should be "my_cool_bucket"
		Array[File] files_to_upload
	}

	call dropkick_curl {
		input:
			destination_bucket = destination_bucket,
			files_to_upload = files_to_upload
	}
}

task dropkick_curl {
	input {
		String destination_bucket
		Array[File] files_to_upload
	}
	Int bigness = ceil(size(files_to_upload, "GB")) + 5
	
	command <<<
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] Booted into container"
		set -eu pipefail
		set +x
		# this needs to be http, not https
		TOKEN=$(curl -s -H "Metadata-Flavor: Google" \
			http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/token \
			| sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p')
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] Grabbed token for this service account"
		for FILE in ~{sep=' ' files_to_upload}
		do
			BASENAME=$(basename "$FILE")
			echo "[$(date '+%Y-%m-%d %H:%M:%S')] Uploading $BASENAME..."
			curl -f -X POST \
			-H "Authorization: Bearer $TOKEN" \
			-H "Content-Type: application/octet-stream" \
			--data-binary @"$FILE" \
			"https://storage.googleapis.com/upload/storage/v1/b/~{destination_bucket}/o?uploadType=media&name=${BASENAME}&ifGenerationMatch=0"
		echo "[$(date '+%Y-%m-%d %H:%M:%S')] Finished"
		done
	>>>

	runtime {
		cpu: 2
		disks: "local-disk " + bigness + " SSD"
		docker: "ashedpotatoes/dropkick:0.0.3"
		memory: "8 GB"
		preemptible: 2
		maxRetries: 2
	}
}